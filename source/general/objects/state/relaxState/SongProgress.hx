package general.objects.state.relaxState;
#if RELAX_ALLOWED

import flixel.util.FlxSpriteUtil;

/**
 * 底部播放进度条。
 *
 * 旧实现有三个让它"摸不到"的原因：
 * 1. 构造时 y = FlxG.height - 4、高 8 —— 条子有一半在屏幕外，能点到的只有 4px；
 * 2. 命中判定用 FlxG.mouse.overlaps()，走的是成员自己的 camera 与世界坐标，
 *    和这条所在的 camHUD 不是一个空间，偏了就永远判不上；
 * 3. 纯视觉条只有几像素高，本身就是最小可点面积，鼠标压不住。
 *
 * 现在：整体挪到按钮块上方，判定改成"屏幕坐标 + 上下各撑 HIT_PADDING_Y 的可抓区"，
 * 相机由自身 cameras 决定（不再默认 FlxG.camera）。
 *
 * 另外去掉了自带的 timeText —— 中键里的 songLengthText 已经在显示同一串时间，
 * 那条只是当初被挤到屏幕外才没露出来，挪上来之后会变成重复的两份。
 */
class SongProgress extends FlxSpriteGroup
{
	/** 视觉条太细，命中区在它上下各撑这么多像素 */
	public static inline var HIT_PADDING_Y:Float = 10;

	public var bgBar:FlxSprite;
	public var progressBar:FlxSprite;
	public var handle:FlxSprite;

	public var barX:Float = 0;
	public var barY:Float = 0;
	public var barWidth:Float = 300;
	public var barHeight:Float = 4;

	public var handleSize:Float = 10;

	public var currentTime:Float = 0;
	public var totalTime:Float = 0;

	public var dragging:Bool = false;
	public var hovered:Bool = false;

	/** 拖动中记录的进度比例，松手时用它做跳转，避免再从 handle.x 反算 */
	var dragRatio:Float = 0;

	public var onSeek:Float->Void = null;

	public function new(x:Float = 0, y:Float = 0, width:Float = 300, height:Float = 4)
	{
		super(x, y);

		this.barX = 0;
		this.barY = 0;
		this.barWidth = width;
		this.barHeight = height;

		// 背景横线
		bgBar = new FlxSprite(barX, barY);
		bgBar.makeGraphic(Std.int(barWidth), Std.int(barHeight), FlxColor.GRAY);
		bgBar.alpha = 0.6;
		add(bgBar);

		// 进度条：整条画满，长度靠裁源帧控制（同 win8.NumButton 的做法，
		// 避免 scale + updateHitbox 那套 offset 换算把条子画歪）
		progressBar = new FlxSprite(barX, barY);
		progressBar.makeGraphic(Std.int(barWidth), Std.int(barHeight), FlxColor.CYAN);
		add(progressBar);

		// 拖动球(居中)。注意子元素一律用**局部**坐标建：
		// FlxSpriteGroup.preAdd 会把本组的 x / y 加进成员坐标，这里再带一次就翻倍了。
		handle = new FlxSprite(barX, barY - handleSize / 2 + barHeight / 2);
		handle.makeGraphic(Std.int(handleSize * 2), Std.int(handleSize * 2), FlxColor.TRANSPARENT);
		handle.antialiasing = true;
		FlxSpriteUtil.drawCircle(handle, handleSize, handleSize, handleSize, FlxColor.WHITE);
		handle.visible = false;
		add(handle);

		renderRatio(0);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var mouse = FlxG.mouse;
		var cam:FlxCamera = camera;
		var mx:Float = -9999;
		var my:Float = -9999;

		if (cam != null)
		{
			var screen = mouse.getScreenPosition(cam);
			mx = screen.x;
			my = screen.y;
		}

		// 命中区 = 视觉条 + 上下各 HIT_PADDING_Y
		hovered = (mx >= this.x && mx <= this.x + barWidth
			&& my >= this.y - HIT_PADDING_Y && my <= this.y + barHeight + HIT_PADDING_Y);

		if (mouse.justPressed && hovered)
		{
			dragging = true;
			dragTo(mx - this.x);
		}

		if (dragging)
		{
			if (mouse.pressed)
			{
				dragTo(mx - this.x);
			}
			else
			{
				dragging = false;
				if (onSeek != null)
					onSeek(totalTime * dragRatio);
			}
		}

		// 拖动球平时淡出，悬停 / 拖动时才显形并放大
		handle.visible = hovered || dragging;
		var scale:Float = (hovered || dragging) ? 1.2 : 1.0;
		handle.scale.set(scale, scale);
	}

	public function updateProgress(current:Float, total:Float):Void
	{
		currentTime = current;
		totalTime = total;

		if (totalTime <= 0) return;
		if (!dragging) renderRatio(currentTime / totalTime);
	}

	/** 拖动中：把屏幕 X 换算成比例并即时反映在条上 */
	private function dragTo(localX:Float):Void
	{
		var clamped:Float = FlxMath.bound(localX - barX, 0, barWidth);
		renderRatio(barWidth <= 0 ? 0 : clamped / barWidth);
	}

	private function renderRatio(ratio:Float):Void
	{
		ratio = FlxMath.bound(ratio, 0, 1);
		dragRatio = ratio;

		// 裁源帧：只影响这一个精灵的帧副本
		var w:Float = barWidth * ratio;
		progressBar._frame.frame.width = (w < 1) ? 1 : w;

		// 拖动球同样按局部坐标基准（this.x + barX）摆放，中心跟随比例
		handle.x = this.x + barX + barWidth * ratio - handleSize;
	}
}
#end
