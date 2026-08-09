package codename.funkin.options.categories;

#if mobile
import lime.system.System as LimeSystem;
#end
import codename.funkin.options.PlayerSettings;

class MobileOptions extends TreeMenuScreen
{
	public function new()
	{
		super('Mobile Options', 'Configure Codename touch controls.');

		add(new ArrayOption('Extra Hints', 'Select how many extra hitbox hints are shown.',
			['NONE', 'SINGLE', 'DOUBLE'], ['None', 'Single', 'Double'], 'extraHints'));
		add(new NumOption('Hitbox Opacity', 'Changes the gameplay hitbox opacity.',
			0, 1, 0.1, 'hitboxAlpha'));
		add(new Checkbox('Old Pad Texture', 'Uses the original virtual-pad texture.', 'oldPadTexture', rebuildPad));
		add(new NumOption('TouchPad Opacity', 'Changes the menu TouchPad opacity.',
			0, 1, 0.1, 'touchPadAlpha', updatePadAlpha));
		add(new ArrayOption('Hitbox Style', 'Changes the gameplay hitbox rendering style.',
			['noGradient', 'noGradientOld', 'gradient', 'hidden'],
			['No Gradient', 'No Gradient (Old)', 'Gradient', 'Hidden'], 'hitboxType'));
		add(new Checkbox('Hitbox Position', 'Moves extra hitbox hints between the top and bottom.', 'hitboxPos'));
		#if mobile
		add(new Checkbox('Allow Screen Timeout', 'Allows the screen to sleep while inactive.',
			'screenTimeOut', () -> LimeSystem.allowScreenTimeout = Options.screenTimeOut));
		#end
	}

	function rebuildPad():Void
	{
		var state:MusicBeatState = Std.downcast(FlxG.state, MusicBeatState);
		if (state == null || state.touchPad == null) return;
		var dpad = state.touchPad.curDPadMode;
		var action = state.touchPad.curActionMode;
		state.removeTouchPad();
		state.addTouchPad(dpad, action);
		state.addTouchPadCamera();
		refreshMobileControls();
	}

	function updatePadAlpha(value:Float):Void
	{
		var state:MusicBeatState = Std.downcast(FlxG.state, MusicBeatState);
		if (state != null && state.touchPad != null) state.touchPad.alpha = value;
		FlxG.mouse.visible = FlxG.mouse.useSystemCursor = !PlayerSettings.solo.controls.touchC;
	}
}
