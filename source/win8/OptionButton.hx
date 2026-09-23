package win8;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

/**
 * 动作按钮（ACTION 类型，比如 Open / Reset）。
 *
 * Win8 风格：2px 描边 + 按下填充强调色（Metro 按钮）。
 */
class OptionButton extends FlxSpriteGroup
{
	var follow:PanelOption;
	var bg:Rect;
	var border:FlxSprite;
	var actionText:FlxText;

	var isReset:Bool;

	var hover:Bool = false;
	var pressing:Bool = false;

	var confirmPending:Bool = false;
	var confirmTimer:Float = 0;

	public function new(X:Float, Y:Float, width:Float, height:Float,
						follow:PanelOption, isReset:Bool = false, fontSize:Int = 16)
	{
		super(X, Y);

		this.follow = follow;
		this.isReset = isReset;

		bg = new Rect(0, 0, width, height, 0, 0, baseColor(), 1);
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		border = Theme.makeFrameSprite(width, height);
		border.color = borderColor();
		add(border);

		actionText = new FlxText(0, 0, width - 20, getActionText(), fontSize);
		actionText.setFormat(Paths.font('montserrat.ttf'), fontSize, Theme.text(), CENTER);
		actionText.borderStyle = NONE;
		actionText.antialiasing = ClientPrefs.data.antialiasing;
		actionText.y = bg.y + (height - actionText.height) * 0.5;
		add(actionText);
	}

	function getActionText():String
	{
		if (follow.actionLabel != null && follow.actionLabel != '')
			return follow.actionLabel;

		return isReset ? 'Reset' : 'Open';
	}

	inline function baseColor():FlxColor
		return isReset ? Theme.dangerBase() : Theme.face();

	function borderColor():FlxColor
	{
		if (isReset) return Theme.danger();
		return (hover || pressing) ? Theme.accent() : Theme.border();
	}

	/** 根据状态计算目标背景色 */
	function computeTargetColor():FlxColor
	{
		if (isReset)
			return pressing ? Theme.dangerPress() : (hover ? Theme.dangerHover() : Theme.dangerBase());

		return pressing ? Theme.accent() : (hover ? Theme.faceHover() : Theme.face());
	}

	/** 文字颜色（按下时底色是强调色，文字转白） */
	function computeTextColor():FlxColor
	{
		if (isReset) return confirmPending ? Theme.danger() : Theme.text();
		return pressing ? Theme.onAccent() : (hover ? Theme.accent() : Theme.text());
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (!follow.allowUpdate) return;

		var mouse = FlxG.mouse;
		var wasHover = hover;
		hover = Input.overlaps(bg);

		// 悬浮状态变化 → tween 渐变
		if (hover != wasHover)
		{
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 0.12, bg.color, computeTargetColor(), {ease: FlxEase.quadOut});
			border.color = borderColor();
		}

		// 确认计时器（Reset 的二次确认）
		if (isReset && confirmPending)
		{
			confirmTimer -= elapsed;
			if (confirmTimer <= 0)
			{
				confirmPending = false;
				actionText.text = getActionText();
				actionText.color = Theme.text();
			}
			else
			{
				actionText.color = Theme.danger();
			}
		}

		if (!isReset)
			actionText.color = computeTextColor();

		if (hover && mouse.justPressed)
		{
			pressing = true;

			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 0.05, bg.color, computeTargetColor());
			border.color = borderColor();

			if (isReset)
			{
				if (!confirmPending)
				{
					confirmPending = true;
					confirmTimer = 1.5;
					actionText.text = 'Confirm?';
					actionText.color = Theme.danger();
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
				}
				else
				{
					confirmPending = false;
					doReset();
				}
			}
		}

		if (mouse.justReleased && pressing && !isReset)
		{
			pressing = false;
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 0.1, bg.color, computeTargetColor(), {ease: FlxEase.quadOut});
			border.color = borderColor();

			if (hover)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);
				if (follow.action != null) follow.action();
			}
		}

		if (!hover && pressing)
		{
			pressing = false;
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 0.1, bg.color, computeTargetColor(), {ease: FlxEase.quadOut});
			border.color = borderColor();
		}
	}

	/** 动态改按钮文字（比如深浅色切换按钮） */
	public function setActionText(text:String):Void
	{
		if (actionText != null) actionText.text = text;
	}

	function doReset():Void
	{
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);

		if (follow.action != null)
			follow.action();
	}
}
