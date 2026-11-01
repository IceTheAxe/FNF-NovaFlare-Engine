package substates;
#if RELAX_ALLOWED

import sys.thread.Thread;

import openfl.filters.BlurFilter;
import openfl.display.Shape;
import openfl.media.Sound;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFilterFrames;
import flixel.FlxBasic;
import flixel.util.FlxSpriteUtil;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.system.FlxAssets.FlxGraphicAsset;

import general.backend.relax.GetInit;
import general.backend.relax.GetInit.SongLists;
import general.backend.relax.GetInit.SongInfo;

import general.objects.AudioCircleDisplay;
import general.objects.state.relaxState.*;
import general.objects.state.relaxState.windows.PlayListWindow;
import general.objects.state.relaxState.windows.RelaxOptionPanel;
import general.objects.state.relaxState.backend.*;

/*
    这一大坨屎山代码出自MaoPou https://github.com/MaoPou
*/

class RelaxSubState extends MusicBeatSubstate
{
    public static var instance:RelaxSubState;
    
	public var SongsArray:SongLists = {
		name: "Unknown",
		list: []
	};
	public var currentSongIndex:Int = 0;
	private var pendingSongIndex:Int = -1;
	
	public var nowChoose:Array<Int> = [0,0];

	var camBack:FlxCamera;
	var camHollow:FlxCamera;
	var camMidd:FlxCamera;
	var camPic:FlxCamera;
	var camText:FlxCamera;
	var camHUD:FlxCamera;
	public var camOption:FlxCamera;
	var camVpad:FlxCamera;

	private var currentBPM:Float = 100;
	private var beatTime:Float = 0.6;
	private var beatTimer:Float = 0;
	private var defaultZoom:Float = 1.0;
	private var zoomIntensity:Float = 0.05;
	
	var maskRadius:Float = 150;
	var circleMask:Shape;
	
	var triangleEmitter:HollowTriangleEmitter;
	
	var backendPicture:FlxSprite;
	public var audio:AudioCircleDisplay;
	public var strAudio:AudioDisplay;
	var recordPicture:FlxSprite;
	/** 当前歌曲的唱片图 key，切主题时用于补建 */
	var currentRecordImage:FlxGraphicAsset;
	
	var oldBackendPicture:FlxSprite;
	var oldRecordPicture:FlxSprite;
	var oldAudio:FlxBasic;

	var transitionTime:Float = 0.5;
	var isTransitioning:Bool = false;
	
	public var controlButtons:ControlButtons;
	public var topButtons:TopButtons;
	public var backButtons:BackButtons;
	public var songInfoDisplay:SongInfoDisplay;
	
	public var LyricsMap:Map<Int, String> = new Map();
	public var songLyrics:FlxText;
	
	public var playListWindow:PlayListWindow;
	
	var Sound1:FlxSound = new FlxSound();
	var Sound2:FlxSound = new FlxSound();
	
	public var songProgress:SongProgress;
	
	//options var
	//public var enableBpmZoom:Bool = true; //启用唱片根据bpm zoom
	//public var RelaxAudioSymmetry:Bool = true; //启用可视化中间对称
	//public var RelaxAudioNumber:Int = 5; //解析器的数量
	//public var RelaxAudioDisplayQuality:Int = 5; //解析器质量（仅用于RelaxState)
	//public var NextSongs:String = "Next"; //播放下一个歌曲的方式 ["Next", "Restart", "Random"]
	
	public function new()
	{
		super();
		camBack = new FlxCamera();
		camHollow = new FlxCamera();
		camMidd = new FlxCamera();
		camPic = new FlxCamera();
		camText = new FlxCamera();
		camHUD = new FlxCamera();
		camVpad = new FlxCamera();

		camHUD.bgColor.alpha = 0;
		camPic.bgColor.alpha = 0;
		camText.bgColor.alpha = 0;
		camBack.bgColor.alpha = 0;
		camHollow.bgColor.alpha = 0;
		camMidd.bgColor.alpha = 0;
		camVpad.bgColor.alpha = 0;

		camOption = new FlxCamera();
		camOption.bgColor.alpha = 0;
		camOption.y = 0;

		FlxG.cameras.add(camBack, false);
		FlxG.cameras.add(camHollow, false);
		FlxG.cameras.add(camMidd, false);
		FlxG.cameras.add(camPic, false);
		FlxG.cameras.add(camText, false);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOption, false);
		FlxG.cameras.add(camVpad, false);
		
