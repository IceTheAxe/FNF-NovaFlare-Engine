package general.objects.state.relaxState.windows;
#if RELAX_ALLOWED

import win8.Theme;

import general.backend.Paths;
import general.backend.relax.GetInit;

/**
 * Metro 风格的磁贴网格（Win8 开始屏幕）。
 *
 * 用于 Relax 的歌单窗：一格 160px、间距 8px；索引等于 largeIndex 的那一格渲染成 2×2 大磁贴，
 * 其余 1×1。大磁贴占掉的四个格子会被跳过，所以网格是"实心排布"而不是留洞。
 *
 * 动画全部走"指数逼近目标值"，不用 FlxTween：
 *   - 位置/尺寸每帧 `x += (tx - x) * k` → 出现跟退场都是自然的缓出，也不会漏 tween
 *   - 入场按格序 stagger（每格 18ms 延迟）
 *   - 切歌时 2×2 ↔ 1×1 靠 sizeT 从 1 逼近 2（或反向）自然长出来
 *
 * 磁贴内部全部用可改尺寸的原语：底色 = 1×1 精灵靠 scale 撑开，描边 = 四条细边，
 * 不用 shapeEx.Rect（它的图是按尺寸缓存的，没法跟着动画变形）。
 */
class TileGridView extends FlxSpriteGroup
{
	public static inline var TILE:Float = 160;
	public static inline var GAP:Float = 8;

	/** 网格可视区（相对本组坐标） */
	public var viewX:Float = 0;
	public var viewY:Float = 0;
	public var viewW:Float = 800;
	public var viewH:Float = 600;

	/** 单击 / 回车 */
	public var onActivate:Int->Void = null;

	public var selected:Int = 0;
	public var largeIndex:Int = -1;

	var tiles:Array<TileView> = [];
	var entries:Array<TileEntry> = [];

	var cameraRef:FlxCamera;

	// 滚动
	var scroll:Float = 0;
	var scrollTarget:Float = 0;
	var scrollVelocity:Float = 0;
	var dragging:Bool = false;
	var dragStartY:Float = 0;
	var dragMoved:Float = 0;
	var pressedTile:Int = -1;

	var hovered:Int = -1;
	var contentH:Float = 0;

	public function new(cam:FlxCamera)
	{
		super(0, 0);
		cameraRef = cam;
	}

	// =========================================================
	// 数据
	// =========================================================
	/**
	 * 重建全部磁贴。
	 * @param instant 为 true 时不做 stagger 入场（二级列表切换用）
	 */
	public function setEntries(list:Array<TileEntry>, large:Int = -1, instant:Bool = false):Void
	{
		clearTiles();

		entries = (list != null) ? list : [];
		largeIndex = (large >= 0 && large < entries.length) ? large : -1;

		for (i in 0...entries.length)
		{
			var view:TileView = new TileView(entries[i], i);
			view.sizeT = (i == largeIndex) ? 2 : 1;
			view.sizeTarget = view.sizeT;
			// 入场：整组 alpha 从 0 起，按格序延迟后开始淡入
			view.alpha = instant ? 1 : 0;
			view.revealDelay = instant ? 0 : i * 0.018;

			if (cameraRef != null) view.cameras = [cameraRef];
			tiles.push(view);
			add(view);
			// 注意顺序：先 add 再设相机。FlxSpriteGroup.preAdd 会把本组的 _cameras 写给成员，
			// 在 add 之前设会被它覆盖回 null。
			if (cameraRef != null) view.cameras = [cameraRef];
		}

		scroll = 0;
		scrollTarget = 0;
		scrollVelocity = 0;
		selected = (largeIndex >= 0) ? largeIndex : 0;

		layout(true);
		applyVisuals();
	}

