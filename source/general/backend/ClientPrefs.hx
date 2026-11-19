package general.backend;

import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.FlxG;
import flixel.math.FlxMath;

import states.titleState.TitleState;

import games.backend.ExtraKeysHandler.EKNoteColor;

import lime.system.Display;

#if mobile
import general.objects.screen.MouseEffect;
import general.shaders.MobileShaderConverter;
#end

// 设置数据结构，和原版完全一致，只移除了安全相关字段（原本也没有）
@:structInit class SaveVariables
{
	//更新这个直接原地爆破所有人设置
	public var prefsVersion:Int = 120;
	//更新这个能让性能相关的强制更新
	public var performanceDefaultsVersion:Int = 10;

	// General
	public var framerate:Int = 120;
	public var drawFramerate:Int = 120;
	// lime 8.4 的 FrameProfile.UNCAPPED：放开绘制帧率（TPS 仍由 framerate 决定）
	public var unlimitedFPS:Bool = false;
	public var lockRender:Bool = true;
	// lime 8.4 换底后渲染线程（GL worker）默认关：worker 首次接管 context 时
	// wglMakeCurrent 可能失败（“请求的资源在使用中”），一旦失败主线程也没有
	// 当前 context，整条渲染链会静默失效。需要时用设置项/环境变量显式开启。
	public var renderThread:Bool = false;
	public var resolution:String = 'Native';
	public var colorblindMode:String = 'None';
	public var lowQuality:Bool = false;
	public var gameQuality:Int = #if mobile 0 #else 1 #end;
	public var antialiasing:Bool = true;
	public var flashing:Bool = true;
	public var shaders:Bool = true;
	public var cacheOnGPU:Bool = false;
	public var autoPause:Bool = true;
	public var gcFreeZone:Bool = true;
	#if mobile
	public var autoOrientation:Bool = false;
	// 宽屏模式：画布按手机屏幕实际比例铺满（不开则 16:9 信箱居中）。改后重启游戏画布才真正变宽。
	public var wideScreen:Bool = false;
	// 边缘安全区额外内缩(画布 px)：刘海/灵动岛/挖孔自动检测之外的补充量。
	// 仅 wideScreen 下与自动检测叠加生效(16:9 画布够不到刘海,恒 0);改后下一个界面生效。
	public var edgeSafeOffset:Int = 0;
	public var autoShaderConversion:Bool = true;
	public var mouseTrailEffect:Bool = true;
	#end

	// Gameplay
	public var downScroll:Bool = false;
	public var middleScroll:Bool = false;
	public var flipChart:Bool = false;
	public var ghostTapping:Bool = true;
	public var guitarHeroSustains:Bool = true;
	public var noReset:Bool = false;
	public var playOpponent:Bool = false;
	public var opponentCodeFix:Bool = false;
	public var botOpponentFix:Bool = true;
	public var healthDrainOPPOMult:Float = 0.5;
	public var healthDrainOPPO:Bool = false;

	// Backend
	public var gameplayGC:Bool = false;
	public var fixLNL:Int = 0;
	public var saveScoreBase:String = 'Score';
	public var mainMusic:String = 'None';
	public var optionMusic:String = 'None';
	public var pauseMusic:String = 'Tea Time';
	public var hitsoundType:String = 'Default';
	public var hitsoundVolume:Float = 0;
	public var oldHscriptVersion:Bool = false;
	public var pauseButton:Bool = #if mobile true #else false #end;
	public var compulsionPause:Bool = false;
	public var compulsionPauseNumber:Int = 3;
	public var gameOverVibration:Bool = false;
	public var ratingOffset:Int = 0;
	public var noteOffset:Int = 0;
	public var replayQuality:Bool = true;
	public var showReplayWatermark:Bool = true;
	public var marvelousWindow:Int = 15;
	public var sickWindow:Int = 45;
	public var goodWindow:Int = 90;
	public var badWindow:Int = 135;
	public var safeFrames:Float = 10;
	public var marvelousRating:Bool = true;
	public var marvelousSprite:Bool = true;
	// 开局判定信息提示（MessageBox toast）的停留秒数，0 = 不创建
	public var startInfoTime:Float = 2;

	// App
	public var discordRPC:Bool = true;
	public var checkForUpdates:Bool = true;
	public var screensaver:Bool = false;
	public var githubCheck:Bool = false;
	public var filesCheck:Bool = true;
	public var quotaGCIncreace:Float = 1;

	// Game UI
	public var hideHud:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;
	public var opponentStrums:Bool = true;
	public var judgementCounter:Bool = false;
	public var totalNoteHits:Bool = true; // JudgementCounter 顶部显示 当前命中/总note
	public var keyboardViewer:Bool = true;
	public var timeBarType:String = 'Time Left';
	public var healthBarAlpha:Float = 1;
	public var oldHealthBarVersion:Bool = false;
	public var comboStacking:Bool = true;
	public var comboColor:Bool = true;
	public var comboOffsetFix:Bool = true;
	public var keyboardAlpha:Float = 0.8;
	public var keyboardTimeDisplay:Bool = true;
	public var keyboardTime:Float = 500;
	public var keyboardBGColor:String = 'WHITE';
	public var keyboardTextColor:String = 'BLACK';
	public var camZooms:Bool = true;
	public var scoreZoom:Bool = true;

	// Skin
	public var noteSkin:String = 'Default';
	// 音符着色体系三态：'auto' = 谱面皮肤优先 + 自动甄别 / 'legacy' = 沿用谱面皮肤 + 强制 HSV /
	// 'new' = 忽略谱面皮肤（换玩家皮肤）+ 强制 RGB。取值见 general.backend.NoteSkinStyle
	public var noteSystem:String = 'auto';
	// splash s
	public var splashSkin:String = 'Psych';
	public var splashSystem:String = 'auto';
	public var showSplash:Bool = true;
	public var splashAlpha:Float = 0.6;

	// Input
	public var dynamicColors:Bool = true;
	public var needMobileControl:Bool = true;
	public var hitboxLocation:String = 'Bottom';
	public var controlsAlpha:Float = 0.6;
	public var playControlsAlpha:Float = 0.2;
	public var hideHitboxHints:Bool = false;

	public var extraKey:Int = 4;
	public var extraKeyReturn1:String = 'Space';
	public var extraKeyReturn2:String = 'Space';
	public var extraKeyReturn3:String = 'Shift';
	public var extraKeyReturn4:String = 'Shift';

	// UI
	public var uiScale:Float = 1;
	public var customFade:String = 'Move';
	public var customFadeSound:Float = 0.5;
	public var customFadeText:Bool = true;
	public var skipTitleVideo:Bool = false;
	public var audioDisplayQuality:Int = 1;
	public var audioDisplayUpdate:Int = 50;
	public var resultsScreen:Bool = true;
	public var loadingScreen:Bool = false;
	public var loadThreads:Int = #if mobile 2 #else 4 #end;
	public var useFlixelCoords:Bool = true;

	// Watermark
	public var showFPS:Bool = true;
	public var rainbowFPS:Bool = true;
	public var fpsDisplayMode:String = 'TPS';
	public var memoryType:String = 'Usage';
	public var fpsScale:Float = 1;
	public var watermarkScale:Float = 1;
	public var showWatermark:Bool = true;

	public var comboOffset:Array<Int> = [0, 0, 0, 0, 530, 470];
	public var language:String = 'English';
	public var storageFolder:String = 'NovaFlare Engine';
	public var developerMode:Bool = false;
	public var devConScale:Float = #if mobile 1.8 #else 1.5 #end;
	public var deepDebug:Bool = false;
	public var moreLuaErrors:Bool = false;

	public var showKeybinds:Bool = false;
	public var enableRecordRotation:Bool = true;
	public var enableBpmZoom:Bool = true;
	public var theme:String = "Circle";
	public var songInfo:String = "None";
	public var showMS:Bool = true;
	public var hitErrorBarVisible:Bool = false;
	public var hitBarLines:Int = 5;
	public var hitBarLineTime:Float = 2.5;
	public var hitErrorBarOffsetX:Float = 0;
	public var hitErrorBarOffsetY:Float = 0;
	public var guideLineAlpha:Float = 0;
	public var msInErrorBar:Bool = false;
	public var pointerType:String = "triangle";
	public var customColor:Bool = true;
	public var gradientTimeBar:Bool = true;
	public var pauseType:String = "NF";
	public var coolBackdrop:Bool = true;
	// FE 同步：暂停菜单动画/输入选项（NewPauseSubState）
	public var pauseSkipFadeIn:Bool = false;            // 跳过开场滑入动画
	public var pauseSkipFadeOut:Bool = false;           // 跳过关闭滑出动画
	public var pauseDoubleEnterSkip:Bool = false;       // 关闭动画期间双击 accept 键瞬时关闭
	public var pauseUnlockInputDuringAnim:Bool = false; // 开场动画期间也允许操作
	public var luaDebugPrint:Bool = true;
	public var noteOffsetChangingAllowed:Bool = false;
	public var peChartEditor:Bool = false;

	// ===== RelaxState Options（RelaxSubState 音乐播放器，选项面板直接 Reflect 写入） =====
	public var NextSongs:String = 'Next';              // 播放结束行为：Next / Restart / Random
	public var RelaxAudioDisplayQuality:Int = 2;       // 频谱 FFT 质量（仅 Relax 界面，1-10）
	public var RelaxAudioNumber:Int = 3;               // 频谱条数（120 / 该值，1-8）
	public var RelaxAudioSymmetry:Bool = true;         // 频谱中间对称
	// enableRecordRotation / enableBpmZoom / theme / songInfo 沿用上方旧字段（172-175 行）

	// 主菜单闲置 N 分钟后自动进入 Relax（类休眠），0 = 关闭
	public var relaxIdleMinutes:Int = 0;
	// Arrow RGB
	public var arrowRGB:Array<Array<FlxColor>> = [
		[0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
		[0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
		[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
		[0xFFF9393F, 0xFFFFFFFF, 0xFF651038]
	];
	public var arrowRGBPixel:Array<Array<FlxColor>> = [
		[0xFFE276FF, 0xFFFFF9FF, 0xFF60008D],
		[0xFF3DCAFF, 0xFFF4FFFF, 0xFF003060],
		[0xFF71E300, 0xFFF6FFE6, 0xFF003100],
		[0xFFFF884E, 0xFFFFFAF5, 0xFF6C0000]
	];
	// legacy 体系的每轨 HSV 偏移：16 轨（多键引擎里 10 键也够用），lane 越界由 general.shaders.NoteHSV 取模归一
	public var arrowHSV:Array<Array<Float>> = [for (i in 0...16) [0.0, 0.0, 0.0]];

	public var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative',
		'songspeed' => 1.0,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'instakill' => false,
		'practice' => false,
		'botplay' => false,
		'opponentplay' => false
	];
}

class ClientPrefs
{
	public static var data:SaveVariables = {};
	public static var defaultData:SaveVariables = {};
	public static var modsData:Map<String, Map<String, Dynamic>>= [];

	// Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public static var keyBinds:Map<String, Array<FlxKey>> = [
		'note_left' => [A, LEFT],
		'note_down' => [S, DOWN],
		'note_up' => [K, UP],
		'note_right' => [L, RIGHT],

		'0_key_0' => [SPACE],

		'1_key_0' => [D, LEFT],
		'1_key_1' => [K, RIGHT],

		'2_key_0' => [D],
		'2_key_1' => [SPACE],
		'2_key_2' => [K],

		'4_key_0' => [D],
		'4_key_1' => [F],
		'4_key_2' => [SPACE],
		'4_key_3' => [J],
		'4_key_4' => [K],

		'5_key_0' => [S],
		'5_key_1' => [D],
		'5_key_2' => [F],
		'5_key_3' => [J],
		'5_key_4' => [K],
		'5_key_5' => [L],

		'6_key_0' => [S],
		'6_key_1' => [D],
		'6_key_2' => [F],
		'6_key_3' => [SPACE],
		'6_key_4' => [J],
		'6_key_5' => [K],
		'6_key_6' => [L],

		'7_key_0' => [A],
		'7_key_1' => [S],
		'7_key_2' => [D],
		'7_key_3' => [F],
		'7_key_4' => [J],
		'7_key_5' => [K],
		'7_key_6' => [L],
		'7_key_7' => [SEMICOLON],

		'8_key_0' => [A],
		'8_key_1' => [S],
		'8_key_2' => [D],
		'8_key_3' => [F],
		'8_key_4' => [SPACE],
		'8_key_5' => [J],
		'8_key_6' => [K],
		'8_key_7' => [L],
		'8_key_8' => [SEMICOLON],

		'9_key_0' => [A],
		'9_key_1' => [S],
		'9_key_2' => [D],
		'9_key_3' => [F],
		'9_key_4' => [V],
		'9_key_5' => [N],
		'9_key_6' => [J],
		'9_key_7' => [K],
		'9_key_8' => [L],
		'9_key_9' => [SEMICOLON],

		'ui_up' => [W, UP],
		'ui_left' => [A, LEFT],
		'ui_down' => [S, DOWN],
		'ui_right' => [D, RIGHT],
		'accept' => [SPACE, ENTER],
		'back' => [BACKSPACE, ESCAPE],
		'pause' => [ENTER, ESCAPE],
		'reset' => [R],
		'volume_mute' => [#if mobile F10 #else ZERO #end],
		'volume_up' => [NUMPADPLUS, PLUS],
		'volume_down' => [NUMPADMINUS, MINUS],
		'debug_1' => [SEVEN],
		'debug_2' => [EIGHT],
		'fullscreen' => [F11]
	];

	//(男人叹气)(男人叹气)(男人叹气)(男人叹气)(男人叹气)(男人叹气)(男人叹气)(男人叹气)(男人叹气)
	public static var gamepadBinds:Map<String, Array<FlxGamepadInputID>> = [
		'0_key_0' => [DPAD_LEFT, X],

		'1_key_0'	 => [DPAD_LEFT, X],
		'1_key_1' 	 => [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],

		'2_key_0'	 => [DPAD_LEFT, X],
		'2_key_1'	 => [DPAD_UP, Y],
		'2_key_2'	 => [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],

		'note_up'    => [DPAD_UP, Y],
		'note_left'  => [DPAD_LEFT, X],
		'note_down'  => [DPAD_DOWN, A],
		'note_right' => [DPAD_RIGHT, B],

		'ui_up'      => [DPAD_UP, LEFT_STICK_DIGITAL_UP],
		'ui_left'    => [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
		'ui_down'    => [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
		'ui_right'   => [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],

		'accept'     => [A, START],
		'back'       => [B],
		'pause'      => [START],
		'reset'      => [BACK]
	];

	public static var defaultMobileBinds:Map<String, Array<FlxKey>> = null;
	public static var defaultKeys:Map<String, Array<FlxKey>> = null;
	public static var defaultButtons:Map<String, Array<FlxGamepadInputID>> = null;

	public static function resetKeys(controller:Null<Bool> = null)
	{
		if (controller != true)
			for (key in keyBinds.keys())
				if (defaultKeys.exists(key))
				{
					var arr = keyBinds.get(key);
					arr.resize(0);
					for (i in defaultKeys.get(key))
						arr.push(i);
				}

		if (controller != false)
			for (key in gamepadBinds.keys())
				if (defaultButtons.exists(key))
				{
					var arr = gamepadBinds.get(key);
					arr.resize(0);
					for (i in defaultButtons.get(key))
						arr.push(i);
				}
	}

	public static function clearInvalidKeys(key:String)
	{
		var keyBind:Array<FlxKey> = keyBinds.get(key);
		while (keyBind != null && keyBind.contains(NONE))
			keyBind.remove(NONE);
	}

	public static function clearInvalidButtons(key:String)
	{
		var buttonBind:Array<FlxGamepadInputID> = gamepadBinds.get(key);
		while (buttonBind != null && buttonBind.contains(FlxGamepadInputID.NONE))
			buttonBind.remove(FlxGamepadInputID.NONE);
	}

	public static function loadDefaultKeys()
	{
		defaultKeys = [for (key => value in keyBinds) key => value.copy()];
		loadDefaultButtons();
	}

	public static function loadDefaultButtons()
	{
		defaultButtons = [for (key => value in gamepadBinds) key => value.copy()];
	}

	public static function saveSettings()
	{
		for (key in Reflect.fields(data))
			if (key != 'arrowRGB' && key != 'arrowRGBPixel')
			{
				Reflect.setField(FlxG.save.data, key, Reflect.field(data, key));
			} //遍历data输入到flxsave里
		#if sys
		else if (key == 'arrowRGB')
			saveArrowRGBData('arrowRGB.json', data.arrowRGB);
		else if (key == 'arrowRGBPixel')
			saveArrowRGBData('arrowRGBPixel.json', data.arrowRGBPixel);
		#end

		FlxG.save.data.modsData = modsData;

		#if ACHIEVEMENTS_ALLOWED Achievements.save(); #end
		FlxG.save.flush();

		// Placing this in a separate save so that it can be manually deleted without removing your Score and stuff
		var save:FlxSave = new FlxSave();
		save.bind('controls_v4', CoolUtil.getSavePath());
		save.data.keyboard = keyBinds;
		save.data.gamepad = gamepadBinds;

		save.flush();
		FlxG.log.add("Settings saved!");
	}

	/**
	 * 无限 FPS 时 split render 的绘制上限（lime 自己的帧率归一化上限也是 10000）。
	 */
	public static inline final UNLIMITED_DRAW_FRAMERATE:Int = 10000;

	/**
	 * 统一应用帧率 / lime 帧调度。loadPrefs() 与设置菜单的即时生效都走这里。
	 *
	 * NF 的 flixel 平时是 variable timestep（`fixedTimestep = false`，见 InitState），
	 * 逻辑 update 直接挂在 lime 主循环的 ENTER_UPDATE 上，节拍由 `window.frameRate` 决定。
	 * 无限 FPS 下主循环被 uncap，ENTER_UPDATE 变成「每轮循环一次」，速率由渲染耗时
	 * 决定（也就是等于绘制帧率），不能直接当逻辑时钟用：所以这时切回 flixel 的固定
	 * 步长累加器，让逻辑按真实时间推进，只放开渲染侧。
	 *
	 * 累加器那边有两点是硬要求，改动 flixel 时要一起看（`FlxGame.onEnterUpdate`）：
	 * - 步长必须精确到 `1000 / tps` 的浮点值。`fixedStepMS` 是 Int，120 TPS 会落成
	 *   8ms（125 步/秒），逻辑整体快 4%。
	 * - 累加器只能在单个 tick 上设追赶上限，不能夹成「一两步」。夹太紧时 tick 一稀，
	 *   差额被永久丢弃，游戏就变成慢动作 —— 这正是「更新帧率低于目标值就慢放」的成因。
	 *
	 * 渲染侧还有第二道闸：NF 的 lime fork 把 render 拆成了独立 deadline
	 * （`lockRender` / `window.drawFrameRate`），只 uncap 主循环并不会抬高绘制频率，
	 * 所以 drawFrameRate 要一并抬到上限。
	 */
	public static function applyFrameTiming():Void
	{
		final tps:Int = Std.int(FlxMath.bound(data.framerate, 1, 2000));
		final fps:Int = Std.int(FlxMath.bound(data.drawFramerate, 1, UNLIMITED_DRAW_FRAMERATE));

		// 基础帧率对所有平台都生效（含 html5 / switch）
		FlxG.fixedTimestep = false;
		FlxG.fixedStepMSExact = 0;
		FlxG.updateFramerate = tps;
		FlxG.drawFramerate = fps;

		#if (!html5 && !switch)
		if (FlxG.stage == null || FlxG.stage.application == null)
			return;

		final app = FlxG.stage.application;

		if (data.unlimitedFPS)
		{
			FlxG.updateFramerate = tps;
			// 同步写 FlxG.drawFramerate：flixel 的 onFocus 会拿它回写窗口绘制上限，
			// 只改 window.drawFrameRate 的话切出再切回就会掉回原来的 FPS 上限。
			FlxG.drawFramerate = UNLIMITED_DRAW_FRAMERATE;
			// 先写整型（兼容只读 fixedStepMS 的地方），再写精确值；整型 setter 会清掉精确值
			FlxG.fixedStepMS = Std.int(Math.max(1, Math.round(1000 / tps)));
			FlxG.fixedStepMSExact = 1000.0 / tps;
			FlxG.fixedTimestep = true;

			if (FlxG.game != null)
			{
				// 切换瞬间旧累加器（variable timestep 下残留的真实耗时）会一次性补好几步，
				// 清掉避免第一帧逻辑跳一下
				@:privateAccess FlxG.game._accumulator = 0;
			}

			#if (lime >= "8.4.0")
			app.configureFrameTiming(lime.app.FrameProfile.UNCAPPED, {uncapMode: lime.app.UncapMode.SOFT}, lime.app.VSyncMode.OFF);
			#end

			app.window.drawFrameRate = UNLIMITED_DRAW_FRAMERATE;
			// 这里最后写 lockRender：FlxG.drawFramerate 的 setter 会强制把它置 true
			app.window.lockRender = data.lockRender;
			return;
		}

		#if (lime >= "8.4.0")
		// 退出无限模式时把主循环的 profile 与 vsync 复位，否则 frameRate 仍被忽略
		app.configureFrameTiming(lime.app.FrameProfile.BALANCED, {uncapMode: lime.app.UncapMode.OFF}, lime.app.VSyncMode.OFF);
		#end

		app.window.frameRate = tps;
		app.window.drawFrameRate = fps;
		app.window.lockRender = data.lockRender;
		#end
	}

	#if sys
	public static function saveArrowRGBData(path:String, rgbArray:Array<Array<FlxColor>>)
	{
		var saveArrowRGB:ArrowRGBSavedData;
		var colors:Array<EKNoteColor> = [];
		for (color in rgbArray)
		{
			var inner = color[0];
			var border = color[1];
			var outline = color[2];

			var resultColor = new EKNoteColor();
			resultColor.inner = inner.toHexString(false, false);
			resultColor.border = border.toHexString(false, false);
			resultColor.outline = outline.toHexString(false, false);

			colors.push(resultColor);

			// trace('Saved color ${resultColor.inner} ${resultColor.border} ${resultColor.outline}');
		}

		saveArrowRGB = new ArrowRGBSavedData(colors);
		var writer = new json2object.JsonWriter<ArrowRGBSavedData>();
		var content = writer.write(saveArrowRGB, '    ');
		File.saveContent(path, content);

		trace('Wrote to $path');
	}
	#end

	public static function loadArrowRGBData(path:String, pixel:Bool = false, defaultColors:Array<EKNoteColor>)
	{
		var savedColors:CoolUtil.ArrowRGBSavedData = CoolUtil.getArrowRGB(path, defaultColors);

		if (pixel)
			ClientPrefs.defaultData.arrowRGBPixel = [];
		else
			ClientPrefs.defaultData.arrowRGB = [];

		for (defaultColor in defaultColors)
		{
			var thisNote = [
				CoolUtil.colorFromString(defaultColor.inner),
				CoolUtil.colorFromString(defaultColor.border),
				CoolUtil.colorFromString(defaultColor.outline)
			];
			if (pixel)
				ClientPrefs.defaultData.arrowRGBPixel.push(thisNote);
			else
				ClientPrefs.defaultData.arrowRGB.push(thisNote);
		}

		if (pixel)
			ClientPrefs.data.arrowRGBPixel = [];
		else
			ClientPrefs.data.arrowRGB = [];

		for (color in savedColors.colors)
		{
			var thisNote = [
				CoolUtil.colorFromString(color.inner),
				CoolUtil.colorFromString(color.border),
				CoolUtil.colorFromString(color.outline)
			];

			// trace('Loaded color into save: $thisNote, pixel? $pixel');

			if (pixel)
				ClientPrefs.data.arrowRGBPixel.push(thisNote);
			else
				ClientPrefs.data.arrowRGB.push(thisNote);
		}
	}

	public static function loadPrefs()
	{
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end

		if (FlxG.save.data.prefsVersion != data.prefsVersion)
		{
			data = {};
			modsData = [];
			for (key in Reflect.fields(defaultData))
			{
				if (key == 'arrowRGB' || key == 'arrowRGBPixel' || key == 'modsData')
					continue;
				if (key == 'gameplaySettings')
				{
					data.gameplaySettings.clear();
					for (k => v in defaultData.gameplaySettings)
						data.gameplaySettings.set(k, v);
					FlxG.save.data.gameplaySettings = data.gameplaySettings;
					continue;
				}
				Reflect.setField(data, key, Reflect.field(defaultData, key));
				Reflect.setField(FlxG.save.data, key, Reflect.field(defaultData, key));
			}
			FlxG.save.data.modsData = modsData;

			// 全平台统一 120 TPS / 120 FPS 默认（不再按刷新率或桌面/移动分档）
			data.framerate = 120;
			data.drawFramerate = 120;
			Reflect.setField(FlxG.save.data, 'framerate', data.framerate);
			Reflect.setField(FlxG.save.data, 'drawFramerate', data.drawFramerate);

			FlxG.save.flush();

			#if sys
			if (FileSystem.exists('arrowRGB.json')) FileSystem.deleteFile('arrowRGB.json');
			if (FileSystem.exists('arrowRGBPixel.json')) FileSystem.deleteFile('arrowRGBPixel.json');
			#end
			loadArrowRGBData('arrowRGB.json', false, ExtraKeysHandler.instance.data.colors);
			loadArrowRGBData('arrowRGBPixel.json', true, ExtraKeysHandler.instance.data.pixelNoteColors);

			if (defaultKeys == null)
				loadDefaultKeys();
			if (defaultButtons == null)
				loadDefaultButtons();

			keyBinds.clear();
			for (name => keys in defaultKeys)
				keyBinds.set(name, keys.copy());

			gamepadBinds.clear();
			for (name => buttons in defaultButtons)
				gamepadBinds.set(name, buttons.copy());

			var controlSave:FlxSave = new FlxSave();
			controlSave.bind('controls_v4', CoolUtil.getSavePath());
			if (controlSave != null)
			{
				controlSave.data.keyboard = defaultKeys;
				controlSave.data.gamepad = defaultButtons;
				controlSave.flush();
			}
			reloadVolumeKeys();
		}
		else
		{
			for (key in Reflect.fields(data))
				if (key != 'gameplaySettings' && 
					key != 'arrowRGB' &&
					key != 'arrowRGBPixel' &&
					// Keep the compiled migration target. Loading the saved marker
					// here makes the later comparison oldVersion < targetVersion
					// compare the old value with itself and silently skip migration.
					key != 'performanceDefaultsVersion' && Reflect.hasField(FlxG.save.data, key))
				{
					var savedValue:Dynamic = Reflect.field(FlxG.save.data, key);
					// Older builds exposed this integer as a checkbox and may have saved a Bool.
					if (key == 'fixLNL' && Std.isOfType(savedValue, Bool)) savedValue = savedValue ? 1 : 0;
					Reflect.setField(data, key, savedValue);
				}
				else if (key == 'arrowRGB') 
				{
					loadArrowRGBData('arrowRGB.json', false, ExtraKeysHandler.instance.data.colors);
				} 
				else if (key == 'arrowRGBPixel') 
				{
					loadArrowRGBData('arrowRGBPixel.json', true, ExtraKeysHandler.instance.data.pixelNoteColors);
				}

			if (FlxG.save.data.modsData != null)
				modsData = FlxG.save.data.modsData;
			else modsData = [];

			var save:FlxSave = new FlxSave();
			save.bind('controls_v4', CoolUtil.getSavePath());
			if (save != null)
			{
				if (save.data.keyboard != null)
				{
					var loadedControls:Map<String, Array<FlxKey>> = save.data.keyboard;
					for (control => keys in loadedControls)
						if (keyBinds.exists(control))
						{
							var arr = keyBinds.get(control);
							arr.resize(0);
							for (i in keys)
								arr.push(i);
						}
				}
				if (save.data.gamepad != null)
				{
					var loadedButtons:Map<String, Array<FlxGamepadInputID>> = save.data.gamepad;
					for (control => buttons in loadedButtons)
						if (gamepadBinds.exists(control))
						{
							var arr = gamepadBinds.get(control);
							arr.resize(0);
							for (i in buttons)
								arr.push(i);
						}
				}
				reloadVolumeKeys();
			}
		}

		#if desktop
		// Migrate only the measured desktop scheduling defaults. Keep every other
		// preference and key binding intact.
		var savedPerformanceDefaultsVersion:Dynamic = Reflect.field(FlxG.save.data, 'performanceDefaultsVersion');
		if (savedPerformanceDefaultsVersion == null || savedPerformanceDefaultsVersion < data.performanceDefaultsVersion)
		{
			// v10：默认调度从 240 TPS / 1200 FPS 收到 120 / 120。
			// 这一档只动帧率，分辨率 / 独立渲染 / 渲染线程保持用户当前选择。
			data.framerate = 120;
			data.drawFramerate = 120;
			Reflect.setField(FlxG.save.data, 'framerate', data.framerate);
			Reflect.setField(FlxG.save.data, 'drawFramerate', data.drawFramerate);

			// v9：性能相关的一整套默认值（只对更早的存档生效，避免 v10 反复覆盖）
			if (savedPerformanceDefaultsVersion == null || savedPerformanceDefaultsVersion < 9)
			{
				data.lockRender = true;
				// lime 8.4 底上 GL worker 还不稳定（首次绑 context 会失败并把渲染链
				// 打死），性能默认值不再强制开渲染线程，保持主线程直渲。
				data.renderThread = false;
				// Keep desktop high-FPS mode at the engine's authored resolution.
				// Higher resolutions remain selectable, but should be an explicit
				// image-quality choice rather than a hidden cost on every interface.
				data.resolution = '720P';
				Reflect.setField(FlxG.save.data, 'lockRender', data.lockRender);
				Reflect.setField(FlxG.save.data, 'renderThread', data.renderThread);
				Reflect.setField(FlxG.save.data, 'resolution', data.resolution);
			}

			Reflect.setField(FlxG.save.data, 'performanceDefaultsVersion', data.performanceDefaultsVersion);
			FlxG.save.flush();
		}
		#end

		if (Main.fpsVar != null)
			Main.fpsVar.visible = data.showFPS;

		#if (!html5 && !switch)
		FlxG.autoPause = data.autoPause;

		// 存档缺键时的兜底：全平台统一 120，不再按桌面/移动分档
		if (FlxG.save.data.framerate == null)
			data.framerate = 120;

		if (FlxG.save.data.drawFramerate == null)
			data.drawFramerate = 120;
		#end

		var useRenderThread:Bool = data.renderThread;
		#if sys
		final renderThreadOverride:String = Sys.getEnv('NOVAFLARE_RENDER_THREAD');
		if (renderThreadOverride == '0')
			useRenderThread = false;
		else if (renderThreadOverride == '1')
			useRenderThread = true;
		#end
		lime.graphics.opengl.GL.setMultiThreaded(useRenderThread);

		#if mobile
		MobileShaderConverter.setEnabled(data.autoShaderConversion);
		MouseEffect.setUserEffectsEnabled(data.mouseTrailEffect);
		#end

		// 帧率 / 无限 FPS / lime 帧调度统一入口
		applyFrameTiming();

		// 分辨率设置
		var output:Array<Float> = [];
		switch(data.resolution) {
			case '360P': output = [640, 360];
			case '480P': output = [854, 480];
			case '540P': output = [960, 540];
			case '720P': output = [1280, 720];
			case '768P': output = [1366, 768];
			case '900P': output = [1600, 900];
			case '1080P': output = [1920, 1080];
			case '1440P (2K)': output = [2560, 1440];
			case '1600P': output = [2560, 1600];
			case '1800P': output = [3200, 1800];
			case '2160P (4K)': output = [3840, 2160];
			default:
				var display:Display = lime.system.System.getDisplay(0);
				output = [display.bounds.width, display.bounds.height];
				data.resolution = "Native: " + display.bounds.width + "x" + display.bounds.height;
		}
		openfl.Lib.current.stage.setLogicalSize(Std.int(output[0]), Std.int(output[1]));

		if (FlxG.save.data.gameplaySettings != null)
		{
			var savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
			for (name => value in savedMap)
				data.gameplaySettings.set(name, value);
		}

		// flixel automatically saves your volume!
		if (FlxG.save.data.volume != null)
			FlxG.sound.volume = FlxG.save.data.volume;
		if (FlxG.save.data.mute != null)
			FlxG.sound.muted = FlxG.save.data.mute;

		normalizeNoteSystems();

		#if DISCORD_ALLOWED
		DiscordClient.check();
		#end
	}

	// ========== 辅助函数 ==========

	/**
	 * 音符 / 溅射着色体系的三态规范化，以及从已废弃的 noteRGB / noteColorSwap / splashRGB 迁移。
	 *
	 * 老存档里这三个 Bool 是"强制"语义：noteColorSwap=true 等价于强制 HSV（legacy），
	 * noteRGB=false 是同一诉求的另一种写法；splashRGB=false 同理。新存档只写 noteSystem /
	 * splashSystem，所以只在「还没有新键」时执行迁移，不会覆盖用户后来选的 auto。
	 */
	static function normalizeNoteSystems():Void
	{
		// 16 轨：老存档只有 4 项，补到 16 项；顺手把残缺项修成三元组。
		// 重建一份新数组，别和 defaultData 共享同一份引用（否则"重置默认值"会带上用户的改动）
		final oldHSV:Array<Array<Float>> = data.arrowHSV;
		final normalized:Array<Array<Float>> = [];
		for (i in 0...16)
		{
			final row:Array<Float> = (oldHSV != null && i < oldHSV.length) ? oldHSV[i] : null;
			normalized.push((row != null && row.length >= 3) ? row.copy() : [0.0, 0.0, 0.0]);
		}
		data.arrowHSV = normalized;

		// 新存档没有 noteRGB / noteColorSwap / splashRGB 这三个键，老存档才有
		final savedNoteSystem:Dynamic = Reflect.field(FlxG.save.data, 'noteSystem');
		if (savedNoteSystem == null)
		{
			final oldSwap:Dynamic = Reflect.field(FlxG.save.data, 'noteColorSwap');
			final oldRGB:Dynamic = Reflect.field(FlxG.save.data, 'noteRGB');
			if (oldSwap == true || oldRGB == false)
				data.noteSystem = NoteSkinStyle.LEGACY;
		}

		final savedSplashSystem:Dynamic = Reflect.field(FlxG.save.data, 'splashSystem');
		if (savedSplashSystem == null)
		{
			final oldSplashRGB:Dynamic = Reflect.field(FlxG.save.data, 'splashRGB');
			if (oldSplashRGB == false)
				data.splashSystem = NoteSkinStyle.LEGACY;
		}

		data.noteSystem = NoteSkinStyle.normalizeMode(data.noteSystem);
		data.splashSystem = NoteSkinStyle.normalizeMode(data.splashSystem);
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic
	{
		if (!customDefaultValue)
			defaultValue = defaultData.gameplaySettings.get(name);
		return data.gameplaySettings.exists(name) ? data.gameplaySettings.get(name) : defaultValue;
	}

	public static function reloadVolumeKeys()
	{
		TitleState.muteKeys = keyBinds.get('volume_mute').copy();
		TitleState.volumeDownKeys = keyBinds.get('volume_down').copy();
		TitleState.volumeUpKeys = keyBinds.get('volume_up').copy();
		toggleVolumeKeys(true);
	}

	public static function toggleVolumeKeys(?turnOn:Bool = true)
	{
		FlxG.sound.muteKeys = turnOn ? TitleState.muteKeys : [];
		FlxG.sound.volumeDownKeys = turnOn ? TitleState.volumeDownKeys : [];
		FlxG.sound.volumeUpKeys = turnOn ? TitleState.volumeUpKeys : [];
	}

	public static function get(variable:String, supportMods:Bool = true):Dynamic {
		if (supportMods) {
			if (modsData.get(Mods.currentModDirectory).get(variable) != null)
				return modsData.get(Mods.currentModDirectory).get(variable);

			if (modsData.get('Global mod').get(variable) != null)
				return modsData.get('Global mod').get(variable);

			for (mod in Mods.getGlobalMods())
				if (modsData.get(mod).get(variable) != null)
					return modsData.get(mod).get(variable);
		}

		if (Reflect.getProperty(ClientPrefs.data, variable) != null)
			return Reflect.getProperty(ClientPrefs.data, variable);

		return null;
	}

	public static function set(variable:String, data:Bool = true, path:String = '') {
		switch (path) {
			case '':
				if (Mods.currentModDirectory != '') {
					if (modsData.get(Mods.currentModDirectory) == null)
						modsData.set(Mods.currentModDirectory, []);
					modsData.get(Mods.currentModDirectory).set(variable, data);
				} else {
					if (modsData.get('Global mod') == null)
						modsData.set('Global mod', []);
					modsData.get('Global mod').set(variable, data);
				}
			case 'data':
				try { Reflect.setProperty(ClientPrefs.data, variable, data); }
			case _:
				if (modsData.get(path) == null)
					modsData.set(path, []);
				modsData.get(path).set(variable, data);
		}
	}

	// ========== 箭头颜色（存在主存档里，不再单独落 .json） ==========

	/**
	 * 从主存档读 note 颜色。首启或老存档里没有这份数据时返回 null。
	 */
	static function readArrowRGBFromSave(fieldName:String):Array<Array<FlxColor>>
	{
		if (FlxG.save == null || FlxG.save.data == null || !Reflect.hasField(FlxG.save.data, fieldName))
			return null;

		final raw:Dynamic = Reflect.field(FlxG.save.data, fieldName);
		if (raw == null || !Std.isOfType(raw, Array))
			return null;

		final result:Array<Array<FlxColor>> = [];
		for (note in cast(raw, Array<Dynamic>))
		{
			if (note == null || !Std.isOfType(note, Array))
				continue;

			final noteColors:Array<FlxColor> = [];
			for (value in cast(note, Array<Dynamic>))
				noteColors.push(value == null ? FlxColor.WHITE : Std.int(value));
			result.push(noteColors);
		}

		return result.length > 0 ? result : null;
	}

	static function writeArrowRGBToSave(fieldName:String, value:Array<Array<FlxColor>>):Void
	{
		if (FlxG.save == null || FlxG.save.data == null)
			return;

		try
		{
			Reflect.setField(FlxG.save.data, fieldName, value);
			FlxG.save.flush();
		}
		catch (error:Dynamic)
		{
			FlxG.log.error('[ClientPrefs] Failed to write note colors: $error');
		}
	}
}