package substates;

import win8.Panel;
import win8.Panel.PanelEntry;
import win8.PanelOption;
import win8.OptionType;

/**
 * Gameplay Changers —— Win8 风格设置面板。
 *
 * 继承 win8.Panel 的单页设置页，两组：
 *   - Gameplay Changers：各选项走 win8 包下那套控件（NumButton / StringSelect / BoolButton）
 *   - Reset：一个 Reset 动作按钮
 *
 * 对外接口保持不变：类名、无参构造、getOptionByName()、同模块的 GameplayOption。
 * 选项值仍然读写 ClientPrefs.data.gameplaySettings，落盘时机也跟旧实现一致
 * —— 关闭面板时统一 saveSettings()，不做即时落盘。
 */
class GameplayChangersSubstate extends Panel
{
	var optionsArray:Array<GameplayOption> = [];

	public function new()
	{
		super();
	}

	// =========================================================
	// 分组声明
	// =========================================================
	override public function buildEntries():Array<PanelEntry>
	{
		buildOptions();

		var opts:Array<PanelOption> = [];
		for (o in optionsArray) opts.push(o);

		var resetOpt:PanelOption = new PanelOption('Reset Gameplay Changers', 'reset', ACTION, null,
			'Restore every gameplay changer to its default value');
		resetOpt.actionLabel = 'Reset';
		resetOpt.action = resetAll;

		return [
			{
				id: 'gameplay',
				title: 'Gameplay Changers',
				description: 'Scroll speed, health multipliers, instakill, botplay and more',
				options: opts
			},
			{
				id: 'reset',
				title: 'Reset',
				description: 'Put every gameplay changer back to its default value',
				options: [resetOpt]
			}
		];
	}

	// =========================================================
	// 单页模式的总标题
	// =========================================================
	override public function getPageTitle():String
		return 'Gameplay Changers';

	override public function getPageDescription():String
		return 'Scroll speed, health multipliers, instakill, botplay and more';

	// =========================================================
	// 选项表（与旧实现一致）
	// =========================================================
	function buildOptions():Void
	{
		optionsArray = [];

		var scrollType:GameplayOption = new GameplayOption('Scroll Type', 'scrolltype', STRING, 'multiplicative',
			["multiplicative", "constant"],
			'How the scroll speed is interpreted');
		scrollType.onChange = function() {
			applyScrollType();
			// 取值上限 / 显示格式变了，控件要按新配置重建
			requestPanelRebuild();
		};
		optionsArray.push(scrollType);

		var speed:GameplayOption = new GameplayOption('Scroll Speed', 'scrollspeed', FLOAT, 1, null,
			'How fast the notes scroll');
		speed.minValue = 0.35;
		speed.changeValue = 0.05;
		speed.decimals = 2;
		optionsArray.push(speed);

		#if FLX_PITCH
		var rate:GameplayOption = new GameplayOption('Playback Rate', 'songspeed', FLOAT, 1, null,
			'Speed multiplier of the whole song');
		rate.minValue = 0.5;
		rate.maxValue = 3.0;
		rate.changeValue = 0.05;
		rate.displayFormat = '%vX';
		rate.decimals = 2;
		optionsArray.push(rate);
		#end

		var healthGain:GameplayOption = new GameplayOption('Health Gain Multiplier', 'healthgain', FLOAT, 1, null,
			'How much health you gain when hitting a note');
		healthGain.minValue = 0;
		healthGain.maxValue = 5;
		healthGain.changeValue = 0.1;
		healthGain.displayFormat = '%vX';
		optionsArray.push(healthGain);

		var healthLoss:GameplayOption = new GameplayOption('Health Loss Multiplier', 'healthloss', FLOAT, 1, null,
			'How much health you lose when missing a note');
		healthLoss.minValue = 0.5;
		healthLoss.maxValue = 5;
		healthLoss.changeValue = 0.1;
		healthLoss.displayFormat = '%vX';
		optionsArray.push(healthLoss);

		optionsArray.push(new GameplayOption('Instakill on Miss', 'instakill', BOOL, false, null,
			'Missing a single note kills you'));
		optionsArray.push(new GameplayOption('Practice Mode', 'practice', BOOL, false, null,
			'Practice mode: no death, you can retry sections'));
		optionsArray.push(new GameplayOption('Botplay', 'botplay', BOOL, false, null,
			'Let the engine play the chart for you'));

		// Scroll Type 会影响 Scroll Speed 的取值范围 / 显示格式
		applyScrollType();
	}