	/** 只切换"哪一格是大磁贴"，位置与尺寸靠逼近动画自然变形 */
	public function setLargeIndex(index:Int):Void
	{
		if (index < 0 || index >= tiles.length || index == largeIndex) return;

		largeIndex = index;
		for (i in 0...tiles.length)
			tiles[i].sizeTarget = (i == index) ? 2 : 1;

		layout(true);
	}

	public function getEntryCount():Int
		return entries.length;

	/** 面板整体平移（滑入滑出用）。改了可视区原点就重排一次格子 */
	public function setPan(panX:Float, panY:Float):Void
	{
		if (viewX == panX && viewY == panY) return;

		viewX = panX;
		viewY = panY;
		layout(true);
	}

	public function getEntry(index:Int):TileEntry
		return (index >= 0 && index < entries.length) ? entries[index] : null;

	// =========================================================
	// 布局
	// =========================================================
	/** 按当前列数排格子；大磁贴占 2×2，占掉的格子跳过 */
	function layout(keepScroll:Bool = false):Void
	{
		var cols:Int = colCount();
		var used:Map<Int, Bool> = new Map();

		var cell:Int = 0;

		for (i in 0...tiles.length)
		{
			var span:Int = (i == largeIndex) ? 2 : 1;

			while (true)
			{
				var cx:Int = cell % cols;
				var cy:Int = Std.int(cell / cols);

				// 这一行放不下 2×2 → 直接换行
				if (cx + span > cols)
				{
					cell += (cols - cx);
					continue;
				}

				var fits:Bool = true;
				for (dy in 0...span)
				{
					for (dx in 0...span)
					{
						if (used.get((cy + dy) * cols + (cx + dx)) == true) fits = false;
					}
				}

				if (!fits)
				{
					cell++;
					continue;
				}

				for (dy in 0...span)
				{
					for (dx in 0...span)
						used.set((cy + dy) * cols + (cx + dx), true);
				}

				var view:TileView = tiles[i];
				view.tx = viewX + cx * (TILE + GAP);
				view.ty = viewY + cy * (TILE + GAP);
				view.row = cy;

				cell++;
				break;
			}
		}

		// 内容高度 = 最后一个格子的底边
		var maxBottom:Float = 0;
		for (view in tiles)
		{
			var bottom:Float = (view.ty - viewY) + TILE * view.sizeTarget + GAP;
			if (bottom > maxBottom) maxBottom = bottom;
		}

		contentH = maxBottom;
		clampScroll();

		if (!keepScroll)
		{
			scroll = scrollTarget;
		}
	}

	function maxScroll():Float
	{
		return Math.max(0, contentH - viewH);
	}

	/** 当前可视宽度能排几列（至少 1 列） */
	inline function colCount():Int
	{
		var c:Int = Std.int((viewW + GAP) / (TILE + GAP));
		return (c < 1) ? 1 : c;
	}

	function clampScroll():Void
	{
		scrollTarget = FlxMath.bound(scrollTarget, 0, maxScroll());
	}

	/** 选中项滚进可视区 */
	public function scrollIntoView(index:Int):Void
	{
		if (index < 0 || index >= tiles.length) return;

		var view:TileView = tiles[index];
		var top:Float = (view.ty - viewY) - scroll;
		var size:Float = TILE * view.sizeTarget;

		if (top < 0)
			scrollTarget += top;
		else if (top + size > viewH)
			scrollTarget += (top + size) - viewH;

		clampScroll();
	}

	// =========================================================
	// 更新
	// =========================================================
	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var mx:Float = -9999;
		var my:Float = -9999;
		var wheel:Int = 0;

		if (cameraRef != null)
		{
			var p = FlxG.mouse.getScreenPosition(cameraRef);
			mx = p.x;
			my = p.y;
			wheel = Std.int(FlxG.mouse.wheel);
		}

		var inside:Bool = (mx >= viewX && mx <= viewX + viewW && my >= viewY && my <= viewY + viewH);

		handleScroll(elapsed, wheel, inside, mx, my);

		// 悬停 / 按下
		hovered = inside ? hitTest(mx, my) : -1;

