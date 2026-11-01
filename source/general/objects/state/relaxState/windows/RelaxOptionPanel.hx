package general.objects.state.relaxState.windows;
#if RELAX_ALLOWED

import win8.Panel;
import win8.Panel.PanelEntry;
import win8.PanelOption;
import win8.OptionType;

import substates.RelaxSubState;

/**
 * Relax 设置面板 —— 复用 win8.Panel 的浮出层（右侧滑入 / 分组 / 轨道滑块 / 底部说明栏）。
 *
 * 换掉了原来那个 1280×580 的居中方窗 + 三列网格（OptionButton + optionType 四件套）。
 *
 * 两个必须显式处理的地方：
 * 1. 相机。Panel.create() 只在 `_cameras` 为空时去取"最后一台相机"，
 *    而 Relax 里最后一台是 camVpad —— 锁定按钮会改它的 alpha，面板会跟着一起被隐掉。
 *    所以这里在构造期就把 cameras 钉成 Relax 的 camOption。
 * 2. 父状态放行。FlxState.tryUpdate / draw 在 `subState != null` 且父状态没开
 *    persistentUpdate / persistentDraw 时会**连绘制一起跳过**，Relax 的画面会整个冻住。
 *    这两个标志由 RelaxSubState 自己开关（见 openOptionPanel / 本类 closePanel）。
 */
class RelaxOptionPanel extends Panel
{
	public function new()
	{
		super();

		var host:RelaxSubState = RelaxSubState.instance;
		if (host != null && host.camOption != null)
			cameras = [host.camOption];

		// 0.3 的行宽只有 289px，StringSelect 会太挤；0.34 大约是 435px
		panelWidthRatio = 0.34;
		dismissOnOutsideClick = true;
	}

	override function getPageTitle():String
		return lang('relaxSettings', 'Relax Settings');

	override function getPageDescription():String
		return lang('relaxSettingsDesc', 'Player and visualiser settings');

	// =========================================================
	// 面板内容
	// =========================================================
	override public function buildEntries():Array<PanelEntry>
	{
		return [
			{
				id: 'playback',
				title: lang('groupPlayback', 'Playback'),
				description: '',
				options: [makeString('NextSongs', ['Next', 'Restart', 'Random'])]
			},
			{
				id: 'record',
				title: lang('groupRecord', 'Record'),
				description: '',
				options: [makeBool('enableRecordRotation'), makeBool('enableBpmZoom')]
			},
			{
				id: 'spectrum',
				title: lang('groupSpectrum', 'Spectrum'),
				description: '',
				options: [
					makeInt('RelaxAudioDisplayQuality', 1, 10),
					makeInt('RelaxAudioNumber', 1, 8),
					makeBool('RelaxAudioSymmetry')
				]
			},
			{
				id: 'appearance',
				title: lang('groupTheme', 'Appearance'),
				description: '',
				options: [
					makeString('theme', ['Circle', 'Straight', 'None']),
					makeString('songInfo', ['None', 'Middle', 'topLeft', 'downLeft', 'topRight', 'downRight'])
				]
			}
		];
	}

	override public function closePanel():Void
	{
		// 值改过之后频谱 / 唱片大概要重建，趁宿主还在的时候刷一次
		var host:RelaxSubState = RelaxSubState.instance;
		if (host != null)
		{
			host.updateOptions();
			host.persistentUpdate = false;
		}

		super.closePanel();
	}

	// =========================================================
	// 选项构造
	// =========================================================
	/** 布尔项：值直连 ClientPrefs.data.<key> */
	function makeBool(key:String):PanelOption
	{
		return bind(new RelaxOption(
			lang(key, key),
			key,
			BOOL,
			function() return Reflect.getProperty(ClientPrefs.data, key),
			function(v) Reflect.setProperty(ClientPrefs.data, key, (v == true)),
			null,
			lang('desc_' + key, '')
		));
	}

	/** 整数项：NumButton 轨道滑块，步长 1 */
	function makeInt(key:String, min:Float, max:Float):PanelOption
	{
		var opt:PanelOption = bind(new RelaxOption(
			lang(key, key),
			key,
			INT,
			function() return Reflect.getProperty(ClientPrefs.data, key),
			function(v) Reflect.setProperty(ClientPrefs.data, key, Std.int(cast(v, Float))),
			null,
			lang('desc_' + key, '')
		));

		opt.minValue = min;
		opt.maxValue = max;
		opt.changeValue = 1;
		opt.decimals = 0;
		return opt;
	}

	/** 枚举项：StringSelect 下拉 */
	function makeString(key:String, values:Array<String>):PanelOption
	{
		return bind(new RelaxOption(
			lang(key, key),
			key,
			STRING,
			function() return Reflect.getProperty(ClientPrefs.data, key),
			function(v) Reflect.setProperty(ClientPrefs.data, key, Std.string(v)),
			values,
			lang('desc_' + key, '')
		));
	}

	/** 值一变就让宿主重建频谱 / 唱片 */
	function bind(opt:PanelOption):PanelOption
	{
		opt.onChange = function()
		{
			if (RelaxSubState.instance != null)
				RelaxSubState.instance.updateOptions();
		};
		return opt;
	}

	/** 语言表里没有这个 key 时用 fallback（Language.get 缺 key 会原样返回 key） */
	inline function lang(key:String, fallback:String):String
	{
		var v:String = Language.get(key, 'relax');
		// 缺 key 时 Language.get 会原样返回 key，开发者模式下还会加个 " (404)"
		return (v == null || v == key || v.endsWith(' (404)')) ? fallback : v;
	}
}

/**
 * Relax 专用选项：值不落在自己身上，由 getter / setter 闭包桥接 ClientPrefs。
 * 同一套写法见 substates/PauseDebugCharm.hx 的 DebugOption。
 *
 * defaultValue 取 ClientPrefs.defaultData —— 面板的 RESET 键靠它回滚，
 * 回落成 PanelOption 按类型给的 0 / false 会直接写出非法值（比如画质 0 → fftN = 0）。
 */
class RelaxOption extends PanelOption
{
	var getter:Void->Dynamic;
	var setter:Dynamic->Void;

	public function new(name:String, variable:String, type:OptionType, getter:Void->Dynamic, setter:Dynamic->Void,
			?options:Array<String>, ?description:String = null)
	{
		super(name, variable, type, options, description);
		this.getter = getter;
		this.setter = setter;

		var def:Dynamic = Reflect.getProperty(ClientPrefs.defaultData, variable);
		if (def != null) defaultValue = def;
	}

	override public function getValue():Dynamic
		return (getter != null) ? getter() : null;

	override public function setValue(value:Dynamic):Void
	{
		if (setter != null) setter(value);
	}
}
#end
