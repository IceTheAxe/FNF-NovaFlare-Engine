package general.objects;

import funkin.vis.dsp.SpectralAnalyzer;
import funkin.vis.dsp.SpectralAnalyzer.Bar;

import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;

import lime.media.AudioSource;

/**
 * 环形频谱。
 *
 * 旧实现是 `line * Number` 个 Rect 精灵拼成一圈（两者乘积恒为 120），
 * 于是每帧固定 120 次 draw call，另外还有 120 个对象各自跑一遍 update / 变换。
 *
 * 现在整圈折进一个 FlxSprite：谱条不再是个体对象，只是同一份顶点缓冲里的一段四边形，
 * 一次 `camera.drawTriangles()` 画完。顶点缓冲每帧原地覆盖，不产生临时分配。
 */
class AudioCircleDisplay extends FlxSprite
{
	public var analyzer:SpectralAnalyzer;

	public var snd:FlxSound;

	var boundAudioSource:AudioSource;

	/** 谱条最大长度（像素） */
	var barHeight:Int;

	/** 单根谱条宽度（像素） */
	var barWidth:Float = 4;

	public var line:Int;

	public var Radius:Float = 0;

	public var symmetry:Bool = true;

	public var Number:Int = 1;

	/** Relax 界面用独立画质档位（RelaxAudioDisplayQuality），不复用主菜单的 audioDisplayQuality */
	public var inRelax:Bool = false;

	public var Rotate:Bool = false;
	public var RotateSpeed:Float = 1;

	/** 谱条总数 = line * Number，恒为 120 */
	var barCount:Int = 0;

	/** 每根谱条的方向角（弧度，屏幕坐标系：y 轴向下）及其三角函数缓存 */
	var barAngle:Array<Float>;
	var barCos:Array<Float>;
	var barSin:Array<Float>;

	/** 每根谱条当前长度（像素），等价于旧实现的 sprite.scale.y */
	var barLength:Array<Float>;

	var vertices:DrawData<Float>;
	var indices:DrawData<Int>;
	var uvtData:DrawData<Float>;

	public var stopUpdate:Bool = false;

	public var amplitude:Float = 0;

	var saveTime:Float = 0;
	var getValues:Array<Bar>;

	/** 所有谱条共用的一张纯白贴图，颜色与实际 alpha 都走 colorTransform */
	static var barTexture:FlxGraphic = null;

	public function new(snd:FlxSound = null, X:Float = 0, Y:Float = 0, Width:Int, Height:Int, line:Int, gap:Int, Color:FlxColor, Radius:Float = 40,
			symmetry:Bool = true, Number:Int = 5)
	{
		super(X, Y);

		this.snd = snd;
		this.line = line;
		this.Radius = Radius;
		this.symmetry = symmetry;

		if (Number < 1)
			Number = 1;

		this.Number = Number;

		barWidth = (gap > 0) ? gap : 1;
		barHeight = Height;

		graphic = getBarTexture();
		color = Color;

		barCount = line * this.Number;

		barAngle = [];
		barCos = [];
		barSin = [];
		barLength = [];

		for (i in 0...barCount)
		{
			// 与旧实现一致：第 i 根谱条的方向 = 环上角度减去 90°，所以 0° 在正上方、顺时针递增
			var angle:Float = (i * 360 / barCount + 1 - 90) * (Math.PI / 180);
			barAngle.push(angle);
			barCos.push(Math.cos(angle));
			barSin.push(Math.sin(angle));
			barLength.push(barHeight / 40);
		}

		buildStaticBuffers();

		// 不在这里绑定分析器：FlxG.sound.playMusic 每次切歌都会换掉 sound 的 channel，
		// 构造期抓到的 AudioSource 会被释放。绑定统一放到 update 里做（见 refreshAnalyzerBinding）。
	}

	static function getBarTexture():FlxGraphic
	{
		if (barTexture == null)
		{
			// 4x4 纯白即可：顶点 uv 全部取纹理中心，靠 colorTransform 上色与淡入淡出
			barTexture = FlxG.bitmap.create(4, 4, FlxColor.WHITE, false, 'relaxSpectrumBarTexture');
			barTexture.persist = true;
			barTexture.destroyOnNoUse = false;
		}
		return barTexture;
	}

	/** 索引与 uv 永不变化，建一次即可；顶点每帧只改坐标 */
	function buildStaticBuffers():Void
	{
		vertices = new DrawData<Float>();
		indices = new DrawData<Int>();
		uvtData = new DrawData<Float>();

		for (i in 0...barCount)
		{
			var v:Int = i * 4;

			// 4 个顶点 × (x, y)
			for (_ in 0...8)
				vertices.push(0);

			// 4 个顶点 × (u, v)，只采样纯白贴图的中心
			for (_ in 0...8)
				uvtData.push(0.5);

			indices.push(v);
			indices.push(v + 1);
			indices.push(v + 2);
			indices.push(v);
			indices.push(v + 2);
			indices.push(v + 3);
		}
	}

