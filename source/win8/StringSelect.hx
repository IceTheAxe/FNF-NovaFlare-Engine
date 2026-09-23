package win8;

import openfl.display.BitmapData;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

/**
 * 字符串选项的下拉条（Win8 风格：方角 + 2px 描边）。
 *
 * 展开的下拉弹层默认挂在 overlay 上（面板的浮层容器），这样它不会被行的裁剪/滚动切掉。
 * 开关弹层时会同步 WidgetFactory.popupOpen，面板据此决定要不要把滚动和"点外部关闭"让给弹层。
 */
class StringSelect extends FlxSpriteGroup
{
	/**
	 * 当前展开着的下拉数量。
	 *
	 * 用计数而不是布尔：面板重建行时旧控件会 destroy()，只存一个 Bool 的话，
	 * 关掉其中一个就会把"还有别的开着"这件事一起抹掉。计数能自愈。
	 */
	static var openCount:Int = 0;

	var follow:PanelOption;

	var bg:Rect;          // 当前值的条
	var border:FlxSprite; // Win8 描边
	var dis:FlxText;

	var popup:FlxSpriteGroup;   // 展开的下拉
	var popupBg:Rect;
	var popupBorder:FlxSprite;
	var popupItems:Array<Rect> = [];
	var popupTexts:Array<FlxText> = [];

	var overlay:FlxSpriteGroup;

	public var isOpen(default, set):Bool = false;

	var mainW:Float;
	var mainH:Float;

	// 状态
	var hover:Bool = false;
	var pressing:Bool = false;

	// 下拉项尺寸 / 边缘留白
	static inline var ITEM_H:Float = 32.0;
	static inline var EDGE_MARGIN:Float = 4.0;

	// 手动绘制的箭头
	var arrowGfx:FlxSprite;

	public function new(X:Float, Y:Float, width:Float, height:Float, follow:PanelOption, ?overlay:FlxSpriteGroup)
	{
		super(X, Y);

		this.follow = follow;
		this.overlay = overlay;
		mainW = width;
		mainH = height;

		bg = new Rect(0, 0, width, height, 0, 0, Theme.face(), 1);
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		// 描边统一走 Theme.makeFrameSprite 自绘：shapeEx.Rect 的 lineStyle 有静态共享缓存的坑（多处描边会串色）
		border = Theme.makeFrameSprite(width, height);
		border.color = borderColor();
		add(border);

		dis = new FlxText(10, 0, width - 30, '', 16);
		dis.setFormat(Paths.font('montserrat.ttf'), 16, textColor(), LEFT);
		dis.borderStyle = NONE;
		dis.antialiasing = ClientPrefs.data.antialiasing;
		dis.y = (height - dis.height) * 0.5;
		add(dis);

		arrowGfx = new FlxSprite();
		arrowGfx.antialiasing = ClientPrefs.data.antialiasing;
		arrowGfx.x = width - arrowGfx.width - 16;
		arrowGfx.y = height * 0.4;
		add(arrowGfx);
		redrawArrow();

		refreshValue();

		popup = new FlxSpriteGroup();
		popup.visible = false;
		popup.x = this.x;
		popup.y = this.y + height + 4;

		if (overlay != null)
			overlay.add(popup);
		else
			add(popup);
	}

	function set_isOpen(v:Bool):Bool
	{
		if (isOpen == v) return v;
		isOpen = v;

		if (v) openCount++;
		else if (openCount > 0) openCount--;

		WidgetFactory.popupOpen = (openCount > 0);

		return v;
	}

	inline function accentColor():FlxColor
		return Theme.accent();

	inline function mainTextColor():FlxColor
		return Theme.text();

	inline function popupBGColor():FlxColor
		return Theme.panelBG();

	inline function popupItemColor():FlxColor
		return Theme.railHover();

	inline function iconColor():FlxColor
		return Theme.textSecondary();

	inline function textColor():FlxColor
		return (hover || isOpen) ? accentColor() : mainTextColor();

	function borderColor():FlxColor
		return (hover || isOpen) ? Theme.accent() : Theme.border();

	public function refreshValue():Void
	{
		var v:Dynamic = follow.getValue();
		dis.text = follow.getOptionText(v);
		dis.color = textColor();
		if (border != null) border.color = borderColor();
	}

	/** 下拉可视行数：显示全部选项 */
	function visibleRows():Int
	{
		var opts:Array<String> = follow.options;
		if (opts == null) return 0;
		return opts.length;
	}

	function getPopupHeight():Float
	{
		var n:Int = visibleRows();
		if (n <= 0) return 0;
		return n * ITEM_H + 8;
	}

