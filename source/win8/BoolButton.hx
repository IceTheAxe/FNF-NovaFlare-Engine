package win8;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

/**
 * 开关控件（Win8 风格）。
 *
 * 直角方框轨道 + 方形滑块，状态表达靠滑块停靠位置 + 轨道配色，不用对勾。
 */
class BoolButton extends FlxSpriteGroup
{
	var bg:Rect;
	var dis:Rect;
	var border:FlxSprite;
	var hitArea:Rect;

	var follow:PanelOption;

	var hover:Bool = false;
	var pressing:Bool = false;

	/**
	 * 方形滑块的两个停靠点（相对本组左上角的局部坐标）。
	 * 用"绝对目标"而不是"相对位移"，updateDisplay() 被重复调用时才不会累积漂移
	 * （键盘改值 + WidgetFactory.refreshValue 会反复触发它）。
	 */
	var knobOffX:Float = 0;
	var knobOnX:Float = 0;

	inline function getOffColor():FlxColor
		return Theme.face();

	inline function getOnColor():FlxColor
		return Theme.accent();

	/** 滑块配色：关 = 和描边同色（压在轨道上看得清），开 = 强调色底上的白块 */
	inline function getKnobColor(on:Bool):FlxColor
		return on ? Theme.onAccent() : Theme.border();

	public function new(X:Float, Y:Float, width:Float, height:Float, follow:PanelOption)
	{
		super(X, Y);

		this.follow = follow;

		var on:Bool = (follow.getValue() == true);

		// 整块区域的透明命中区：铺满整个控件尺寸
		hitArea = new Rect(0, 0, width, height, 0, 0, 0x00000000, 0);
		add(hitArea);

		// 滑块边长
		var d:Float = height / 1.5;

		// 直角轨道（Metro 不给圆角）
		bg = new Rect(0, 0, width, height, 0, 0, on ? getOnColor() : getOffColor(), 1);
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		// Win8 控件一律带描边。注意不能用 shapeEx.Rect 的 lineStyle（静态缓存会串色），
		// 统一走 Theme.makeFrameSprite 自绘
		border = Theme.makeFrameSprite(width, height);
		border.x = bg.x;
		border.y = bg.y;
		border.color = Theme.border();
		add(border);

		// 方形滑块：左右留 pad，垂直居中
		var pad:Float = (height - d) * 0.5;
		knobOffX = pad;
		knobOnX = width - d - pad;

		// 位置在 add() 之前写进构造函数：add() 的 preAdd 会把本组的 x/y 加进来，
		// 之后再写局部坐标会把滑块弹到屏幕左上角（FlxSpriteGroup 的子元素坐标是绝对的）
		dis = new Rect(on ? knobOnX : knobOffX, pad, d, d, 0, 0, getKnobColor(on), 1);
		dis.antialiasing = ClientPrefs.data.antialiasing;
		add(dis);
	}

	/** 同步方形滑块的配色。轨道底色交给每帧的 updateBgColor() 平滑过渡 */
	function refreshKnob():Void
	{
		if (dis != null) dis.color = getKnobColor(follow.getValue() == true);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (!follow.allowUpdate) return;

		var mouse = FlxG.mouse;

		// ---------- 悬停 / 按下状态（只做视觉反馈，不影响点击判定） ----------
		var wasHover = hover;
		hover = Input.overlaps(hitArea);

		if (hover != wasHover)
			refreshBgTween();

		if (hover && mouse.justPressed)
		{
			pressing = true;
			refreshBgTween(true);
		}

		// ---------- 点击判定 ----------
		if (mouse.justPressed && Input.overlaps(hitArea))
		{
			var nextValue:Bool = !(follow.getValue() == true);
			follow.setValue(nextValue);
			follow.change();
			follow.saveCurrentValue();
			updateDisplay();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
		}

		if (mouse.justReleased && pressing)
		{
			pressing = false;
			refreshBgTween();
		}

		// 每帧平滑逼近目标色（作为 tween 之外的兜底收敛）
		updateBgColor();
	}

	/** 计算当前状态的目标背景色 */
	function computeTargetColor():FlxColor
	{
		var base:FlxColor = follow.getValue() ? getOnColor() : getOffColor();

		if (pressing) return Theme.pressTint(base);
		else if (hover) return Theme.hoverTint(base);

		return base;
	}

	function refreshBgTween(isPress:Bool = false)
	{
		FlxTween.cancelTweensOf(bg);
		var target:FlxColor = computeTargetColor();
		var dur:Float = isPress ? 0.05 : 0.12;
		FlxTween.color(bg, dur, bg.color, target, {ease: FlxEase.quadOut});
	}

	var moveTween:FlxTween;
	public function updateDisplay():Void
	{
		if (moveTween != null) moveTween.cancel();

		var on:Bool = (follow.getValue() == true);

		// 方形滑块滑到两个停靠点之一。这里要写"本组 x + 局部停靠点"：
		// 子元素坐标是绝对的（preAdd 已经把本组 x/y 烘焙进去了）
		var targetX:Float = this.x + (on ? knobOnX : knobOffX);
		refreshKnob();

		moveTween = FlxTween.tween(dis, {x: targetX}, 0.2, {ease: FlxEase.quadOut});
	}

	function updateBgColor():Void
	{
		var targetColor:FlxColor = computeTargetColor();
		bg.color = FlxColor.interpolate(bg.color, targetColor, 0.2);
	}
}
