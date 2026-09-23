package win8;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

/**
 * 面板标题栏左上角的返回按钮（图标由 Icons 现场画）。
 *
 * 默认只有浅色图标；悬停 / 按下时底色提亮、图标转强调色。
 * 点一下执行 onClick（宿主接 onBackAction()）。
 */
class PanelIconButton extends FlxSpriteGroup
{
	public var bg:Rect;
	public var icon:FlxSprite;

	public var onClick:Void->Void = null;

	var isHover:Bool = false;
	/** 面板滑入 / 滑出过程中要关掉，否则还没停稳就能点到返回 */
	public var inputEnabled:Bool = true;

	var mainW:Float;
	var iconSize:Int;
	var iconY:Float;

	var pressing:Bool = false;
	/** 上次画的图标颜色（-1 = 还没画过）。颜色没变就不重画 —— Icons 没有缓存 */
	var lastIconColor:Int = -1;

	public function new(x:Float, y:Float, w:Float, h:Float, ?onClick:Void->Void)
	{
		super(x, y);

		this.onClick = onClick;
		mainW = w;

		bg = new Rect(0, 0, w, h, 0, 0, Theme.railHover(), 0);
		add(bg);

		iconSize = Std.int(Math.min(w * 0.46, h * 0.44));
		icon = new FlxSprite();
		icon.antialiasing = ClientPrefs.data.antialiasing;
		iconY = h * 0.18;
		icon.x = (w - iconSize) * 0.5;
		icon.y = iconY;
		add(icon);
		redrawIcon(true);

		applyColors();
	}

	/**
	 * 只关鼠标输入，不改配色。
	 * 面板滑入 / 滑出时用它 —— 按钮还是正常颜色，只是点不到、也不会有 hover 高亮。
	 */
	public function setInputEnabled(v:Bool):Void
	{
		if (inputEnabled == v) return;
		inputEnabled = v;

		if (!v)
		{
			isHover = false;
			pressing = false;
		}

		applyColors();
	}

	function applyColors():Void
	{
		if (bg != null) bg.alpha = isHover ? 1 : 0;
		redrawIcon();
	}

	function redrawIcon(?force:Bool = false):Void
	{
		if (icon == null) return;

		var c:FlxColor = isHover ? Theme.accent() : Theme.textSecondary();

		// 判活，而不是判 `icon.pixels != null` —— 那个 getter 就是 `graphic.bitmap`，
		// 图被 dispose 之后仍然非 null，拿它当"图还在"会让这个按钮永远不重画。
		if (!force && lastIconColor == c && icon.graphic != null && !icon.graphic.isDestroyed) return;
		lastIconColor = c;

		icon.pixels = Icons.draw('back', iconSize, c);
		icon.offset.set(0, 0);
		icon.origin.set(0, 0);
		icon.scale.set(1, 1);
		icon.updateHitbox();
		// 注意：FlxSpriteGroup 的子元素坐标是"绝对"的（add() 时已经加过本组的 x/y，
		// 之后本组移动也是靠 set_x 把增量传播下来），所以这里必须带上 this.x / this.y，
		// 否则重绘（比如 hover 变色）会把图标弹回屏幕左上角。
		icon.x = this.x + (mainW - iconSize) * 0.5;
		icon.y = this.y + iconY;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!visible || !active) return;
		if (!inputEnabled)
		{
			if (isHover)
			{
				isHover = false;
				pressing = false;
				applyColors();
			}
			return;
		}

		var mouse = FlxG.mouse;
		var wasHover:Bool = isHover;
		isHover = Input.overlaps(bg);

		if (isHover != wasHover)
		{
			FlxTween.cancelTweensOf(bg);
			FlxTween.tween(bg, {alpha: isHover ? 1 : 0}, 0.12, {ease: FlxEase.quadOut});
			if (!isHover) pressing = false;
			applyColors();
		}

		if (isHover && mouse.justPressed)
		{
			pressing = true;
			FlxTween.cancelTweensOf(bg);
			FlxTween.tween(bg, {alpha: 1}, 0.05);
		}

		if (mouse.justReleased && pressing)
		{
			pressing = false;
			if (isHover && onClick != null) onClick();
		}
	}
}
