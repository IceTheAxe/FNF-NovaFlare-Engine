package general.backend;

import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

import states.titleState.TitleState;

import games.backend.ExtraKeysHandler.EKNoteColor;

import lime.system.Display;

#if mobile
import general.objects.screen.MouseEffect;
import general.shaders.MobileShaderConverter;
#end

// Add a variable here and it will get automatically saved
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
	// Opponent s
	public var playOpponent:Bool = false;
	public var opponentCodeFix:Bool = false;
	public var botOpponentFix:Bool = true;
	public var healthDrainOPPOMult:Float = 0.5;
	public var healthDrainOPPO:Bool = false;

	// Backend
	// Gameplay backend s
	public var gameplayGC:Bool = false;
	public var fixLNL:Int = 0; // fix long note length
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

	// App backend s
	public var discordRPC:Bool = true;
	public var checkForUpdates:Bool = true;
	public var screensaver:Bool = false;
	public var githubCheck:Bool = false;
	public var filesCheck:Bool = true;
	public var quotaGCIncreace:Float = 1;

	// Game UI
	// Visble s
	public var hideHud:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;
	public var opponentStrums:Bool = true;
	public var judgementCounter:Bool = false;
	public var keyboardViewer:Bool = true;
	// TimeBar s
	public var timeBarType:String = 'Time Left';
	// HealthBar s
	public var healthBarAlpha:Float = 1;
	public var oldHealthBarVersion:Bool = false;
	// Combe s
	public var comboStacking:Bool = true;
	public var comboColor:Bool = true;
	public var comboOffsetFix:Bool = true;
	// KeyBoard s
	public var keyboardAlpha:Float = 0.8;
	public var keyboardTimeDisplay:Bool = true;
	public var keyboardTime:Float = 500;
	public var keyboardBGColor:String = 'WHITE';
	public var keyboardTextColor:String = 'BLACK';
	// Camera s
	public var camZooms:Bool = true;
	public var scoreZoom:Bool = true;

	// Skin
	public var noteSkin:String = 'Default';
	public var noteRGB:Bool = true;
	public var noteColorSwap:Bool = false;
	// splash s
	public var splashSkin:String = 'Psych';
	public var splashRGB:Bool = true;
	public var showSplash:Bool = true;
	public var splashAlpha:Float = 0.6;

	// Input
	// Moblie Input Backend s
	public var dynamicColors:Bool = true;
	public var needMobileControl:Bool = true; // work for desktop
	public var hitboxLocation:String = 'Bottom';
	public var controlsAlpha:Float = 0.6;
	public var playControlsAlpha:Float = 0.2;
	public var hideHitboxHints:Bool = false;

	public var extraKey:Int = 4;
	public var extraKeyReturn1:String = 'Space';
	public var extraKeyReturn2:String = 'Space';
	public var extraKeyReturn3:String = 'Shift';
	public var extraKeyReturn4:String = 'Shift';

	// User Interface
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

	//For Extra Keys (maybe)
	public var showKeybinds:Bool = false;
	
	public var enableRecordRotation:Bool = true;
	public var enableBpmZoom:Bool = true;
	
	//public var theme:Array<String> = ["Circle", "Straight", "None"];
	//public var songInfo:Array<String> = ["None", "Middle", "topLeft", "downLeft", "topRight", "downRight"];
	public var theme:String = "Circle";
	public var songInfo:String = "None";
	
	//////////////////////////////////////////////////////////////////////////////////////

	//Psych引擎的箭头RGB可以扔了，已经几乎被PsychEK代替了————卡昔233
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

	//其实这个也可以扔了,我们有多k，，，，，
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

#if sys
private typedef SafePrefsCandidate =
{
	var generation:Int;
	var payload:Dynamic;
	var sourcePath:String;
}

private typedef PendingSafePrefsCandidate =
{
	var baseGeneration:Int;
	var revision:Float;
	var candidate:SafePrefsCandidate;
}
#end

class ClientPrefs
{
	public static var data:SaveVariables = {};
	public static var defaultData:SaveVariables = {};
	public static var modsData:Map<String, Map<String, Dynamic>>= [];
	public static var flashingWarningAcknowledged(default, null):Bool = false;
	public static var protectedSettingsReady(default, null):Bool = false;

	#if sys
	static inline var SAFE_PREFS_MAGIC:String = 'NF_SAFE_PREFS';
	// Version 1 was produced with Reflect.hasField() on the concrete
	// SaveVariables class. hxcpp always returned false there, so every v1 core
	// snapshot contained compiled defaults even though its checksum was valid.
	// Reject those snapshots and migrate again from the legacy mirror.
	static inline var SAFE_PREFS_VERSION:Int = 2;
	static inline var SAFE_PREFS_MAX_PAYLOAD:Int = 512 * 1024;
	static inline var SAFE_PREFS_MAX_FILE:Int = 1024 * 1024;
	static inline var SAFE_PREFS_MAX_MOD_VALUE:Int = 16 * 1024;
	static inline var SAFE_PREFS_MAX_MOD_TOTAL:Int = 128 * 1024;
	static inline var LEGACY_PENDING_MARKER:String = 'nfLegacyPrefsPending';
	static inline var LEGACY_PENDING_BASE_GENERATION:String = 'nfLegacyPrefsBaseGeneration';
	static inline var LEGACY_PENDING_KEYBINDS:String = 'nfLegacyPrefsPendingKeyBinds';
	static inline var LEGACY_PENDING_REVISION:String = 'nfLegacyPrefsRevision';
	static inline var MAIN_SAFE_FORMAT_VERSION_FIELD:String = 'nfSafePrefsFormatVersion';
	static inline var CONTROLS_PENDING_MAGIC:String = 'NF_PENDING_PREFS';
	static inline var CONTROLS_PENDING_MAGIC_FIELD:String = 'nfPendingPrefsMagic';
	static inline var CONTROLS_PENDING_VERSION_FIELD:String = 'nfPendingPrefsVersion';
	static inline var CONTROLS_PENDING_BASE_FIELD:String = 'nfPendingPrefsBaseGeneration';
	static inline var CONTROLS_PENDING_GENERATION_FIELD:String = 'nfPendingPrefsGeneration';
	static inline var CONTROLS_PENDING_REVISION_FIELD:String = 'nfPendingPrefsRevision';
	static inline var CONTROLS_PENDING_PAYLOAD_FIELD:String = 'nfPendingPrefsPayload';
	static inline var CONTROLS_PENDING_DIGEST_FIELD:String = 'nfPendingPrefsDigest';
	static var safePrefsGeneration:Int = 0;
	static var safePrefsFutureVersionFound:Bool = false;
	static var lastSafePrefsError:String = '';
	static var protectedCheckpointTimer:FlxTimer;
	static var volumeCheckpointRegistered:Bool = false;
	#end

	// Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public static var keyBinds:Map<String, Array<FlxKey>> = [
		// Key Bind, Name for ControlsSubState
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
	public static var defaultMobileBinds:Map<String, Array<FlxKey>> = null;
	public static var defaultKeys:Map<String, Array<FlxKey>> = null;
	public static var defaultButtons:Map<String, Array<FlxGamepadInputID>> = null;

