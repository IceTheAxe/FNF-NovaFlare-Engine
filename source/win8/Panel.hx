package win8;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

/**
 * ==========================================================================
 * Win8 风格设置面板（基类）
 * ==========================================================================
 *
 * Windows 8 的"设置浮出层"（Settings flyout）：贴屏幕右侧的面板，从右边缘滑入，
 * 顶部标题栏 + 中间滚动区 + 底部说明栏。子类只重写 buildEntries() 声明分组与选项，
 * 排版 / 滚动 / 键鼠输入全由基类处理。
 *
 * 关闭路径只有一条：animateOutAndClose() → closePanel() → close()。
 * 返回按钮 / ESC / 右键共用 onBackAction()，子类可以重写。
 */
class Panel extends MusicBeatSubstate
{
	// =========================================================
	// 布局常量
	// =========================================================
	/** 顶部标题区高度 */
	public static inline var HEADER_H:Float = 96;
	/** 面板内一行的高度（标题在上、控件在下） */
	public static inline var ROW_H:Float = 88;
	public static inline var ROW_GAP:Float = 6;
	/** 动作按钮（ACTION）的高度；largeActionButtons 打开时用 */
	public static inline var ACTION_BTN_H:Float = 40;
	/** 面板内边距 */
	public static inline var PANEL_PAD:Float = 12;
	/** 底部"选项说明"栏的高度 */
	public static inline var FOOTER_H:Float = 54;
	/**
	 * 面板最小宽度。
	 * 30% 面板下这个下限只在窗口宽 < 1000px 时才会生效，
	 * 300 是"行标题还能单行放下"的下限（OptionRow 的 title.fieldWidth = panelW - 52）。
	 */
	static inline var PANEL_W_MIN:Float = 300;
	/** 两组之间的额外间距 */
	static inline var SECTION_GAP:Float = 12;

	public static inline var ANIM_IN:Float = 0.34;
	public static inline var ANIM_OUT:Float = 0.24;

	// =========================================================
	// 数据
	// =========================================================
	/** 子类通过 buildEntries() 填充 */
	public var entries:Array<PanelEntry> = [];

	/**
	 * ACTION 按钮是否用"大按钮"渲染。
	 * false（默认）= 工厂默认的 100×35 小按钮；true = widgetW 宽 × ACTION_BTN_H 高。
	 */
	public var largeActionButtons:Bool = false;

	/** 分组小标题（每条带 options 的条目对应一个） */
	public var sections:Array<OptionSection> = [];
	/** 面板内的行 */
	public var rows:Array<OptionRow> = [];
	/** 键盘选中的行 */
	public var selectedRow:Int = 0;

	// =========================================================
	// UI
	// =========================================================
	/** 整屏暗色遮罩（面板不是整屏时左侧那一块） */
	var dim:Rect;

	var panelBG:Rect;
	var panelHeader:Rect;
	var panelTitle:FlxText;
	var panelDesc:FlxText;
	var backBtn:PanelIconButton;

	/** 底部"选项说明"栏 */
	var footerBG:Rect;
	var footerDivider:Rect;
	var footerText:FlxText;
	/** 鼠标当前悬停在哪一行，-1 = 没有 */
	var hoveredRow:Int = -1;

	var contentGroup:FlxSpriteGroup;
	/** 下拉弹层的挂载层（永远在最上面） */
	var overlayContainer:FlxSpriteGroup;

	// =========================================================
	// 滚动 / 动画状态
	// =========================================================
	var scroller:MouseMove;
	var scrollHolder:{value:Float} = {value: 0};
	public var scroll:Float = 0;
	public var maxScroll:Float = 0;

	var panelX:Float = 0;
	var panelW:Float = 0;

	/** 面板相对"最终位置"的偏移量（= panelW 表示完全在右边屏幕外） */
	var panelOffset:Float = 0;
	/** FlxTween 用的载体（FlxTween 只能 tween 对象字段） */
	var panelSlide:{value:Float} = {value: 0};
	/** 标题 / 描述 / 返回按钮的最终 x，滑动时在它基础上加 panelOffset */
	var titleBaseX:Float = 0;
	var backBaseX:Float = 0;
	var footerBaseX:Float = 0;

