package codenamechain;

#if CODENAME_ENGINE_COMPAT
import flixel.text.FlxText.FlxTextFormatRange;

/**
 * Retains runtime classes that CNE mods instantiate only through HScript.
 * Haxe does not compile an otherwise unreachable class merely because a script
 * contains its name, even with DCE disabled.
 */
class CodeNameScriptRuntime
{
	static final retainedClasses:Array<Class<Dynamic>> = [
		cast hxvlc.flixel.FlxVideo,
		cast FlxTextFormatRange,
		cast flixel.text.FlxTextAlign_HSC,
		cast codename.funkin.backend.utils.CoolSfx_HSC
	];

	public static function init():Void
	{
		// Reading the registry makes the class roots reachable without constructing
		// them or changing NovaFlare's normal runtime behavior.
		if (retainedClasses.length == 0)
			throw "CodeName script runtime registry was not generated";
	}
}
#end