	public static function resetKeys(controller:Null<Bool> = null) // Null = both, False = Keyboard, True = Controller
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
	}

	public static function clearInvalidKeys(key:String)
	{
		var keyBind:Array<FlxKey> = keyBinds.get(key);
		while (keyBind != null && keyBind.contains(NONE))
			keyBind.remove(NONE);
	}

	public static function loadDefaultKeys()
	{
		defaultKeys = [for (key => value in keyBinds) key => value.copy()];
	}

	public static function acknowledgeFlashingWarning():Void
	{
		flashingWarningAcknowledged = true;
	}

	/** Legacy score fields may only be removed after settings have a verified independent copy. */
	public static inline function canSafelyCleanLegacyScoreFields():Bool
	{
		#if sys
		return protectedSettingsReady;
		#else
		return true;
		#end
	}

	/** Coalesces direct settings writes (sound tray, fullscreen, mod options). */
	public static function scheduleProtectedSettingsCheckpoint(delay:Float = 1.25):Void
	{
		#if sys
		if (protectedCheckpointTimer != null)
			protectedCheckpointTimer.cancel();
		protectedCheckpointTimer = new FlxTimer().start(delay, function(_:FlxTimer)
		{
			protectedCheckpointTimer = null;
			if (!saveSettings(false))
				FlxG.log.error('[ClientPrefs] Deferred protected settings checkpoint failed.');
		});
		#end
	}

	public static function checkpointProtectedSettings():Bool
	{
		#if sys
		return saveSettings();
		#else
		return true;
		#end
	}

	/**
	 * Saves a small, independently recoverable preference snapshot before
	 * mirroring settings to the legacy save. Scores and per-note history never
	 * enter this snapshot.
	 */
	public static function saveSettings(showFailureAlert:Bool = true, preferLegacyAuxiliary:Bool = false):Bool
	{
		#if sys
		// If the protected write fails, this generation identifies the safe
		// snapshot on top of which the legacy fallback was created. It lets the
		// loader distinguish a genuinely newer fallback from a stale marker whose
		// cleanup simply did not reach disk.
		var pendingBaseGeneration:Int = safePrefsGeneration;
		#end
		var safeSaved:Bool = true;
		#if sys
		safeSaved = saveSafePrefs(preferLegacyAuxiliary);
		var pendingRevision:Float = Date.now().getTime();
		var controlsPendingGeneration:Int = pendingBaseGeneration + 1;
		var controlsPendingPayload:String = null;
		if (!safeSaved)
		{
			// The old protected generation is still a valid rollback copy, but it no
			// longer contains the user's current edits. Keep score cleanup away from
			// the main file until the pending fallback has been reconciled.
			protectedSettingsReady = false;
			if (!safePrefsFutureVersionFound)
				try
				{
					var fallbackPayload:String = buildSafePrefsPayload(controlsPendingGeneration, preferLegacyAuxiliary);
					var parsedFallback:Dynamic = haxe.Json.parse(fallbackPayload);
					if (utf8Length(fallbackPayload) <= SAFE_PREFS_MAX_PAYLOAD
						&& parsedFallback != null && validateSafePrefsPayload(parsedFallback))
						controlsPendingPayload = fallbackPayload;
				}
				catch (error:Dynamic)
				{
					FlxG.log.error('[ClientPrefs] Could not prepare the independent fallback payload: $error');
				}
		}
		#end

		// controls_v4 remains a compatibility mirror. A separate immutable copy is
		// embedded in the pending main-save transaction below, so recovery does not
		// depend on two files being flushed atomically.
		var controlsSaved:Bool = false;
		var controlsSave:FlxSave = new FlxSave();
		try
		{
			if (controlsSave.bind('controls_v4', CoolUtil.getSavePath()))
			{
				controlsSave.data.keyboard = keyBinds;
				#if sys
				if (safeSaved)
					clearControlsPendingPrefs(controlsSave.data);
				else if (controlsPendingPayload != null)
				{
					Reflect.setField(controlsSave.data, CONTROLS_PENDING_MAGIC_FIELD, CONTROLS_PENDING_MAGIC);
					Reflect.setField(controlsSave.data, CONTROLS_PENDING_VERSION_FIELD, SAFE_PREFS_VERSION);
					Reflect.setField(controlsSave.data, CONTROLS_PENDING_BASE_FIELD, pendingBaseGeneration);
					Reflect.setField(controlsSave.data, CONTROLS_PENDING_GENERATION_FIELD, controlsPendingGeneration);
					Reflect.setField(controlsSave.data, CONTROLS_PENDING_REVISION_FIELD, pendingRevision);
					Reflect.setField(controlsSave.data, CONTROLS_PENDING_PAYLOAD_FIELD, controlsPendingPayload);
					Reflect.setField(controlsSave.data, CONTROLS_PENDING_DIGEST_FIELD,
						pendingPrefsDigest(pendingBaseGeneration, controlsPendingGeneration, pendingRevision, controlsPendingPayload));
				}
				#end
				controlsSaved = controlsSave.flush();
			}
		}
		catch (error:Dynamic)
		{
			FlxG.log.error('[ClientPrefs] Controls save threw: $error');
		}

		var mainSaved:Bool = false;
		#if sys
		var independentFallbackSaved:Bool = !safeSaved && controlsPendingPayload != null && controlsSaved;
		#end
		var mainData:Dynamic = FlxG.save != null ? FlxG.save.data : null;
		if (mainData != null)
		{
			// Always mirror the complete current state. When the safe commit failed,
			// the marker turns this same main flush into an explicit fallback
			// transaction instead of silently discarding the user's edits.
			for (key in Reflect.fields(data))
				if (key != 'arrowRGB' && key != 'arrowRGBPixel')
					Reflect.setField(mainData, key, Reflect.field(data, key));
			mainData.modsData = modsData;
			// During startup migration the runtime sound/fullscreen state has not yet
			// been restored. saveSafePrefs(true) already mirrors the validated legacy
			// auxiliary values, so do not overwrite them with startup defaults here.
			if (!preferLegacyAuxiliary && FlxG.sound != null)
			{
				Reflect.setField(mainData, 'volume', FlxG.sound.volume);
				Reflect.setField(mainData, 'mute', FlxG.sound.muted);
			}
			if (!preferLegacyAuxiliary)
				Reflect.setField(mainData, 'fullscreen', FlxG.fullscreen);
			if (flashingWarningAcknowledged)
				mainData.openedFlash = true;

			#if sys
			if (safeSaved)
				clearLegacyPendingPrefs(mainData);
			else
			{
				Reflect.setField(mainData, LEGACY_PENDING_MARKER, true);
				Reflect.setField(mainData, LEGACY_PENDING_BASE_GENERATION, pendingBaseGeneration);
				Reflect.setField(mainData, LEGACY_PENDING_KEYBINDS, snapshotCurrentKeyBinds());
				Reflect.setField(mainData, LEGACY_PENDING_REVISION, pendingRevision);
			}
			#end

			#if ACHIEVEMENTS_ALLOWED Achievements.save(); #end
			try
			{
				mainSaved = FlxG.save.flush();
			}
			catch (error:Dynamic)
			{
				FlxG.log.error('[ClientPrefs] Legacy main-save flush threw: $error');
			}
		}
		else
			FlxG.log.error('[ClientPrefs] Legacy main save is not bound; settings were kept only in the safe snapshot.');

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

		var allSaved:Bool = safeSaved && mainSaved && controlsSaved;
		#if sys
		var fallbackSaved:Bool = mainSaved || independentFallbackSaved;
		#else
		var fallbackSaved:Bool = mainSaved;
		#end
		if (allSaved)
			FlxG.log.add('[ClientPrefs] Settings saved.');
		else if (safeSaved)
			FlxG.log.warn('[ClientPrefs] Protected settings were saved, but a legacy compatibility save was incomplete (main=$mainSaved, controls=$controlsSaved).');
		else if (fallbackSaved)
			FlxG.log.warn('[ClientPrefs] Protected settings failed, but a complete versioned legacy fallback was saved and will be reconciled on next startup.');
		else
		{
			FlxG.log.error('[ClientPrefs] Settings save was incomplete (safe=$safeSaved, main=$mainSaved, controls=$controlsSaved).');
			#if (desktop || mobile)
			if (showFailureAlert && lime.app.Application.current != null && lime.app.Application.current.window != null)
				lime.app.Application.current.window.alert('The protected save and its fallback both failed. Your previous protected settings are still intact.'
					+ (lastSafePrefsError.length > 0 ? '\n\n' + lastSafePrefsError : ''), 'Settings save failed');
			#end
		}
		// The protected snapshot contains the complete preference/control state and
		// is the commit that prevents an Android main-save failure from resetting
		// the user. Legacy mirrors are best-effort compatibility copies.
		#if sys
		return safeSaved || fallbackSaved;
		#else
		return mainSaved && controlsSaved;
		#end
	}

	#if sys
	static function registerProtectedCheckpointSignals():Void
	{
		if (volumeCheckpointRegistered || FlxG.sound == null)
			return;
		volumeCheckpointRegistered = true;
		FlxG.sound.onVolumeChange.add(onProtectedVolumeChange);
	}

	static function onProtectedVolumeChange(_:Float):Void
	{
		scheduleProtectedSettingsCheckpoint();
	}

	static function safePrefsFailure(message:String):Bool
	{
		lastSafePrefsError = message;
		trace('[ClientPrefs] $message');
		FlxG.log.error('[ClientPrefs] $message');
		return false;
	}

	static function snapshotCurrentKeyBinds():Map<String, Array<FlxKey>>
	{
		var snapshot:Map<String, Array<FlxKey>> = [];
		for (control => keys in keyBinds)
			if (keys != null)
				snapshot.set(control, keys.copy());
		return snapshot;
	}

	static function decodePendingKeyBinds(raw:Dynamic):Map<String, Array<FlxKey>>
	{
		if (raw == null)
			return null;
		try
		{
			var source:Map<String, Array<FlxKey>> = cast raw;
			var restored:Map<String, Array<FlxKey>> = [];
			var recognized:Int = 0;
			for (control => keys in source)
			{
				if (!keyBinds.exists(control) || keys == null)
					continue;
				var copied:Array<FlxKey> = [];
				for (key in keys)
				{
					var code:Int = cast key;
					if (code < -2 || code > 302)
						return null;
					copied.push(key);
				}
				restored.set(control, copied);
				recognized++;
			}
			return recognized > 0 ? restored : null;
		}
		catch (_:Dynamic)
		{
			return null;
		}
	}

	static function applyPendingKeyBinds(restored:Map<String, Array<FlxKey>>):Void
	{
		if (restored == null)
			return;
		for (control => keys in restored)
			keyBinds.set(control, keys.copy());
	}

	static function isValidPendingLegacyPrefs(mainData:Dynamic, safeCandidate:SafePrefsCandidate,
		pendingKeyBinds:Map<String, Array<FlxKey>>):Bool
	{
		if (mainData == null || Reflect.field(mainData, LEGACY_PENDING_MARKER) != true || pendingKeyBinds == null)
			return false;
		var baseGeneration:Null<Int> = readSafeInt(Reflect.field(mainData, LEGACY_PENDING_BASE_GENERATION));
		var candidateGeneration:Int = safeCandidate != null ? safeCandidate.generation : 0;
		if (baseGeneration == null || baseGeneration < 0 || baseGeneration < candidateGeneration)
			return false;

		var templates:SaveVariables = {};
		for (key in ['flashing', 'framerate', 'drawFramerate', 'resolution'])
			if (!Reflect.hasField(mainData, key)
				|| coerceSafeValue(Reflect.field(mainData, key), Reflect.field(templates, key)) == null)
				return false;
		return true;
	}

	static function clearLegacyPendingPrefs(mainData:Dynamic):Void
	{
		if (mainData == null)
			return;
		Reflect.deleteField(mainData, LEGACY_PENDING_MARKER);
		Reflect.deleteField(mainData, LEGACY_PENDING_BASE_GENERATION);
		Reflect.deleteField(mainData, LEGACY_PENDING_KEYBINDS);
		Reflect.deleteField(mainData, LEGACY_PENDING_REVISION);
	}

	static function clearControlsPendingPrefs(controlsData:Dynamic):Void
	{
		if (controlsData == null)
			return;
		for (field in [CONTROLS_PENDING_MAGIC_FIELD, CONTROLS_PENDING_VERSION_FIELD, CONTROLS_PENDING_BASE_FIELD,
			CONTROLS_PENDING_GENERATION_FIELD, CONTROLS_PENDING_REVISION_FIELD, CONTROLS_PENDING_PAYLOAD_FIELD,
			CONTROLS_PENDING_DIGEST_FIELD])
			Reflect.deleteField(controlsData, field);
	}

	static function readControlsPendingPrefs(controlsData:Dynamic, safeCandidate:SafePrefsCandidate):PendingSafePrefsCandidate
	{
		try
		{
			if (controlsData == null || Reflect.field(controlsData, CONTROLS_PENDING_MAGIC_FIELD) != CONTROLS_PENDING_MAGIC
				|| readSafeInt(Reflect.field(controlsData, CONTROLS_PENDING_VERSION_FIELD)) != SAFE_PREFS_VERSION)
				return null;
			var baseGeneration:Null<Int> = readSafeInt(Reflect.field(controlsData, CONTROLS_PENDING_BASE_FIELD));
			var generation:Null<Int> = readSafeInt(Reflect.field(controlsData, CONTROLS_PENDING_GENERATION_FIELD));
			var revision:Null<Float> = readSafeFloat(Reflect.field(controlsData, CONTROLS_PENDING_REVISION_FIELD));
			var payload:String = Std.isOfType(Reflect.field(controlsData, CONTROLS_PENDING_PAYLOAD_FIELD), String)
				? cast Reflect.field(controlsData, CONTROLS_PENDING_PAYLOAD_FIELD)
				: null;
			var digest:String = Std.isOfType(Reflect.field(controlsData, CONTROLS_PENDING_DIGEST_FIELD), String)
				? cast Reflect.field(controlsData, CONTROLS_PENDING_DIGEST_FIELD)
				: null;
			var safeGeneration:Int = safeCandidate != null ? safeCandidate.generation : 0;
			if (baseGeneration == null || generation == null || revision == null || payload == null || digest == null
				|| baseGeneration < safeGeneration || generation != baseGeneration + 1
				|| utf8Length(payload) > SAFE_PREFS_MAX_PAYLOAD
				|| digest != pendingPrefsDigest(baseGeneration, generation, revision, payload))
				return null;
			var parsed:Dynamic = haxe.Json.parse(payload);
			if (parsed == null
				|| readSafeInt(Reflect.field(parsed, 'schemaVersion')) != SAFE_PREFS_VERSION
				|| readSafeInt(Reflect.field(parsed, 'generation')) != generation
				|| !Std.isOfType(Reflect.field(parsed, 'flashingWarningAcknowledged'), Bool)
				|| !validateSafePrefsPayload(parsed))
				return null;
			return {
				baseGeneration: baseGeneration,
				revision: revision,
				candidate: {generation: generation, payload: parsed, sourcePath: 'controls_v4 pending fallback'}
			};
		}
		catch (_:Dynamic)
		{
			return null;
		}
	}

	static function summarizeSafePrefsPayload(payload:Dynamic):String
	{
		var prefs:Dynamic = payload != null ? Reflect.field(payload, 'prefs') : null;
		if (prefs == null)
			return 'missing prefs';
		var templates:SaveVariables = {};
		var present:Int = 0;
		var changed:Array<String> = [];
		for (key in Reflect.fields(templates))
		{
			if (key == 'arrowRGB' || key == 'arrowRGBPixel' || key == 'gameplaySettings' || !Reflect.hasField(prefs, key))
				continue;
			present++;
			var template:Dynamic = Reflect.field(templates, key);
			var value:Dynamic = coerceSafeValue(Reflect.field(prefs, key), template);
			if (value != null)
			{
				var valueText:String = haxe.Json.stringify(value);
				var templateText:String = haxe.Json.stringify(coerceSafeValue(template, template));
				if (valueText != templateText)
					changed.push(key);
			}
		}
		changed.sort(function(a:String, b:String):Int return Reflect.compare(a, b));
		var shown:Array<String> = changed.length > 16 ? changed.slice(0, 16) : changed;
		return 'fields=$present, nonDefault=${changed.length}'
			+ (shown.length > 0 ? ' [' + shown.join(',') + (changed.length > shown.length ? ',...' : '') + ']' : '');
	}

	static function saveSafePrefs(preferLegacyAuxiliary:Bool = false):Bool
	{
		lastSafePrefsError = '';
		if (safePrefsFutureVersionFound)
			return safePrefsFailure('A newer safe-preferences format exists; refusing to overwrite it.');

		var stage:String = 'building payload';
		try
		{
			var nextGeneration:Int = safePrefsGeneration + 1;
			var payload:String = buildSafePrefsPayload(nextGeneration, preferLegacyAuxiliary);
			if (payload == null || payload.length <= 0 || utf8Length(payload) > SAFE_PREFS_MAX_PAYLOAD)
				return safePrefsFailure('Safe preference payload is empty or too large.');

			stage = 'validating payload';
			var parsedPayload:Dynamic = haxe.Json.parse(payload);
			if (parsedPayload == null || !validateSafePrefsPayload(parsedPayload))
				return safePrefsFailure('Safe preference payload failed in-memory validation.');
			trace('[ClientPrefs] Prepared protected settings generation $nextGeneration: ${summarizeSafePrefsPayload(parsedPayload)}');

			stage = 'building envelope';
			var envelope:Dynamic = {};
			Reflect.setField(envelope, 'magic', SAFE_PREFS_MAGIC);
			Reflect.setField(envelope, 'formatVersion', SAFE_PREFS_VERSION);
			Reflect.setField(envelope, 'generation', nextGeneration);
			Reflect.setField(envelope, 'payload', payload);
			Reflect.setField(envelope, 'digest', safePrefsDigest(nextGeneration, payload));
			var encoded:String = haxe.Json.stringify(envelope);
			if (utf8Length(encoded) > SAFE_PREFS_MAX_FILE)
				return safePrefsFailure('Safe preference envelope is too large.');

			stage = 'writing inactive slot';
			var targetPath:String = getSafePrefsPath(nextGeneration % 2 == 1 ? 'a' : 'b');
			if (!writeSafePrefsFile(targetPath, encoded, nextGeneration))
				return false;
			trace('[ClientPrefs] Verified protected settings generation $nextGeneration in $targetPath');

			protectedSettingsReady = true;
			safePrefsGeneration = nextGeneration;
			if (FlxG.save != null && FlxG.save.data != null)
			{
				var committedPayload:Dynamic = haxe.Json.parse(payload);
				// Mirror the exact committed auxiliary values into the legacy save, but
				// do not touch live sound/fullscreen state here. Doing so dispatches the
				// checkpoint signal again and would create an endless save timer loop.
				applySafeAuxiliary(Reflect.field(committedPayload, 'auxiliary'), FlxG.save.data, nextGeneration, true, false);
				Reflect.setField(FlxG.save.data, 'nfSafePrefsGeneration', nextGeneration);
				Reflect.setField(FlxG.save.data, MAIN_SAFE_FORMAT_VERSION_FIELD, SAFE_PREFS_VERSION);
				clearLegacyPendingPrefs(FlxG.save.data);
			}
			return true;
		}
		catch (error:Dynamic)
		{
			return safePrefsFailure('Safe preference save threw while $stage: $error');
		}
	}

	static function buildSafePrefsPayload(generation:Int, preferLegacyAuxiliary:Bool):String
	{
		var templateData:SaveVariables = {};
		var prefs:Dynamic = {};
		for (key in Reflect.fields(templateData))
		{
			if (key == 'arrowRGB' || key == 'arrowRGBPixel' || key == 'gameplaySettings')
				continue;
			var template:Dynamic = Reflect.field(templateData, key);
			// SaveVariables is a concrete class. On hxcpp its generated class exposes
			// __Field/__GetFields but not __HasField, so Reflect.hasField(data, key)
			// always returns false and used to replace every live setting with the
			// compiled default. The keys come from another SaveVariables instance and
			// are therefore known class fields; read them directly.
			var current:Dynamic = data != null ? Reflect.field(data, key) : template;
			var copied:Dynamic = coerceSafeValue(current, template);
			if (copied == null)
				copied = coerceSafeValue(template, template);
			if (copied != null)
				Reflect.setField(prefs, key, copied);
		}

		var gameplayEntries:Array<Dynamic> = [];
		var gameplayKeys:Array<String> = data.gameplaySettings != null
			? [for (key in data.gameplaySettings.keys()) key]
			: [];
		gameplayKeys.sort(function(a:String, b:String):Int return Reflect.compare(a, b));
		for (key in gameplayKeys)
		{
			var template:Dynamic = templateData.gameplaySettings.get(key);
			var copied:Dynamic = template != null
				? coerceSafeValue(data.gameplaySettings.get(key), template)
				: copySafeJsonValue(data.gameplaySettings.get(key));
			if (copied == null && template != null)
				copied = coerceSafeValue(template, template);
			if (copied != null)
			{
				var entry:Array<Dynamic> = [key, copied];
				gameplayEntries.push(entry);
			}
		}

		var modEntries:Array<Dynamic> = [];
		var protectedModBytes:Int = 0;
		var skippedModValues:Int = 0;
		var modsDataComplete:Bool = true;
		var modSettingsComplete:Bool = true;
		var modNames:Array<String> = modsData != null ? [for (name in modsData.keys()) name] : [];
		modNames.sort(function(a:String, b:String):Int return Reflect.compare(a, b));
		for (modName in modNames)
		{
			var modValues:Map<String, Dynamic> = modsData.get(modName);
			if (modValues == null)
			{
				modsDataComplete = false;
				continue;
			}
			var valueNames:Array<String> = [for (name in modValues.keys()) name];
			valueNames.sort(function(a:String, b:String):Int return Reflect.compare(a, b));
			var savedValues:Array<Dynamic> = [];
			for (name in valueNames)
			{
				var copied:Dynamic = copySafeJsonValue(modValues.get(name));
				if (copied != null)
				{
					var valueEntry:Array<Dynamic> = [name, copied];
					var valueBytes:Int = utf8Length(haxe.Json.stringify(valueEntry));
					if (valueBytes <= SAFE_PREFS_MAX_MOD_VALUE && protectedModBytes + valueBytes <= SAFE_PREFS_MAX_MOD_TOTAL)
					{
						savedValues.push(valueEntry);
						protectedModBytes += valueBytes;
					}
					else
					{
						skippedModValues++;
						modsDataComplete = false;
					}
				}
				else
				{
					skippedModValues++;
					modsDataComplete = false;
				}
			}
			var modEntry:Array<Dynamic> = [modName, savedValues];
			modEntries.push(modEntry);
		}

		var controlEntries:Array<Dynamic> = [];
		var controlNames:Array<String> = [for (key in keyBinds.keys()) key];
		controlNames.sort(function(a:String, b:String):Int return Reflect.compare(a, b));
		for (control in controlNames)
		{
			var codes:Array<Int> = [];
			var binds:Array<FlxKey> = keyBinds.get(control);
			if (binds != null)
				for (key in binds)
				{
					var code:Int = cast key;
					if (code >= -2 && code <= 302)
						codes.push(code);
				}
			var entry:Array<Dynamic> = [control, codes];
			controlEntries.push(entry);
		}

		var mainData:Dynamic = FlxG.save != null ? FlxG.save.data : null;
		var legacyModSettings:Array<Dynamic> = [];
		if (mainData != null && Reflect.field(mainData, 'modSettings') != null)
			try
			{
				var rawModSettings:Map<String, Dynamic> = cast Reflect.field(mainData, 'modSettings');
				var folders:Array<String> = [for (folder in rawModSettings.keys()) folder];
				folders.sort(function(a:String, b:String):Int return Reflect.compare(a, b));
				for (folder in folders)
				{
					var rawValues:Map<String, Dynamic> = cast rawModSettings.get(folder);
					if (rawValues == null)
					{
						modSettingsComplete = false;
						continue;
					}
					var names:Array<String> = [for (name in rawValues.keys()) name];
					names.sort(function(a:String, b:String):Int return Reflect.compare(a, b));
					var savedValues:Array<Dynamic> = [];
					for (name in names)
					{
						var copied:Dynamic = copySafeJsonValue(rawValues.get(name));
						if (copied == null)
						{
							skippedModValues++;
							modSettingsComplete = false;
							continue;
						}
						var valueEntry:Array<Dynamic> = [name, copied];
						var valueBytes:Int = utf8Length(haxe.Json.stringify(valueEntry));
						if (valueBytes <= SAFE_PREFS_MAX_MOD_VALUE && protectedModBytes + valueBytes <= SAFE_PREFS_MAX_MOD_TOTAL)
						{
							savedValues.push(valueEntry);
							protectedModBytes += valueBytes;
						}
						else
						{
							skippedModValues++;
							modSettingsComplete = false;
						}
					}
					var folderEntry:Array<Dynamic> = [folder, savedValues];
					legacyModSettings.push(folderEntry);
				}
			}
			catch (error:Dynamic)
			{
				modSettingsComplete = false;
				FlxG.log.warn('[ClientPrefs] Some legacy mod settings could not be protected: $error');
			}
		if (skippedModValues > 0)
			FlxG.log.warn('[ClientPrefs] Skipped $skippedModValues oversized mod setting value(s) while protecting core preferences.');
		var auxiliary:Dynamic = {};
		var legacyVolume:Null<Float> = mainData != null ? readSafeFloat(Reflect.field(mainData, 'volume')) : null;
		if (legacyVolume != null && (legacyVolume < 0 || legacyVolume > 1))
			legacyVolume = null;
		var runtimeVolume:Null<Float> = FlxG.sound != null ? readSafeFloat(FlxG.sound.volume) : null;
		if (runtimeVolume != null && (runtimeVolume < 0 || runtimeVolume > 1))
			runtimeVolume = null;
		Reflect.setField(auxiliary, 'volume', preferLegacyAuxiliary && legacyVolume != null
			? legacyVolume
			: (runtimeVolume != null ? runtimeVolume : (legacyVolume != null ? legacyVolume : 1.0)));
		var legacyMute:Dynamic = mainData != null ? Reflect.field(mainData, 'mute') : null;
		var runtimeMute:Dynamic = FlxG.sound != null ? FlxG.sound.muted : null;
		Reflect.setField(auxiliary, 'mute', preferLegacyAuxiliary && Std.isOfType(legacyMute, Bool)
			? legacyMute
			: (Std.isOfType(runtimeMute, Bool) ? runtimeMute : (Std.isOfType(legacyMute, Bool) ? legacyMute : false)));
		var legacyFullscreen:Dynamic = mainData != null ? Reflect.field(mainData, 'fullscreen') : null;
		Reflect.setField(auxiliary, 'fullscreen', preferLegacyAuxiliary && Std.isOfType(legacyFullscreen, Bool) ? legacyFullscreen : FlxG.fullscreen);
		if (mainData != null)
		{
			var mode:Null<Int> = readSafeInt(Reflect.field(mainData, 'mobileControlsMode'));
			if (mode != null && mode >= 0 && mode <= 5)
				Reflect.setField(auxiliary, 'mobileControlsMode', mode);
			var buttons:Dynamic = copySafePointArray(Reflect.field(mainData, 'buttons'));
			if (buttons != null)
				Reflect.setField(auxiliary, 'buttons', buttons);
			var extraButtons:Dynamic = copySafePointArray(Reflect.field(mainData, 'extraButtons'));
			if (extraButtons != null)
				Reflect.setField(auxiliary, 'extraButtons', extraButtons);
		}

		var payload:Dynamic = {};
		Reflect.setField(payload, 'schemaVersion', SAFE_PREFS_VERSION);
		Reflect.setField(payload, 'generation', generation);
		Reflect.setField(payload, 'flashingWarningAcknowledged', flashingWarningAcknowledged);
		Reflect.setField(payload, 'prefs', prefs);
		Reflect.setField(payload, 'gameplaySettings', gameplayEntries);
		Reflect.setField(payload, 'modsData', modEntries);
		Reflect.setField(payload, 'modsDataComplete', modsDataComplete);
		Reflect.setField(payload, 'modSettings', legacyModSettings);
		Reflect.setField(payload, 'modSettingsComplete', modSettingsComplete);
		Reflect.setField(payload, 'keyBinds', controlEntries);
		Reflect.setField(payload, 'auxiliary', auxiliary);
		return haxe.Json.stringify(payload);
	}

	static function copySafeJsonValue(value:Dynamic, depth:Int = 0):Dynamic
	{
		if (value == null || depth > 8)
			return null;
		if (Std.isOfType(value, Bool) || Std.isOfType(value, Int) || Std.isOfType(value, String))
			return value;
		if (Std.isOfType(value, Float))
		{
			var number:Float = cast value;
			return isFiniteNumber(number) ? number : null;
		}
		if (Std.isOfType(value, Array))
		{
			var output:Array<Dynamic> = [];
			for (item in (cast value:Array<Dynamic>))
			{
				var copied:Dynamic = copySafeJsonValue(item, depth + 1);
				if (copied == null)
					return null;
				output.push(copied);
			}
			return output;
		}
		if (Reflect.isObject(value) && !Reflect.isFunction(value) && Type.getClass(value) == null)
		{
			var output:Dynamic = {};
			var fields:Array<String> = Reflect.fields(value);
			fields.sort(function(a:String, b:String):Int return Reflect.compare(a, b));
			for (field in fields)
			{
				var copied:Dynamic = copySafeJsonValue(Reflect.field(value, field), depth + 1);
				if (copied == null)
					return null;
				Reflect.setField(output, field, copied);
			}
			return output;
		}
		return null;
	}

	static function copySafePointArray(value:Dynamic):Dynamic
	{
		if (value == null || !Std.isOfType(value, Array))
			return null;
		var result:Array<Dynamic> = [];
		for (point in (cast value:Array<Dynamic>))
		{
			if (point == null)
				return null;
			var x:Null<Float> = readSafeFloat(Reflect.field(point, 'x'));
			var y:Null<Float> = readSafeFloat(Reflect.field(point, 'y'));
			if (x == null || y == null)
				return null;
			var pair:Array<Dynamic> = [x, y];
			result.push(pair);
		}
		return result;
	}

	static function loadSafePrefs():SafePrefsCandidate
	{
		safePrefsGeneration = 0;
		safePrefsFutureVersionFound = false;
		var newest:SafePrefsCandidate = null;
		for (slot in ['a', 'b'])
		{
			var basePath:String = getSafePrefsPath(slot);
			for (suffix in ['', '.bak', '.tmp'])
			{
				var candidate:SafePrefsCandidate = readSafePrefsFile(basePath + suffix, suffix == '');
				if (candidate != null && (newest == null || candidate.generation > newest.generation))
					newest = candidate;
			}
		}
		if (newest != null)
			safePrefsGeneration = newest.generation;
		return newest;
	}

	static function readSafePrefsFile(path:String, allowFutureVersionLock:Bool = false):SafePrefsCandidate
	{
		try
		{
			if (!FileSystem.exists(path) || FileSystem.isDirectory(path))
				return null;
			var encoded:String = File.getContent(path);
			if (encoded == null || encoded.length <= 0 || utf8Length(encoded) > SAFE_PREFS_MAX_FILE)
				return null;
			var envelope:Dynamic = haxe.Json.parse(encoded);
			if (envelope == null || Reflect.field(envelope, 'magic') != SAFE_PREFS_MAGIC)
				return null;

			var formatVersion:Null<Int> = readSafeInt(Reflect.field(envelope, 'formatVersion'));
			if (formatVersion != SAFE_PREFS_VERSION)
			{
				if (allowFutureVersionLock && formatVersion != null && formatVersion > SAFE_PREFS_VERSION)
				{
					var futureGeneration:Null<Int> = readSafeInt(Reflect.field(envelope, 'generation'));
					var futurePayload:Dynamic = Reflect.field(envelope, 'payload');
					var futureDigest:Dynamic = Reflect.field(envelope, 'digest');
					if (futureGeneration != null && futureGeneration > 0
						&& Std.isOfType(futurePayload, String)
						&& Std.isOfType(futureDigest, String)
						&& utf8Length(futurePayload) <= SAFE_PREFS_MAX_PAYLOAD
						&& futureDigest == safePrefsDigest(futureGeneration, futurePayload, formatVersion))
						safePrefsFutureVersionFound = true;
				}
				return null;
			}
			var generation:Null<Int> = readSafeInt(Reflect.field(envelope, 'generation'));
			var payload:String = Std.isOfType(Reflect.field(envelope, 'payload'), String)
				? cast Reflect.field(envelope, 'payload')
				: null;
			var digest:String = Std.isOfType(Reflect.field(envelope, 'digest'), String)
				? cast Reflect.field(envelope, 'digest')
				: null;
			if (generation == null || generation <= 0 || payload == null || utf8Length(payload) > SAFE_PREFS_MAX_PAYLOAD || digest == null)
				return null;
			if (digest != safePrefsDigest(generation, payload))
				return null;

			var parsed:Dynamic = haxe.Json.parse(payload);
			if (parsed == null
				|| readSafeInt(Reflect.field(parsed, 'schemaVersion')) != SAFE_PREFS_VERSION
				|| readSafeInt(Reflect.field(parsed, 'generation')) != generation
				|| !Std.isOfType(Reflect.field(parsed, 'flashingWarningAcknowledged'), Bool)
				|| !validateSafePrefsPayload(parsed))
				return null;
			return {generation: generation, payload: parsed, sourcePath: path};
		}
		catch (error:Dynamic)
		{
			return null;
		}
	}

	static function applySafePrefs(candidate:SafePrefsCandidate, mainData:Dynamic):SaveVariables
	{
		var restored:SaveVariables = {};
		var savedPrefs:Dynamic = Reflect.field(candidate.payload, 'prefs');
		for (key in Reflect.fields(restored))
		{
			if (key == 'arrowRGB' || key == 'arrowRGBPixel' || key == 'gameplaySettings' || !Reflect.hasField(savedPrefs, key))
				continue;
			var coerced:Dynamic = coerceSafeValue(Reflect.field(savedPrefs, key), Reflect.field(restored, key));
			if (coerced != null)
				Reflect.setField(restored, key, coerced);
		}

		var gameplayEntries:Dynamic = Reflect.field(candidate.payload, 'gameplaySettings');
		if (Std.isOfType(gameplayEntries, Array))
			for (rawEntry in (cast gameplayEntries:Array<Dynamic>))
			{
				if (!Std.isOfType(rawEntry, Array))
					continue;
				var entry:Array<Dynamic> = cast rawEntry;
				if (entry.length != 2 || !Std.isOfType(entry[0], String))
					continue;
				var key:String = cast entry[0];
				var template:Dynamic = restored.gameplaySettings.get(key);
				if (template == null)
				{
					var customValue:Dynamic = copySafeJsonValue(entry[1]);
					if (customValue != null)
						restored.gameplaySettings.set(key, customValue);
					continue;
				}
				var value:Dynamic = coerceSafeValue(entry[1], template);
				if (value != null)
					restored.gameplaySettings.set(key, value);
			}

		applySafeKeyBinds(Reflect.field(candidate.payload, 'keyBinds'));
		var restoredMods:Map<String, Map<String, Dynamic>> = decodeSafeModsData(Reflect.field(candidate.payload, 'modsData'));
		if (restoredMods != null)
		{
			var modsComplete:Bool = cast Reflect.field(candidate.payload, 'modsDataComplete');
			var currentMods:Map<String, Map<String, Dynamic>> = !modsComplete && mainData != null
				? copyLegacyNestedMap(Reflect.field(mainData, 'modsData'))
				: null;
			modsData = currentMods != null ? mergeNestedMaps(currentMods, restoredMods) : restoredMods;
		}
		var protectedModSettings:Map<String, Map<String, Dynamic>> = decodeSafeModsData(Reflect.field(candidate.payload, 'modSettings'));
		if (mainData != null && protectedModSettings != null)
		{
			var modSettingsComplete:Bool = cast Reflect.field(candidate.payload, 'modSettingsComplete');
			var mainGeneration:Null<Int> = readCurrentMainGeneration(mainData);
			// Raw modSettings can be changed and flushed directly by mod menus. If
			// that happens after generation N was committed (including when the next
			// protected checkpoint fails), the same-generation main value is newer.
			var preferMainModSettings:Bool = mainGeneration != null && mainGeneration >= candidate.generation;
			var currentModSettings:Map<String, Map<String, Dynamic>> = (preferMainModSettings || !modSettingsComplete)
				? copyLegacyNestedMap(Reflect.field(mainData, 'modSettings'))
				: null;
			var resolvedModSettings:Map<String, Map<String, Dynamic>> = protectedModSettings;
			if (currentModSettings != null)
				// Main is authoritative in this branch, including deletions that an
				// overlay cannot represent. Older main data remains only a fallback for
				// values omitted from an intentionally bounded safe snapshot.
				resolvedModSettings = preferMainModSettings
					? currentModSettings
					: mergeNestedMaps(currentModSettings, protectedModSettings);
			Reflect.setField(mainData, 'modSettings', resolvedModSettings);
		}
		applySafeAuxiliary(Reflect.field(candidate.payload, 'auxiliary'), mainData, candidate.generation);
		if (mainData != null)
		{
			Reflect.setField(mainData, 'nfSafePrefsGeneration', candidate.generation);
			Reflect.setField(mainData, MAIN_SAFE_FORMAT_VERSION_FIELD, SAFE_PREFS_VERSION);
		}
		// Acknowledgement is monotonic. If the newest safe slot is damaged and we
		// fall back one generation, a newer/legacy main mirror that already records
		// the confirmation must not send the user through FlashingState again.
		flashingWarningAcknowledged = cast Reflect.field(candidate.payload, 'flashingWarningAcknowledged');
		if (!flashingWarningAcknowledged && mainData != null && Reflect.field(mainData, 'openedFlash') == true)
			flashingWarningAcknowledged = true;
		return restored;
	}

	static function applySafeKeyBinds(rawEntries:Dynamic):Void
	{
		if (!Std.isOfType(rawEntries, Array))
			return;
		for (rawEntry in (cast rawEntries:Array<Dynamic>))
		{
			if (!Std.isOfType(rawEntry, Array))
				continue;
			var entry:Array<Dynamic> = cast rawEntry;
			if (entry.length != 2 || !Std.isOfType(entry[0], String) || !Std.isOfType(entry[1], Array))
				continue;
			var control:String = cast entry[0];
			if (!keyBinds.exists(control))
				continue;
			var restored:Array<FlxKey> = [];
			var valid:Bool = true;
			for (rawCode in (cast entry[1]:Array<Dynamic>))
			{
				var code:Null<Int> = readSafeInt(rawCode);
				if (code == null || code < -2 || code > 302)
				{
					valid = false;
					break;
				}
				restored.push(cast code);
			}
			if (valid)
				keyBinds.set(control, restored);
		}
	}

	static function decodeSafeModsData(rawEntries:Dynamic):Map<String, Map<String, Dynamic>>
	{
		if (!Std.isOfType(rawEntries, Array))
			return null;
		var restored:Map<String, Map<String, Dynamic>> = [];
		for (rawModEntry in (cast rawEntries:Array<Dynamic>))
		{
			if (!Std.isOfType(rawModEntry, Array))
				return null;
			var modEntry:Array<Dynamic> = cast rawModEntry;
			if (modEntry.length != 2 || !Std.isOfType(modEntry[0], String) || !Std.isOfType(modEntry[1], Array))
				return null;
			var values:Map<String, Dynamic> = [];
			for (rawValueEntry in (cast modEntry[1]:Array<Dynamic>))
			{
				if (!Std.isOfType(rawValueEntry, Array))
					return null;
				var valueEntry:Array<Dynamic> = cast rawValueEntry;
				if (valueEntry.length != 2 || !Std.isOfType(valueEntry[0], String))
					return null;
				var value:Dynamic = copySafeJsonValue(valueEntry[1]);
				if (value == null)
					return null;
				values.set(cast valueEntry[0], value);
			}
			restored.set(cast modEntry[0], values);
		}
		return restored;
	}

	static function copyLegacyNestedMap(rawMap:Dynamic):Map<String, Map<String, Dynamic>>
	{
		if (rawMap == null)
			return null;
		try
		{
			var cloned:Map<String, Map<String, Dynamic>> = cast haxe.Unserializer.run(haxe.Serializer.run(rawMap));
			// Force the abstract Map cast to prove that the cloned value is map-like.
			var iterator = cloned.keys();
			if (iterator.hasNext())
				iterator.next();
			return cloned;
		}
		catch (_:Dynamic) {}
		try
		{
			var source:Map<String, Dynamic> = cast rawMap;
			var restored:Map<String, Map<String, Dynamic>> = [];
			for (groupName => rawValues in source)
			{
				var sourceValues:Map<String, Dynamic> = cast rawValues;
				if (sourceValues == null)
					continue;
				var values:Map<String, Dynamic> = [];
				for (name => rawValue in sourceValues)
				{
					var copied:Dynamic = copySafeJsonValue(rawValue);
					if (copied != null)
						values.set(name, copied);
				}
				restored.set(groupName, values);
			}
			return restored;
		}
		catch (_:Dynamic)
		{
			return null;
		}
	}

	static function mergeNestedMaps(base:Map<String, Map<String, Dynamic>>,
		overlay:Map<String, Map<String, Dynamic>>):Map<String, Map<String, Dynamic>>
	{
		if (base == null)
			base = [];
		if (overlay == null)
			return base;
		for (groupName => overlayValues in overlay)
		{
			var baseValues:Map<String, Dynamic> = base.get(groupName);
			if (baseValues == null)
			{
				baseValues = [];
				base.set(groupName, baseValues);
			}
			if (overlayValues != null)
				for (name => value in overlayValues)
					baseValues.set(name, value);
		}
		return base;
	}

	static function validateSafePrefsPayload(payload:Dynamic):Bool
	{
		var prefs:Dynamic = Reflect.field(payload, 'prefs');
		if (prefs == null || Std.isOfType(prefs, Array) || Std.isOfType(prefs, String))
			return false;
		var templates:SaveVariables = {};
		// These fields identify a real NF preference snapshot. Every other setting
		// is coerced independently by applySafePrefs(), so one stale optional value
		// must not invalidate the complete checksum-verified generation.
		for (key in ['flashing', 'framerate', 'drawFramerate', 'resolution'])
			if (!Reflect.hasField(prefs, key)
				|| coerceSafeValue(Reflect.field(prefs, key), Reflect.field(templates, key)) == null)
				return false;

		var gameplayEntries:Dynamic = Reflect.field(payload, 'gameplaySettings');
		var modsEntries:Dynamic = Reflect.field(payload, 'modsData');
		var modSettingsEntries:Dynamic = Reflect.field(payload, 'modSettings');
		var controlEntries:Dynamic = Reflect.field(payload, 'keyBinds');
		var auxiliary:Dynamic = Reflect.field(payload, 'auxiliary');
		if (!Std.isOfType(gameplayEntries, Array)
			|| !Std.isOfType(modsEntries, Array)
			|| !Std.isOfType(modSettingsEntries, Array)
			|| !Std.isOfType(controlEntries, Array)
			|| !Std.isOfType(Reflect.field(payload, 'modsDataComplete'), Bool)
			|| !Std.isOfType(Reflect.field(payload, 'modSettingsComplete'), Bool)
			|| auxiliary == null
			|| Std.isOfType(auxiliary, Array)
			|| Std.isOfType(auxiliary, String))
			return false;
		return true;
	}

	static function applySafeAuxiliary(auxiliary:Dynamic, mainData:Dynamic, candidateGeneration:Int, forceProtected:Bool = false,
		applyRuntime:Bool = true):Void
	{
		if (auxiliary == null)
			return;
		var mainGeneration:Null<Int> = readCurrentMainGeneration(mainData);
		var preferMain:Bool = !forceProtected && mainGeneration != null && mainGeneration >= candidateGeneration;
		var safeVolume:Null<Float> = readSafeFloat(Reflect.field(auxiliary, 'volume'));
		var mainVolume:Null<Float> = preferMain ? readSafeFloat(Reflect.field(mainData, 'volume')) : null;
		var volume:Null<Float> = mainVolume != null ? mainVolume : safeVolume;
		if (volume != null && volume >= 0 && volume <= 1)
		{
			if (applyRuntime && FlxG.sound != null && FlxG.sound.volume != volume)
				FlxG.sound.volume = volume;
			if (mainData != null)
				Reflect.setField(mainData, 'volume', volume);
		}
		var safeMute:Dynamic = Reflect.field(auxiliary, 'mute');
		var mainMute:Dynamic = preferMain ? Reflect.field(mainData, 'mute') : null;
		var mute:Dynamic = Std.isOfType(mainMute, Bool) ? mainMute : safeMute;
		if (Std.isOfType(mute, Bool))
		{
			if (applyRuntime && FlxG.sound != null && FlxG.sound.muted != mute)
				FlxG.sound.muted = mute;
			if (mainData != null)
				Reflect.setField(mainData, 'mute', mute);
		}
		var safeFullscreen:Dynamic = Reflect.field(auxiliary, 'fullscreen');
		var mainFullscreen:Dynamic = preferMain ? Reflect.field(mainData, 'fullscreen') : null;
		var fullscreen:Dynamic = Std.isOfType(mainFullscreen, Bool) ? mainFullscreen : safeFullscreen;
		if (Std.isOfType(fullscreen, Bool))
		{
			if (applyRuntime && FlxG.fullscreen != fullscreen)
				FlxG.fullscreen = fullscreen;
			if (mainData != null)
				Reflect.setField(mainData, 'fullscreen', fullscreen);
		}
		if (mainData == null)
			return;
		var safeMode:Null<Int> = readSafeInt(Reflect.field(auxiliary, 'mobileControlsMode'));
		var mainMode:Null<Int> = preferMain ? readSafeInt(Reflect.field(mainData, 'mobileControlsMode')) : null;
		var mode:Null<Int> = mainMode != null ? mainMode : safeMode;
		if (mode != null && mode >= 0 && mode <= 5)
			Reflect.setField(mainData, 'mobileControlsMode', mode);
		var mainButtonsValid:Bool = preferMain && copySafePointArray(Reflect.field(mainData, 'buttons')) != null;
		var buttons:Dynamic = mainButtonsValid ? Reflect.field(mainData, 'buttons') : restoreSafePointArray(Reflect.field(auxiliary, 'buttons'));
		if (buttons != null)
			Reflect.setField(mainData, 'buttons', buttons);
		var mainExtraButtonsValid:Bool = preferMain && copySafePointArray(Reflect.field(mainData, 'extraButtons')) != null;
		var extraButtons:Dynamic = mainExtraButtonsValid ? Reflect.field(mainData, 'extraButtons') : restoreSafePointArray(Reflect.field(auxiliary, 'extraButtons'));
		if (extraButtons != null)
			Reflect.setField(mainData, 'extraButtons', extraButtons);
	}

	static function restoreSafePointArray(value:Dynamic):Dynamic
	{
		if (!Std.isOfType(value, Array))
			return null;
		var points:Array<Dynamic> = [];
		for (rawPair in (cast value:Array<Dynamic>))
		{
			if (!Std.isOfType(rawPair, Array))
				return null;
			var pair:Array<Dynamic> = cast rawPair;
			if (pair.length != 2)
				return null;
			var x:Null<Float> = readSafeFloat(pair[0]);
			var y:Null<Float> = readSafeFloat(pair[1]);
			if (x == null || y == null)
				return null;
			points.push({x: x, y: y});
		}
		return points;
	}

	static function coerceSafeValue(value:Dynamic, template:Dynamic):Dynamic
	{
		if (value == null || template == null)
			return null;
		if (Std.isOfType(template, Bool))
			return Std.isOfType(value, Bool) ? value : null;
		if (Std.isOfType(template, Int))
			return readSafeInt(value);
		if (Std.isOfType(template, Float))
			return readSafeFloat(value);
		if (Std.isOfType(template, String))
			return Std.isOfType(value, String) ? value : null;
		if (Std.isOfType(template, Array) && Std.isOfType(value, Array))
		{
			var templates:Array<Dynamic> = cast template;
			var values:Array<Dynamic> = cast value;
			if (templates.length != values.length)
				return null;
			var result:Array<Dynamic> = [];
			for (i in 0...values.length)
			{
				var converted:Dynamic = coerceSafeValue(values[i], templates[i]);
				if (converted == null)
					return null;
				result.push(converted);
			}
			return result;
		}
		return null;
	}

	static function readSafeInt(value:Dynamic):Null<Int>
	{
		if (!Std.isOfType(value, Int) && !Std.isOfType(value, Float))
			return null;
		var number:Float = cast value;
		if (!isFiniteNumber(number) || number != Math.floor(number) || number < -2147483648.0 || number > 2147483647.0)
			return null;
		return Std.int(number);
	}

	static function readSafeFloat(value:Dynamic):Null<Float>
	{
		if (!Std.isOfType(value, Int) && !Std.isOfType(value, Float))
			return null;
		var number:Float = cast value;
		return isFiniteNumber(number) ? number : null;
	}

	/**
	 * A generation only makes the legacy mirror authoritative when it was
	 * written by the same protected format. Version 1 left a higher generation
	 * marker beside an all-default snapshot, so comparing that marker with a new
	 * version 2 generation would otherwise resurrect stale auxiliary/mod values.
	 */
	static function readCurrentMainGeneration(mainData:Dynamic):Null<Int>
	{
		if (mainData == null
			|| readSafeInt(Reflect.field(mainData, MAIN_SAFE_FORMAT_VERSION_FIELD)) != SAFE_PREFS_VERSION)
			return null;
		return readSafeInt(Reflect.field(mainData, 'nfSafePrefsGeneration'));
	}

	static inline function isFiniteNumber(value:Float):Bool
	{
		return !Math.isNaN(value) && value != Math.POSITIVE_INFINITY && value != Math.NEGATIVE_INFINITY;
	}

	static function safePrefsDigest(generation:Int, payload:String, formatVersion:Int = SAFE_PREFS_VERSION):String
	{
		var source:String = SAFE_PREFS_MAGIC + ':' + formatVersion + ':' + generation + ':' + payload;
		return haxe.crypto.Sha256.make(haxe.io.Bytes.ofString(source)).toHex();
	}

	static function pendingPrefsDigest(baseGeneration:Int, generation:Int, revision:Float, payload:String):String
	{
		var source:String = CONTROLS_PENDING_MAGIC + ':' + SAFE_PREFS_VERSION + ':' + baseGeneration + ':'
			+ generation + ':' + revision + ':' + payload;
		return haxe.crypto.Sha256.make(haxe.io.Bytes.ofString(source)).toHex();
	}

	static inline function utf8Length(value:String):Int
	{
		return haxe.io.Bytes.ofString(value).length;
	}

	static function getSafePrefsDirectory():String
	{
		return haxe.io.Path.join([lime.system.System.applicationStorageDirectory, 'nf-safe-prefs']);
	}

	static function getSafePrefsPath(slot:String):String
	{
		return haxe.io.Path.join([getSafePrefsDirectory(), 'prefs_' + slot + '.json']);
	}

	static function writeSafePrefsFile(targetPath:String, content:String, generation:Int):Bool
	{
		var directory:String = getSafePrefsDirectory();
		try
		{
			if (FileSystem.exists(directory))
			{
				if (!FileSystem.isDirectory(directory))
					return safePrefsFailure('Safe preference path is not a directory: $directory');
			}
			else
				FileSystem.createDirectory(directory);

			if (FileSystem.exists(targetPath) && FileSystem.isDirectory(targetPath))
				return safePrefsFailure('Safe preference slot is a directory: $targetPath');
			File.saveContent(targetPath, content);
		}
		catch (error:Dynamic)
		{
			return safePrefsFailure('Safe preference slot write failed at $targetPath: $error');
		}

		try
		{
			var readBack:String = File.getContent(targetPath);
			if (readBack != content)
				return safePrefsFailure('Safe preference slot byte verification failed at $targetPath.');
		}
		catch (error:Dynamic)
		{
			return safePrefsFailure('Safe preference slot read-back failed at $targetPath: $error');
		}

		var written:SafePrefsCandidate = readSafePrefsFile(targetPath);
		if (written == null || written.generation != generation)
			return safePrefsFailure('Safe preference semantic verification failed at $targetPath.');
		return true;
	}
	#end

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
		#if sys
		protectedSettingsReady = false;
		#else
		protectedSettingsReady = true;
		#end

		var mainData:Dynamic = FlxG.save != null ? FlxG.save.data : null;
		var loadedData:SaveVariables = {};
		if (mainData != null)
		{
			for (key in Reflect.fields(loadedData))
				if (key != 'gameplaySettings'
					&& key != 'arrowRGB'
					&& key != 'arrowRGBPixel'
					&& Reflect.hasField(mainData, key))
				{
					#if sys
					var legacyValue:Dynamic = coerceSafeValue(Reflect.field(mainData, key), Reflect.field(loadedData, key));
					if (legacyValue != null)
						Reflect.setField(loadedData, key, legacyValue);
					#else
					Reflect.setField(loadedData, key, Reflect.field(mainData, key));
					#end
				}

			if (Reflect.field(mainData, 'gameplaySettings') != null)
				try
				{
					var savedMap:Map<String, Dynamic> = cast Reflect.field(mainData, 'gameplaySettings');
					for (name => value in savedMap)
					{
						#if sys
						var template:Dynamic = loadedData.gameplaySettings.get(name);
						var legacyValue:Dynamic = template != null ? coerceSafeValue(value, template) : copySafeJsonValue(value);
						if (legacyValue != null)
							loadedData.gameplaySettings.set(name, legacyValue);
						#else
						loadedData.gameplaySettings.set(name, value);
						#end
					}
				}
				catch (error:Dynamic)
				{
					FlxG.log.warn('[ClientPrefs] Ignored invalid legacy gameplay settings: $error');
				}

			if (Reflect.field(mainData, 'modsData') != null)
			{
				#if sys
				var copiedMods:Map<String, Map<String, Dynamic>> = copyLegacyNestedMap(Reflect.field(mainData, 'modsData'));
				modsData = copiedMods != null ? copiedMods : [];
				#else
				try modsData = cast Reflect.field(mainData, 'modsData') catch (error:Dynamic) modsData = [];
				#end
			}
			else
				modsData = [];
		}
		else
			modsData = [];
		data = loadedData;

		var controlsWereSaved:Bool = false;
		var controlsSave:FlxSave = new FlxSave();
		try
		{
			if (controlsSave.bind('controls_v4', CoolUtil.getSavePath()) && controlsSave.data.keyboard != null)
			{
				var loadedControls:Map<String, Array<FlxKey>> = cast controlsSave.data.keyboard;
				var pendingControls:Map<String, Array<FlxKey>> = [];
				var recognizedControls:Int = 0;
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
						pendingControls.set(control, arr);
						recognizedControls++;
					}
				if (recognizedControls > 0)
				{
					for (control => keys in pendingControls)
						keyBinds.set(control, keys);
					controlsWereSaved = true;
				}
			}
		}
		catch (error:Dynamic)
		{
			FlxG.log.warn('[ClientPrefs] Ignored invalid controls save: $error');
		}

		var legacyAcknowledged:Bool = mainData != null
			&& (Reflect.field(mainData, 'openedFlash') == true
				|| (Reflect.hasField(mainData, 'flashing') && Std.isOfType(Reflect.field(mainData, 'flashing'), Bool)));
		var recoveredSafePrefs:Bool = false;
		var shouldBootstrapSafePrefs:Bool = false;
		var shouldReconcilePendingPrefs:Bool = false;
		#if sys
		var safeCandidate:SafePrefsCandidate = loadSafePrefs();
		var controlsPendingPrefs:PendingSafePrefsCandidate = controlsSave.isBound
			? readControlsPendingPrefs(controlsSave.data, safeCandidate)
			: null;
		var pendingKeyBinds:Map<String, Array<FlxKey>> = mainData != null
			? decodePendingKeyBinds(Reflect.field(mainData, LEGACY_PENDING_KEYBINDS))
			: null;
		var pendingLegacyPrefs:Bool = isValidPendingLegacyPrefs(mainData, safeCandidate, pendingKeyBinds);
		var mainPendingRevision:Null<Float> = pendingLegacyPrefs
			? readSafeFloat(Reflect.field(mainData, LEGACY_PENDING_REVISION))
			: null;
		var preferControlsPending:Bool = controlsPendingPrefs != null
			&& (!pendingLegacyPrefs || mainPendingRevision == null || controlsPendingPrefs.revision > mainPendingRevision);
		if (preferControlsPending)
		{
			if (controlsPendingPrefs.baseGeneration > safePrefsGeneration)
				safePrefsGeneration = controlsPendingPrefs.baseGeneration;
			trace('[ClientPrefs] Recovering independent controls-slot fallback generation '
				+ '${controlsPendingPrefs.candidate.generation}: '
				+ summarizeSafePrefsPayload(controlsPendingPrefs.candidate.payload));
			data = applySafePrefs(controlsPendingPrefs.candidate, mainData);
			protectedSettingsReady = false;
			recoveredSafePrefs = true;
			shouldReconcilePendingPrefs = !safePrefsFutureVersionFound;
		}
		else if (pendingLegacyPrefs)
		{
			// loadedData/modsData were decoded from the pending main transaction
			// before any safe candidate could mutate them. Its embedded bindings make
			// that one main flush a complete fallback transaction.
			applyPendingKeyBinds(pendingKeyBinds);
			var mainPendingBase:Null<Int> = readSafeInt(Reflect.field(mainData, LEGACY_PENDING_BASE_GENERATION));
			if (mainPendingBase != null && mainPendingBase > safePrefsGeneration)
				safePrefsGeneration = mainPendingBase;
			var safeAcknowledged:Bool = safeCandidate != null
				&& Reflect.field(safeCandidate.payload, 'flashingWarningAcknowledged') == true;
			flashingWarningAcknowledged = safeAcknowledged
				|| (mainData != null && Reflect.field(mainData, 'openedFlash') == true);
			protectedSettingsReady = false;
			shouldReconcilePendingPrefs = !safePrefsFutureVersionFound;
			trace('[ClientPrefs] Recovering a newer legacy fallback; protected settings will be recommitted after startup normalization.');
			FlxG.log.warn('[ClientPrefs] Recovering a newer legacy fallback; protected settings will be recommitted after startup normalization.');
		}
		else if (safeCandidate != null)
		{
			trace('[ClientPrefs] Loading protected settings generation ${safeCandidate.generation} from ${safeCandidate.sourcePath}: '
				+ summarizeSafePrefsPayload(safeCandidate.payload));
			data = applySafePrefs(safeCandidate, mainData);
			protectedSettingsReady = true;
			recoveredSafePrefs = true;
			FlxG.log.add('[ClientPrefs] Loaded verified settings snapshot generation ${safeCandidate.generation}.');
		}
		else
		{
			flashingWarningAcknowledged = legacyAcknowledged || controlsWereSaved;
			shouldBootstrapSafePrefs = flashingWarningAcknowledged && !safePrefsFutureVersionFound;
		}
		#else
		flashingWarningAcknowledged = legacyAcknowledged || controlsWereSaved;
		#end

		if (flashingWarningAcknowledged && mainData != null)
			Reflect.setField(mainData, 'openedFlash', true);

		loadArrowRGBData('arrowRGB.json', false, ExtraKeysHandler.instance.data.colors);
		loadArrowRGBData('arrowRGBPixel.json', true, ExtraKeysHandler.instance.data.pixelNoteColors);
		reloadVolumeKeys();

		if (Main.fpsVar != null)
			Main.fpsVar.visible = data.showFPS;

		#if (!html5 && !switch)
		FlxG.autoPause = data.autoPause;

		if (!recoveredSafePrefs && (mainData == null || Reflect.field(mainData, 'framerate') == null))
		{
			final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate * 2;
			data.framerate = Std.int(FlxMath.bound(refreshRate, 60, 1000));
		}

		if (!recoveredSafePrefs && (mainData == null || Reflect.field(mainData, 'drawFramerate') == null))
		{
			final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
			data.drawFramerate = Std.int(FlxMath.bound(refreshRate, 60, 1000));
		}
		#end

		var useRenderThread:Bool = data.renderThread;
		#if sys
		// Keep the saved preference as the default, while allowing repeatable
		// render-path A/B tests without rewriting the user's save file.
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

		var output:Array<Float> = [];
		switch(data.resolution) {
			case '360P':
				output = [640, 360];
			case '480P':
				output = [854, 480];
			case '540P':
				output = [960, 540];
			case '720P':
				output = [1280, 720];
			case '768P':
				output = [1366, 768];
			case '900P':
				output = [1600, 900];
			case '1080P':
				output = [1920, 1080];
			case '1440P (2K)':
				output = [2560, 1440];
			case '1600P':	
				output = [2560, 1600];
			case '1800P':
				output = [3200, 1800];
			case '2160P (4K)':	
				output = [3840, 2160];
			default:
				var display:Display = lime.system.System.getDisplay(0);
				output = [display.bounds.width, display.bounds.height];
				data.resolution = "Native: " + display.bounds.width + "x" + display.bounds.height;
		}
		openfl.Lib.current.stage.setLogicalSize(Std.int(output[0]), Std.int(output[1]));

		// flixel automatically saves your volume!
		if (mainData != null && Reflect.field(mainData, 'volume') != null)
			FlxG.sound.volume = Reflect.field(mainData, 'volume');
		if (mainData != null && Reflect.field(mainData, 'mute') != null)
			FlxG.sound.muted = Reflect.field(mainData, 'mute');

		#if sys
		// Bootstrap only after legacy defaults (notably refresh-rate fallbacks and
		// sound state) have been fully applied. Highscore.load() runs afterwards,
		// so this protected snapshot still exists before the large legacy rewrite.
		if (shouldReconcilePendingPrefs)
		{
			if (saveSafePrefs(true))
			{
				if (controlsSave.isBound)
					try
					{
						clearControlsPendingPrefs(controlsSave.data);
						if (!controlsSave.flush())
							FlxG.log.warn('[ClientPrefs] Recovered settings were protected, but the stale controls fallback could not be cleared.');
					}
					catch (error:Dynamic)
					{
						FlxG.log.warn('[ClientPrefs] Recovered settings were protected, but clearing the stale controls fallback threw: $error');
					}
				// The verified generation is already authoritative. Clearing the old
				// marker is best effort: if this main flush is interrupted, its base
				// generation is older than the new safe generation and will be ignored.
				if (mainData != null)
					try
					{
						clearLegacyPendingPrefs(mainData);
						if (!FlxG.save.flush())
							FlxG.log.warn('[ClientPrefs] Recovered settings were protected, but the stale legacy marker could not be cleared.');
					}
					catch (error:Dynamic)
					{
						FlxG.log.warn('[ClientPrefs] Recovered settings were protected, but clearing the stale legacy marker threw: $error');
					}
			}
			else
				FlxG.log.error('[ClientPrefs] Could not reconcile the pending legacy fallback into a protected snapshot.');
		}
		else if (shouldBootstrapSafePrefs && !saveSettings(false, true))
			FlxG.log.error('[ClientPrefs] Could not bootstrap a safe snapshot from legacy settings.');
		registerProtectedCheckpointSignals();
		#end

		#if DISCORD_ALLOWED
		DiscordClient.check();
		#end
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic
	{
		if (!customDefaultValue)
			defaultValue = defaultData.gameplaySettings.get(name);
		return /*PlayState.isStoryMode ? defaultValue : */ (data.gameplaySettings.exists(name) ? data.gameplaySettings.get(name) : defaultValue);
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
			{
				if (modsData.get(mod).get(variable) != null)
					return modsData.get(mod).get(variable);
			}
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
				try{ Reflect.setProperty(ClientPrefs.data, variable, data); }
			case _:
				if (modsData.get(path) == null)
						modsData.set(path, []);
				modsData.get(path).set(variable, data);
		}
	}
}