	public var isAnimating:Bool = true;
	public var closing:Bool = false;

	/**
	 * 面板占屏宽的比例。默认 0.3 —— 也就是真 Win8 那个贴屏幕右侧的设置浮出层。
	 * 面板贴屏幕最右（panelX = FlxG.width - panelW）。
	 */
	public var panelWidthRatio:Float = 0.3;

	/** 面板是否处于"贴右展开"状态 */
	public var panelVisible:Bool = false;

	/** 点面板之外的地方是否收起整个面板 */
	public var dismissOnOutsideClick:Bool = true;

	/** 待重建标记：0 = 无，1 = 面板内容，2 = 整块重建 */
	var pendingRebuild:Int = 0;

	// =========================================================
	// 生命周期
	// =========================================================
	public function new()
	{
		super();
	}

	override function create()
	{
		super.create();

		// 面板画在"最后一个相机"上 —— 菜单状态里那台相机不滚动不缩放，
		// 面板的命中判定（Input）与坐标才能跟 FlxG.mouse 对上，也才能盖在所有图层之上。
		if (cameras == null || cameras.length == 0)
			cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		// 声明本界面画在哪台相机上：控件 / 行悬停 / 点空白 / 拖拽滚动全靠它统一到同一台相机，
		// 否则控件会按 FlxG.camera 的 scroll / zoom 去算命中区，整体偏掉。
		Input.bind(this, (cameras != null && cameras.length > 0) ? cameras[0] : null);

		FlxG.mouse.visible = true;

		computeLayout();

		// 1) 数据（子类的字段必须先初始化好）
		entries = buildEntries();
		if (entries == null) entries = [];

		// 2) 面板本体
		createPanelUI();

		// 3) 面板内容
		rebuildRows();
		applyHeaderText();

		// 4) 入场动画
		startIntro();
	}

	/** 计算面板的 x 与宽度 */
	function computeLayout():Void
	{
		var ratio:Float = FlxMath.bound(panelWidthRatio, 0.25, 1);
		panelW = FlxMath.bound(FlxG.width * ratio, PANEL_W_MIN, FlxG.width);
		panelX = FlxG.width - panelW;
	}

	// =========================================================
	// 子类接口
	// =========================================================
	/** 声明所有分组（子类必须重写） */
	public function buildEntries():Array<PanelEntry>
	{
		return [];
	}

	/**
	 * 返回：顶部返回按钮 / ESC / 右键都走这里。
	 * 默认 = 关闭整个面板。
	 */
	public function onBackAction():Void
	{
		animateOutAndClose();
	}

	/**
	 * 点了面板外面的地方。
	 * 默认：dismissOnOutsideClick 为真时关闭整个面板。
	 * 触发条件里带了 !WidgetFactory.popupOpen，不会因为点自己的下拉而误关。
	 */
	public function handleOutsideClick():Void
	{
		if (dismissOnOutsideClick) animateOutAndClose();
	}

	/** 面板滑出结束后调用；默认直接关闭自己 */
	public function closePanel():Void
	{
		close();
	}

	/** 面板顶部的标题。默认取第一个分组的标题；子类想要个总标题就重写它。 */
	public function getPageTitle():String
	{
		if (entries.length == 0 || entries[0] == null) return '';
		return entries[0].title;
	}

	/** 面板顶部的说明文字 */
	public function getPageDescription():String
	{
		if (entries.length == 0 || entries[0] == null) return '';
		return entries[0].description;
	}

	/** 把面板标题 / 说明写成某个分组的（entry 为 null 时用 getPageTitle/getPageDescription） */
	function applyHeaderText(?entry:PanelEntry):Void
	{
		if (panelTitle == null) return;

		var t:String = (entry != null) ? entry.title : getPageTitle();
		var d:String = (entry != null) ? entry.description : getPageDescription();

		panelTitle.text = (t != null) ? t : '';
		panelDesc.text = (d != null) ? d : '';
	}