	/**
	 * 把所有下拉项摆回"全部可见"的位置。
	 *
	 * ⚠️ FlxSpriteGroup 的成员坐标是**绝对**的：`popup.add(x)` 时 preAdd 已经把 popup 自己的
	 * x/y 加进了成员的 x/y，而 FlxSpriteGroup.draw() 只是逐个 `member.draw()`，
	 * 绘制时**不会**再叠加父级偏移。
	 * 所以这里必须写 `popup.y + 局部Y`；直接写局部 Y 会让整列文字/高亮跑到屏幕顶部
	 * （背景块位置正确、内容却飞到最上面，就是这个原因）。
	 */
	function applyPopupScroll():Void
	{
		var oy:Float = (popup != null) ? popup.y : 0;

		for (i in 0...popupItems.length)
		{
			var y:Float = oy + 4 + i * ITEM_H;

			popupItems[i].y = y;
			if (i < popupTexts.length)
				popupTexts[i].y = y + (ITEM_H - popupTexts[i].height) * 0.5;

			popupItems[i].visible = true;
			if (i < popupTexts.length) popupTexts[i].visible = true;
		}
	}

	function syncPopupPosition():Void
	{
		if (popup == null) return;

		var popupH:Float = getPopupHeight();
		if (popupH <= 0) return;

		var viewX:Float = this.x;
		var viewY:Float;

		var belowY:Float = this.y + mainH + 4;
		var aboveY:Float = this.y - popupH - 4;
		var maxBottom:Float = FlxG.height - EDGE_MARGIN;

		if (belowY + popupH <= maxBottom)
		{
			// 1. 下方放得下
			viewY = belowY;
		}
		else if (aboveY >= EDGE_MARGIN)
		{
			// 2. 上方放得下
			viewY = aboveY;
		}
		else
		{
			// 3. 上下都放不下 → 直接盖在控件上，居中并夹取到屏幕内
			viewY = this.y + mainH * 0.5 - popupH * 0.5;
			if (viewY + popupH > maxBottom)
				viewY = maxBottom - popupH;
			if (viewY < EDGE_MARGIN)
				viewY = EDGE_MARGIN;
		}

		// 水平方向夹取
		if (viewX + mainW > FlxG.width - EDGE_MARGIN)
			viewX = FlxG.width - mainW - EDGE_MARGIN;
		if (viewX < EDGE_MARGIN)
			viewX = EDGE_MARGIN;

		// popup 的子元素坐标是绝对的（preAdd 已把 popup 自身的 x/y 加进去，绘制时不再叠加父级），
		// 所以不管挂在 overlay 还是挂在 this 上，这里统一写**绝对坐标**即可，
		// 不能再减一次 this.x / this.y（会少偏移一次）。
		popup.x = viewX;
		popup.y = viewY;
	}

	function redrawArrow():Void
	{
		var size:Float = mainH * 0.18;
		var thickness:Float = Math.max(1.5, mainH * 0.05);
		var w:Int = Std.int(size * 2 + thickness + 2);
		var h:Int = Std.int(size + thickness + 2);

		var bmd:BitmapData = new BitmapData(w, h, true, 0x00000000);

		var cx:Float = w * 0.5;
		var cy:Float = h * 0.5;
		var dir:Float = isOpen ? -1.0 : 1.0;

		var c:FlxColor = (hover || isOpen) ? accentColor() : iconColor();

		drawThickLine(bmd,
			cx - size, cy - size * 0.4 * dir,
			cx,        cy + size * 0.4 * dir,
			thickness, c);

		drawThickLine(bmd,
			cx,        cy + size * 0.4 * dir,
			cx + size, cy - size * 0.4 * dir,
			thickness, c);

		arrowGfx.pixels = bmd;
		arrowGfx.offset.set(0, 0);
		arrowGfx.origin.set(0, 0);
		arrowGfx.scale.set(1, 1);
		arrowGfx.updateHitbox();
	}

	function drawThickLine(bmd:BitmapData,
		x1:Float, y1:Float, x2:Float, y2:Float,
		thickness:Float, color:FlxColor):Void
	{
		var dx:Float = x2 - x1;
		var dy:Float = y2 - y1;
		var len:Float = Math.sqrt(dx * dx + dy * dy);
		if (len == 0) return;
		var nx:Float = dx / len;
		var ny:Float = dy / len;
		var half:Float = thickness * 0.5;

		var steps:Int = Std.int(len);
		for (i in 0...steps + 1)
		{
			var t:Float = i / steps;
			var px:Float = x1 + dx * t;
			var py:Float = y1 + dy * t;
			var perpX:Float = -ny;
			var perpY:Float = nx;
			for (j in 0...Std.int(thickness) + 1)
			{
				var off:Float = -half + j;
				var fx:Int = Std.int(px + perpX * off);
				var fy:Int = Std.int(py + perpY * off);
				if (fx >= 0 && fy >= 0 && fx < bmd.width && fy < bmd.height)
					bmd.setPixel32(fx, fy, color);
			}
		}
	}

	/**
	 * 清空下拉弹层里的旧成员。
	 *
	 * 注意：不能在遍历 `popup.members` 的同时 `remove`（splice 会就地删元素，
	 * 结果隔一个漏一个，旧项会残留在弹层里变成幽灵行）。
	 * 另外必须把 popupBg / popupBorder 置空 —— 它们已经被 destroy，
	 * 留着非 null 引用会被 update() 里的 `Input.overlaps(popupBg)` 拿去用，
	 * 触发 Null Object Reference。
	 */
	function clearPopup():Void
	{
		if (popup == null) return;

		var old:Array<FlxSprite> = popup.members.copy();
		for (m in old)
		{
			if (m == null) continue;
			popup.remove(m, true);
			m.destroy();
		}

		popupItems = [];
		popupTexts = [];
		popupBg = null;
		popupBorder = null;
	}

