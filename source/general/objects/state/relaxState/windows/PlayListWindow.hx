package general.objects.state.relaxState.windows;
#if RELAX_ALLOWED

import flixel.util.FlxSpriteUtil;

import win8.Theme;

import general.backend.relax.GetInit;
import general.backend.relax.GetInit.SongInfo;
import general.backend.relax.GetInit.SongLists;

import substates.RelaxSubState;

/**
 * Relax 歌单窗 —— Win8 开始屏幕的磁贴墙（左侧滑入）。
 *
 * 两级：一级是歌单（每个 List.json 一块磁贴），点进去二级是曲目磁贴。
 * 标题栏左边是返回箭头 + 面包屑，和 win8.Panel 的浮出层保持同一套视觉语言。
 *
 * 面板只占上方，底部留出 100px 给进度条和播放控制块 —— 否则滑出来会盖住播放键。
 */
class PlayListWindow extends FlxSpriteGroup
{
	public static var instance:PlayListWindow;

	public var Hidding:Bool = true;

	/** 面板底与标题栏 */
	var panelBG:Rect;
	var headerBG:Rect;
	var headerLine:Rect;
	var headerTitle:FlxText;
	var headerCrumb:FlxText;
	/** ‹ 的两笔（drawLine 每次都会重建绘制上下文，画在同一张图上第二笔会盖掉第一笔） */
	var chevrons:Array<FlxSprite> = [];
	var backVisible:Bool = false;
	var backHit:FlxSprite;

	public var grid:TileGridView;

	/** 0 = 收起（整块在屏幕左外侧），1 = 展开 */
	var slide:Float = 0;
	var slideTarget:Float = 0;

	/** 当前层级：0 = 歌单，1 = 曲目 */
	public var level:Int = 0;
	var openedList:Int = 0;

	static inline var HEADER_H:Float = 64;
	static inline var PAD:Float = 24;
	/** 顶部让开顶栏（梯形面板高 40），否则顶栏上的三个按钮会被挡在面板下面 */
	static inline var PANEL_TOP:Float = 44;
	/** 底部给进度条 + 控制块留的空间 */
	static inline var BOTTOM_RESERVE:Float = 100;

	var panelW:Float = 0;
	var panelH:Float = 0;
	var gridBaseX:Float = 0;
	var gridBaseY:Float = 0;

	var camRef:FlxCamera;

	public function new()
	{
		super();

		camRef = (RelaxSubState.instance != null) ? RelaxSubState.instance.camOption : null;

		panelW = Math.floor(FlxG.width * 0.62);
		panelH = FlxG.height - PANEL_TOP - BOTTOM_RESERVE;

		panelBG = new Rect(0, PANEL_TOP, panelW, panelH, 0, 0, Theme.panelBG(), 1);
		add(panelBG);

		headerBG = new Rect(0, PANEL_TOP, panelW, HEADER_H, 0, 0, Theme.panelHeader(), 1);
		add(headerBG);

		headerLine = new Rect(0, PANEL_TOP + HEADER_H, panelW, 1, 0, 0, Theme.divider(), 1);
		add(headerLine);

		// 返回箭头：两笔划出来的 ‹，避免依赖字体里有没有箭头字形
		for (k in 0...2)
		{
			var chev:FlxSprite = new FlxSprite();
			chev.makeGraphic(28, 28, FlxColor.TRANSPARENT);
			if (k == 0)
				FlxSpriteUtil.drawLine(chev, 19, 5, 9, 14, {thickness: 2, color: FlxColor.WHITE});
			else
				FlxSpriteUtil.drawLine(chev, 9, 14, 19, 23, {thickness: 2, color: FlxColor.WHITE});
			chev.visible = false;
			chevrons.push(chev);
			add(chev);
		}

		backHit = new FlxSprite();
		backHit.makeGraphic(44, 44, FlxColor.TRANSPARENT);
		backHit.alpha = 0;
		backHit.visible = false;
		add(backHit);

		headerTitle = new FlxText(0, PANEL_TOP + 14, panelW - PAD * 2, '', 20);
		headerTitle.setFormat(Paths.font('montserrat.ttf'), 20, Theme.text(), LEFT);
		headerTitle.borderStyle = NONE;
		headerTitle.antialiasing = ClientPrefs.data.antialiasing;
		add(headerTitle);

		headerCrumb = new FlxText(0, PANEL_TOP + 40, panelW - PAD * 2, '', 11);
		headerCrumb.setFormat(Paths.font('montserrat.ttf'), 11, Theme.textSecondary(), LEFT);
		headerCrumb.borderStyle = NONE;
		headerCrumb.antialiasing = ClientPrefs.data.antialiasing;
		add(headerCrumb);

		gridBaseX = PAD;
		gridBaseY = PANEL_TOP + HEADER_H + PAD;

		grid = new TileGridView(camRef);
		grid.viewX = gridBaseX;
		grid.viewY = gridBaseY;
		grid.viewW = panelW - PAD * 2;
		grid.viewH = panelH - HEADER_H - PAD * 2;
		grid.onActivate = onTileActivated;
		add(grid);

		instance = this;

		if (camRef != null) cameras = [camRef];

		alpha = 1;
		showPlaylists();
		applySlide();
	}

