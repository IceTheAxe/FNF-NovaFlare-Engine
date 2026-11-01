package substates;

import win8.Panel;
import win8.Panel.PanelEntry;
import win8.PanelOption;
import win8.OptionType;

import flixel.util.FlxStringUtil;

/**
 * PauseDebugCharm —— 暂停菜单的 Tool 调试面板（win8.Panel 实现）。
 *
 * 与 GameplayChangersSubstate 同一套 win8.Panel 浮出层；宿主是 NewPauseSubState，
 * 经 new(host) 传入，面板只调用其公开 API（restartSong / setPracticeMode /
 * setBotplay / closeMenu / endSong）。
 *
 * 内容随模式变化（initDebugKeys）：
 *   chartingMode              → Skip Time / Skip to Time / Practice / Botplay / Leave Charting Mode / End Song
 *   practice 或 botplay 开启   → 对应开关 + Skip Time / Skip to Time
 *   其余                      → 空，create() 里直接关掉自己
 */
class PauseDebugCharm extends Panel
{
	var host:NewPauseSubState;
	var debugKeys:Array<String> = [];
	var curTime:Float = 0;
	var aborted:Bool = false;

	public function new(host:NewPauseSubState)
	{
		super();

		this.host = host;
		initDebugKeys();
		curTime = Math.max(0, Conductor.songPosition);
		dismissOnOutsideClick = true;

		// 动作行（Skip to Time / Leave Charting Mode / End Song）用大按钮，
		// 宽度与上方 Skip Time 的数值条对齐。
		largeActionButtons = true;
	}

	override function create()
	{
		// 没有可调试的项（不在 charting、也没开 practice/botplay）→ 不等 super.create()，
		// 直接关掉自己。此时 _parentState 已由 FlxState.resetSubState 赋好，close() 能正常路由。
		if (debugKeys.length == 0)
		{
			aborted = true;
			close();
			return;
		}

		super.create();
	}

	override function update(elapsed:Float)
	{
		// 中止路径：create() 没跑完，本帧 update 不能碰任何控件
		if (aborted) return;
		super.update(elapsed);
	}

	// =========================================================
	// 面板内容
	// =========================================================
	override public function buildEntries():Array<PanelEntry>
	{
		var opts:Array<PanelOption> = buildDebugOptions();
		if (opts.length == 0) return [];

		return [{
			id: 'tool',
			title: 'Debug',
			description: 'Debug tools for charting, practice and botplay',
			options: opts
		}];
	}

	/** 面板顶部大标题（基类默认取第一个分组的标题，会和分组小标题撞车） */
	override public function getPageTitle():String
	{
		return Language.getPhrase('debug_panel', 'Charting Panel');
	}

	// =========================================================
	// 条目集合（debugKeys 只是内部标识，不是语言 key）
	// =========================================================
	function initDebugKeys():Void
	{
		if (PlayState.chartingMode)
		{
			debugKeys = ['pause_skip_time', 'pause_toggle_practice_mode', 'pause_toggle_botplay',
				'pause_leave_charting_mode', 'pause_end_song'];
		}
		else if (PlayState.instance.practiceMode || PlayState.instance.cpuControlled)
		{
			debugKeys = [];
			if (PlayState.instance.practiceMode) debugKeys.push('pause_toggle_practice_mode');
			if (PlayState.instance.cpuControlled) debugKeys.push('pause_toggle_botplay');
			debugKeys.push('pause_skip_time');
		}
		else
		{
			debugKeys = [];
		}
	}

	function buildDebugOptions():Array<PanelOption>
	{
		var out:Array<PanelOption> = [];

		for (key in debugKeys)
		{
			switch (key)
			{
				case 'pause_skip_time':
					out.push(makeSkipTimeOption());
					out.push(makeSkipActionOption());

				case 'pause_toggle_practice_mode':
					out.push(makePracticeOption());

				case 'pause_toggle_botplay':
					out.push(makeBotplayOption());

				case 'pause_leave_charting_mode':
					var leave:PanelOption = new PanelOption(
						Language.getPhrase('pause_leave_charting_mode', 'Leave Charting Mode'),
						'leave_charting',
						ACTION,
						null,
						'Turn charting mode off and restart the song');
					leave.actionLabel = Language.getPhrase('leave', 'Leave');
					leave.action = function() {
						PlayState.chartingMode = false;
						if (host != null) host.restartSong();
					};
					out.push(leave);

				case 'pause_end_song':
					var end:PanelOption = new PanelOption(
						Language.getPhrase('pause_end_song', 'End Song'),
						'end_song',
						ACTION,
						null,
						'Jump straight to the results screen');
					end.actionLabel = Language.getPhrase('end_song', 'End Song');
					end.action = function() { runHostAction(function() { if (host != null) host.endSong(); }); };
					out.push(end);
			}
		}

		return out;
	}

