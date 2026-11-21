package win8;

import openfl.display.BitmapData;

/**
 * 数值控件（Win8 滑块 + ± 步进按钮）。
 *
 * 布局照 NF 主设置的 NumButton：左右两个步进按钮夹住轨道，值文本在右 ——
 * 点 ± 步进一格（步长 = changeValue），按住不放先憋一小会再连发；轨道点击直接跳转，
 * 按住滑块（+它的外扩热区）拖动连续改值。
 *
 * ± 按钮用 Win8 风格绘制：Metro 方角 + 2px 描边 + faceHover/facePress 配色反馈，
 * 符号是自绘线条（不搬 NF 主设置的红绿圆角位图）。
 *
 * 已填充部分的长度靠**裁窄源帧**实现：`_frame` 是每个精灵自己的帧副本
 * （FlxSprite.set_frame 里走 `FlxFrame.copyTo`，其中 frame 矩形是深拷贝），
 * 所以直接改 `moveDis._frame.frame.width` 只影响这一个 Rect，不会串到同尺寸的别的 Rect 上。
 */
class NumButton extends FlxSpriteGroup
{
	/** ± 步进按钮边长 */
	static inline var BTN:Float = 22;
	/** 布局间隙 */
	static inline var GAP:Float = 6;
	/** 按住多久开始连发 / 连发间隔（FE KEOption 与 NF 主设置的节奏） */
	static inline var HOLD_DELAY:Float = 0.35;
	static inline var HOLD_REPEAT:Float = 0.07;

	var follow:PanelOption;

	public var moveBG:Rect;
	public var moveDis:Rect;
	public var rod:Rect;
	var minusBtn:StepperButton;
	var plusBtn:StepperButton;
	var valueText:FlxText;
	var valueTextWidth:Float = 64;
	/** 透明扩大的触控热区：轨道只有 3px 高，点跳转/悬停用它（拖滑块仍认 rod） */
	var hitArea:Rect;
	/** 滑块自己的外扩热区（跟 rod 一起动）：rod 只有 8px 宽，手指按不准它就没法微调 */
	var rodHit:Rect;

	var max:Float;
	var min:Float;

	/** 拖拽基准（命中判定空间的指针 X，Float —— Input.mouseX() 不是整数） */
	var lastMouseX:Float = 0;

	/** 正在拖动（鼠标按下且起始点在轨道/滑块上） */
	public var onFocus:Bool = false;

	var savePending:Bool = false;

	/** 键盘选中宿主行时由 OptionRow 置位：让滑块看起来和鼠标悬停一样（只参与配色） */
	public var keyboardHighlight:Bool = false;

	public function setKeyboardHighlight(v:Bool):Void
	{
		keyboardHighlight = v;
	}

	public function new(X:Float, Y:Float, width:Float, height:Float, follow:PanelOption)
	{
		super(X, Y);

		this.follow = follow;
		// min / max 是 Dynamic（有的选项不设），这里兜个底，免得后面算比例时除零
		this.min = (follow.minValue != null) ? cast follow.minValue : 0;
		this.max = (follow.maxValue != null) ? cast follow.maxValue : 1;

		var trackH:Float = 3;
		var rodH:Float = Math.min(height, 18);
		var rodW:Float = 8;

		// 透明扩大的触控热区：整个控件四周扩一圈（轨道只有 3px 高，移动端手指没法点）
		hitArea = new Rect(-Theme.TOUCH_PAD_X, -Theme.TOUCH_PAD_Y,
			width + Theme.TOUCH_PAD_X * 2, height + Theme.TOUCH_PAD_Y * 2, 0, 0, 0x00000000, 0);
		add(hitArea);

		// ---------- ± 步进按钮（NF 主设置同款布局，Win8 风格绘制） ----------
		var btnY:Float = (height - BTN) * 0.5;
		minusBtn = new StepperButton(0, btnY, BTN, false);
		add(minusBtn);

		// ---------- 轨道（夹在两按钮之间） ----------
		var trackX:Float = BTN + GAP;
		var trackW:Float = width - BTN * 2 - GAP * 3 - valueTextWidth;
		if (trackW < 40) trackW = 40; // 最窄兜底：值文本窄，挤压轨道比挤没了强

		moveBG = new Rect(trackX, 0, trackW, trackH, 0, 0, Theme.track(), 1.0);
		moveBG.y += (height - moveBG.height) / 2;
		add(moveBG);

		// 已填充部分：宽度不动，靠 rectUpdate() 裁源帧
		moveDis = new Rect(trackX, 0, trackW, trackH, 0, 0, Theme.accent(), 1.0);
		moveDis.y += (height - moveDis.height) / 2;
		add(moveDis);

		rod = new Rect(0, 0, rodW, rodH, 0, 0, Theme.knob(), 1.0);
		rod.y += (height - rod.height) / 2;
		add(rod);

		// 滑块的外扩热区：跟 rod 同位同动（update 里每帧同步），透明不画东西
		rodHit = new Rect(0, 0, rodW + Theme.TOUCH_PAD_X * 2, rodH + Theme.TOUCH_PAD_Y * 2,
			0, 0, 0x00000000, 0);
		rodHit.y = rod.y;
		add(rodHit);

		plusBtn = new StepperButton(trackX + trackW + GAP, btnY, BTN, true);
		add(plusBtn);

		valueText = new FlxText(0, 0, valueTextWidth, '', 12);
		valueText.setFormat(Theme.uiFont(), 12, Theme.text(), LEFT);
		valueText.borderStyle = NONE;
		valueText.antialiasing = ClientPrefs.data.antialiasing;
		valueText.y = (height - valueText.height) * 0.5;
		valueText.x = trackX + trackW + GAP + BTN + GAP;
		add(valueText);

		initData();
	}