	/** 把每根谱条的当前长度展开成四边形顶点（局部坐标，相对本对象的世界位置） */
	function updateVertices():Void
	{
		var half:Float = barWidth * 0.5;
		var p:Int = 0;

		for (i in 0...barCount)
		{
			var c:Float = barCos[i];
			var s:Float = barSin[i];

			// 谱条根部落在半径 Radius 处，沿法线方向向外生长
			var bx:Float = c * Radius;
			var by:Float = s * Radius;
			var ex:Float = bx + c * barLength[i];
			var ey:Float = by + s * barLength[i];

			// 垂直于生长方向的半宽偏移
			var px:Float = -s * half;
			var py:Float = c * half;

			vertices[p++] = bx - px;
			vertices[p++] = by - py;
			vertices[p++] = bx + px;
			vertices[p++] = by + py;
			vertices[p++] = ex + px;
			vertices[p++] = ey + py;
			vertices[p++] = ex - px;
			vertices[p++] = ey - py;
		}
	}

	override function draw():Void
	{
		if (graphic == null || alpha <= 0 || barCount <= 0)
			return;

		updateVertices();

		for (camera in cameras)
		{
			if (camera == null || !camera.visible || !camera.exists)
				continue;

			getScreenPosition(_point, camera).subtractPoint(offset);

			// 整圈谱条 = 一次 drawTriangles
			camera.drawTriangles(graphic, vertices, indices, uvtData, null, _point, blend, false, antialiasing, colorTransform, shader);
		}
	}

	/** 当前真正在播的音频源；切歌/换 channel 后可能和已绑定的不同 */
	function getCurrentAudioSource():AudioSource
	{
		var source:AudioSource = null;
		@:privateAccess
		if (snd != null && snd._channel != null && snd._channel.__audioSource != null)
		{
			var candidate:AudioSource = snd._channel.__audioSource;
			if (candidate.buffer != null && candidate.buffer.data != null
				&& candidate.buffer.data.length > 0)
				source = candidate;
		}
		return source;
	}

	function refreshAnalyzerBinding():Void
	{
		var source = getCurrentAudioSource();
		if (source == boundAudioSource)
			return;

		getValues = null;
		amplitude = 0;
		saveTime = 0;
		clearUpdate();

		if (source == null)
		{
			if (analyzer != null)
				analyzer.changeSnd(null);
			boundAudioSource = null;
			return;
		}

		var quality:Int = Std.int(inRelax ? ClientPrefs.data.RelaxAudioDisplayQuality : ClientPrefs.data.audioDisplayQuality);
		if (quality < 1)
			quality = 1;

		if (analyzer == null)
		{
			analyzer = new SpectralAnalyzer(source, Std.int(line + Math.abs(0.05 * (4 - quality))), 1, 5);
			analyzer.fftN = 256 * quality;
		}
		else
			analyzer.changeSnd(source);

		boundAudioSource = source;
	}

	override function update(elapsed:Float):Void
	{
		if (stopUpdate)
			return;

		// 切歌后 channel 会被替换，必须重新绑定，否则拿到的是已释放的 AudioSource
		refreshAnalyzerBinding();

		if (Rotate)
			rotateBars(elapsed);

		if (saveTime < ClientPrefs.data.audioDisplayUpdate)
		{
			saveTime += (elapsed * 1000);
			stepBars(elapsed);
			return;
		}

		saveTime = 0;

		// 复用 getValues：原本每个采样周期都新分配一整条 Bar 数组，20Hz 下持续制造垃圾
		if (analyzer != null)
			getValues = analyzer.getLevels(getValues);

		stepBars(elapsed);
		updateAmplitude();
	}

	function rotateBars(elapsed:Float):Void
	{
		var delta:Float = elapsed * RotateSpeed * 20 * (Math.PI / 180);

		for (i in 0...barCount)
		{
			var angle:Float = barAngle[i] + delta;
			barAngle[i] = angle;
			barCos[i] = Math.cos(angle);
			barSin[i] = Math.sin(angle);
		}
	}

	function stepBars(elapsed:Float):Void
	{
		if (getValues == null || getValues.length < line)
			return;

		var volume:Float = FlxG.sound.volume;
		var smooth:Float = Math.exp(-elapsed * 16);
		var minLength:Float = barHeight / 40;

		for (i in 0...line)
		{
			var target:Float;

			if (i >= line / 2 && symmetry)
				target = Math.round(getValues[line - i].value * barHeight);
			else
				target = Math.round(getValues[i].value * barHeight);

			target = Math.round(target * volume);

			for (i1 in 0...Number)
			{
				var index:Int = i + i1 * line;
				if (index >= barCount)
					continue;

				var length:Float = FlxMath.lerp(target, barLength[index], smooth);
				if (length < minLength)
					length = minLength;

				barLength[index] = length;
			}
		}
	}

	function updateAmplitude():Void
	{
		if (getValues == null || getValues.length <= 0)
			return;

		var helpAmplitude:Float = 0;
		var sampleCount:Int = Std.int(Math.min(5, getValues.length));

		for (i in 0...sampleCount)
			helpAmplitude += getValues[i].value;

		amplitude = helpAmplitude / sampleCount;
	}

	public function changeAnalyzer(snd:FlxSound)
	{
		@:privateAccess
		if (snd != null && snd._channel != null)
		{
			analyzer.changeSnd(snd._channel.__audioSource);
			boundAudioSource = snd._channel.__audioSource;
		}

		stopUpdate = false;
	}

	/** 把所有谱条收回最短长度（切歌 / 重绑分析器时用） */
	public function clearUpdate()
	{
		var minLength:Float = barHeight / 40;

		for (i in 0...barCount)
			barLength[i] = minLength;
	}

	override function destroy():Void
	{
		barCount = 0;
		barAngle = null;
		barCos = null;
		barSin = null;
		barLength = null;
		vertices = null;
		indices = null;
		uvtData = null;

		super.destroy();
	}
}
