package general.objects.state.relaxState.backend;
#if RELAX_ALLOWED

import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;

/**
 * 空心三角粒子。
 *
 * ============================================================
 * 为什么之前完全看不到粒子
 * ============================================================
 * 旧实现每帧做 `emissionRate = emissionRate * externalSpeedFactor / 50`，
 * 这是**自己乘自己**：进 Relax 时振幅还是 0（`clearUpdate()` 会先清零），
 * 第一帧就把 emissionRate 乘成 0，而 0 乘任何数永远是 0 —— 之后再也发不出粒子。
 * 就算振幅不为 0，0.3 的振幅也只会得到 0.006 颗/秒，等于没有。
 *
 * 第二个问题：粒子判定出屏用的是 `y + height < 0`，而 height 是那张 1200×1200 的位图高度，
 * 速度只有 5~10px/s，一颗要飘 2~6 分钟才死；池子满了之后 `getAvailableTriangle()`
 * 还会无上限地新建，每颗一张 5.76MB 位图 —— 越播越占内存。
 *
 * ============================================================
 * 现在的实现
 * ============================================================
 * - 粒子只是纯数据（坐标 / 尺寸 / 速度），不再是一张张 1200² 位图；
 *   全部三角形写进同一份顶点缓冲，一次 `camera.drawTriangles()` 画完。
 * - 发射率 = 每秒基础颗数 × 振幅系数，不再自乘，振幅为 0 时也留一个最低节奏。
 * - 出屏判定按三角形自身尺寸，池子固定 poolSize，满了就回收最早的一颗。
 */
class HollowTriangleEmitter extends FlxSprite
{
	/** 基础发射频率（颗/秒，振幅为 0 时） */
	public var emissionRate:Float = 3;

	/** 跟随音乐振幅（0~1），既加快发射也加快上升速度 */
	public var externalSpeedFactor:Float = 0;

	var emissionTimer:Float = 0;

	var minTriangleSize:Int = 100;
	var maxTriangleSize:Int = 400;
	var minSpeed:Int = 5;
	var maxSpeed:Int = 10;

	/** 粒子池上限 */
	var poolSize:Int = 100;

	var px:Array<Float> = [];
	var py:Array<Float> = [];
	var pSize:Array<Float> = [];
	var pSpeed:Array<Float> = [];
	var pAlive:Array<Bool> = [];
	/** 已存活时间，回收时用它挑最老的一颗 */
	var pAge:Array<Float> = [];
	var aliveCount:Int = 0;

	var vertices:DrawData<Float>;
	var indices:DrawData<Int>;
	var uvtData:DrawData<Float>;

	/** 死掉的槽位统一落到这个坐标，退化三角形不占像素 */
	static inline var DEAD_COORD:Float = -9999;

	static var triTexture:FlxGraphic = null;

	public function new()
	{
		super(0, 0);

		graphic = getTexture();

		for (i in 0...poolSize)
		{
			px.push(0);
			py.push(0);
			pSize.push(0);
			pSpeed.push(0);
			pAlive.push(false);
			pAge.push(0);
		}

		buildBuffers();
	}

	static function getTexture():FlxGraphic
	{
		if (triTexture == null)
		{
			// 旧实现 drawPolygon 的 FillColor 就是 FlxColor.BLACK —— 实心黑三角。
			// 直接烘进贴图，颜色不用再走 colorTransform；整体透明度仍由 alpha 控制。
			triTexture = FlxG.bitmap.create(4, 4, FlxColor.BLACK, false, 'relaxTriangleParticleTexture');
			triTexture.persist = true;
			triTexture.destroyOnNoUse = false;
		}
		return triTexture;
	}

	function buildBuffers():Void
	{
		vertices = new DrawData<Float>();
		indices = new DrawData<Int>();
		uvtData = new DrawData<Float>();

		for (i in 0...poolSize)
		{
			var v:Int = i * 3;

			for (_ in 0...6)
				vertices.push(DEAD_COORD);

			for (_ in 0...6)
				uvtData.push(0.5);

			indices.push(v);
			indices.push(v + 1);
			indices.push(v + 2);
		}
	}