	// =========================================================
	// 层级 / 数据
	// =========================================================
	public function showPlaylists():Void
	{
		level = 0;
		setBackVisible(false);

		headerTitle.text = lang('playlists', 'Playlists');
		headerCrumb.text = lang('playlistsHint', 'Click a playlist to open it');

		grid.setEntries(buildPlaylistTiles(), -1);
	}

	function showSongs(listIndex:Int):Void
	{
		openedList = listIndex;
		level = 1;
		setBackVisible(true);

		var lists:Array<TileEntry> = buildSongTiles(listIndex);
		var large:Int = -1;

		// 正在播的那首做成 2×2
		for (i in 0...lists.length)
		{
			if (lists[i].playing == true)
			{
				large = i;
				break;
			}
		}

		headerTitle.text = listName(listIndex);
		headerCrumb.text = lang('songsHint', 'Click a song to play it');

		grid.setEntries(lists, large);
	}

	function listName(listIndex:Int):String
	{
		var names = GetInit.getAllListName();
		var n:String = (names != null) ? names.get(listIndex) : null;
		return (n != null) ? n : 'Playlist ' + listIndex;
	}

	function buildPlaylistTiles():Array<TileEntry>
	{
		var out:Array<TileEntry> = [];
		var count:Int = GetInit.getListNum();

		// 名字表只取一次：getListNum / getAllListName / getList 每次都会重扫 playlists 目录，
		// 放在循环里就是 O(n²) 次磁盘读
		var names = GetInit.getAllListName();

		for (i in 0...count)
		{
			var list:SongLists = GetInit.getList(i);
			var songCount:Int = (list != null && list.list != null) ? list.list.length : 0;
			var n:String = (names != null) ? names.get(i) : null;

			out.push({
				title: (n != null) ? n : 'Playlist ' + i,
				subtitle: songCount + ' ' + lang('songsUnit', 'songs'),
				cover: firstCover(list),
				playing: (playlistPlaying() == i)
			});
		}

		return out;
	}

	function buildSongTiles(listIndex:Int):Array<TileEntry>
	{
		var out:Array<TileEntry> = [];
		var list:SongLists = GetInit.getList(listIndex);
		if (list == null || list.list == null) return out;

		var playingIndex:Int = playingSongIn(listIndex);

		for (i in 0...list.list.length)
		{
			var s:SongInfo = list.list[i];
			var sub:String = 'BPM ' + Std.string(s.bpm);
			if (s.writer != null && s.writer != '') sub += ' · ' + s.writer;

			out.push({
				title: (s.name != null) ? s.name : 'unknown',
				subtitle: sub,
				cover: coverOf(s),
				playing: (i == playingIndex)
			});
		}

		return out;
	}

	/** 当前正在播的歌单下标（没在播本窗口的列表就返回 -1） */
	function playlistPlaying():Int
	{
		var host:RelaxSubState = RelaxSubState.instance;
		if (host == null || host.nowChoose == null) return -1;
		return host.nowChoose[0];
	}