		if (inside && FlxG.mouse.justPressed)
		{
			if (hovered >= 0)
			{
				selected = hovered;
				pressedTile = hovered;
				dragStartY = my;
				dragMoved = 0;
				dragging = true;
			}
			else
			{
				pressedTile = -1;
				dragging = true;
				dragStartY = my;
				dragMoved = 0;
			}
		}

		if (dragging && FlxG.mouse.pressed)
			dragMoved = Math.max(dragMoved, Math.abs(my - dragStartY));

		if (FlxG.mouse.justReleased)
		{
			// 拖动超过阈值就不算点击，避免"想滚列表结果切了歌"
			if (pressedTile >= 0 && dragMoved < 8 && hovered == pressedTile && onActivate != null)
				onActivate(pressedTile);

			pressedTile = -1;
			dragging = false;
			dragMoved = 0;
		}

		// 逐格逼近目标：位置 / 尺寸 / 入场透明度
		for (i in 0...tiles.length)
		{
			var view:TileView = tiles[i];
			var k:Float = Math.min(1, elapsed * 14);

			view.sizeT += (view.sizeTarget - view.sizeT) * k;

			// stagger 入场：延迟没走完就保持全透明，走完才开始淡入
			if (view.revealDelay > 0)
			{
				view.revealDelay -= elapsed;
			}
			else if (view.alpha < 1)
			{
				view.alpha = Math.min(1, view.alpha + elapsed * 6);
			}

			var targetY:Float = view.ty - scroll;
			view.x += (view.tx - view.x) * k;
			view.y += (targetY - view.y) * k;

			view.applyGeometry(view.sizeT);
			view.updateState(i == selected, i == hovered, i == pressedTile);
		}

		applyVisuals();

		// 滚轮 / 方向键
		handleKeys();
	}

	function handleKeys():Void
	{
		if (tiles.length == 0) return;

		var cols:Int = colCount();
		var old:Int = selected;

		if (FlxG.keys.justPressed.LEFT) selected--;
		else if (FlxG.keys.justPressed.RIGHT) selected++;
		else if (FlxG.keys.justPressed.UP) selected -= cols;
		else if (FlxG.keys.justPressed.DOWN) selected += cols;

		if (selected != old)
		{
			selected = FlxMath.wrap(selected, 0, tiles.length - 1);
			scrollIntoView(selected);
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}

		if (FlxG.keys.justPressed.ENTER && onActivate != null)
			onActivate(selected);
	}

	function handleScroll(elapsed:Float, wheel:Int, inside:Bool, mx:Float, my:Float):Void
	{
		if (wheel != 0 && inside)
			scrollTarget -= wheel * 80;

		if (inside && FlxG.mouse.pressed && dragging && Math.abs(my - dragStartY) > 8)
			scrollTarget -= (my - dragStartY);

		// 拖动时同步基准点，避免越拖越快
		if (dragging && FlxG.mouse.pressed && Math.abs(my - dragStartY) > 8)
			dragStartY = my;

		clampScroll();
		scroll += (scrollTarget - scroll) * Math.min(1, elapsed * 16);

		if (!FlxG.mouse.pressed) scrollVelocity = 0;
	}

	/** 屏幕坐标 → 磁贴下标（按视觉矩形判，大磁贴自然更大） */
	function hitTest(mx:Float, my:Float):Int
	{
		for (i in 0...tiles.length)
		{
			var view:TileView = tiles[i];
			var size:Float = TILE * view.sizeT;
			if (mx >= view.x && mx <= view.x + size && my >= view.y && my <= view.y + size)
				return i;
		}
		return -1;
	}

	/** 视口外裁剪：看不见的磁贴直接不绘制 */
	function applyVisuals():Void
	{
		for (view in tiles)
		{
			var size:Float = TILE * view.sizeT;
			var visible:Bool = (view.y + size > viewY) && (view.y < viewY + viewH);
			view.visible = visible && view.alpha > 0.01;
		}
	}

	function clearTiles():Void
	{
		for (view in tiles)
		{
			remove(view, true);
			view.destroy();
		}
		tiles = [];
		entries = [];
		largeIndex = -1;
	}

	override function destroy():Void
	{
		clearTiles();
		super.destroy();
	}
}

