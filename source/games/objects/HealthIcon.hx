package games.objects;

import openfl.display.BitmapData;
import openfl.utils.AssetType;
#if sys
import sys.FileSystem;
#end

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;

	private var isOldIcon:Bool = false;
	private var isPlayer:Bool = false;
	private var char:String = '';
	/** 图标图片标识（icons/<char> 等），波形取主色的缓存与磁盘回读用 */
	public var iconKey:String = null;

	public function new(char:String = 'bf', isPlayer:Bool = false, ?allowGPU:Bool = true)
	{
		super();
		isOldIcon = (char == 'bf-old');
		this.isPlayer = isPlayer;
		changeIcon(char, allowGPU);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	private var iconOffsets:Array<Float> = [0, 0];

	public function changeIcon(char:String, ?allowGPU:Bool = true)
	{
		if (this.char != char)
		{
			// 名字解析放在缓存判定外：即使命中 Frame 缓存也要留下 iconKey，供波形取主色用
			var name:String = 'icons/' + char;
			if (!Paths.fileExists('images/' + name + '.png', IMAGE))
				name = 'icons/icon-' + char; // Older versions of psych engine's support
			if (!Paths.fileExists('images/' + name + '.png', IMAGE))
				name = 'icons/icon-face'; // Prevents crash from missing icon
			this.iconKey = name;

			if (Cache.checkFrame('icon-' + Mods.currentModDirectory + '-' + char) == false) {
				var spr = new FlxSprite();
				var graphic = Paths.image(name, allowGPU);
				var delimiter:Int = (Math.floor(graphic.width / 3) >= graphic.height) ? 3 : 2;
				spr.loadGraphic(graphic, true, Math.floor(graphic.width / delimiter), graphic.height);
				updateHitbox();
				Cache.setFrame('icon-' + Mods.currentModDirectory + '-' + char, {graphic:null, frame:spr.frames});
			}

			frames = Cache.getFrame('icon-' + Mods.currentModDirectory + '-' + char);
			animation.add(char, [for (i in 0...numFrames) i], 0, false, isPlayer);
			updateHitbox();
			animation.play(char);

			this.char = char;

			if (char.endsWith('-pixel'))
				antialiasing = false;
			else
				antialiasing = ClientPrefs.data.antialiasing;
		}
	}

	// win icon from https://github.com/ShadowMario/FNF-PsychEngine/issues/13642#issuecomment-1819278538
	public var autoAdjustOffset:Bool = true;

	override function updateHitbox()
	{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}

	public function getCharacter():String
	{
		return char;
	}

	/**
	 * 图标主色（谱面编辑器给波形染色用，FE 同款移植）。
	 *
	 * GPU Caching 之后 sprite 的 BitmapData 不可读，getPixel32 会静默返回 0，所以读不到就
	 * 从磁盘临时解一份。只采首帧，按 HSV 色相分 24 桶、用 saturation*brightness 加权：
	 * 白眼睛/高光、黑描边这类无彩或极暗像素不参与，避免主色跑偏。
	 */
	public function getDominantColor():Int
	{
		if(iconKey == null) return 0xFF808080;

		var cacheKey:String = (Mods.currentModDirectory != null ? Mods.currentModDirectory + '|' : '') + iconKey;
		if(dominantColorCache.exists(cacheKey))
			return dominantColorCache.get(cacheKey);

		var bitmap:BitmapData = null;
		var temporary:Bool = false;
		if(graphic != null && graphic.bitmap != null && graphic.bitmap.readable)
			bitmap = graphic.bitmap;

		#if sys
		if(bitmap == null)
		{
			try
			{
				var file:String = Paths.getPath('images/$iconKey.png', IMAGE);
				if(file != null && FileSystem.exists(file))
				{
					bitmap = BitmapData.fromFile(file);
					temporary = bitmap != null;
				}
			}
			catch(e:Dynamic) {}
		}
		#end

		var color:Int = 0xFF808080;
		if(bitmap != null)
		{
			var sampleW:Int = frameWidth > 0 ? frameWidth : bitmap.width;
			var sampleH:Int = frameHeight > 0 ? frameHeight : bitmap.height;
			color = dominantColorFrom(bitmap, sampleW, sampleH);
			if(temporary) bitmap.dispose();
		}

		dominantColorCache.set(cacheKey, color);
		return color;
	}

	static var dominantColorCache:Map<String, Int> = new Map();

	/** 采样位图首帧，返回最有存在感的彩色；整张图基本无彩色时退回平均灰度。 */
	static function dominantColorFrom(bitmap:BitmapData, sampleW:Int, sampleH:Int):Int
	{
		var step:Int = 2;
		var buckets:Int = 24; // 每桶 15°
		var maxX:Int = Std.int(Math.min(sampleW, bitmap.width));
		var maxY:Int = Std.int(Math.min(sampleH, bitmap.height));

		var weight:Array<Float> = [for (i in 0...buckets) 0.0];
		var sumR:Array<Float> = [for (i in 0...buckets) 0.0];
		var sumG:Array<Float> = [for (i in 0...buckets) 0.0];
		var sumB:Array<Float> = [for (i in 0...buckets) 0.0];

		var graySum:Float = 0;
		var grayCount:Int = 0;

		var py:Int = 0;
		while (py < maxY)
		{
			var px:Int = 0;
			while (px < maxX)
			{
				var pixel:Int = bitmap.getPixel32(px, py);
				px += step;

				if(((pixel >>> 24) & 0xFF) < 128) continue;

				var r:Int = (pixel >> 16) & 0xFF;
				var g:Int = (pixel >> 8) & 0xFF;
				var b:Int = pixel & 0xFF;

				graySum += (r + g + b) / 3;
				grayCount++;

				var maxC:Float = Math.max(r, Math.max(g, b));
				var minC:Float = Math.min(r, Math.min(g, b));
				var brightness:Float = maxC / 255;
				var delta:Float = maxC - minC;
				var saturation:Float = maxC > 0 ? delta / maxC : 0;

				if(brightness < 0.12) continue; // 黑描边
				if(saturation < 0.15 && brightness > 0.9) continue; // 白眼睛 / 高光

				var hue:Float = 0;
				if(delta > 0)
				{
					if(maxC == r) hue = 60 * ((g - b) / delta);
					else if(maxC == g) hue = 60 * ((b - r) / delta + 2);
					else hue = 60 * ((r - g) / delta + 4);
					if(hue < 0) hue += 360;
				}

				var bucket:Int = Std.int(hue / 15) % buckets;
				var w:Float = saturation * brightness;
				weight[bucket] += w;
				sumR[bucket] += r * w;
				sumG[bucket] += g * w;
				sumB[bucket] += b * w;
			}
			py += step;
		}

		var best:Int = -1;
		var bestWeight:Float = 0;
		for (i in 0...buckets)
		{
			if(weight[i] > bestWeight)
			{
				bestWeight = weight[i];
				best = i;
			}
		}

		// bestWeight 太小 = 整张图基本没彩色（纯灰图标），用平均亮度代替
		if(best < 0 || bestWeight < 5)
		{
			if(grayCount < 1) return 0xFF808080;
			var gray:Int = Std.int(FlxMath.bound(graySum / grayCount, 0, 255));
			return FlxColor.fromRGB(gray, gray, gray);
		}

		return FlxColor.fromRGB(
			Std.int(FlxMath.bound(sumR[best] / bestWeight, 0, 255)),
			Std.int(FlxMath.bound(sumG[best] / bestWeight, 0, 255)),
			Std.int(FlxMath.bound(sumB[best] / bestWeight, 0, 255))
		);
	}
}