	function playingSongIn(listIndex:Int):Int
	{
		var host:RelaxSubState = RelaxSubState.instance;
		if (host == null || host.nowChoose == null) return -1;
		if (host.nowChoose[0] != listIndex) return -1;
		return host.currentSongIndex;
	}

	function firstCover(list:SongLists):String
	{
		if (list == null || list.list == null) return null;

		for (s in list.list)
		{
			var c:String = coverOf(s);
			if (c != null) return c;
		}
		return null;
	}

	function coverOf(s:SongInfo):String
	{
		if (s == null) return null;
		if (s.record != null && s.record.length > 0 && s.record[0] != null) return Std.string(s.record[0]);
		if (s.background != null && s.background.length > 0 && s.background[0] != null) return Std.string(s.background[0]);
		return null;
	}

	// =========================================================
	// 交互
	// =========================================================
	function onTileActivated(index:Int):Void
	{
		if (level == 0)
		{
			showSongs(index);
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			return;
		}

		var host:RelaxSubState = RelaxSubState.instance;
		if (host != null)
		{
			host.OtherListLoad([openedList, index]);
			host.nowChoose = [openedList, index];
		}

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		hide();
	}

	/** 返回上一级；已经在一级时返回 false（交给上层关闭窗口） */
	public function goBack():Bool
	{
		if (level == 0) return false;

		showPlaylists();
		FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
		return true;
	}

	// =========================================================
	// 展开 / 收起
	// =========================================================
	public function show():Void
	{
		if (!Hidding) return;
		Hidding = false;
		slideTarget = 1;

		// 每次重新打开都刷一次内容：正在播放的标记、Freeplay 虚拟歌单都可能已经变了
		GetInit.refreshFreeplayList();
		if (level == 1) showSongs(openedList);
		else showPlaylists();
	}

	public function hide():Void
	{
		if (Hidding) return;
		Hidding = true;
		slideTarget = 0;
	}

	public function toggle():Void
	{
		if (Hidding) show();
		else hide();
	}

	/** 返回箭头与它的命中区一起开关 */
	function setBackVisible(v:Bool):Void
	{
		backVisible = v;
		for (chev in chevrons)
			chev.visible = v;
		backHit.visible = v;
	}

	/** 把 slide 套用到每个元素的 x 上（面板整体左滑进出） */
	function applySlide():Void
	{
		var ox:Float = -panelW * (1 - slide);

		panelBG.x = ox;
		headerBG.x = ox;
		headerLine.x = ox;
		headerCrumb.x = ox + PAD;
		for (chev in chevrons)
		{
			chev.x = ox + PAD;
			chev.y = PANEL_TOP + 18;
		}
		backHit.x = ox + PAD - 8;
		backHit.y = PANEL_TOP + 10;

		// 有返回箭头时标题右移，给箭头让位
		headerTitle.x = ox + PAD + (backVisible ? 36 : 0);
		headerCrumb.x = headerTitle.x;

		grid.setPan(gridBaseX + ox, grid.viewY);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var k:Float = Math.min(1, elapsed * 16);
		if (Math.abs(slideTarget - slide) > 0.001)
		{
			slide += (slideTarget - slide) * k;
			applySlide();
		}
		else if (slide != slideTarget)
		{
			slide = slideTarget;
			applySlide();
		}

		// 收起来就别再吃输入（磁贴自己也就不再响应）
		grid.active = (!Hidding);

		if (Hidding) return;

		// 返回箭头 / 右键都回上一级；BACK 键由 RelaxSubState 统一处理（它会先调 goBack）
		if (backVisible && camRef != null && FlxG.mouse.justPressed)
		{
			var p = FlxG.mouse.getScreenPosition(camRef);
			if (p.x >= backHit.x && p.x <= backHit.x + backHit.width && p.y >= backHit.y && p.y <= backHit.y + backHit.height)
			{
				goBack();
				return;
			}
		}

		if (FlxG.mouse.justPressedRight)
		{
			if (!goBack()) hide();
		}
	}

	inline function lang(key:String, fallback:String):String
	{
		var v:String = Language.get(key, 'relax');
		return (v == null || v == key || v.endsWith(' (404)')) ? fallback : v;
	}
}
#end