/**
 * 单个磁贴。
 *
 * 所有部件都按"比例 × 基准尺寸"摆放，applyGeometry() 每帧按当前 sizeT 重算，
 * 所以 1×1 ↔ 2×2 的变形就是 sizeT 从 1 逼近 2 的过程，不需要重建对象。
 */
class TileView extends FlxSpriteGroup
{
	public var entry:TileEntry;
	public var index:Int = 0;

	/** 当前 / 目标尺寸倍数（1 = 1×1，2 = 2×2） */
	public var sizeT:Float = 1;
	public var sizeTarget:Float = 1;

	/** 目标位置与所在行 */
	public var tx:Float = 0;
	public var ty:Float = 0;
	public var row:Int = 0;

	/** 入场：延迟（秒）—— 延迟走完才开始淡入 */
	public var revealDelay:Float = 0;

	var bg:FlxSprite;
	var cover:FlxSprite;
	var shade:FlxSprite;
	var title:FlxText;
	var subtitle:FlxText;
	var marker:FlxSprite;
	var edges:Array<FlxSprite> = [];

	var hovered:Bool = false;
	var pressed:Bool = false;
	var isSelected:Bool = false;
	var playing:Bool = false;

	/** 已应用的字号，避免每帧重建 FlxText 的格式 */
	var lastTitleSize:Int = -1;
	var lastSubSize:Int = -1;

	public function new(data:TileEntry, index:Int)
	{
		super(0, 0);

		this.entry = data;
		this.index = index;
		this.playing = (data.playing == true);

		bg = new FlxSprite();
		bg.makeGraphic(1, 1, Theme.face());
		bg.origin.set(0, 0);      // 1×1 撑开时必须以左上角为锚点，否则会被"中心缩放"顶偏
		add(bg);

		cover = null;
		var gfx = GetInit.resolveImage(data.cover); // 歌单内文件直读本地，资源键仍走 Paths.image
		if (gfx != null)
		{
			cover = new FlxSprite();
			cover.loadGraphic(gfx);
			cover.origin.set(0, 0);
			cover.antialiasing = ClientPrefs.data.antialiasing;
			add(cover);
		}

		// 歌名压条：磁贴底部一块半透明黑，保证任何封面上字都看得清
		shade = new FlxSprite();
		shade.makeGraphic(1, 1, 0xFF000000);
		shade.origin.set(0, 0);
		shade.alpha = 0.55;
		add(shade);

		title = new FlxText(0, 0, 100, data.title != null ? data.title : '');
		title.setFormat(Theme.uiFont(), 12, 0xFFFFFFFF, LEFT);
		title.borderStyle = NONE;
		title.antialiasing = ClientPrefs.data.antialiasing;
		add(title);

		subtitle = new FlxText(0, 0, 100, (data.subtitle != null) ? data.subtitle : '');
		subtitle.setFormat(Theme.uiFont(), 10, 0xFFCCCCCC, LEFT);
		subtitle.borderStyle = NONE;
		subtitle.antialiasing = ClientPrefs.data.antialiasing;
		subtitle.visible = false;
		add(subtitle);

		// 选中指示条（磁贴下方 4px）
		marker = new FlxSprite();
		marker.makeGraphic(1, 1, Theme.accent());
		marker.origin.set(0, 0);
		marker.visible = false;
		add(marker);

		// 描边四条：可以自由改长度，所以不用 makeFrameSprite
		for (k in 0...4)
		{
			var e:FlxSprite = new FlxSprite();
			e.makeGraphic(1, 1, 0xFFFFFFFF);
			e.origin.set(0, 0);
			e.visible = false;
			edges.push(e);
			add(e);
		}

		applyGeometry(1);
	}