	// =========================================================
	// 构建
	// =========================================================
	function createPanelUI():Void
	{
		// ---------- 遮罩：面板不是整屏时挡在左边 ----------
		dim = new Rect(0, 0, FlxG.width, FlxG.height, 0, 0, Theme.overlay(), 0);
		dim.scrollFactor.set();
		add(dim);

		// ---------- 面板底 ----------
		// 全部按"最终位置"创建，滑动效果由 applyPanelOffset() 统一加 panelOffset 实现
		panelBG = new Rect(panelX, 0, panelW, FlxG.height, 0, 0, Theme.panelBG(), 0);
		panelBG.scrollFactor.set();
		add(panelBG);

		contentGroup = new FlxSpriteGroup();
		// 内容层用面板坐标（scrollFactor = 0）：命中区就是元素自身坐标，不受相机 scroll 影响。
		// 设一次就够 —— 之后 add() 进来的行由 preAdd 继承，行再传给自己的标题与控件。
		contentGroup.scrollFactor.set();
		add(contentGroup);

		// 标题区画在内容之后 → 内容往上滚时会"钻"到标题下面（等于裁剪）
		panelHeader = new Rect(panelX, 0, panelW, HEADER_H, 0, 0, Theme.panelHeader(), 0);
		panelHeader.scrollFactor.set();
		add(panelHeader);

		// 返回按钮在左（12 + 40 + 8 = 60），标题从它右边开始，右侧只留一个内边距
		backBaseX = panelX + 12;
		titleBaseX = panelX + 60;

		var titleW:Float = panelW - 60 - PANEL_PAD;

		panelTitle = new FlxText(titleBaseX, 20, titleW, '', 20);
		panelTitle.setFormat(Paths.font('montserrat.ttf'), 20, Theme.text(), LEFT);
		panelTitle.borderStyle = NONE;
		panelTitle.antialiasing = ClientPrefs.data.antialiasing;
		panelTitle.scrollFactor.set();
		add(panelTitle);

		panelDesc = new FlxText(titleBaseX, 48, titleW, '', 11);
		panelDesc.setFormat(Paths.font('montserrat.ttf'), 11, Theme.textSecondary(), LEFT);
		panelDesc.borderStyle = NONE;
		panelDesc.antialiasing = ClientPrefs.data.antialiasing;
		panelDesc.scrollFactor.set();
		add(panelDesc);

		backBtn = new PanelIconButton(backBaseX, 14, 40, 40, function() {
			onBackAction();
		});
		backBtn.scrollFactor.set();
		add(backBtn);

		// ---------- 底部说明栏 ----------
		footerBG = new Rect(panelX, FlxG.height - FOOTER_H, panelW, FOOTER_H, 0, 0, Theme.panelHeader(), 0);
		footerBG.scrollFactor.set();
		add(footerBG);

		footerDivider = new Rect(panelX, FlxG.height - FOOTER_H, panelW, 1, 0, 0, Theme.divider(), 0);
		footerDivider.scrollFactor.set();
		add(footerDivider);

		footerBaseX = panelX + PANEL_PAD + 2;

		footerText = new FlxText(footerBaseX, 0, panelW - PANEL_PAD * 2 - 4, '', 12);
		footerText.setFormat(Paths.font('montserrat.ttf'), 12, Theme.accent(), LEFT);
		footerText.borderStyle = NONE;
		footerText.antialiasing = ClientPrefs.data.antialiasing;
		footerText.y = FlxG.height - FOOTER_H + 10;
		footerText.scrollFactor.set();
		add(footerText);

		// 下拉弹层挂在这里，同样要面板坐标（理由见上面 contentGroup 那段）
		overlayContainer = new FlxSpriteGroup();
		overlayContainer.scrollFactor.set();
		add(overlayContainer);

		buildScroller();

		// 初始状态：面板整体停在屏幕右边外面
		//（不需要淡入 —— 这个位置整个面板都在屏幕外，看不见，纯滑动就是真 Win8 的效果）
		panelSlide.value = panelW;
		applyPanelOffset();
	}