	public function getOptionByName(name:String):GameplayOption
	{
		for (i in optionsArray)
		{
			var opt:GameplayOption = i;
			if (opt.name == name)
				return opt;
		}
		return null;
	}

	/**
	 * 按 Scroll Type 调整 Scroll Speed：
	 * constant（cmod）最大 6，multiplicative（amod）最大 3 且带 X 后缀。
	 */
	function applyScrollType():Void
	{
		var st:GameplayOption = getOptionByName('Scroll Type');
		var sp:GameplayOption = getOptionByName('Scroll Speed');
		if (sp == null) return;

		var constant:Bool = (st != null && st.getValue() == 'constant');

		sp.displayFormat = constant ? '%v' : '%vX';
		sp.maxValue = constant ? 6 : 3;
		sp.valueFormatter = makeFormatter(sp);

		if (!constant && cast(sp.getValue(), Float) > 3)
			sp.setValue(3);
	}

	/** 用 displayFormat 生成数值文本（NumButton 支持 valueFormatter） */
	function makeFormatter(opt:PanelOption):Float->String
	{
		return function(v:Float):String
		{
			var decimals:Int = opt.decimals;
			var s:String;

			if (decimals <= 0)
			{
				s = Std.string(Std.int(v));
			}
			else
			{
				s = Std.string(FlxMath.roundDecimal(v, decimals));
				if (s.indexOf('.') < 0) s += '.';
				var parts:Array<String> = s.split('.');
				while (parts[1].length < decimals) parts[1] += '0';
				s = parts[0] + '.' + parts[1].substr(0, decimals);
			}

			return opt.displayFormat.replace('%v', s);
		};
	}

	/** 把全部 gameplay changer 恢复默认值 */
	function resetAll():Void
	{
		for (opt in optionsArray)
		{
			opt.setValue(opt.defaultValue);
			if (opt.type == STRING && opt.options != null)
			{
				var idx:Int = opt.options.indexOf(Std.string(opt.getValue()));
				opt.curOption = idx < 0 ? 0 : idx;
			}
			opt.change();
		}

		applyScrollType();
		ClientPrefs.saveSettings();

		// 值变了，控件要按新值重建（顺便刷掉正在显示的下拉）。
		// 注意这里走的是"延后一帧"的请求 —— resetAll 是控件回调里调的，
		// 直接重建会把正在跑 update 的那个控件当场销毁。
		requestPanelRebuild();
	}

	override public function closePanel():Void
	{
		ClientPrefs.saveSettings();
		super.closePanel();
	}
}

/**
 * 写进 ClientPrefs.data.gameplaySettings 的选项（不是普通存档字段）。
 * 继承 win8.PanelOption，这样就能直接喂给 win8 包下那套控件。
 */
class GameplayOption extends PanelOption
{
	public function new(name:String, variable:String, type:OptionType, defaultValue:Dynamic,
		?options:Array<String> = null, ?description:String = null)
	{
		super(name, variable, type, options, description);

		this.defaultValue = defaultValue;

		// 存档里还没有这个键时补一个默认值，否则控件会读到 null
		if (getValue() == null) setValue(defaultValue);

		if (type == STRING && options != null)
		{
			var num:Int = options.indexOf(Std.string(getValue()));
			if (num > -1) curOption = num;
		}
	}

	override public function getValue():Dynamic
		return ClientPrefs.data.gameplaySettings.get(variable);

	override public function setValue(value:Dynamic):Void
	{
		ClientPrefs.data.gameplaySettings.set(variable, value);
	}
}
