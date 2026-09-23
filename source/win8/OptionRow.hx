package win8;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

/**
 * 面板里的一行：标题在上（18px，左对齐），控件在下，行本身不放描述文字
 * —— 描述统一显示在面板底部的说明栏里。
 *
 * ⚠️ FlxSpriteGroup 的子元素坐标是**绝对**的（add() 时 preAdd 已经把本组的 x/y 加进成员），
 * 而 draw() 只是逐个 member.draw()，绘制时不会再叠加父级偏移。
 * 所以这里摆子元素必须带上 this.x / this.y，否则会把它们弹回屏幕左上角。
 */
class OptionRow extends FlxSpriteGroup
{
	/** 左右内边距 */
	public static inline var PAD_X:Float = 14;
	/** 标题在组内的 y */
	public static inline var TITLE_Y:Float = 9;
	/** 控件在组内的 y */
	public static inline var WIDGET_Y:Float = 46;

	public var title:FlxText;
	public var widget:FlxSpriteGroup;
	public var option:PanelOption;
	public var bg:Rect;

	public var baseY:Float = 0;
	public var rowH:Float = 0;

	/** 键盘选中态：整行铺一层底色 + 标题转强调色。bg 默认 alpha = 0，不选中时整行是隐形的 */
	var selected:Bool = false;

	public function new(x:Float, y:Float, w:Float, h:Float, opt:PanelOption, widget:FlxSpriteGroup)
	{
		super(x, y);

		this.option = opt;
		this.widget = widget;

		bg = new Rect(0, 0, w, h, 0, 0, Theme.rowSelected(), 0.0);
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		title = new FlxText(0, 0, w - PAD_X * 2, opt.name, 18);
		title.setFormat(Paths.font('montserrat.ttf'), 18, Theme.text(), LEFT);
		title.borderStyle = NONE;
		title.antialiasing = ClientPrefs.data.antialiasing;
		add(title);
		title.x = this.x + PAD_X;
		title.y = this.y + TITLE_Y;

		if (widget != null)
		{
			add(widget);
			widget.x = this.x + PAD_X;
			widget.y = this.y + WIDGET_Y;
		}
	}

	public function setRowMeta(baseY:Float, rowH:Float):Void
	{
		this.baseY = baseY;
		this.rowH = rowH;
	}

	public function setSelected(v:Bool):Void
	{
		if (selected == v) return;
		selected = v;

		if (bg != null)
		{
			FlxTween.cancelTweensOf(bg);
			FlxTween.tween(bg, {alpha: v ? 1 : 0}, 0.1, {ease: FlxEase.quadOut});
		}

		if (title != null)
			title.color = selected ? Theme.accent() : Theme.text();
	}

	public function isSelected():Bool
		return selected;
}
