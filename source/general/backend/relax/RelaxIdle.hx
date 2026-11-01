package general.backend.relax;
#if RELAX_ALLOWED

/**
 * 类休眠：主菜单 / Freeplay 闲置指定分钟数后自动打开 RelaxSubState。
 * 同一时刻只有一个状态在前台，用静态计时器即可；进入状态或子状态关闭时调 reset() 重新计时。
 * 分钟数在 FE特色功能 里配置（ClientPrefs.data.relaxIdleMinutes，0 = 关闭）。
 */
class RelaxIdle
{
	public static var idleTime:Float = 0;

	public static function reset():Void
	{
		idleTime = 0;
	}

	public static function checkInput():Bool
	{
		var anyInput:Bool = FlxG.keys.justPressed.ANY
			|| FlxG.mouse.justPressed || FlxG.mouse.justReleased
			|| FlxG.mouse.justMoved || FlxG.mouse.wheel != 0;
		if (!anyInput)
		{
			for (touch in FlxG.touches.list)
			{
				if (touch.justPressed || touch.justReleased)
				{
					anyInput = true;
					break;
				}
			}
		}
		return anyInput;
	}

	/**
	 * @param allow 传 false 直接跳过（例如状态正在退场切换时）
	 */
	public static function update(elapsed:Float, allow:Bool = true):Void
	{
		var idleMinutes:Int = ClientPrefs.data.relaxIdleMinutes;
		if (idleMinutes <= 0 || !allow) return;
		if (FlxG.state.subState != null) return;

		if (checkInput())
		{
			idleTime = 0;
			return;
		}

		idleTime += elapsed;
		if (idleTime >= idleMinutes * 60)
		{
			idleTime = 0;
			// 没有任何歌单时打开只会是空播放器，直接跳过
			if (GetInit.getListNum() > 0)
				FlxG.state.openSubState(new substates.RelaxSubState());
		}
	}
}
#end