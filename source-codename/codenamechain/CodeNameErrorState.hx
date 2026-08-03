package codenamechain;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class CodeNameErrorState extends FlxState
{
	override public function create():Void
	{
		super.create();
		FlxG.camera.bgColor = FlxColor.BLACK;
		var text:FlxText = new FlxText(48, 80, FlxG.width - 96,
			"CodeName could not start.\n\n" + (CodeNameMode.preparationError ?? "Unknown startup error")
			+ "\n\nPress Enter or Escape to return to NovaFlare on the next launch.", 24);
		text.setFormat(null, 24, FlxColor.WHITE, LEFT);
		add(text);
	}

	override public function update(elapsed:Float):Void
	{
		if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.ESCAPE)
		{
			originfunkin.OriginFunkinConfig.requestNovaFlare();
			lime.system.System.exit(0);
			return;
		}
		super.update(elapsed);
	}
}