        FlxG.state.persistentUpdate = false;
		FlxG.sound.music.stop();
	}
	
	/** 图片实际由 Paths.image 从 assets/shared/images/ 读取，这里同步兼容 assets/shared/ 直放；歌单内文件走本地直读 */
	private function imageExists(key:String):Bool {
		if (GetInit.isPlaylistPath(key)) return FileSystem.exists(key);
		return FileSystem.exists('assets/shared/images/$key.png') || FileSystem.exists('assets/shared/$key.png');
	}

	/** 封面/唱片：歌单内文件直读本地，资源键走 Paths.image */
	private function resolveGraphic(asset:FlxGraphicAsset):FlxGraphic {
		if (asset == null) return null;
		if (Std.isOfType(asset, String)) return GetInit.resolveImage(asset);
		return FlxG.bitmap.add(asset);
	}

	public function inspectFile(NowInfo:SongInfo):Array<Dynamic>{
	    var result:Array<Dynamic> = [];
	    var error:String = " ";
	    if (NowInfo.sound != null && NowInfo.sound.length > 0){
	        for (i in NowInfo.sound){
	            if (GetInit.isPlaylistPath(i)){ // 歌单内文件按完整路径直读
	                if (!FileSystem.exists(i))
	                    error += "can't find '" + i + "'\n";
	            }
	            else if (!FileSystem.exists('assets/shared/$i')){  //以防万一如果有一个歌曲不存在就终止加载
	                error += "can't find '" + 'assets/shared/$i' + "'\n";
	            }
	        }
	    }
	    
    if (NowInfo.background != null && NowInfo.background.length > 0){
        for (i in NowInfo.background){
            if (!imageExists(i)){  //以防万一如果有一个背景不存在就终止加载
                error += "can't find '" + i + ".png'\n";
            }
        }
    }
    
    if (NowInfo.record != null && NowInfo.record.length > 0){
        for (i in NowInfo.record){
            if (!imageExists(i)){  //以防万一如果有一个曲绘唱片不存在就终止加载
                error += "can't find '" + i + ".png'\n";
            }
        }
    }
	    
	    result = [true, ""];
	    if (error != " ") result = [false, error];
	    
	    return result;
	}

	/**
	 *	@param	songInfo	歌曲信息
	**/
	public function loadSongs(songInfo:SongInfo = null):Void {
		if (isTransitioning || songInfo == null) return;
		var res:Array<Dynamic> = inspectFile(songInfo);
		if (!res[0]){
		    trace(res[1]);
		    return;
		}
		
		isTransitioning = true;
		Sound1.destroy();
		Sound2.destroy();

		if (songInfo.sound != null && songInfo.sound.length > 0) {
            if (songInfo.sound.length > 1) {
                Sound1.loadEmbedded(GetInit.resolveSound(songInfo.sound[1]), false, true);
                Sound1.play();
            }
            
            if (songInfo.sound.length > 2) {
                Sound2.loadEmbedded(GetInit.resolveSound(songInfo.sound[2]), false, true);
                Sound2.play();
            }
        }
        
        LyricsMap = null;
        songLyrics.text = '';
        var lyricsData:Array<Dynamic> = GetInit.getSongLyrics(songInfo);
        if (lyricsData != null && lyricsData.length > 0)
            LyricsMap = lyricsData[0];
        if (lyricsData != null && lyricsData.length > 1 && lyricsData[1] != null)
            songLyrics.font = lyricsData[1];
        rebuildLyricTimes();
		
		FlxG.sound.music.stop();
		if (songInfo.sound != null && songInfo.sound.length > 0) {
			FlxG.sound.playMusic(GetInit.resolveSound(songInfo.sound[0]), 1);
			
			FlxG.sound.music.onComplete = () -> {
			    switch(ClientPrefs.data.NextSongs){
			        case 'Next':
			            nextSong();
			        case 'Restart':
			            FlxG.sound.resume();
			        case 'Random':
			            var randomNum:Int = FlxG.random.int(0, SongsArray.list.length - 1);
			            loadSongs(SongsArray.list[randomNum]);
			            currentSongIndex = randomNum;
			    }
			};
			
			if (songInfoDisplay.songLengthText != null) {
				songInfoDisplay.songLengthText.text = "0:00 / 0:00";
				songInfoDisplay.songLengthText.screenCenter(X);
			}
		}
		
		if (backendPicture != null) {
			oldBackendPicture = backendPicture;
			backendPicture = null;
		}
		
		if (recordPicture != null) {
			oldRecordPicture = recordPicture;
			recordPicture = null;
		}
		
		if (audio != null) {
			oldAudio = audio;
			audio = null;
		}
		if (strAudio != null) {
			oldAudio = strAudio;
			strAudio = null;
		}
		
		var backgroundImage:FlxGraphicAsset = (songInfo.background != null && songInfo.background.length > 0) ? songInfo.background[0] : null;
		var recordImage:FlxGraphicAsset = (songInfo.record != null && songInfo.record.length > 0) ? songInfo.record[0] : null;
		
		createNewElements(backgroundImage, recordImage);
		
		updateSongInfoDisplay(songInfo);
		
		var allComplete:Bool = false;
		var newElementsComplete:Bool = false;
		var oldElementsComplete:Bool = false;
		
		function checkAllComplete() {
			if (newElementsComplete && oldElementsComplete && !allComplete) {
				allComplete = true;
				isTransitioning = false;
				
				if (pendingSongIndex != -1) {
					var indexToLoad = pendingSongIndex;
					pendingSongIndex = -1;
					
					new FlxTimer().start(0.1, function(_) {
						if (indexToLoad >= 0 && indexToLoad < SongsArray.list.length) {
							currentSongIndex = indexToLoad;
							loadSongs(SongsArray.list[currentSongIndex]);
						}
					});
				}
			}
		}
		
		fadeInNewElements(() -> {
			newElementsComplete = true;
			checkAllComplete();
		});
		
		fadeOutOldElements(() -> {
			oldElementsComplete = true;
			checkAllComplete();
		});
	}

	private function fadeOutOldElements(onComplete:Void->Void):Void {
		var tweenCount = 0;
		var totalTweens = 0;
		
		if (oldBackendPicture != null) totalTweens++;
		if (oldRecordPicture != null) totalTweens++;
		if (oldAudio != null) totalTweens++;
		
		if (totalTweens == 0) {
			onComplete();
			return;
		}
		
		function checkComplete() {
			tweenCount++;
			if (tweenCount >= totalTweens) {
				onComplete();
			}
		}
		
		if (oldBackendPicture != null) {
			FlxTween.tween(oldBackendPicture, {alpha: 0}, transitionTime, {
				ease: FlxEase.quadIn,
				onComplete: function(twn:FlxTween) {
					remove(oldBackendPicture);
					oldBackendPicture.destroy();
					oldBackendPicture.kill();
					oldBackendPicture = null;
					checkComplete();
				}
			});
		}
		
		if (oldRecordPicture != null) {
			FlxTween.tween(oldRecordPicture, {alpha: 0, angle: 180}, transitionTime, {
				ease: FlxEase.quadIn,
				onComplete: function(twn:FlxTween) {
					remove(oldRecordPicture);
					oldRecordPicture.destroy();
					oldRecordPicture.kill();
					oldRecordPicture = null;
					checkComplete();
				}
			});
		}
		
		if (oldAudio != null) {
			FlxTween.tween(oldAudio, {alpha: 0}, transitionTime, {
				ease: FlxEase.quadIn,
				onComplete: function(twn:FlxTween) {
					remove(oldAudio);
					oldAudio.destroy();
					oldAudio = null;
					checkComplete();
				}
			});
		}
	}
	
	private function createNewElements(background:FlxGraphicAsset, recordImage:FlxGraphicAsset):Void {
		if (background != null) {
			var bgGraphic = resolveGraphic(background);
			if (bgGraphic != null) {
				backendPicture = new FlxSprite().loadGraphic(bgGraphic);
				backendPicture.antialiasing = ClientPrefs.data.antialiasing;
				backendPicture.scale.set(1.1,1.1);
				backendPicture.updateHitbox();
				backendPicture.screenCenter();
				backendPicture.cameras = [camBack];
				backendPicture.alpha = 0;
				add(backendPicture);
			}
		}
		
		var isCircle:Bool = (ClientPrefs.data.theme == 'Circle');
		
		createSpectrum();
		
		var actualRecordImage:FlxGraphicAsset = recordImage;
		if (actualRecordImage == null && background != null) {
			actualRecordImage = background;
		}
		currentRecordImage = actualRecordImage;
		
		// 唱片只在环形主题下有意义（直条主题下唱片会铺满全屏）
		if (isCircle && actualRecordImage != null) {
			createRecordSprite(actualRecordImage);
		}
	}
	
	private function createRecordSprite(image:FlxGraphicAsset):Void {
		if (image == null || recordPicture != null) return;
		var recordGraphic = resolveGraphic(image);
		if (recordGraphic == null) return;
		recordPicture = new FlxSprite().loadGraphic(recordGraphic);
		recordPicture.antialiasing = ClientPrefs.data.antialiasing;
		updatePictureScale();
		recordPicture.cameras = [camPic];
		recordPicture.alpha = 0;
		add(recordPicture);
	}
	
	/**
	 * 按当前 theme 创建频谱可视化（环形 / 直条）。主流程和选项面板共用这一份。
	 */
	private function createSpectrum():Void {
		var lineCount:Int = Std.int(120 / Std.int(Math.max(1, ClientPrefs.data.RelaxAudioNumber)));
		var theme:String = ClientPrefs.data.theme;
		
		// theme 有三档：Circle / Straight / None（None = 只要背景和唱片，不要频谱）
		if (theme == 'Circle')
			audio = new AudioCircleDisplay(FlxG.sound.music, FlxG.width / 2, FlxG.height / 2, 500, 100, lineCount, 4, FlxColor.WHITE, 150,
				ClientPrefs.data.RelaxAudioSymmetry, ClientPrefs.data.RelaxAudioNumber);
		else if (theme == 'Straight')
			strAudio = new AudioDisplay(FlxG.sound.music, 50, FlxG.height - 50, 200, 100, lineCount, 4, FlxColor.WHITE,
				ClientPrefs.data.RelaxAudioSymmetry);
		
		if (strAudio != null) {
			strAudio.alpha = 0;
			strAudio.inRelax = true;
			strAudio.cameras = [camMidd];
			add(strAudio);
		}
		else if (audio != null) {
			audio.alpha = 0;
			audio.inRelax = true;
			audio.cameras = [camMidd];
			add(audio);
		}
	}
	
	private function destroySpectrum():Void {
		if (audio != null) {
			remove(audio);
			audio.destroy();
			audio = null;
		}
		if (strAudio != null) {
			remove(strAudio);
			strAudio.destroy();
			strAudio = null;
		}
	}
	
	private function currentSpectrumSymmetry():Bool {
		if (audio != null) return audio.symmetry;
		if (strAudio != null) return strAudio.symmetry;
		return ClientPrefs.data.RelaxAudioSymmetry;
	}
	
	/**
	 * 更新歌曲信息显示
	 * @param songInfo 歌曲信息
	 */
	private function updateSongInfoDisplay(songInfo:SongInfo):Void {
		if (songInfo == null) return;
		
		currentBPM = songInfo.bpm > 0 ? songInfo.bpm : 100;
		beatTime = 60 / currentBPM;
		beatTimer = 0;
		
		songInfoDisplay.updateSongInfo(
			songInfo, 
			controlButtons.MiddleButton.x, 
			controlButtons.MiddleButton.y, 
			controlButtons.MiddleButton.width, 
			controlButtons.MiddleButton.height
		);
	}

	private function fadeInNewElements(onComplete:Void->Void):Void {
		var tweenCount = 0;
		var totalTweens = 0;
		
		if (backendPicture != null) totalTweens++;
		if (recordPicture != null) totalTweens++;
		if (audio != null) totalTweens++;
		if (strAudio != null) totalTweens++;
		
		if (totalTweens == 0) {
			onComplete();
			return;
		}
		
		function checkComplete() {
			tweenCount++;
			if (tweenCount >= totalTweens) {
				onComplete();
			}
		}
		
		if (backendPicture != null) {
			FlxTween.tween(backendPicture, {alpha: 1}, transitionTime, {
				ease: FlxEase.quadOut,
				onComplete: function(_) checkComplete()
			});
		}
		
		if (recordPicture != null) {
			FlxTween.tween(recordPicture, {alpha: 1, angle: 360}, transitionTime, {
				ease: FlxEase.quadOut,
				onComplete: function(_) checkComplete()
			});
		}
		
		if (audio != null) {
			FlxTween.tween(audio, {alpha: 0.7}, transitionTime, {
				ease: FlxEase.quadOut,
				onComplete: function(_) checkComplete()
			});
		}
		
		if (strAudio != null) {
			FlxTween.tween(strAudio, {alpha: 0.7}, transitionTime, {
				ease: FlxEase.quadOut,
				onComplete: function(_) checkComplete()
			});
		}
	}

	var topTrapezoid:FlxSprite;
	var hideTimer:Float = 0;
	var waitingToHide:Bool = false;
	var topTrapezoidTween:FlxTween = null;
	var isTweening:Bool = false;

	private function drawTrapezoid(topWidth:Float, height:Float):Void {
		var bottomWidth = topWidth * 0.8;
		var sideSlope = (topWidth - bottomWidth) / 2;
		
		topTrapezoid.makeGraphic(Std.int(topWidth), Std.int(height), FlxColor.TRANSPARENT, true);
		
		var vertices = [
			new FlxPoint(0, 0),
			new FlxPoint(topWidth, 0),
			new FlxPoint(topWidth - sideSlope, height), 
			new FlxPoint(sideSlope, height)
		];
		FlxSpriteUtil.drawPolygon(topTrapezoid, vertices, 0xFF24232C);
	}

	private function createTopButtons():Void {
		topButtons = new TopButtons();
		
		// 设置相机
		for (member in topButtons.members) {
			if (member != null) {
				member.cameras = [camOption];
			}
		}
		
		add(topButtons);
	}

	private function createBackButtons():Void {
		backButtons = new BackButtons();

		for (member in backButtons.members) {
			if (member != null) {
				member.cameras = [camVpad];
			}
		}
		
		add(backButtons);
		backButtons.y = FlxG.height - backButtons.height - 8;

		backButtons.back = function() {
		    Sound1.destroy();
		    Sound2.destroy();
		    FlxG.sound.playMusic(Paths.music('freakyMenu'));
		    ClientPrefs.saveSettings();
			close();
		}
	}

	override function create()
	{
	    instance = this;

		// 设置面板是叠在本状态之上的 substate。FlxState 在 subState != null 时
		// 会跳过父状态的 update / draw（除非父状态自己开了 persistent*），
		// 不开这两个标志的话一进设置，唱片、频谱、进度条就全冻住不动了。
		persistentDraw = true;
		persistentUpdate = false;

		topTrapezoid = new FlxSprite();
		drawTrapezoid(FlxG.width * 0.7, 40);
		topTrapezoid.y = 0;
		topTrapezoid.x = (FlxG.width - topTrapezoid.width) / 2;
		topTrapezoid.scrollFactor.set();
		topTrapezoid.cameras = [camOption];
		add(topTrapezoid);
		camOption.y = -topTrapezoid.height;

		createTopButtons();
		createBackButtons();
		
		defaultZoom = 1.0;
		camPic.zoom = defaultZoom;

		super.create();

		createButtons();

		// 创建歌曲信息显示
		songInfoDisplay = new SongInfoDisplay();
		add(songInfoDisplay.songNameText);
		add(songInfoDisplay.writerText);
		add(songInfoDisplay.songLengthText);
		
		songInfoDisplay.songNameText.cameras = [camText];
		songInfoDisplay.writerText.cameras = [camText];
		songInfoDisplay.songLengthText.cameras = [camHUD];

		circleMask = new Shape();
		updateMask();

		initSongsList(0);
		
		songLyrics = new FlxText(0, 0, FlxG.width, 'lyrics', 25);
		songLyrics.setFormat(Paths.font('Lang-ZH.ttf'), 25, FlxColor.WHITE, CENTER);
		add(songLyrics);
		songLyrics.cameras = [camHUD];
		
		songLyrics.y = 40;
		
		if (SongsArray.list.length > 0) {
			currentSongIndex = 0;
			pendingSongIndex = -1;
			loadSongs(SongsArray.list[0]);
		}
		
		playListWindow = new PlayListWindow();
		for (i in playListWindow.members){
		    i.cameras = [camOption];
		}
		add(playListWindow);
		
		triangleEmitter = new HollowTriangleEmitter();
		triangleEmitter.cameras = [camHollow];
        add(triangleEmitter);
        

        // 进度条要落在按钮块上方：控制条高 60、离底 10，所以按钮块顶边 = FlxG.height - 70
        songProgress = new SongProgress(0, FlxG.height - 86, FlxG.width, 6);
        songProgress.cameras = [camHUD];
        songProgress.onSeek = function(time:Float) {
            if (FlxG.sound.music != null) {
                FlxG.sound.music.time = time * 1000;
                if (Sound1 != null && Sound1.playing) Sound1.time = time * 1000;
                if (Sound2 != null && Sound2.playing) Sound2.time = time * 1000;
            }
        };
        add(songProgress);
        
        camHollow.alpha = 0.6;
	}

	function createButtons(){
		controlButtons = new ControlButtons();
		
		add(controlButtons.LeftButton);
		add(controlButtons.MiddleButton);
		add(controlButtons.RightButton);
		
		controlButtons.LeftButton.cameras = [camHUD];
		controlButtons.MiddleButton.cameras = [camHUD];
		controlButtons.RightButton.cameras = [camHUD];
		
		controlButtons.LeftButton.pixelPerfectPosition = true;
		controlButtons.RightButton.pixelPerfectPosition = true;
		controlButtons.MiddleButton.pixelPerfectPosition = true;
	}
	
	private function initSongsList(ListNum:Int = 0):Void {
		GetInit.refreshFreeplayList(); // Freeplay 曲目虚拟歌单（mods/周可能刚变过，重扫一遍）
		SongsArray = GetInit.getList(ListNum);
	}
	
	/** 歌词时间戳只在切歌时排一次序，update 里直接二分查，避免每帧重建数组 + 排序 */
	private function rebuildLyricTimes():Void {
		sortedLyricTimes = [];
		if (LyricsMap == null) return;
		
		for (time in LyricsMap.keys())
			sortedLyricTimes.push(time);
		sortedLyricTimes.sort((a, b) -> a - b);
	}
	/**
	 * 切换到下一首歌曲
	 */
	private function nextSong():Void {
		if (SongsArray.list.length <= 1) return;
		
		var nextIndex = (currentSongIndex + 1) % SongsArray.list.length;
		
		if (isTransitioning) {
			pendingSongIndex = nextIndex;
			return;
		}
		
		currentSongIndex = nextIndex;
		loadSongs(SongsArray.list[currentSongIndex]);
	}
	
	/**
	 * 切换到上一首歌曲
	 */
	private function prevSong():Void {
		if (SongsArray.list.length <= 1) return;
		
		var prevIndex = (currentSongIndex - 1 + SongsArray.list.length) % SongsArray.list.length;
		
		if (isTransitioning) {
			pendingSongIndex = prevIndex;
			return;
		}
		
		currentSongIndex = prevIndex;
		loadSongs(SongsArray.list[currentSongIndex]);
	}

	var maskW:Float = -1;
	var maskH:Float = -1;
	var maskApplied:Bool = false;

	private function updateMask():Void
	{
		if (ClientPrefs.data.theme != 'Circle')
		{
			clearMask();
			return;
		}
		
		if (circleMask == null)
			circleMask = new Shape();
		
		var sw:Float = FlxG.stage.stageWidth;
		var sh:Float = FlxG.stage.stageHeight;
		
		// 舞台尺寸没变就不用每帧重画矢量遮罩（原先每帧 clear + drawCircle）
		if (maskApplied && maskW == sw && maskH == sh)
			return;
		
		maskW = sw;
		maskH = sh;
		maskApplied = true;
		
		var maxRadius:Float = Math.min(sw, sh) / 2;
		maskRadius = Math.min(maskRadius, maxRadius);
		
		circleMask.graphics.clear();
		circleMask.graphics.beginFill(0xFFFFFF);
		
		var scaledRadius:Float = Math.min(
			maskRadius * (sh / FlxG.height), 
			maskRadius * (sw / FlxG.width)
		);
		
		circleMask.graphics.drawCircle(sw / 2, sh / 2, scaledRadius);
		circleMask.graphics.endFill();

		camPic.flashSprite.mask = circleMask;
		camText.flashSprite.mask = circleMask;
	}
	
	/** 退出环形主题时必须撤掉遮罩，否则整个画面还是被裁成圆形 */
	private function clearMask():Void
	{
		if (!maskApplied) return;
		maskApplied = false;
		if (camPic != null && camPic.flashSprite != null) camPic.flashSprite.mask = null;
		if (camText != null && camText.flashSprite != null) camText.flashSprite.mask = null;
	}

	private function updatePictureScale():Void
	{
		if (recordPicture == null) return;
		
		var scaleX:Float = (maskRadius * 2) / recordPicture.width;
		var scaleY:Float = (maskRadius * 2) / recordPicture.height;
		var scale:Float = Math.max(scaleX, scaleY);

		recordPicture.scale.set(scale, scale);
		recordPicture.updateHitbox();
		recordPicture.screenCenter();
	}

	override function destroy()
	{
		if (songInfoDisplay.songNameTween != null && songInfoDisplay.songNameTween.active) {
			songInfoDisplay.songNameTween.cancel();
			songInfoDisplay.songNameTween = null;
		}
		
		if (topTrapezoidTween != null && topTrapezoidTween.active) {
			topTrapezoidTween.cancel();
			topTrapezoidTween = null;
		}
		
		if (backendPicture != null) {
			backendPicture.destroy();
			backendPicture = null;
		}
		
		if (recordPicture != null) {
			recordPicture.destroy();
			recordPicture = null;
		}
		
		if (audio != null) {
			audio.destroy();
			audio = null;
		}
		
		if (strAudio != null) {
			strAudio.destroy();
			strAudio = null;
		}
		
		if (oldBackendPicture != null) {
			oldBackendPicture.destroy();
			oldBackendPicture = null;
		}
		
		if (oldRecordPicture != null) {
			oldRecordPicture.destroy();
			oldRecordPicture = null;
		}
		
		if (oldAudio != null) {
			oldAudio.destroy();
			oldAudio = null;
		}
		
		clearMask();
		if (circleMask != null) {
			circleMask = null;
		}
		
		if (controlButtons != null) {
			controlButtons.destroy();
			controlButtons = null;
		}
		
		if (topButtons != null) {
			topButtons.destroy();
			topButtons = null;
		}
		
		if (songInfoDisplay != null) {
			songInfoDisplay.destroy();
			songInfoDisplay = null;
		}
		
		if (topTrapezoid != null) {
			topTrapezoid.destroy();
			topTrapezoid = null;
		}

		currentSongIndex = 0;
		pendingSongIndex = -1;
		SongsArray = {
			name: "Unknown",
			list: []
		};
		
		super.destroy();
	}

	private function handleTopTrapezoidVisibility(nearTop:Bool, elapsed:Float):Void {
		if (nearTop) {
			if (waitingToHide) {
				waitingToHide = false;
				hideTimer = 0;
			}
			
			if (camOption.y < 0 && !isTweening) {
				if (topTrapezoidTween != null && topTrapezoidTween.active) {
					topTrapezoidTween.cancel();
				}
				
				isTweening = true;
				topTrapezoidTween = FlxTween.tween(camOption, {y: 0}, 0.3, {
					ease: FlxEase.quadOut,
					onComplete: function(_) {
						isTweening = false;
					}
				});
			}
		} 
		else {
			if (!waitingToHide && !isTweening) {
				waitingToHide = true;
				hideTimer = 0;
			}
			
			if (waitingToHide) {
				if(!clickList && !clickOption) hideTimer += elapsed;
				if (hideTimer >= 3.0 && !isTweening) {
					waitingToHide = false;

					if (topTrapezoidTween != null && topTrapezoidTween.active) {
						topTrapezoidTween.cancel();
					}
					
					isTweening = true;
					topTrapezoidTween = FlxTween.tween(camOption, {y: -topTrapezoid.height}, 0.3, {
						ease: FlxEase.quadIn,
						onComplete: function(_) {
							isTweening = false;
						}
					});
				}
			}
		}
	}
	
	var bgFollowSmooth:Float = 0.2;

	var clickList:Bool = false;
	var clickOption:Bool = false;
	var clickLock:Bool = false;
	
	var lastLyrics:String = '';
	var sortedLyricTimes:Array<Int> = [];
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		updateMask();
		
		// 一帧只取一次鼠标位置（原来取了 3 次）
		var mousePos = FlxG.mouse.getScreenPosition(camHUD);
		
		if (backendPicture != null && !isTransitioning) {
			var mouseX = mousePos.x;
			var mouseY = mousePos.y;
			var centerX = FlxG.width / 2;
			var centerY = FlxG.height / 2;
			
			var targetOffsetX = (mouseX - centerX) * 0.01;
			var targetOffsetY = (mouseY - centerY) * 0.01;
			
			var currentOffsetX = backendPicture.x - (centerX - backendPicture.width / 2);
			var currentOffsetY = backendPicture.y - (centerY - backendPicture.height / 2);
			
			var smoothX = FlxMath.lerp(currentOffsetX, targetOffsetX, bgFollowSmooth);
			var smoothY = FlxMath.lerp(currentOffsetY, targetOffsetY, bgFollowSmooth);
			
			backendPicture.x = centerX - backendPicture.width / 2 + smoothX;
			backendPicture.y = centerY - backendPicture.height / 2 + smoothY;
		}

		var nearTop = mousePos.y < 50;
		handleTopTrapezoidVisibility(nearTop, elapsed);

		songInfoDisplay.writerText.y = songInfoDisplay.songNameText.y + songInfoDisplay.songNameText.height + 10;
		
		songInfoDisplay.updateSongLengthPosition(
			controlButtons.MiddleButton.x,
			controlButtons.MiddleButton.y,
			controlButtons.MiddleButton.width,
			controlButtons.MiddleButton.height
		);
		
		if (ClientPrefs.data.enableBpmZoom && FlxG.sound.music != null && FlxG.sound.music.playing) {
			beatTimer += elapsed;
			
			if (beatTimer >= beatTime) {
				beatTimer -= beatTime;
				onBPMBeat();
			}
		}
		
		if (FlxG.sound.music != null) {
			var currentTime:Float = FlxG.sound.music.time / 1000;
			var totalTime:Float = FlxG.sound.music.length / 1000;
			
			songProgress.updateProgress(currentTime, totalTime);
			//我李奶奶的腿要是haxe的毫秒运算能够非常精确那我就不用大费周章了
			//把所有时间戳排序，并读取当前时间戳小且最接近的歌词
			var currentLyric:String = "";
			if (sortedLyricTimes.length > 0) {
				var nowMs:Int = Std.int(FlxG.sound.music.time);
				var lo:Int = 0;
				var hi:Int = sortedLyricTimes.length - 1;
				var idx:Int = -1;
				
				// 二分找"最后一个 <= 当前时间"的歌词时间戳
				while (lo <= hi) {
					var mid:Int = (lo + hi) >> 1;
					if (sortedLyricTimes[mid] <= nowMs) {
						idx = mid;
						lo = mid + 1;
					} else {
						hi = mid - 1;
					}
				}
				
				if (idx != -1) currentLyric = LyricsMap.get(sortedLyricTimes[idx]);
			}
            
            if (currentLyric != lastLyrics) {
                lastLyrics = currentLyric;
                songLyrics.text = currentLyric;
            }
            
			songInfoDisplay.updateSongLength(currentTime, totalTime);
		}

		// 设置面板是 substate，开着时本状态的键鼠让位（它有自己的 dim 与全套输入）。
		// 歌单磁贴墙不走 substate，面板也刻意从顶栏下方开始画，所以鼠标照常可用；
		// 只有左右方向键要避让 —— 磁贴墙自己拿它选磁贴。
		var uiBlocked:Bool = (subState != null);
		var listOpen:Bool = !playListWindow.Hidding;
		clickOption = uiBlocked;
		clickList = listOpen;
		songProgress.active = !uiBlocked;

		if (!uiBlocked && !listOpen && FlxG.keys.justPressed.LEFT) {
			prevSong();
		}
		else if (!uiBlocked && !listOpen && FlxG.keys.justPressed.RIGHT) {
			nextSong();
		}
		
		var isOverLeft = controlButtons.isMouseOverLeftButton(mousePos);
		var isOverMiddle = controlButtons.isMouseOverMiddleButton(mousePos);
		var isOverRight = controlButtons.isMouseOverRightButton(mousePos);

		var isOverList = topButtons.isMouseOverListButton(mousePos);
		var isOverSetting = topButtons.isMouseOverSettingButton(mousePos);
		var isOverRock = topButtons.isMouseOverLockButton(mousePos);
		
		controlButtons.setButtonAlphas(isOverLeft, isOverMiddle, isOverRight);
		topButtons.setButtonAlphas(isOverList, isOverSetting, isOverRock, clickList, clickOption, clickLock);
		
		if (!uiBlocked && FlxG.mouse.justPressed) {
			if (isOverLeft) {
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.7);
				controlButtons.animateLeftButtonPress(0.1);
				prevSong();
			}
			else if (isOverMiddle && FlxG.sound.music != null) {
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.7);
				
				if (FlxG.sound.music.playing) {
					FlxG.sound.music.pause();
					Sound1.pause();
					Sound2.pause();
				} else {
					FlxG.sound.music.play();
					Sound1.play();
					Sound2.play();
				}
			}
			else if (isOverRight) {
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.7);
				controlButtons.animateRightButtonPress(0.1);
				nextSong();
			}
			else if (isOverList) {
				playListWindow.toggle();
			}
			else if (isOverSetting) {
				openOptionPanel();
			}
			else if (isOverRock) {
				clickLock = !clickLock;
				camVpad.alpha = clickLock ? 0 : 1;
			}
		}
		
		if (ClientPrefs.data.theme == 'Circle' && recordPicture != null && !isTransitioning) {
			if (ClientPrefs.data.enableRecordRotation) {
				recordPicture.angle += elapsed * 20;
				if (recordPicture.angle >= 360) recordPicture.angle -= 360;
			} else {
				if (recordPicture.angle <= 180)
					recordPicture.angle = FlxMath.lerp(recordPicture.angle, 0, 0.1);
				else
					recordPicture.angle = FlxMath.lerp(recordPicture.angle, 360, 0.1);
			}
		}
		
		// 设置面板开着时 BACK 归面板；歌单窗开着时 BACK 要先收歌单，不能直接退出
		if (subState == null && controls.BACK) {
			// 歌单窗开着时 BACK 先收歌单（若在二级则先回一级），不直接退出 Relax
			if (!playListWindow.Hidding)
			{
				if (!playListWindow.goBack()) 
				{
					playListWindow.hide();
					clickList = false;
				}
			}
			else
			{
			    removeVirtualPad();
			    Sound1.destroy();
			    Sound2.destroy();
			    FlxG.sound.playMusic(Paths.music('freakyMenu'));
			    ClientPrefs.saveSettings();
				close();
			}
		}
	    
	    if (audio != null)
	        triangleEmitter.externalSpeedFactor = audio.amplitude;
	    else if (strAudio != null)
	        triangleEmitter.externalSpeedFactor = strAudio.amplitude;
	}

	/** 打开 Win8 设置浮出层（叠在本状态之上的 substate，关闭后由面板回刷参数） */
	public function openOptionPanel():Void
	{
		if (subState != null) return;

		// 歌单窗和设置面板互斥
		if (!playListWindow.Hidding)
		{
			playListWindow.Hidding = true;
			playListWindow.hide();
			clickList = false;
		}

		// 放行本状态的 update：频谱 / 进度条 / 歌词在设置面板开着时继续跑
		persistentUpdate = true;
		openSubState(new RelaxOptionPanel());
	}
	
	public function updateOptions(){
		var theme:String = ClientPrefs.data.theme;
		var themeChanged:Bool = (theme != lastTheme);
		
		if (!themeChanged
			&& currentSpectrumSymmetry() == ClientPrefs.data.RelaxAudioSymmetry
			&& lastAudioQuality == ClientPrefs.data.RelaxAudioDisplayQuality
			&& lastAudioNumber == ClientPrefs.data.RelaxAudioNumber)
			return;
		
		lastTheme = theme;
		lastAudioQuality = ClientPrefs.data.RelaxAudioDisplayQuality;
		lastAudioNumber = ClientPrefs.data.RelaxAudioNumber;
		
		destroySpectrum();
		createSpectrum();
		
		// createSpectrum 里 alpha=0 是给切歌淡入用的，选项面板改完要直接可见
		if (audio != null) audio.alpha = 0.7;
		if (strAudio != null) strAudio.alpha = 0.7;
		
		updateRecordVisibility();
		applySongInfoVisibility();
	}
	
	/**
	 * 唱片只在 Circle 主题显示；从 Straight/None 切回来时补建。
	 */
	private function updateRecordVisibility():Void {
		if (ClientPrefs.data.theme == 'Circle') {
			if (recordPicture == null && currentRecordImage != null) {
				createRecordSprite(currentRecordImage);
				if (recordPicture != null) recordPicture.alpha = 0.7;
			}
		}
		else if (recordPicture != null) {
			recordPicture.visible = false;
		}
	}
	
	/**
	 * songInfo 选项：None 隐藏歌名/作者文字，其余位置沿用居中布局。
	 */
	private function applySongInfoVisibility():Void {
		if (songInfoDisplay == null) return;
		var hide:Bool = (ClientPrefs.data.songInfo == 'None');
		songInfoDisplay.songNameText.visible = !hide;
		songInfoDisplay.writerText.visible = !hide;
	}

	var beatTimess:Int = 0;
	var helpBool:Bool = false;
	var lastAudioQuality:Int = ClientPrefs.data.RelaxAudioDisplayQuality;
	var lastAudioNumber:Int = ClientPrefs.data.RelaxAudioNumber;
	var lastTheme:String = '';

	function onBPMBeat(){
		var targetZoom = defaultZoom + zoomIntensity;

		controlButtons.handleBeatAnimation(beatTime);
		
		beatTimess++;
		helpBool = !helpBool;
		
		topButtons.handleBeatAnimation(helpBool, beatTime);
		/*
		if(helpBool){
			Main.watermark.scaleX = ClientPrefs.data.WatermarkScale + 0.1;
			Main.watermark.scaleY = ClientPrefs.data.WatermarkScale - 0.1;
		}else{
			Main.watermark.scaleX = ClientPrefs.data.WatermarkScale - 0.1;
			Main.watermark.scaleY = ClientPrefs.data.WatermarkScale + 0.1;
		} //XD
		
		FlxTween.tween(Main.watermark, {scaleX: ClientPrefs.data.WatermarkScale, scaleY: ClientPrefs.data.WatermarkScale}, beatTime * 0.5, {
			ease: FlxEase.quadOut
		});
		*/
		if(beatTimess == 4)
		{
			beatTimess = 0;
			//fourTimeBeat();
		}
	}
	function fourTimeBeat() {
		controlButtons.handleFourTimeBeatAnimation(beatTime);
		
		var currentY = songInfoDisplay.songLengthText.y;
		songInfoDisplay.songLengthText.y += 5;
		
		FlxTween.tween(songInfoDisplay.songLengthText, {y: currentY}, beatTime * 0.5, {
			ease: FlxEase.quadOut
		});
	}

	public function OtherListLoad(data:Array<Int> = null){
        try{
            if(data[0] >= GetInit.getListNum())
                data[0] = GetInit.getListNum() - 1;
                
            SongsArray = GetInit.getList(data[0]);
            
            if(data[1] >= SongsArray.list.length){
                data[1] = SongsArray.list.length - 1;
            }
            
            nowChoose = data;
            currentSongIndex = data[1];
            pendingSongIndex = -1;
            
            loadSongs(SongsArray.list[data[1]]);
        }
    }
}#end