	public function initData():Void
	{
		var curValue:Dynamic = follow.getValue();
		if (curValue == null) curValue = follow.defaultValue;
		var percent:Float = (max - min) == 0 ? 0 : (curValue - min) / (max - min);
		// 初始值也吸附一次，免得跟拖动后的取值口径不一致
		var stepped:Float = snapToStep(cast curValue, min, getStep());
		var outputData:Float = FlxMath.roundDecimal(stepped, follow.decimals);
		rectUpdate(percent, outputData);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!follow.allowUpdate) return;

		var mouse = FlxG.mouse;

		// ---------- 悬浮 / 按下 的颜色反馈 ----------
		// 轨道只有 3px 高：hover / 点跳转都认扩大的热区。
		// "按住滑块微调"认 rod + 它的外扩热区（rodHit）：触控板式手感 —— 按住附近开始拖，
		// 手指滑到哪都行，值随相对位移微调。
		var rodHitX:Float = rod.x;
		if (rodHit != null) rodHit.x = rodHitX;

		var hoverRod:Bool = Input.overlaps(rod) || Input.overlaps(rodHit);
		var hoverBG:Bool = Input.overlaps(hitArea);

		if (mouse.pressed && (onFocus || hoverRod || hoverBG))
			setRodColor(Theme.knobPress());
		else if (hoverRod || hoverBG || keyboardHighlight)
			setRodColor(Theme.knobHover());
		else
			setRodColor(Theme.knob());

		// ---------- ± 步进按钮：点击步进、按住连发（NF 主设置同款交互） ----------
		var minusHover:Bool = Input.overlaps(minusBtn.hitArea);
		var plusHover:Bool = Input.overlaps(plusBtn.hitArea);

		var minusHeld:Bool = minusHover && mouse.pressed;
		var plusHeld:Bool = plusHover && mouse.pressed;

		if (minusHeld)
		{
			WidgetFactory.suspendScroll = true;
			if (mouse.justPressed) stepValue(-1);
			else handleStepperRepeat(minusBtn, elapsed, -1);
		}
		else
		{
			minusBtn.holdTimer = 0;
			minusBtn.repeatTimer = 0;
		}
		minusBtn.setState(minusHover || keyboardHighlight, minusHeld);

		if (plusHeld)
		{
			WidgetFactory.suspendScroll = true;
			if (mouse.justPressed) stepValue(1);
			else handleStepperRepeat(plusBtn, elapsed, 1);
		}
		else
		{
			plusBtn.holdTimer = 0;
			plusBtn.repeatTimer = 0;
		}
		plusBtn.setState(plusHover || keyboardHighlight, plusHeld);

		// ---------- 轨道：点跳转 / 按住滑块拖动 ----------
		// 指针映射用的是"命中判定空间"的坐标（就是 FlxObject.overlapsPoint 里的 xPos，见 Input）。
		// 不能拿 FlxG.mouse.x —— 那是相对 FlxG.camera 的世界坐标，会被游戏相机的 scroll 推着走，
		// 和 moveBG.x（屏幕坐标）不在一个空间，点数值条会跳到错误的位置。
		if (mouse.justPressed && hoverRod)
		{
			onFocus = true;
			lastMouseX = Input.mouseX();
			WidgetFactory.suspendScroll = true;
		}
		// 落在 ± 按钮热区上的按下不算轨道跳转
		else if (mouse.justPressed && hoverBG && !hoverRod && !minusHover && !plusHover)
		{
			onFocus = true;
			jumpToPointer(Input.mouseX());
			lastMouseX = Input.mouseX();   // 防止下一帧 onHold 突跳
			WidgetFactory.suspendScroll = true;
		}

		if (mouse.justReleased && savePending)
		{
			follow.saveCurrentValue();
			savePending = false;
		}

