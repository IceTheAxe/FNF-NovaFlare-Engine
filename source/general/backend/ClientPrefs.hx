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
	// General
	public var framerate:Int = 1000;
	public var drawFramerate:Int = 1000;
	public var lockRender:Bool = true;
	public var renderThread:Bool = true;
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
	public var noteRGB:Bool = true;
	public var noteColorSwap:Bool = false;
	public var splashSkin:String = 'Psych';
	public var splashRGB:Bool = true;
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
	public var luaDebugPrint:Bool = true;
	public var noteOffsetChangingAllowed:Bool = false;
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
	public var arrowHSV:Array<Array<Float>> = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];

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
	public static var modsData:Map<String, Map<String, Dynamic>> = [];
	public static var flashingWarningAcknowledged(default, null):Bool = false;

	// 按键绑定
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

	public static var defaultKeys:Map<String, Array<FlxKey>> = null;

	public static function resetKeys(controller:Null<Bool> = null) // 只保留键盘，忽略controller参数
	{
		if (controller != true)
			for (key in keyBinds.keys())
				if (defaultKeys.exists(key))
					keyBinds.set(key, defaultKeys.get(key).copy());
	}

	public static function clearInvalidKeys(key:String)
	{
		var keyBind:Array<FlxKey> = keyBinds.get(key);
		while (keyBind != null && keyBind.contains(NONE))
			keyBind.remove(NONE);
	}

	public static function loadDefaultKeys()
	{
		defaultKeys = keyBinds.copy();
	}

	public static function acknowledgeFlashingWarning():Void
	{
		flashingWarningAcknowledged = true;
	}

	// ========== 保存和加载（完全基于 FlxSave，移除安全机制） ==========

	public static function saveSettings(showFailureAlert:Bool = true):Bool
	{
		// 保存主设置到 FlxG.save
		if (FlxG.save != null)
		{
			for (key in Reflect.fields(data))
				if (key != 'arrowRGB' && key != 'arrowRGBPixel')
					Reflect.setField(FlxG.save.data, key, Reflect.field(data, key));
			FlxG.save.data.modsData = modsData;
			if (FlxG.sound != null)
			{
				Reflect.setField(FlxG.save.data, 'volume', FlxG.sound.volume);
				Reflect.setField(FlxG.save.data, 'mute', FlxG.sound.muted);
			}
			Reflect.setField(FlxG.save.data, 'fullscreen', FlxG.fullscreen);
			if (flashingWarningAcknowledged)
				FlxG.save.data.openedFlash = true;

			#if ACHIEVEMENTS_ALLOWED Achievements.save(); #end
			FlxG.save.flush();
		}

		// 保存按键绑定到单独的 controls_v4
		var controlsSave:FlxSave = new FlxSave();
		try
		{
			if (controlsSave.bind('controls_v4', CoolUtil.getSavePath()))
			{
				controlsSave.data.keyboard = keyBinds;
				controlsSave.flush();
			}
		}
		catch (error:Dynamic)
		{
			FlxG.log.error('[ClientPrefs] Controls save threw: $error');
		}

		// 保存箭头颜色（独立文件）
		#if sys
		try
		{
			saveArrowRGBData('arrowRGB.json', data.arrowRGB);
			saveArrowRGBData('arrowRGBPixel.json', data.arrowRGBPixel);
		}
		catch (error:Dynamic)
		{
			FlxG.log.error('[ClientPrefs] Failed to save note colors: $error');
		}
		#end

		FlxG.log.add('[ClientPrefs] Settings saved.');
		return true;
	}

	public static function loadPrefs()
	{
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end

		var mainData:Dynamic = FlxG.save != null ? FlxG.save.data : null;

		// 从 FlxG.save 读取设置
		if (mainData != null)
		{
			for (key in Reflect.fields(data))
				if (key != 'gameplaySettings'
					&& key != 'arrowRGB'
					&& key != 'arrowRGBPixel'
					&& Reflect.hasField(mainData, key))
				{
					Reflect.setField(data, key, Reflect.field(mainData, key));
				}

			if (Reflect.field(mainData, 'gameplaySettings') != null)
				try
				{
					var savedMap:Map<String, Dynamic> = cast Reflect.field(mainData, 'gameplaySettings');
					for (name => value in savedMap)
						data.gameplaySettings.set(name, value);
				}
				catch (error:Dynamic)
				{
					FlxG.log.warn('[ClientPrefs] Ignored invalid legacy gameplay settings: $error');
				}

			if (Reflect.field(mainData, 'modsData') != null)
				try
				{
					modsData = cast Reflect.field(mainData, 'modsData');
				}
				catch (error:Dynamic)
				{
					modsData = [];
				}
			else
				modsData = [];
		}
		else
			modsData = [];

		// 加载按键绑定
		var controlsSave:FlxSave = new FlxSave();
		try
		{
			if (controlsSave.bind('controls_v4', CoolUtil.getSavePath()) && controlsSave.data.keyboard != null)
			{
				var loadedControls:Map<String, Array<FlxKey>> = cast controlsSave.data.keyboard;
				for (control => keys in loadedControls)
					if (keyBinds.exists(control) && keys != null)
					{
						var arr:Array<FlxKey> = [];
						for (key in keys)
						{
							var keyCode:Int = cast key;
							if (keyCode < -2 || keyCode > 302)
								throw 'Invalid FlxKey code $keyCode';
							arr.push(key);
						}
						keyBinds.set(control, arr);
					}
			}
		}
		catch (error:Dynamic)
		{
			FlxG.log.warn('[ClientPrefs] Ignored invalid controls save: $error');
		}

		// 处理闪烁警告确认
		if (mainData != null && Reflect.field(mainData, 'openedFlash') == true)
			flashingWarningAcknowledged = true;

		// 加载箭头颜色
		loadArrowRGBData('arrowRGB.json', false, ExtraKeysHandler.instance.data.colors);
		loadArrowRGBData('arrowRGBPixel.json', true, ExtraKeysHandler.instance.data.pixelNoteColors);

		reloadVolumeKeys();

		if (Main.fpsVar != null)
			Main.fpsVar.visible = data.showFPS;

		#if (!html5 && !switch)
		FlxG.autoPause = data.autoPause;

		if (mainData == null || Reflect.field(mainData, 'framerate') == null)
		{
			final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate * 2;
			data.framerate = Std.int(FlxMath.bound(refreshRate, 60, 1000));
		}

		if (mainData == null || Reflect.field(mainData, 'drawFramerate') == null)
		{
			final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
			data.drawFramerate = Std.int(FlxMath.bound(refreshRate, 60, 1000));
		}
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

		FlxG.updateFramerate = data.framerate;
		FlxG.drawFramerate = data.drawFramerate;
		FlxG.stage.application.window.lockRender = data.lockRender;

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

		// 音量和静音
		if (mainData != null && Reflect.field(mainData, 'volume') != null)
			FlxG.sound.volume = Reflect.field(mainData, 'volume');
		if (mainData != null && Reflect.field(mainData, 'mute') != null)
			FlxG.sound.muted = Reflect.field(mainData, 'mute');

		#if DISCORD_ALLOWED
		DiscordClient.check();
		#end
	}

	// ========== 辅助函数 ==========

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

	// ========== 箭头颜色保存（独立文件） ==========
	#if sys
	public static function saveArrowRGBData(path:String, rgbArray:Array<Array<FlxColor>>)
	{
		var colors:Array<EKNoteColor> = [];
		for (color in rgbArray)
		{
			var resultColor = new EKNoteColor();
			resultColor.inner = color[0].toHexString(false, false);
			resultColor.border = color[1].toHexString(false, false);
			resultColor.outline = color[2].toHexString(false, false);
			colors.push(resultColor);
		}
		var saveArrowRGB = new ArrowRGBSavedData(colors);
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
			if (pixel)
				ClientPrefs.data.arrowRGBPixel.push(thisNote);
			else
				ClientPrefs.data.arrowRGB.push(thisNote);
		}
	}
}