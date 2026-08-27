package substates;

import games.backend.WeekData;
import games.backend.Highscore;
import games.backend.Song;

import flixel.util.FlxStringUtil;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

import states.storyMenuState.StoryMenuState;
import states.freeplayState.FreeplayState;
import options.OptionsState;

class LegacyPauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = [];
	var menuItemsOG:Array<String> = ['Resume', 'Restart Song','Change Difficulty', 'Options', 'Exit to menu'];
	var difficultyChoices = [];
	var curSelected:Int = 0;

	public var pauseMusic:FlxSound;
	var practiceText:FlxText;
	var skipTimeText:FlxText;
	var skipTimeTracker:Alphabet;
	var curTime:Float = Math.max(0, Conductor.songPosition);

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	var font:String;

	public static var songName:String = null;
	
	var mouseOverItem:Int = -1;
	var lastMousePos:FlxPoint;
	var allowMouse:Bool = true;
	
	private var clickHitboxOffsetX:Float = 0;
	private var clickHitboxOffsetY:Float = 0;

	override function create()
	{
		font = Paths.font(Language.get('fontName', 'main') + '.ttf');
		if(Difficulty.list.length < 2) menuItemsOG.remove('Change Difficulty');
		if(PlayState.chartingMode)
		{
			menuItemsOG.insert(2, 'Leave Charting Mode');
			var num:Int = 0;
			if(!PlayState.instance.startingSong)
			{
				num = 1;
				menuItemsOG.insert(3, 'Skip Time');
			}
			menuItemsOG.insert(3 + num, 'End Song');
			menuItemsOG.insert(4 + num, 'Toggle Practice Mode');
			menuItemsOG.insert(5 + num, 'Toggle Botplay');
		} else if(PlayState.instance.practiceMode && !PlayState.instance.startingSong)
			menuItemsOG.insert(3, 'Skip Time');
		menuItems = menuItemsOG;

		for (i in 0...Difficulty.list.length) {
			var diff:String = Difficulty.getString(i);
			difficultyChoices.push(diff);
		}
		difficultyChoices.push('BACK');

		pauseMusic = new FlxSound();
		try
		{
			var pauseSong:String = getPauseSong();
			if(pauseSong != null) pauseMusic.loadEmbedded(Paths.music(pauseSong), true, true);
		}
		catch(e:Dynamic) {}
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		if(ClientPrefs.data.coolBackdrop)
		{
			var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33FFFFFF, 0x0));
			grid.velocity.set(40, 40);
			grid.alpha = 0;
			FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
			add(grid);
		}

		var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var levelInfo:FlxText = new FlxText(20, 15, 0, PlayState.SONG.song, 32);
		levelInfo.antialiasing = ClientPrefs.data.antialiasing;
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(font, 32);
		levelInfo.updateHitbox();
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, Difficulty.getString().toUpperCase(), 32);
		levelDifficulty.antialiasing = ClientPrefs.data.antialiasing;
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(font, 32);
		levelDifficulty.updateHitbox();
		add(levelDifficulty);

		// 改为与 PauseSubState 一致：用 'blueballed' 键
		var blueballedTxt:FlxText = new FlxText(20, 15 + 64, 0, Language.get('blueballed', 'pause') + ': ' + PlayState.deathCounter, 32);
		blueballedTxt.antialiasing = ClientPrefs.data.antialiasing;
		blueballedTxt.scrollFactor.set();
		blueballedTxt.setFormat(font, 32);
		blueballedTxt.updateHitbox();
		add(blueballedTxt);

		// 改为用 'practice_mode' 键
		practiceText = new FlxText(20, 15 + 101, 0, Language.get('practice_mode', 'pause').toUpperCase(), 32);
		practiceText.antialiasing = ClientPrefs.data.antialiasing;
		practiceText.scrollFactor.set();
		practiceText.setFormat(font, 32);
		practiceText.x = FlxG.width - (practiceText.width + 20);
		practiceText.updateHitbox();
		practiceText.visible = PlayState.instance.practiceMode;
		add(practiceText);

		// 改为用 'charting_mode' 键
		var chartingText:FlxText = new FlxText(20, 15 + 101, 0, Language.get('charting_mode', 'pause').toUpperCase(), 32);
		chartingText.antialiasing = ClientPrefs.data.antialiasing;
		chartingText.scrollFactor.set();
		chartingText.setFormat(font, 32);
		chartingText.x = FlxG.width - (chartingText.width + 20);
		chartingText.y = FlxG.height - (chartingText.height + 20);
		chartingText.updateHitbox();
		chartingText.visible = PlayState.chartingMode;
		add(chartingText);

		blueballedTxt.alpha = 0;
		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
		blueballedTxt.x = FlxG.width - (blueballedTxt.width + 20);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
		FlxTween.tween(blueballedTxt, {alpha: 1, y: blueballedTxt.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		missingTextBG = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		missingTextBG.scale.set(FlxG.width, FlxG.height);
		missingTextBG.updateHitbox();
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.antialiasing = ClientPrefs.data.antialiasing;
		missingText.setFormat(font, 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		regenMenu();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		
		FlxG.mouse.visible = true;
		lastMousePos = FlxPoint.get();

		super.create();
	}
	
	function getPauseSong()
	{
		var formattedSongName:String = (songName != null ? Paths.formatToSongPath(songName) : '');
		var formattedPauseMusic:String = Paths.formatToSongPath(ClientPrefs.data.pauseMusic);
		if(formattedSongName == 'none' || (formattedSongName != 'none' && formattedPauseMusic == 'none')) return null;

		return (formattedSongName != '') ? formattedSongName : formattedPauseMusic;
	}

	var holdTime:Float = 0;
	var cantUnpause:Float = 0.1;
	
	override function update(elapsed:Float)
	{
		cantUnpause -= elapsed;
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		if (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0)
		{
			allowMouse = true;
			updateMouseOver();
		}
		
		if (FlxG.mouse.justPressedRight)
		{
			close();
			return;
		}
		
		if (allowMouse && FlxG.mouse.wheel != 0)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
			changeSelection(-Std.int(FlxG.mouse.wheel));
		}
		
		if (allowMouse && FlxG.mouse.justPressed)
		{
			handleMouseClick();
		}
		
		if (allowMouse && menuItems[curSelected] == 'Skip Time' && skipTimeTracker != null)
		{
			var originalX:Float = skipTimeTracker.x;
			var originalY:Float = skipTimeTracker.y;
			skipTimeTracker.x += clickHitboxOffsetX;
			skipTimeTracker.y += clickHitboxOffsetY;
			var overlaps:Bool = FlxG.mouse.overlaps(skipTimeTracker, cameras[0]);
			skipTimeTracker.x = originalX;
			skipTimeTracker.y = originalY;
			
			if (overlaps)
			{
				if (FlxG.mouse.pressed)
				{
					var dragSpeed:Float = (FlxG.mouse.deltaScreenX + FlxG.mouse.deltaScreenY) * 10;
					if (Math.abs(dragSpeed) > 0.5)
					{
						curTime += dragSpeed * 100;
						if(curTime >= FlxG.sound.music.length) curTime = 0;
						else if(curTime < 0) curTime = FlxG.sound.music.length - 1000;
						updateSkipTimeText();
					}
				}
				
				if (FlxG.mouse.wheel != 0)
				{
					curTime += FlxG.mouse.wheel * 1000;
					if(curTime >= FlxG.sound.music.length) curTime = 0;
					else if(curTime < 0) curTime = FlxG.sound.music.length - 1000;
					updateSkipTimeText();
				}
			}
		}

		super.update(elapsed);

		if(controls.BACK)
		{
			close();
			return;
		}

		if(FlxG.keys.justPressed.F5)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.resetState();
		}

		updateSkipTextStuff();
		
		if (controls.UI_UP_P)
		{
			changeSelection(-1);
			updateItemAlpha();
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
			updateItemAlpha();
		}

		var daSelected:String = menuItems[curSelected];
		switch (daSelected)
		{
			case 'Skip Time':
				if (controls.UI_LEFT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime -= 1000;
					holdTime = 0;
				}
				if (controls.UI_RIGHT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime += 1000;
					holdTime = 0;
				}

				if(controls.UI_LEFT || controls.UI_RIGHT)
				{
					holdTime += elapsed;
					if(holdTime > 0.5)
					{
						curTime += 45000 * elapsed * (controls.UI_LEFT ? -1 : 1);
					}

					if(curTime >= FlxG.sound.music.length) curTime -= FlxG.sound.music.length;
					else if(curTime < 0) curTime += FlxG.sound.music.length;
					updateSkipTimeText();
				}
		}

		if (controls.ACCEPT && (cantUnpause <= 0 || !controls.controllerMode))
		{
			selectCurrentOption();
		}
	}
	
	function updateMouseOver()
	{	
		var newMouseOver:Int = -1;
		for (i in 0...grpMenuShit.members.length)
		{
			var item = grpMenuShit.members[i];
			if (item != null && item.visible)
			{
				var originalX:Float = item.x;
				var originalY:Float = item.y;
				item.x += clickHitboxOffsetX;
				item.y += clickHitboxOffsetY;
				var overlaps:Bool = FlxG.mouse.overlaps(item, cameras[0]);
				item.x = originalX;
				item.y = originalY;
				
				if (overlaps)
				{
					newMouseOver = i;
					break;
				}
			}
		}
		
		if (newMouseOver != mouseOverItem)
		{
			mouseOverItem = newMouseOver;
			updateItemAlpha();
		}
	}
	
	function handleMouseClick()
	{
		if (mouseOverItem == -1) return;
		
		if (mouseOverItem != curSelected)
		{
			changeSelection(mouseOverItem - curSelected);
		}
		else
		{
			selectCurrentOption();
		}
	}
	
	function updateItemAlpha()
	{
		for (num => item in grpMenuShit.members)
		{
			if (item == null) continue;
			
			item.alpha = 0.6;
			item.color = FlxColor.WHITE;
			
			if (num == curSelected)
			{
				item.alpha = 1.0;
			}
			else if (allowMouse && num == mouseOverItem)
			{
				item.alpha = 0.9;
				item.color = 0xFFFFFF00;
			}
		}
	}

	function selectCurrentOption()
	{
		var daSelected:String = menuItems[curSelected];
		
		if (menuItems == difficultyChoices)
		{
			var songLowercase:String = Paths.formatToSongPath(PlayState.SONG.song);
			var poop:String = Highscore.formatSong(songLowercase, curSelected);
			try
			{
				if(menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected))
				{
					Song.loadFromJson(poop, songLowercase);
					PlayState.storyDifficulty = curSelected;
					MusicBeatState.resetState();
					FlxG.sound.music.volume = 0;
					PlayState.changedDifficulty = true;
					PlayState.chartingMode = false;
					return;
				}
			}
			catch(e:haxe.Exception)
			{
				trace('ERROR! ${e.message}');

				var errorStr:String = e.message;
				if(errorStr.startsWith('[lime.utils.Assets] ERROR:')) errorStr = 'Missing file: ' + errorStr.substring(errorStr.indexOf(songLowercase), errorStr.length-1);
				else errorStr += '\n\n' + e.stack;

				missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
				missingText.screenCenter(Y);
				missingText.visible = true;
				missingTextBG.visible = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));

				return;
			}

			menuItems = menuItemsOG;
			regenMenu();
			return;
		}

		switch (daSelected)
		{
			case "Resume":
				FlxG.mouse.visible = false;
				close();
			case 'Change Difficulty':
				menuItems = difficultyChoices;
				deleteSkipTimeText();
				regenMenu();
			case 'Toggle Practice Mode':
				PlayState.instance.practiceMode = !PlayState.instance.practiceMode;
				PlayState.changedDifficulty = true;
				practiceText.visible = PlayState.instance.practiceMode;
			case "Restart Song":
				restartSong();
			case "Leave Charting Mode":
				restartSong();
				PlayState.chartingMode = false;
			case 'Skip Time':
				if(curTime < Conductor.songPosition)
				{
					PlayState.startOnTime = curTime;
					restartSong(true);
				}
				else
				{
					if (curTime != Conductor.songPosition)
					{
						PlayState.instance.clearNotesBefore(curTime);
						PlayState.instance.setSongTime(curTime);
					}
					close();
				}
			case 'End Song':
				close();
				PlayState.instance.notes.clear();
				PlayState.instance.unspawnNotes = [];
				PlayState.instance.finishSong(true);
			case 'Toggle Botplay':
				PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
				PlayState.changedDifficulty = true;
				PlayState.instance.botplayTxt.visible = PlayState.instance.cpuControlled;
				PlayState.instance.botplayTxt.alpha = 1;
			case 'Options':
				OptionsState.stateType = 2;
				PlayState.instance.paused = true;
				PlayState.instance.vocals.volume = 0;
				MusicBeatState.switchState(new OptionsState());
				if(ClientPrefs.data.pauseMusic != 'None')
				{
					if (songName != null && Paths.formatToSongPath(songName) != 'none')
						FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(songName)), pauseMusic.volume);
					else
					FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)), pauseMusic.volume);
					FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.8);
					FlxG.sound.music.time = pauseMusic.time;
				}
			case "Exit to menu":
				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
				PlayState.deathCounter = 0;
				PlayState.seenCutscene = false;
				
				Mods.loadTopMod();
				if(PlayState.isStoryMode)
					MusicBeatState.switchState(new StoryMenuState());
				else MusicBeatState.switchState(new FreeplayState());

				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				PlayState.changedDifficulty = false;
				PlayState.chartingMode = false;
				FlxG.camera.followLerp = 0;
		}
	}

	function deleteSkipTimeText()
	{
		if(skipTimeText != null)
		{
			skipTimeText.kill();
			remove(skipTimeText);
			skipTimeText.destroy();
		}
		skipTimeText = null;
		skipTimeTracker = null;
	}

	public static function restartSong(noTrans:Bool = false)
	{
		PlayState.instance.paused = true;
		FlxG.sound.music.volume = 0;
		PlayState.instance.vocals.volume = 0;

		if(noTrans)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
		}
		MusicBeatState.resetState();
	}

	override function destroy()
	{
		pauseMusic.destroy();
		if (lastMousePos != null) lastMousePos.put();
		FlxG.mouse.visible = true;
		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, menuItems.length - 1);
		
		for (num => item in grpMenuShit.members)
		{
			item.targetY = num - curSelected;
		}
		
		updateItemAlpha();
		
		if (grpMenuShit.members[curSelected] == skipTimeTracker)
		{
			curTime = Math.max(0, Conductor.songPosition);
			updateSkipTimeText();
		}
		
		missingText.visible = false;
		missingTextBG.visible = false;
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	// ===== 重点修改：regenMenu =====
	function regenMenu():Void {
		for (i in 0...grpMenuShit.members.length)
		{
			var obj:Alphabet = grpMenuShit.members[0];
			obj.kill();
			grpMenuShit.remove(obj, true);
			obj.destroy();
		}

		for (num => str in menuItems) {
			// 将菜单项转为小写作为语言键
			var key = str.toLowerCase();
			var item = new Alphabet(90, 320, str, true);
			item.isMenuItem = true;
			item.targetY = num;
			grpMenuShit.add(item);

			if(str == 'Skip Time')
			{
				skipTimeText = new FlxText(0, 0, 0, '', 64);
				skipTimeText.antialiasing = ClientPrefs.data.antialiasing;
				skipTimeText.setFormat(font, 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				skipTimeText.scrollFactor.set();
				skipTimeText.borderSize = 2;
				skipTimeTracker = item;
				add(skipTimeText);

				updateSkipTextStuff();
				updateSkipTimeText();
			}
		}
		curSelected = 0;
		changeSelection();
	}
	
	function updateSkipTextStuff()
	{
		if(skipTimeText == null || skipTimeTracker == null) return;

		skipTimeText.x = skipTimeTracker.x + skipTimeTracker.width + 60;
		skipTimeText.y = skipTimeTracker.y;
		skipTimeText.visible = (skipTimeTracker.alpha >= 1);
	}

	function updateSkipTimeText()
	{
		if(skipTimeText != null)
			skipTimeText.text = FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false) + ' / ' + FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false);
	}
}