	/**
	 * 把 panelOffset 套用到面板的所有元素上。
	 * contentGroup 是 FlxSpriteGroup，给它的 x 赋值会以"增量"方式传播到所有行，
	 * 所以这里只要给绝对偏移即可，不用逐行处理。
	 */
	function applyPanelOffset():Void
	{
		panelOffset = panelSlide.value;

		if (panelBG != null) panelBG.x = panelX + panelOffset;
		if (panelHeader != null) panelHeader.x = panelX + panelOffset;
		if (panelTitle != null) panelTitle.x = titleBaseX + panelOffset;
		if (panelDesc != null) panelDesc.x = titleBaseX + panelOffset;
		if (backBtn != null) backBtn.x = backBaseX + panelOffset;
		if (footerBG != null) footerBG.x = panelX + panelOffset;
		if (footerDivider != null) footerDivider.x = panelX + panelOffset;
		if (footerText != null) footerText.x = footerBaseX + panelOffset;
		if (contentGroup != null) contentGroup.x = panelOffset;
	}

	/** 面板整体滑入 / 滑出（targetOffset = 0 是最终位置，panelW 是屏幕外） */
	function slidePanel(targetOffset:Float, time:Float, ease:Float->Float, ?onDone:Void->Void):Void
	{
		FlxTween.cancelTweensOf(panelSlide);
		FlxTween.tween(panelSlide, {value: targetOffset}, time, {
			ease: ease,
			onUpdate: function(_) applyPanelOffset(),
			onComplete: function(_) {
				applyPanelOffset();
				if (onDone != null) onDone();
			}
		});
	}

	function buildScroller():Void
	{
		if (scroller != null)
		{
			remove(scroller, true);
			scroller = null;
		}

		scroller = new MouseMove(
			scrollHolder, 'value',
			[0, 0],
			[
				[panelX, FlxG.width],
				[HEADER_H, FlxG.height - FOOTER_H]
			],
			function()
			{
				scroll = scrollHolder.value;
				applyScroll();
			},
			true
		);
		scroller.infScroll = false;
		scroller.mouseWheelSensitivity = -1000.0;
		scroller.dragStartDelayMs = 100;
		scroller.dragStartDistance = 10;
		add(scroller);
	}

	// =========================================================
	// 重建
	// =========================================================
	/**
	 * 请求下一帧重建面板内容。
	 * 一定要在控件的回调里用它，而不是直接调 rebuildRows() ——
	 * 直接调会在控件自己的 update 里把它销毁掉。
	 */
	public function requestPanelRebuild():Void
	{
		if (pendingRebuild < 1) pendingRebuild = 1;
	}

	/** 请求下一帧重建整块内容（条目本身变了） */
	public function requestEntriesRebuild():Void
	{
		pendingRebuild = 2;
	}

	/** 重新声明内容（数量 / 条目变了）并重建 */
	public function rebuildEntries():Void
	{
		entries = buildEntries();
		if (entries == null) entries = [];

		clearPanelRows();
		rebuildRows();
		applyHeaderText();
	}