	/** 取一个空槽；满了就回收当前最老的一颗 */
	function acquireSlot():Int
	{
		var oldest:Int = 0;
		var oldestAge:Float = -1;

		for (i in 0...poolSize)
		{
			if (!pAlive[i])
				return i;

			if (pAge[i] > oldestAge)
			{
				oldestAge = pAge[i];
				oldest = i;
			}
		}

		return oldest;
	}

	public function spawnTriangle():Void
	{
		var i:Int = acquireSlot();
		if (!pAlive[i]) aliveCount++;

		var size:Float = FlxG.random.int(minTriangleSize, maxTriangleSize);

		px[i] = FlxG.random.float(0, FlxG.width);
		py[i] = FlxG.height + size;
		pSize[i] = size;
		pSpeed[i] = -FlxG.random.int(minSpeed, maxSpeed);
		pAge[i] = 0;
		pAlive[i] = true;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var amp:Float = FlxMath.bound(externalSpeedFactor, 0, 1);
		var playing:Bool = (FlxG.sound.music != null && FlxG.sound.music.playing);

		// 发射：基础频率 + 振幅加成，不再自乘
		if (playing)
		{
			var rate:Float = emissionRate * (0.4 + 1.6 * amp);
			emissionTimer += elapsed;

			var interval:Float = (rate > 0.01) ? (1 / rate) : 999;
			var guard:Int = 0;

			while (emissionTimer >= interval && guard < 4)
			{
				emissionTimer -= interval;
				spawnTriangle();
				guard++;
			}
		}
		else
		{
			emissionTimer = 0;
		}

		var rise:Float = -(amp * 100);

		for (i in 0...poolSize)
		{
			if (!pAlive[i]) continue;

			py[i] += (pSpeed[i] + rise) * elapsed;
			pAge[i] += elapsed;

			// 按三角形自己的尺寸判出屏 —— 旧实现误用了位图高度，粒子要飘好几分钟才死
			if (py[i] + pSize[i] * 0.5 < 0)
			{
				pAlive[i] = false;
				aliveCount--;
			}
		}
	}

	override function draw():Void
	{
		if (graphic == null || alpha <= 0 || aliveCount <= 0)
			return;

		writeVertices();

		for (camera in cameras)
		{
			if (camera == null || !camera.visible || !camera.exists)
				continue;

			getScreenPosition(_point, camera).subtractPoint(offset);

			camera.drawTriangles(graphic, vertices, indices, uvtData, null, _point, blend, false, antialiasing, colorTransform, shader);
		}
	}

	/** 把存活粒子展开成三角形顶点；死槽位写成退化三角形 */
	function writeVertices():Void
	{
		for (i in 0...poolSize)
		{
			var p:Int = i * 6;

			if (!pAlive[i])
			{
				for (k in 0...3)
				{
					vertices[p + k * 2] = DEAD_COORD;
					vertices[p + k * 2 + 1] = DEAD_COORD;
				}
				continue;
			}

			var cx:Float = px[i];
			var cy:Float = py[i];
			var half:Float = pSize[i] * 0.5;

			vertices[p] = cx;
			vertices[p + 1] = cy - half;
			vertices[p + 2] = cx - half;
			vertices[p + 3] = cy + half;
			vertices[p + 4] = cx + half;
			vertices[p + 5] = cy + half;
		}
	}

	public function setParams(rate:Float = 5, minS:Int = 40, maxS:Int = 80, minSpd:Int = 30, maxSpd:Int = 60):Void
	{
		emissionRate = rate;
		minTriangleSize = minS;
		maxTriangleSize = maxS;
		minSpeed = minSpd;
		maxSpeed = maxSpd;
	}

	/** 清空所有粒子（切歌 / 重进界面时用） */
	public function clearParticles():Void
	{
		for (i in 0...poolSize)
		{
			pAlive[i] = false;
			pAge[i] = 0;
		}
		aliveCount = 0;
		emissionTimer = 0;
	}

	override function destroy():Void
	{
		px = null;
		py = null;
		pSize = null;
		pSpeed = null;
		pAlive = null;
		pAge = null;
		vertices = null;
		indices = null;
		uvtData = null;

		super.destroy();
	}
}
#end