	function makeSkipTimeOption():PanelOption
	{
		// 歌长必须在造控件之前定好 —— NumButton 构造时就把 min/max 存走了（win8/NumButton.hx:39-40）
		var maxTime:Float = 1;
		if (FlxG.sound.music != null)
			maxTime = Math.max(1, FlxG.sound.music.length);

		var opt:DebugOption = new DebugOption(
			Language.getPhrase('skip_time', 'Skip Time'),
			'skip_time',
			INT,
			curTime,
			function() return curTime,
			function(v) { curTime = v; },
			null,
			'Pick a time, then hit Skip to jump there');

		opt.minValue = 0;
		opt.maxValue = maxTime;
		opt.changeValue = 1000;     // 步长 1000ms
		opt.decimals = 0;
		opt.valueFormatter = function(v:Float):String return formatSkipTime(v);

		return opt;
	}

	function formatSkipTime(ms:Float):String
	{
		var cur:String = FlxStringUtil.formatTime(Math.max(0, Math.floor(ms / 1000)), false);
		var total:String = '0:00';
		if (FlxG.sound.music != null)
			total = FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false);
		return cur + ' / ' + total;
	}

	function makeSkipActionOption():PanelOption
	{
		var opt:PanelOption = new PanelOption(
			Language.getPhrase('pause_skip_apply', 'Skip to Time'),
			'skip_apply',
			ACTION,
			null,
			'Jump to the selected time');
		opt.actionLabel = Language.getPhrase('pause_skip', 'Skip');
		opt.action = function() {
			if (curTime < Conductor.songPosition)
			{
				// 往回跳：整首歌重置，不走滑出动画
				PlayState.startOnTime = curTime;
				if (host != null) host.restartSong(true);
				return;
			}

			runHostAction(function() {
				if (curTime != Conductor.songPosition)
				{
					PlayState.instance.clearNotesBefore(curTime);
					PlayState.instance.setSongTime(curTime);
				}
				if (host != null) host.closeMenu();
			});
		};
		return opt;
	}

	function makePracticeOption():PanelOption
	{
		return new DebugOption(
			Language.getPhrase('practice', 'Practice'),
			'practice',
			BOOL,
			PlayState.instance.practiceMode,
			function() return PlayState.instance.practiceMode,
			// BoolButton 已把"取反后的新值"算好（win8/BoolButton.hx:108-116），所以这里是 set 不是 toggle
			function(v) { if (host != null) host.setPracticeMode(v == true); },
			null,
			'Practice mode: no death, retry sections freely');
	}

	function makeBotplayOption():PanelOption
	{
		return new DebugOption(
			Language.getPhrase('botplay', 'Botplay'),
			'botplay',
			BOOL,
			PlayState.instance.cpuControlled,
			function() return PlayState.instance.cpuControlled,
			function(v) { if (host != null) host.setBotplay(v == true); },
			null,
			'Let the engine play the chart for you');
	}

	/** 先执行宿主动作，再滑出面板 */
	function runHostAction(act:Void->Void):Void
	{
		if (act != null) act();
		animateOutAndClose();
	}
}

/**
 * 调试面板专用选项：值不落 ClientPrefs，由 getter/setter 闭包桥接
 * （skip time → 局部变量；practice/botplay → 实时读 PlayState）。
 * 模式同 GameplayChangersSubstate.GameplayOption（同文件子类）。
 */
class DebugOption extends PanelOption
{
	var getter:Void->Dynamic;
	var setter:Dynamic->Void;

	public function new(name:String, variable:String, type:OptionType, defaultValue:Dynamic,
		getter:Void->Dynamic, setter:Dynamic->Void, ?options:Array<String>, ?description:String = null)
	{
		super(name, variable, type, options, description);
		this.defaultValue = defaultValue;
		this.getter = getter;
		this.setter = setter;
	}

	override public function getValue():Dynamic
		return (getter != null) ? getter() : null;

	override public function setValue(value:Dynamic):Void
	{
		if (setter != null) setter(value);
	}
}