	/** 面板内容变了（比如某个选项切换后选项列表变了）→ 就地重建 */
	public function rebuildRows():Void
	{
		clearPanelRows();

		var rowW:Float = panelW - PANEL_PAD * 2;
		var widgetW:Float = Math.min(260, Math.max(160, rowW - 32));
		var curY:Float = HEADER_H + PANEL_PAD;

		var first:Bool = true;

		for (ei in 0...entries.length)
		{
			var e:PanelEntry = entries[ei];
			if (e == null) continue;

			var hasOptions:Bool = (e.options != null && e.options.length > 0);
			var hasAction:Bool = (e.action != null);
			if (!hasOptions && !hasAction) continue;

			// 有选项 → 先铺一条分组小标题，再逐条排控件行
			if (hasOptions)
			{
				if (!first) curY += SECTION_GAP;
				first = false;

				var section:OptionSection = new OptionSection(panelX + PANEL_PAD, curY, rowW, ei, e.id,
					e.title);
				section.setRowMeta(curY, OptionSection.SECTION_H);
				sections.push(section);
				contentGroup.add(section);

				curY += OptionSection.SECTION_H;

				for (opt in e.options)
				{
					if (opt == null) continue;
					var w:FlxSpriteGroup = makeWidget(opt, widgetW);
					if (w == null) continue;
					curY = pushRow(opt, w, rowW, curY);
				}
			}

			// 有动作（且没选项）→ 直接渲染成一行按钮
			if (hasAction)
			{
				if (!first) curY += SECTION_GAP;
				first = false;

				var actOpt:PanelOption = makeActionOption(e);
				var actW:FlxSpriteGroup = makeWidget(actOpt, widgetW);
				if (actW != null) curY = pushRow(actOpt, actW, rowW, curY);
			}
		}

		var contentH:Float = (rows.length > 0 || sections.length > 0) ? (curY - HEADER_H - PANEL_PAD - ROW_GAP) : 0;
		// 可视高度要去掉底部的说明栏
		var viewH:Float = FlxG.height - HEADER_H - FOOTER_H - PANEL_PAD * 2;
		maxScroll = Math.max(0, contentH - viewH);

		scroll = FlxMath.bound(scroll, 0, maxScroll);
		scrollHolder.value = scroll;

		if (scroller != null)
		{
			scroller.moveLimit = [0, maxScroll];
			scroller.velocity = 0;
		}

		var lastRow:Int = rows.length - 1;
		if (lastRow < 0) lastRow = 0;
		if (selectedRow > lastRow) selectedRow = lastRow;
		if (selectedRow < 0) selectedRow = 0;

		applyScroll();
		updateSelectionVisual();
	}

	/**
	 * 造选项控件。
	 * 开了 largeActionButtons 时 ACTION 用更大的按钮 —— 宽度仍取 widgetW，
	 * 好跟同列其它控件的宽度对齐。
	 */
	function makeWidget(opt:PanelOption, widgetW:Float):FlxSpriteGroup
	{
		if (largeActionButtons && opt.type == ACTION)
			return WidgetFactory.createActionButton(opt, widgetW, ACTION_BTN_H);
		return WidgetFactory.create(opt, overlayContainer, widgetW);
	}

	/** 造一行并挂进 contentGroup，返回下一行的 y */
	function pushRow(opt:PanelOption, widget:FlxSpriteGroup, rowW:Float, curY:Float):Float
	{
		var row:OptionRow = new OptionRow(panelX + PANEL_PAD, curY, rowW, ROW_H, opt, widget);
		row.setRowMeta(curY, ROW_H);
		rows.push(row);
		contentGroup.add(row);
		return curY + ROW_H + ROW_GAP;
	}

	/**
	 * 给"只有动作、没有选项"的条目造一个能喂给 OptionButton 的 PanelOption。
	 * 它不读也不写 ClientPrefs，值恒为 null。
	 */
	function makeActionOption(entry:PanelEntry):PanelOption
	{
		var label:String = (entry.actionLabel != null && entry.actionLabel != '') ? entry.actionLabel : 'Open';

		var opt:PanelOption = new PanelOption(entry.title, entry.id, ACTION, null, entry.description);
		opt.actionLabel = label;
		opt.action = entry.action;
		return opt;
	}

	function clearPanelRows():Void
	{
		for (r in rows)
		{
			FlxTween.cancelTweensOf(r);
			contentGroup.remove(r, true);
			r.destroy();
		}
		rows = [];

		for (s in sections)
		{
			FlxTween.cancelTweensOf(s);
			contentGroup.remove(s, true);
			s.destroy();
		}
		sections = [];

		scroll = 0;
		scrollHolder.value = 0;
		maxScroll = 0;
		hoveredRow = -1;
		updateFooterText();
	}

