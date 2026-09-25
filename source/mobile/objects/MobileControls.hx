package mobile.objects;

import haxe.ds.Map;
import haxe.extern.EitherType;

import mobile.flixel.input.FlxMobileInputManager;
import mobile.flixel.FlxButton;

class MobileControls extends FlxTypedSpriteGroup<FlxMobileInputManager>
{
	public var virtualPad:FlxVirtualPad = new FlxVirtualPad(NONE, NONE);
	public var hitbox:FlxHitbox = new FlxHitbox();
	// YOU CAN'T CHANGE PROPERTIES USING THIS EXCEPT WHEN IN RUNTIME!!
	public var current:CurrentManager;

	public static var mode(get, set):Int;
	public static var forcedControl:Null<Int>;

	public function new(?forceType:Int, ?extra:Bool = true)
	{
		super();

		if (forceType != null)
			forcedControl = forceType;
		else
			forcedControl = get_mode();

		switch (forcedControl)
		{
			case 0: // RIGHT_FULL
				initControler(0);
			case 1: // LEFT_FULL
				initControler(1);
			case 2: // CUSTOM
				initControler(2);
			case 3: // BOTH
				initControler(3);
			case 4: // HITBOX
				initControler(4);
			case 5: // KEYBOARD
		}
		current = new CurrentManager(this);
		// Options related stuff
		// alpha = ClientPrefs.data.controlsAlpha;
		if (forcedControl != 5) updateButtonsColors();
	}

	private function initControler(virtualPadMode:Int = 0):Void
	{
		switch (virtualPadMode)
		{
			case 0:
				virtualPad = new FlxVirtualPad(RIGHT_FULL_GAME, controlExtend);
				add(virtualPad);
				virtualPad = getExtraCustomMode(virtualPad);
			case 1:
				virtualPad = new FlxVirtualPad(LEFT_FULL_GAME, controlExtend);
				add(virtualPad);
				virtualPad = getExtraCustomMode(virtualPad);
			case 2:
				virtualPad = new FlxVirtualPad(RIGHT_FULL_GAME, controlExtend);
				virtualPad = getCustomMode(virtualPad);
				virtualPad = getExtraCustomMode(virtualPad);
				add(virtualPad);
			case 3:
				virtualPad = new FlxVirtualPad(BOTH_GAME, controlExtend);
				add(virtualPad);
				virtualPad = getExtraCustomMode(virtualPad);
			case 4:
				hitbox = new FlxHitbox();
				add(hitbox);
		}
	}

	public static function setCustomMode(virtualPad:FlxVirtualPad):Void
	{
		// 存 [x, y] 而不是 FlxPoint：FlxPoint.get() 返回的是池化实例，序列化进 .sol 后
		// 反序列化会失败，整个存档被判为损坏
		if (FlxG.save.data.buttons == null)
		{
			FlxG.save.data.buttons = new Array();
			for (buttons in virtualPad)
				FlxG.save.data.buttons.push([buttons.x, buttons.y]);
		}
		else
		{
			var tempCount:Int = 0;
			for (buttons in virtualPad)
			{
				FlxG.save.data.buttons[tempCount] = [buttons.x, buttons.y];
				tempCount++;
			}
		}
	}

	public static function getCustomMode(virtualPad:FlxVirtualPad):FlxVirtualPad
	{
		var tempCount:Int = 0;

		if (FlxG.save.data.buttons == null)
			return virtualPad;

		for (buttons in virtualPad)
		{
			final saved:Dynamic = FlxG.save.data.buttons[tempCount];
			if (saved != null)
			{
				if (Std.isOfType(saved, Array))
				{
					buttons.x = saved[0];
					buttons.y = saved[1];
				}
				else
				{
					// 早期存档这个位置存的是序列化的 FlxPoint 实例，没有 [0]/[1]
					buttons.x = Reflect.field(saved, 'x');
					buttons.y = Reflect.field(saved, 'y');
				}
			}
			tempCount++;
		}

		return virtualPad;
	}

