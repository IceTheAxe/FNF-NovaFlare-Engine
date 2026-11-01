package games.backend;

/**
 * 歌曲署名（曲师 / 谱师）的统一取数入口（FE 同步，简化链）。
 *
 * 优先级（高 → 低）：
 *   1. 谱面 JSON 内嵌的 artist / charter（含 NF 旧字段 musican / mapper 兜底）
 *   2. week.json 元组第 4/5 项（音乐人 / 各难度谱师）
 *
 * 与 Freeplay 侧共用同一口径，避免两处各写一套优先级、结果还不一致。
 * 调用方只需要把手上有的候选填进 context，缺的留 null。
 */
typedef SongCreditsContext =
{
	var songName:String;
	@:optional var diffName:String;
	@:optional var diffIdx:Null<Int>;
	@:optional var chartArtist:String;
	@:optional var chartCharter:String;
	@:optional var weekMusican:String;
	@:optional var weekCharters:Array<String>;
}

class SongCredits
{
	public static function getArtist(ctx:SongCreditsContext):String
	{
		if (ctx == null) return null;
		if (isSet(ctx.chartArtist)) return ctx.chartArtist;
		if (isSet(ctx.weekMusican)) return ctx.weekMusican;
		return null;
	}

	public static function getCharter(ctx:SongCreditsContext):String
	{
		if (ctx == null) return null;
		if (isSet(ctx.chartCharter)) return ctx.chartCharter;
		var charters:Array<String> = ctx.weekCharters;
		if (charters != null && charters.length > 0)
		{
			var i:Int = (ctx.diffIdx == null || ctx.diffIdx < 0) ? 0 : ctx.diffIdx;
			if (i >= charters.length) i = charters.length - 1;
			if (isSet(charters[i])) return charters[i];
		}
		return null;
	}

	/**
	 * 从当前 PlayState 的全局状态拼一个 context（暂停界面用）。
	 * week 元组按当前周查找；谱面内嵌字段取自 PlayState.SONG。
	 */
	public static function forPlayState():SongCreditsContext
	{
		var songName:String = Song.loadedSongName;
		if (PlayState.SONG != null && PlayState.SONG.song != null && PlayState.SONG.song.length > 0)
			songName = PlayState.SONG.song;

		var ctx:SongCreditsContext = {songName: songName};
		ctx.diffName = Difficulty.getString(PlayState.storyDifficulty, false);
		ctx.diffIdx = PlayState.storyDifficulty;
		if (PlayState.SONG != null)
		{
			// artist/charter 为谱面标准字段；musican/mapper 是 NF 旧字段，兜底
			ctx.chartArtist = firstSet(PlayState.SONG.artist, PlayState.SONG.musican);
			ctx.chartCharter = firstSet(PlayState.SONG.charter, PlayState.SONG.mapper);
		}

		var entry:Array<Dynamic> = WeekData.findSongEntry(null, songName);
		if (entry != null)
		{
			ctx.weekMusican = WeekData.getSongMusican(entry);
			ctx.weekCharters = WeekData.getSongCharters(entry);
		}
		return ctx;
	}

	inline static function isSet(value:String):Bool
		return value != null && value.length > 0 && value != 'N/A';

	inline static function firstSet(a:String, b:String):String
		return isSet(a) ? a : b;
}