	// =========================================================
	// 滚动 / 选中
	// =========================================================
	function applyScroll():Void
	{
		scroll = FlxMath.bound(scrollHolder.value, 0, maxScroll);
		scrollHolder.value = scroll;

		var viewTop:Float = HEADER_H;
		var viewBottom:Float = FlxG.height - FOOTER_H;

		for (s in sections)
		{
			s.y = s.baseY - scroll;
			var vis:Bool = (s.y + s.rowH > viewTop) && (s.y < viewBottom);
			s.visible = vis;
			s.active = vis;
		}

		for (i in 0...rows.length)
		{
			var row:OptionRow = rows[i];
			row.y = row.baseY - scroll;

			var visible:Bool = (row.y + row.rowH > viewTop) && (row.y < viewBottom);
			row.visible = visible;
			row.active = visible;
		}
	}

	function updateSelectionVisual():Void
	{
		for (i in 0...rows.length)
			rows[i].setSelected(i == selectedRow);

		updateFooterText();
	}

	/**
	 * 底部说明栏：优先显示鼠标悬停那一行，没有悬停就显示键盘选中那一行。
	 */
	function updateFooterText():Void
	{
		if (footerText == null) return;

		var opt:PanelOption = null;
		if (hoveredRow >= 0 && hoveredRow < rows.length) opt = rows[hoveredRow].option;
		else if (selectedRow >= 0 && selectedRow < rows.length) opt = rows[selectedRow].option;

		footerText.text = (opt != null && opt.description != null) ? opt.description : '';
	}

	/** 找出鼠标当前悬停在哪一行（只更新说明栏，不抢键盘选中） */
	function updateHoveredRow():Void
	{
		var idx:Int = -1;

		if (!WidgetFactory.popupOpen && rows.length > 0)
		{
			// 面板自己的悬停判定必须和控件的命中判定用同一套坐标 —— 就是 Input 那个空间，
			// 否则两边会对不上。
			var mx:Float = Input.mouseX();
			var my:Float = Input.mouseY();

			if (mx >= panelX && mx <= panelX + panelW && my >= HEADER_H && my < FlxG.height - FOOTER_H)
			{
				for (i in 0...rows.length)
				{
					var r:OptionRow = rows[i];
					if (!r.visible || !r.active) continue;
					if (my >= r.y && my <= r.y + r.rowH)
					{
						idx = i;
						break;
					}
				}
			}
		}

		if (idx != hoveredRow)
		{
			hoveredRow = idx;
			updateFooterText();
		}
	}

	/** 把某一行滚进可视区 */
	function scrollRowIntoView(index:Int):Void
	{
		if (index < 0 || index >= rows.length) return;

		var top:Float = rows[index].baseY - HEADER_H;
		var bottom:Float = top + ROW_H;
		var viewH:Float = FlxG.height - HEADER_H - FOOTER_H - PANEL_PAD;

		var target:Float = scroll;
		if (top < target) target = top;
		else if (bottom > target + viewH) target = bottom - viewH;

		target = FlxMath.bound(target, 0, maxScroll);

		if (scroller != null) scroller.tweenData = target;
		else
		{
			scrollHolder.value = target;
			applyScroll();
		}
	}