	/** 按当前 sizeT 重算所有部件的尺寸与位置（局部坐标，组坐标在 add 时已烘焙） */
	public function applyGeometry(sizeT:Float):Void
	{
		var size:Float = TileGridView.TILE * sizeT;
		var x0:Float = this.x;
		var y0:Float = this.y;

		bg.x = x0;
		bg.y = y0;
		bg.scale.set(size, size);

		if (cover != null)
		{
			var src = cover.frameWidth > 0 ? cover.frameWidth : 1;
			var s:Float = size / src;
			cover.scale.set(s, s);
			cover.x = x0;
			cover.y = y0;
		}

		var shadeH:Float = Math.max(22, size * 0.26);
		shade.x = x0;
		shade.y = y0 + size - shadeH;
		shade.scale.set(size, shadeH);

		var pad:Float = size * 0.055;
		title.fieldWidth = size - pad * 2;

		// setFormat 会重建整个文本格式，变形动画期间每帧都调太浪费 → 只在字号真的变了才设
		var titleSize:Int = Std.int(Math.max(10, size * 0.082));
		if (titleSize != lastTitleSize)
		{
			title.setFormat(Theme.uiFont(), titleSize, 0xFFFFFFFF, LEFT);
			lastTitleSize = titleSize;
		}

		title.x = x0 + pad;
		title.y = y0 + size - shadeH + (shadeH * 0.18);

		// 副标题只在大磁贴（sizeT 过 1.4）时出现，避免 1×1 挤成一团
		var showSub:Bool = (sizeT > 1.4 && subtitle.text != null && subtitle.text != '');
		subtitle.visible = showSub && visible;
		if (showSub)
		{
			var subSize:Int = Std.int(Math.max(9, size * 0.055));
			subtitle.fieldWidth = size - pad * 2;
			if (subSize != lastSubSize)
			{
				subtitle.setFormat(Theme.uiFont(), subSize, 0xFFCCCCCC, LEFT);
				lastSubSize = subSize;
			}
			subtitle.x = x0 + pad;
			subtitle.y = y0 + size - shadeH * 0.52;
		}

		// 描边
		var t:Float = 2;
		setEdge(0, x0, y0, size, t);                    // 上
		setEdge(1, x0, y0 + size - t, size, t);         // 下
		setEdge(2, x0, y0, t, size);                    // 左
		setEdge(3, x0 + size - t, y0, t, size);         // 右

		// 选中指示条
		marker.x = x0;
		marker.y = y0 + size + 3;
		marker.scale.set(size, 4);
	}

	function setEdge(i:Int, x:Float, y:Float, w:Float, h:Float):Void
	{
		var e:FlxSprite = edges[i];
		e.x = x;
		e.y = y;
		e.scale.set(w, h);
	}

	/** 每帧的状态表现：描边颜色 + 选中条 + 按下的轻微下沉 */
	public function updateState(sel:Bool, hov:Bool, press:Bool):Void
	{
		if (sel != isSelected)
		{
			isSelected = sel;
			marker.visible = sel;
		}

		var changed:Bool = (hov != hovered) || (press != pressed);
		hovered = hov;
		pressed = press;

		if (changed || sel)
		{
			// 当前播放 → 强调色描边；悬停/选中 → 白色描边；都没有 → 不画描边
			var hasBorder:Bool = (playing || sel || hov);
			var color:FlxColor = (playing || sel) ? Theme.accent() : 0xFFFFFFFF;

			for (e in edges)
			{
				e.visible = hasBorder;
				if (hasBorder)
					e.color = press ? Theme.pressTint(color) : (hov ? Theme.hoverTint(color) : color);
			}

			shade.alpha = hov ? 0.68 : 0.55;
		}
	}
}
#end