		// 面板滚动惯性还没停时别跟着拖 —— 否则松手后列表滑一下会顺手把数值也改掉
		var inputAllow:Bool = Math.abs(WidgetFactory.scrollVelocity) <= 2;

		if (inputAllow)
		{
			if (onFocus && mouse.pressed) onHold();

			if (mouse.justReleased) onFocus = false;
		}
	}

	inline function setRodColor(color:FlxColor):Void
	{
		if (rod != null && rod.color != color)
			rod.color = color;
	}

	/** 按住 ± 时的连发：先憋 HOLD_DELAY，之后每 HOLD_REPEAT 步进一格（非 justPressed 的按住帧进来） */
	function handleStepperRepeat(btn:StepperButton, elapsed:Float, dir:Int):Void
	{
		btn.holdTimer += elapsed;
		if (btn.holdTimer <= HOLD_DELAY) return;

		btn.repeatTimer += elapsed;
		while (btn.repeatTimer >= HOLD_REPEAT)
		{
			btn.repeatTimer -= HOLD_REPEAT;
			stepValue(dir);
		}
	}

	/**
	 * ± 一步：步长用 changeValue（跟键盘连发同口径），没给就用 decimals 的最小精度。
	 * 每步 change()（GameplayChangers 的 onChange 这类都靠它触发）；
	 * 落盘走 savePending —— 松手时统一 saveCurrentValue，连发期间不反复写存档。
	 */
	function stepValue(dir:Float):Void
	{
		// Dynamic 先判 null 再转 Float —— hxcpp 里 cast null 到 Float 不安全
		var raw:Dynamic = follow.getValue();
		if (raw == null) raw = follow.defaultValue;
		var v:Float = (raw == null) ? min : cast raw;

		var step:Float = getStep();
		if (step <= 0) step = Math.pow(0.1, follow.decimals);

		v += dir * step;
		if (v < min) v = min;
		if (v > max) v = max;

		var stepped:Float = snapToStep(v, min, getStep());
		var outputData:Float = FlxMath.roundDecimal(stepped, follow.decimals);

		var denom:Float = (max - min);
		var percent:Float = denom == 0 ? 0 : (outputData - min) / denom;

		rectUpdate(percent, outputData);
		savePending = true;
	}

	/** 跳转到指针位置（命中判定空间 → 控件内局部比例） */
	function jumpToPointer(pointerX:Float):Void
	{
		// moveBG.x 在 FlxSpriteGroup 里已经是绝对坐标，无需再减 this.x
		var localX:Float = pointerX - moveBG.x;
		var usable:Float = moveBG.width - rod.width;
		if (usable <= 0) return;

		var percent:Float = FlxMath.bound(localX / usable, 0, 1);

		var outputData:Float = FlxMath.roundDecimal(min + (max - min) * percent, follow.decimals);
		rectUpdate(percent, outputData);
	}

	function onHold():Void
	{
		// 拖滑块的这一段时间里，面板的滚动手势要挂起
		WidgetFactory.suspendScroll = true;

		var deltaX:Float = Input.mouseX() - lastMouseX;
		lastMouseX = Input.mouseX();
		if (deltaX == 0) return;

		rod.x += deltaX;

		var startX:Float = moveBG.x;
		var endX:Float = moveBG.x + moveBG.width - rod.width;
		if (rod.x < startX) rod.x = startX;
		if (rod.x > endX) rod.x = endX;

		var percent:Float = (rod.x - moveBG.x) / (moveBG.width - rod.width);
		var outputData:Float = FlxMath.roundDecimal(min + (max - min) * percent, follow.decimals);
		rectUpdate(percent, outputData);
	}

	function rectUpdate(percent:Float, ?outputData:Dynamic):Void
	{
		percent = FlxMath.bound(percent, 0, 1);

		moveDis._frame.frame.width = moveDis.width * percent;
		if (moveDis._frame.frame.width < 1)
			moveDis._frame.frame.width = 1;
		rod.x = moveBG.x + (moveBG.width - rod.width) * percent;

		if (outputData == null) return;

		// 吸附到 changeValue 的整数倍
		var stepped:Float = snapToStep(cast outputData, min, getStep());
		outputData = FlxMath.roundDecimal(stepped, follow.decimals);

		if (valueText != null)
			valueText.text = formatValueText(outputData);

		follow.setValue(outputData);
		follow.change();
		savePending = true;
	}

	/** 按当前值重新摆一次（键盘操作改了值之后由 WidgetFactory.refreshValue 调用） */
	public function refreshValue():Void
	{
		var curValue:Dynamic = follow.getValue();
		if (curValue == null) curValue = follow.defaultValue;
		var denom:Float = (max - min);
		var percent:Float = denom == 0 ? 0 : (curValue - min) / denom;
		rectUpdate(percent, FlxMath.roundDecimal(cast curValue, follow.decimals));
	}

	function formatValueText(value:Dynamic):String
	{
		// 自定义格式化（例如 Skip Time 的 mm:ss）
		if (follow.valueFormatter != null)
			return follow.valueFormatter(cast value);

		var decimals:Int = follow.decimals;
		if (decimals <= 0)
			return Std.string(Std.int(value));

		var roundedValue:Float = FlxMath.roundDecimal(value, decimals);
		var str:String = Std.string(roundedValue);

		if (str.indexOf('.') == -1)
			str += '.';

		var parts:Array<String> = str.split('.');
		while (parts[1].length < decimals)
			parts[1] += '0';

		return parts[0] + '.' + parts[1].substr(0, decimals);
	}

	inline function snapToStep(value:Float, base:Float, step:Float):Float
	{
		if (step <= 0) return value;
		return base + Math.round((value - base) / step) * step;
	}

	inline function getStep():Float
	{
		var s:Float = Std.parseFloat(Std.string(follow.changeValue));
		if (Math.isNaN(s) || s <= 0) return 0;
		return s;
	}
}