	public function changeRowSelection(delta:Int):Void
	{
		if (rows.length == 0) return;

		var old:Int = selectedRow;
		selectedRow = FlxMath.wrap(selectedRow + delta, 0, rows.length - 1);
		if (selectedRow == old) return;

		updateSelectionVisual();
		scrollRowIntoView(selectedRow);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	// =========================================================
	// 键盘操作（控件本身是鼠标驱动的，这里补上键盘支持）
	// =========================================================
	/** 当前选中的选项 */
	public function selectedOption():PanelOption
	{
		if (selectedRow < 0 || selectedRow >= rows.length) return null;
		return rows[selectedRow].option;
	}

	/** 调整当前选中项的值；dir = -1 / +1 */
	public function adjustSelected(dir:Int):Void
	{
		var opt:PanelOption = selectedOption();
		if (opt == null) return;

		switch (opt.type)
		{
			case BOOL:
				opt.setValue(!(opt.getValue() == true));
			case INT, FLOAT, PERCENT:
				var step:Float = Std.parseFloat(Std.string(opt.changeValue));
				if (Math.isNaN(step) || step == 0) step = 1;

				var v:Float = cast opt.getValue();
				v += dir * step;

				var lo:Dynamic = opt.minValue;
				var hi:Dynamic = opt.maxValue;
				if (lo != null && v < lo) v = lo;
				if (hi != null && v > hi) v = hi;

				opt.setValue(opt.type == INT ? Math.round(v) : FlxMath.roundDecimal(v, opt.decimals));
			case STRING:
				cycleString(opt, dir);
			case ACTION:
				return;
		}

		opt.change();
		opt.saveCurrentValue();
		refreshSelectedWidget();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	/** 回车：BOOL 切换、ACTION 执行、其它等同于往右调整一次 */
	public function activateSelected():Void
	{
		var opt:PanelOption = selectedOption();
		if (opt == null) return;

		switch (opt.type)
		{
			case ACTION:
				if (opt.action != null) opt.action();
				return;
			case BOOL:
				opt.setValue(!(opt.getValue() == true));
			case INT, FLOAT, PERCENT, STRING:
				adjustSelected(1);
				return;
		}

		opt.change();
		opt.saveCurrentValue();
		refreshSelectedWidget();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	/** 把当前选中项恢复默认值 */
	public function resetSelected():Void
	{
		var opt:PanelOption = selectedOption();
		if (opt == null) return;

		opt.setValue(opt.defaultValue);
		if (opt.type == STRING && opt.options != null)
		{
			var idx:Int = opt.options.indexOf(Std.string(opt.getValue()));
			opt.curOption = idx < 0 ? 0 : idx;
		}
		opt.change();
		opt.saveCurrentValue();
		refreshSelectedWidget();
		FlxG.sound.play(Paths.sound('cancelMenu'), 0.4);
	}

	function refreshSelectedWidget():Void
	{
		if (selectedRow < 0 || selectedRow >= rows.length) return;
		WidgetFactory.refreshValue(rows[selectedRow].widget);
	}

	/** 收掉所有行上展开的下拉弹层 */
	function closeRowPopups():Void
	{
		for (r in rows)
			WidgetFactory.closePopup(r.widget);
	}

	function cycleString(opt:PanelOption, dir:Int):Void
	{
		if (opt.options == null || opt.options.length == 0) return;

		var idx:Int = opt.options.indexOf(Std.string(opt.getValue()));
		if (idx < 0) idx = opt.curOption;
		idx = FlxMath.wrap(idx + dir, 0, opt.options.length - 1);

		opt.curOption = idx;
		opt.setValue(opt.options[idx]);
	}

	/** 统一开关面板里控件的鼠标响应（动画过程中关掉，避免误触） */
	function setWidgetsEnabled(v:Bool):Void
	{
		for (r in rows)
			if (r.option != null) r.option.allowUpdate = v;

		// 标题栏的返回按钮也要一起关，否则滑入滑出的过程中能被点到
		if (backBtn != null) backBtn.setInputEnabled(v);
	}

	// =========================================================
	// 动画
	// =========================================================
	public function startIntro():Void
	{
		isAnimating = true;
		setWidgetsEnabled(false);

		dim.alpha = 0;
		FlxTween.tween(dim, {alpha: Theme.overlayAlpha()}, ANIM_IN, {ease: FlxEase.quadOut});

		// 面板从屏幕右边外面滑到贴右位置。
		// 不需要淡入：offset = panelW 时整个面板（含所有行）都在屏幕外，看不见。
		panelVisible = true;
		panelSlide.value = panelW;
		applyPanelOffset();

		slidePanel(0, ANIM_IN, FlxEase.quartOut, function() {
			isAnimating = false;
			setWidgetsEnabled(true);
		});
	}

	/** 面板滑出并结束 */
	public function animateOutAndClose():Void
	{
		if (closing) return;
		closing = true;
		setWidgetsEnabled(false);

		FlxTween.tween(dim, {alpha: 0}, ANIM_OUT, {ease: FlxEase.quadOut});
		slidePanel(panelW, ANIM_OUT, FlxEase.quartIn, function() {
			closePanel();
		});
	}

	// =========================================================
	// 更新
	// =========================================================
	override function update(elapsed:Float)
	{
		// 待重建（控件回调里请求的，延后到这里做）
		if (pendingRebuild > 0)
		{
			var mode:Int = pendingRebuild;
			pendingRebuild = 0;
			if (mode == 2) rebuildEntries();
			else rebuildRows();
		}

		// 有下拉展开时滚轮归下拉用；面板收起时滚轮也不该驱动屏外的列表。
		// suspendScroll 由控件（NumButton 拖滑块）写、这里读后清掉 ——
		// 否则拖数值条的同时会把列表一起拖动。
		var suspend:Bool = WidgetFactory.suspendScroll;
		WidgetFactory.suspendScroll = false;

		if (scroller != null)
			scroller.inputAllow = !WidgetFactory.popupOpen && panelVisible && !suspend;

		super.update(elapsed);

		// 面板滚动条当前速度同步给控件：NumButton 靠它判断"现在是在滚面板还是在拖滑块"
		WidgetFactory.scrollVelocity = (scroller != null) ? scroller.velocity : 0;

		if (scrollHolder.value != scroll)
			scrollHolder.value = scroll;

		if (isAnimating || closing) return;

		// ---------- 返回：ESC / 右键 / 顶部返回按钮走同一条路 ----------
		if (controls.BACK || FlxG.mouse.justPressedRight)
		{
			onBackAction();
			return;
		}

		// ---------- 键盘 ----------
		// 换行前先收掉展开的下拉：行一旦滚出可视区就会被置 active = false，
		// 里面的控件跟着停更，弹层会永远停在原地收不掉。
		if (controls.UI_DOWN_P || controls.UI_UP_P)
		{
			closeRowPopups();
			changeRowSelection(controls.UI_DOWN_P ? 1 : -1);
		}

		// 有下拉展开时左右/回车/重置都归下拉用（跟鼠标那边一致），
		// 免得一边开着弹层一边把值改掉、弹层里显示的却还是旧列表。
		if (!WidgetFactory.popupOpen && rows.length > 0)
		{
			if (controls.UI_LEFT_P) adjustSelected(-1);
			if (controls.UI_RIGHT_P) adjustSelected(1);
			if (controls.ACCEPT) activateSelected();
			if (controls.RESET) resetSelected();
		}

		// ---------- 鼠标：悬停更新底部说明 / 点击选中行 ----------
		updateHoveredRow();

		if (FlxG.mouse.justPressed && hoveredRow >= 0 && hoveredRow != selectedRow && !WidgetFactory.popupOpen)
		{
			selectedRow = hoveredRow;
			updateSelectionVisual();
		}

		// ---------- 点空白处 ----------
		// !WidgetFactory.popupOpen 是必须的：下拉弹层挂在 overlayContainer 上，
		// 可能向左伸出 panelX，没有这个判断会"点自己的下拉却把整个面板关掉"。
		if (FlxG.mouse.justPressed && !WidgetFactory.popupOpen && isOutsideUI(Input.mouseX(), Input.mouseY()))
		{
			handleOutsideClick();
		}
	}

	/** 鼠标是否在面板之外（点这里 = 收起） */
	function isOutsideUI(mx:Float, my:Float):Bool
	{
		// 面板占满屏宽时根本没有"外面"
		if (panelW >= FlxG.width) return false;
		return (mx < panelX || mx >= panelX + panelW);
	}

	override function destroy()
	{
		Input.unbind(this);
		super.destroy();
	}
}

// =========================================================
// 面板条目
// =========================================================
typedef PanelEntry = {
	/** 唯一 id（也用作 ACTION 选项的 variable） */
	var id:String;
	/** 标题（分组小标题 / 单条动作行的标题） */
	var title:String;
	/** 说明文字（面板标题下面那行，以及底部说明栏） */
	var description:String;
	/** 分组里的选项；为空时看 action */
	var options:Array<PanelOption>;
	/** 有它且没有 options 时，这一条会渲染成一个动作按钮 */
	@:optional var action:Void->Void;
	/** 动作按钮上的文字（不填就用 "Open"） */
	@:optional var actionLabel:String;
}
