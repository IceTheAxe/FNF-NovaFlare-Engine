package general.objects.state.relaxState.windows;
#if RELAX_ALLOWED

/** 一格磁贴的数据 */
typedef TileEntry = {
	var title:String;
	/** 副标题（大磁贴才显示），例如 "BPM 150 · 作曲" */
	@:optional var subtitle:String;
	/** 封面图 key（走 Paths.image），可为空 */
	@:optional var cover:String;
	/** 标记：正在播放 */
	@:optional var playing:Bool;
}
#end