/**
 * ± 步进按钮（Win8 Metro 风格）：方角底板 + 2px 描边 + 自绘线条符号。
 * 命中判定走自带的外扩热区（22px 本体手指点不准）；
 * hover / 按下配色由宿主 NumButton 统一喂 setState()。
 */
class StepperButton extends FlxSpriteGroup
{
	var bg:Rect;
	var border:FlxSprite;
	var symbol:FlxSprite;
	/** 透明外扩热区 */
	public var hitArea:Rect;

	/** 按住连发的计时（宿主维护）：holdTimer 憋延迟用，repeatTimer 是连发间隔的累加器 */
	public var holdTimer:Float = 0;
	public var repeatTimer:Float = 0;
	public var pressing:Bool = false;

	var hovered:Bool = false;

	public function new(X:Float, Y:Float, size:Float, plus:Bool)
	{
		super(X, Y);

		hitArea = new Rect(-Theme.TOUCH_PAD_X, -Theme.TOUCH_PAD_Y,
			size + Theme.TOUCH_PAD_X * 2, size + Theme.TOUCH_PAD_Y * 2, 0, 0, 0x00000000, 0);
		add(hitArea);

		bg = new Rect(0, 0, size, size, 0, 0, Theme.face(), 1);
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		// 描边统一走 Theme.makeFrameSprite 自绘（shapeEx.Rect 的 lineStyle 静态缓存会串色）
		border = Theme.makeFrameSprite(size, size);
		border.color = Theme.border();
		add(border);

		symbol = new FlxSprite();
		symbol.pixels = drawSymbol(size, plus);
		symbol.antialiasing = ClientPrefs.data.antialiasing;
		symbol.x = (size - symbol.width) * 0.5;
		symbol.y = (size - symbol.height) * 0.5;
		add(symbol);
	}

	/** 自绘 + / − 线条符号：居中十字 / 单横线，2px 粗（对齐控件描边粗细） */
	function drawSymbol(size:Float, plus:Bool):BitmapData
	{
		var w:Int = Std.int(size);
		var bmd:BitmapData = new BitmapData(w, w, true, 0x00000000);
		var c:FlxColor = Theme.text();
		var t:Float = Theme.BORDER_THICKNESS;      // 线宽 2
		var half:Float = size * 0.5;
		var len:Float = size * 0.25;               // 从中心伸出的长度

		var put:Int = 0;
		var x0:Int = Std.int(half - len + 1);
		var x1:Int = Std.int(half + len);
		var cy:Int = Std.int(half - t * 0.5);
		while (cy < half + t * 0.5)
		{
			var px:Int = x0;
			while (px < x1) { bmd.setPixel32(px, cy, c); px++; }
			cy++;
		}

		if (plus)
		{
			var y0:Int = Std.int(half - len + 1);
			var y1:Int = Std.int(half + len);
			var cx:Int = Std.int(half - t * 0.5);
			while (cx < half + t * 0.5)
			{
				var py:Int = y0;
				while (py < y1) { bmd.setPixel32(cx, py, c); py++; }
				cx++;
			}
		}

		return bmd;
	}

	/** 宿主每帧喂状态：hover（含键盘行选中联动）与按下；配色赋值幂等，状态没变时无开销 */
	public function setState(hover:Bool, press:Bool):Void
	{
		hovered = hover;
		pressing = press;

		var target:FlxColor = press ? Theme.facePress() : (hover ? Theme.faceHover() : Theme.face());
		if (bg != null && bg.color != target) bg.color = target;

		var b:FlxColor = (hover || press) ? Theme.accent() : Theme.border();
		if (border != null && border.color != b) border.color = b;
	}
}