	function buildPopup():Void
	{
		clearPopup();

		var opts:Array<String> = follow.options;
		if (opts == null) return;

		var popupW:Float = mainW;
		var popupH:Float = getPopupHeight();

		popupBg = new Rect(0, 0, popupW, popupH, 0, 0, popupBGColor(), 1);
		popupBg.antialiasing = ClientPrefs.data.antialiasing;
		popup.add(popupBg);

		popupBorder = Theme.makeFrameSprite(popupW, popupH);
		popupBorder.color = Theme.border();
		popup.add(popupBorder);

		for (i in 0...opts.length)
		{
			var item:Rect = new Rect(4, 4 + i * ITEM_H, popupW - 8, ITEM_H, 0, 0, popupItemColor(), 0);
			item.antialiasing = ClientPrefs.data.antialiasing;
			popup.add(item);
			popupItems.push(item);

			var t:FlxText = new FlxText(12, 4 + i * ITEM_H, popupW - 24, follow.getOptionText(opts[i]), 15);
			t.setFormat(Paths.font('montserrat.ttf'), 15, mainTextColor(), LEFT);
			t.borderStyle = NONE;
			t.antialiasing = ClientPrefs.data.antialiasing;
			popup.add(t);
			popupTexts.push(t);
		}

		applyPopupScroll();
	}

	function computeMainColor():FlxColor
	{
		return pressing ? Theme.facePress() : (hover ? Theme.faceHover() : Theme.face());
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		syncPopupPosition();

		if (!follow.allowUpdate) return;

		var mouse = FlxG.mouse;

		// 鼠标在下拉弹层上时，主条不再抢悬停（避免覆盖时误判）
		var overPopup:Bool = isOpen && popup.visible && popupBg != null && Input.overlaps(popupBg);

		// ---- 主条悬浮 / 按下反馈 ----
		var wasHover:Bool = hover;
		hover = Input.overlaps(bg) && !overPopup;

		if (hover != wasHover)
		{
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 0.12, bg.color, computeMainColor(), {ease: FlxEase.quadOut});
			redrawArrow();
			refreshValue();
		}

		// 点击主条
		if (hover && mouse.justPressed)
		{
			pressing = true;
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 0.05, bg.color, computeMainColor());
		}

		// 本帧刚打开下拉时，消费这次释放事件，防止同一次点击被下拉项再次处理
		var openedThisFrame:Bool = false;

		if (mouse.justReleased && pressing && hover)
		{
			pressing = false;
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 0.1, bg.color, computeMainColor(), {ease: FlxEase.quadOut});

			isOpen = !isOpen;
			if (isOpen)
			{
				buildPopup();
				syncPopupPosition();
				popup.visible = true;
				openedThisFrame = true;
			}
			else
			{
				popup.visible = false;
			}
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);

			redrawArrow();
			refreshValue();
		}

		if (!hover && pressing)
		{
			pressing = false;
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 0.1, bg.color, computeMainColor(), {ease: FlxEase.quadOut});
		}

		// ---- 下拉项反馈 ----
		if (!isOpen) return;
		if (openedThisFrame) return; // 打开那一帧不处理，避免误触

		for (i in 0...popupItems.length)
		{
			var it:Rect = popupItems[i];
			var itHover:Bool = Input.overlaps(it);

			it.alpha = itHover ? 1.0 : 0.0;

			if (itHover && mouse.justReleased)
			{
				follow.setValue(follow.options[i]);
				follow.curOption = i;
				follow.change();
				follow.saveCurrentValue();
				refreshValue();
				isOpen = false;
				popup.visible = false;
				redrawArrow();
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);
				return;
			}
		}

		// 点外面关闭（主条和弹窗都不算外面）
		if (mouse.justPressed && !Input.overlaps(bg) && !overPopup)
		{
			isOpen = false;
			popup.visible = false;
			redrawArrow();
			refreshValue();
		}
	}

	/** 关闭下拉（键盘切到别的行、面板开始滚动时用） */
	public function closePopup():Void
	{
		if (!isOpen) return;
		isOpen = false;
		if (popup != null) popup.visible = false;
		redrawArrow();
		refreshValue();
	}

	/**
	 * 下拉弹层挂在 overlay 上，销毁时如果不手动清掉，会残留在外层容器里继续渲染。
	 * 顺带把 openCount 还回去 —— 否则控件销毁后 popupOpen 会永远卡在 true，
	 * 面板的滚动和"点外部关闭"就再也回不来了。
	 */
	override function destroy():Void
	{
		if (isOpen) isOpen = false;

		// overlay.members == null 说明外层容器已经先销毁了（那时 popup 也被它一起销毁过），
		// 不能再 remove / destroy 第二遍。
		if (popup != null && overlay != null && overlay.members != null)
		{
			overlay.remove(popup, true);
			popup.destroy();
		}
		popup = null;
		super.destroy();
	}
}