	public static function setExtraCustomMode(virtualPad:FlxVirtualPad):Void
	{
		if (FlxG.save.data.extraButtons == null)
		{
			FlxG.save.data.extraButtons = new Array();
			for (btn in virtualPad.extraKeys)
				FlxG.save.data.extraButtons.push([btn.x, btn.y]);
		}
		else
		{
			var tempCount:Int = 0;
			for (btn in virtualPad.extraKeys)
			{
				FlxG.save.data.extraButtons[tempCount] = [btn.x, btn.y];
				tempCount++;
			}
		}
	}

	public static function getExtraCustomMode(virtualPad:FlxVirtualPad):FlxVirtualPad
	{
		var tempCount:Int = 0;

		if (FlxG.save.data.extraButtons == null)
			return virtualPad;

		for (btn in virtualPad.extraKeys)
		{
			final saved:Dynamic = FlxG.save.data.extraButtons[tempCount];
			if (saved != null)
			{
				if (Std.isOfType(saved, Array))
				{
					btn.x = saved[0];
					btn.y = saved[1];
				}
				else
				{
					// 早期存档这个位置存的是序列化的 FlxPoint 实例，没有 [0]/[1]
					btn.x = Reflect.field(saved, 'x');
					btn.y = Reflect.field(saved, 'y');
				}
			}
			tempCount++;
		}

		return virtualPad;
	}

	override public function destroy():Void
	{
		super.destroy();

		if (virtualPad != null)
		{
			virtualPad = FlxDestroyUtil.destroy(virtualPad);
			virtualPad = null;
		}

		if (hitbox != null)
		{
			hitbox = FlxDestroyUtil.destroy(hitbox);
			hitbox = null;
		}
	}

	// 这里不 flush：ClientPrefs.data 与 FlxG.save.data 是两份数据，裸 flush 落下去的是上次
	// saveSettings() 的旧快照，会把本次会话的改动冲掉。统一由退出时的 ClientPrefs.saveSettings() 落盘
	public static function set_mode(mode:Int = 0)
	{
		FlxG.save.data.mobileControlsMode = mode;
		return mode;
	}

	public static function get_mode():Int
	{
		if (FlxG.save.data.mobileControlsMode == null)
			FlxG.save.data.mobileControlsMode = 0;

		return FlxG.save.data.mobileControlsMode;
	}

	public function updateButtonsColors()
	{
		// Dynamic Controls Color
		var buttonsColors:Array<FlxColor> = [];
		var data:Dynamic;
		if (ClientPrefs.data.dynamicColors)
			data = ClientPrefs.data;
		else
			data = ClientPrefs.defaultData;

		buttonsColors.push(data.arrowRGB[0][0]);
		buttonsColors.push(data.arrowRGB[1][0]);
		buttonsColors.push(data.arrowRGB[2][0]);
		buttonsColors.push(data.arrowRGB[3][0]);
		if (mode == 3)
		{
			virtualPad.buttonLeft2.color = buttonsColors[0];
			virtualPad.buttonDown2.color = buttonsColors[1];
			virtualPad.buttonUp2.color = buttonsColors[2];
			virtualPad.buttonRight2.color = buttonsColors[3];
		}
		current.buttonLeft.color = buttonsColors[0];
		current.buttonDown.color = buttonsColors[1];
		current.buttonUp.color = buttonsColors[2];
		current.buttonRight.color = buttonsColors[3];
	}
}

class CurrentManager
{
	public var buttonLeft:FlxButton;
	public var buttonDown:FlxButton;
	public var buttonUp:FlxButton;
	public var buttonRight:FlxButton;
	public var target:FlxMobileInputManager;

	public function new(control:MobileControls)
	{
		if (MobileControls.mode == 4)
		{
			target = control.hitbox;
			// Use buttonNotes array instead of individual button fields
			buttonLeft = control.hitbox.buttonNotes[0];
			buttonDown = control.hitbox.buttonNotes[1];
			buttonUp = control.hitbox.buttonNotes[2];
			buttonRight = control.hitbox.buttonNotes[3];
		}
		else
		{
			target = control.virtualPad;
			buttonLeft = control.virtualPad.buttonLeft;
			buttonDown = control.virtualPad.buttonDown;
			buttonUp = control.virtualPad.buttonUp;
			buttonRight = control.virtualPad.buttonRight;
		}
	}
}
