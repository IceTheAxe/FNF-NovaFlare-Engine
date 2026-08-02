package gameanalytics;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
#end

/** Enables the private analytics implementation only when every source exists. */
class GACompileConfig
{
	#if macro
	public static function configure():Void
	{
		final requiredSources = [
			'gameanalytics/GameAnalytics.hx',
			'gameanalytics/GameAnalyticsTypes.hx',
			'gameanalytics/GameAnalyticsConfig.hx'
		];

		for (source in requiredSources)
		{
			try
			{
				Context.resolvePath(source);
			}
			catch (_:Dynamic)
			{
				return;
			}
		}

		Compiler.define('GAMEANALYTICS_ENABLED');
		if (Context.defined('debug'))
			Compiler.define('GAMEANALYTICS_VERBOSE');
	}

	/** Compile-time assertion used by build verification. */
	public static function verify(expected:Bool):Void
	{
		final enabled = Context.defined('GAMEANALYTICS_ENABLED');
		if (enabled != expected)
			Context.error('Expected GameAnalytics enabled=$expected, got $enabled', Context.currentPos());
	}
	#end
}
