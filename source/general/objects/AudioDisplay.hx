package general.objects;

import openfl.geom.Rectangle;
import funkin.vis.dsp.SpectralAnalyzer;
import funkin.vis.dsp.SpectralAnalyzer.Bar;

/**
 * Main-menu spectrum rendered as one cached sprite texture.
 *
 * The previous implementation created and submitted one FlxSprite per bar.
 * The first batched implementation still rebuilt and copied hundreds of
 * triangle values on every game frame.  At uncapped frame rates that work was
 * considerably more expensive than the rest of the menu.  This version keeps
 * all 100 bars, but rasterizes them into a private, moderately sized texture at
 * a visual refresh rate.  Normal frames only submit one cached sprite quad.
 */
class AudioDisplay extends FlxSprite
{
	var analyzer:SpectralAnalyzer;

	public var snd:FlxSound;
	public var symmetry:Bool = false;
	public var stopUpdate:Bool = false;
	public var amplitude:Float = 0;

	var line:Int;
	var displayWidth:Int;
	var displayHeight:Int;
	var bitmapWidth:Int;
	var bitmapHeight:Int;
	var barStep:Float;
	var barWidth:Float;
	var barHeights:Array<Float> = [];
	var barColor:FlxColor;
	var drawRect:Rectangle = new Rectangle();
	var saveTime:Float = 0;
	var motionTime:Float = 0;
	var getValues:Array<Bar>;

	static inline final MAX_VISUAL_RATE:Float = 120;
	static inline final MAX_BITMAP_WIDTH:Int = 512;

	public function new(snd:FlxSound = null, X:Float = 0, Y:Float = 0,
		Width:Int, Height:Int, line:Int, gap:Int, Color:FlxColor,
		symmetry:Bool = false)
	{
		super(X, Y);

		this.snd = snd;
		this.line = Std.int(Math.max(1, line));
		this.symmetry = symmetry;
		displayWidth = Width;
		displayHeight = Height;
		barColor = Color;

		// The texture is deliberately smaller than the display.  Spectrum bars
		// do not contain fine detail, and scaling this bitmap saves both CPU
		// raster work and GPU upload bandwidth when its shape changes.
		bitmapWidth = Std.int(Math.min(MAX_BITMAP_WIDTH, Math.max(1, Width)));
		bitmapHeight = Std.int(Math.max(1, Math.ceil(Height * bitmapWidth / Width)));
		barStep = bitmapWidth / this.line;
		barWidth = Math.max(1, barStep - gap * bitmapWidth / Width);

		makeGraphic(bitmapWidth, bitmapHeight, FlxColor.TRANSPARENT, true);
		setGraphicSize(displayWidth, displayHeight);
		updateHitbox();
		x = X;
		y = Y - displayHeight;
		buildBars();
		rasterizeBars();

		@:privateAccess
		if (snd != null && snd._channel != null && snd._channel.__audioSource != null)
		{
			analyzer = new SpectralAnalyzer(snd._channel.__audioSource,
				Std.int(this.line + Math.abs(0.05 *
					(4 - ClientPrefs.data.audioDisplayQuality))), 1, 5);
			analyzer.fftN = 256 * ClientPrefs.data.audioDisplayQuality;
		}
	}

	function buildBars():Void
	{
		final minimum = bitmapHeight / 40;
		for (i in 0...line)
			barHeights.push(minimum);
	}

	override function update(elapsed:Float):Void
	{
		if (stopUpdate)
			return;

		saveTime += elapsed * 1000;
		motionTime += elapsed;
		final sampleInterval = Math.max(1000 / MAX_VISUAL_RATE,
			ClientPrefs.data.audioDisplayUpdate);
		if (analyzer != null && saveTime >= sampleInterval)
		{
			saveTime %= sampleInterval;
			// Reuse both the level array and its Bar records. Passing null here
			// rebuilt roughly one hundred managed records on every FFT sample and
			// needlessly drove a Young collection every few seconds.
			getValues = analyzer.getLevels(getValues);
			updateAmplitude();
		}

		// Visual data only needs display-rate interpolation.  The engine frame
		// loop remains uncapped, while intermediate frames reuse the texture.
		if (getValues != null && motionTime >= 1 / MAX_VISUAL_RATE)
		{
			updateLine(motionTime);
			motionTime = 0;
		}
	}

	function updateAmplitude():Void
	{
		final count = Std.int(Math.min(5, getValues.length));
		if (count == 0)
		{
			amplitude = 0;
			return;
		}

		var total:Float = 0;
		for (i in 0...count)
			total += getValues[i].value;
		amplitude = total / count;
	}

	function addAnalyzer(snd:FlxSound):Void
	{
		@:privateAccess
		if (snd != null && snd._channel != null && snd._channel.__audioSource != null && analyzer == null)
		{
			analyzer = new SpectralAnalyzer(snd._channel.__audioSource, line, 1, 5);
			analyzer.fftN = 256 * ClientPrefs.data.audioDisplayQuality;
		}
	}

	function updateLine(elapsed:Float):Void
	{
		if (getValues == null || getValues.length == 0)
			return;

		final minimum = bitmapHeight / 40;
		final blend = Math.exp(-elapsed * 16);
		final volume = FlxG.sound.volume;
		for (i in 0...line)
		{
			var valueIndex = symmetry && i >= line / 2 ? line - 1 - i : i;
			if (valueIndex >= getValues.length)
				valueIndex = getValues.length - 1;
			final target = Math.round(
				getValues[valueIndex].value * bitmapHeight * volume);
			final height = Math.max(minimum,
				FlxMath.lerp(target, barHeights[i], blend));
			barHeights[i] = height;
		}
		rasterizeBars();
	}

	function rasterizeBars():Void
	{
		final bitmap = pixels;
		if (bitmap == null)
			return;

		bitmap.lock();
		bitmap.fillRect(bitmap.rect, FlxColor.TRANSPARENT);
		for (i in 0...line)
		{
			final x0 = Std.int(barStep * i);
			final x1 = Std.int(Math.min(bitmapWidth, Math.ceil(barStep * i + barWidth)));
			final height = Std.int(Math.min(bitmapHeight, Math.ceil(barHeights[i])));
			drawRect.setTo(x0, bitmapHeight - height, Math.max(1, x1 - x0), height);
			bitmap.fillRect(drawRect, barColor);
		}
		bitmap.unlock();
		dirty = true;
	}

	public function changeAnalyzer(snd:FlxSound):Void
	{
		@:privateAccess
		if (snd != null && snd._channel != null && snd._channel.__audioSource != null)
		{
			if (analyzer == null)
				addAnalyzer(snd);
			else
				analyzer.changeSnd(snd._channel.__audioSource);
			this.snd = snd;
			stopUpdate = false;
		}
	}

	public function clearUpdate():Void
	{
		final minimum = bitmapHeight / 40;
		for (i in 0...line)
			barHeights[i] = minimum;
		rasterizeBars();
	}
}
