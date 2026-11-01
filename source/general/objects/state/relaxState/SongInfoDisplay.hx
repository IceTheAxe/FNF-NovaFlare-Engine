package general.objects.state.relaxState;
#if RELAX_ALLOWED

import flixel.util.FlxStringUtil;

class SongInfoDisplay
{
	public var songNameText:FlxText;
	public var writerText:FlxText;
	public var songLengthText:FlxText;
	
	public var songNameTween:FlxTween;
	public var maskRadius:Float = 150;

	public function new()
	{
		createTextDisplays();
	}

	private function createTextDisplays():Void
	{
		songNameText = new FlxText(0, FlxG.height / 2, FlxG.width, "", 48);
		songNameText.setFormat(Paths.font("montserrat.ttf"), 48, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		songNameText.scale.set(0.5,0.5);
		songNameText.scrollFactor.set();
		songNameText.borderSize = 1;
		songNameText.antialiasing = true;
		songNameText.alpha = 1;
		songNameText.screenCenter();

		writerText = new FlxText(0, songNameText.y + songNameText.height + 10, FlxG.width, "", 32);
		writerText.setFormat(Paths.font("montserrat.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		writerText.scale.set(0.5,0.5);
		writerText.scrollFactor.set();
		writerText.borderSize = 0.8;
		writerText.antialiasing = true;
		writerText.alpha = 1;
		writerText.screenCenter(X);

		songLengthText = new FlxText(0, 0, 0, "0:00 / 0:00", 32);
		songLengthText.setFormat(Paths.font("montserrat.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		songLengthText.scale.set(0.5,0.5);
		songLengthText.scrollFactor.set();
		songLengthText.borderSize = 1;
		songLengthText.antialiasing = true;
		songLengthText.alpha = 1;
	}

	public function updateSongInfo(songInfo:Dynamic, middleButtonX:Float, middleButtonY:Float, middleButtonWidth:Float, middleButtonHeight:Float):Void
	{
		if (songInfo == null) return;
		var actY = FlxG.height / 2;
		var animationDuration:Float = 0.5;
		
		if (songNameTween != null && songNameTween.active) {
			songNameTween.cancel();
			songNameTween = null;
		}

		if (songNameText != null) {
			songNameTween = FlxTween.tween(songNameText, {y: actY + maskRadius}, animationDuration, {
				ease: FlxEase.quadIn,
				onComplete: function(_) {
					songNameText.text = songInfo.name != null ? songInfo.name : "?????";
					writerText.text = songInfo.writer != null ? songInfo.writer : "Unknown";
					
					if (FlxG.sound.music != null) {
						var totalLength:Float = FlxG.sound.music.length / 1000;
						var minutes:Int = Math.floor(totalLength / 60);
						var seconds:Int = Math.floor(totalLength % 60);
						songLengthText.text = '0:00 / ${minutes}:${FlxStringUtil.formatTime(seconds, false)}';
					}

					songNameText.updateHitbox();
					songNameText.screenCenter(X);
					songNameText.y = actY - maskRadius;
					
					songNameTween = FlxTween.tween(songNameText, {y: actY}, animationDuration, {
						ease: FlxEase.backOut
					});
				}
			});
		}

		updateSongLengthPosition(middleButtonX, middleButtonY, middleButtonWidth, middleButtonHeight);
	}

	public function updateSongLengthPosition(middleButtonX:Float, middleButtonY:Float, middleButtonWidth:Float, middleButtonHeight:Float):Void
	{
		if (songLengthText != null) {
			songLengthText.x = middleButtonX + (middleButtonWidth - songLengthText.width) / 2;
			songLengthText.y = middleButtonY + (middleButtonHeight - songLengthText.height) / 2;
		}
	}
	
	/**
	 * 更新歌曲长度显示
	 * @param currentTime 当前时间(秒)
	 * @param totalTime 总时间(秒)
	 */
	public function updateSongLength(currentTime:Float, totalTime:Float):Void
	{
		if (songLengthText != null) {
			var currentTime:Float = FlxG.sound.music.time / 1000;
			var totalTime:Float = FlxG.sound.music.length / 1000;

			var currentMinutes:Int = Math.floor(currentTime / 60);
			var currentSeconds:Int = Math.floor(currentTime % 60);
			var totalMinutes:Int = Math.floor(totalTime / 60);
			var totalSeconds:Int = Math.floor(totalTime % 60);

			songLengthText.text = '${currentMinutes}:${currentSeconds < 10 ? "0" + currentSeconds : Std.string(currentSeconds)} / ${totalMinutes}:${totalSeconds < 10 ? "0" + totalSeconds : Std.string(totalSeconds)}';
		}
	}

	public function update(elapsed:Float):Void
	{
		if (writerText != null && songNameText != null) {
			writerText.y = songNameText.y + songNameText.height + 10;
		}
	}
	
	/**
	 * 处理节拍动画
	 * @param beatTime 节拍时间
	 */
	public function handleBeatAnimation(beatTime:Float):Void
	{
		if (songNameText != null) {
			songNameText.scale.set(1.05, 1.05);
			
			FlxTween.tween(songNameText.scale, {x: 1.0, y: 1.0}, beatTime * 0.5, {
				ease: FlxEase.quadOut
			});
		}
	}
	
	/**
	 * 处理四拍动画
	 * @param beatTime 节拍时间
	 */
	public function handleFourTimeBeatAnimation(beatTime:Float):Void
	{
		if (writerText != null) {
			writerText.scale.set(1.05, 1.05);
			
			FlxTween.tween(writerText.scale, {x: 1.0, y: 1.0}, beatTime * 0.5, {
				ease: FlxEase.quadOut
			});
		}
	}
	
	/**
	 * 销毁资源
	 */
	public function destroy():Void
	{
		if (songNameText != null) {
			songNameText.destroy();
			songNameText = null;
		}
		
		if (writerText != null) {
			writerText.destroy();
			writerText = null;
		}
		
		if (songLengthText != null) {
			songLengthText.destroy();
			songLengthText = null;
		}
		
		if (songNameTween != null && songNameTween.active) {
			songNameTween.cancel();
			songNameTween = null;
		}
	}
}#end