package win8;

/**
 * 数值控件（Win8 滑块）。
 *
 * 细轨道 + 方形滑块（Metro 风格）。点轨道直接跳转，按住滑块拖动连续改值。
 *
 * 已填充部分的长度靠**裁窄源帧**实现：`_frame` 是每个精灵自己的帧副本
 * （FlxSprite.set_frame 里走 `FlxFrame.copyTo`，其中 frame 矩形是深拷贝），
 * 所以直接改 `moveDis._frame.frame.width` 只影响这一个 Rect，不会串到同尺寸的别的 Rect 上。
 */
class NumButton extends FlxSpriteGroup
{
	var follow:PanelOption;

	public var moveBG:Rect;
	public var moveDis:Rect;
	public var rod:Rect;
	var valueText:FlxText;
	var valueTextWidth:Float = 80;

	var max:Float;
	var min:Float;

	/** 拖拽基准（命中判定空间的指针 X，Float —— Input.mouseX() 不是整数） */
	var lastMouseX:Float = 0;

	/** 正在拖动（鼠标按下且起始点在轨道/滑块上） */
	public var onFocus:Bool = false;

	var savePending:Bool = false;

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

		moveBG = new Rect(0, 0, width, trackH, 0, 0, Theme.track(), 1.0);
		moveBG.y += (height - moveBG.height) / 2;
		add(moveBG);

		// 已填充部分：宽度不动，靠 rectUpdate() 裁源帧
		moveDis = new Rect(0, 0, width, trackH, 0, 0, Theme.accent(), 1.0);
		moveDis.y += (height - moveDis.height) / 2;
		add(moveDis);

		rod = new Rect(0, 0, rodW, rodH, 0, 0, Theme.knob(), 1.0);
		rod.y += (height - rod.height) / 2;
		add(rod);

		valueText = new FlxText(0, 0, valueTextWidth, '', 12);
		valueText.setFormat(Paths.font('montserrat.ttf'), 12, Theme.text(), LEFT);
		valueText.borderStyle = NONE;
		valueText.antialiasing = ClientPrefs.data.antialiasing;
		valueText.y = (height - valueText.height) * 0.5;
		valueText.x = moveBG.width + 12;
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
		var hoverRod:Bool = Input.overlaps(rod);
		var hoverBG:Bool = Input.overlaps(moveBG);

		if (mouse.pressed && (onFocus || hoverRod || hoverBG))
			setRodColor(Theme.knobPress());
		else if (hoverRod || hoverBG)
			setRodColor(Theme.knobHover());
		else
			setRodColor(Theme.knob());

		// 指针映射用的是"命中判定空间"的坐标（就是 FlxObject.overlapsPoint 里的 xPos，见 Input）。
		// 不能拿 FlxG.mouse.x —— 那是相对 FlxG.camera 的世界坐标，会被游戏相机的 scroll 推着走，
		// 和 moveBG.x（屏幕坐标）不在一个空间，点数值条会跳到错误的位置。
		if (mouse.justPressed && hoverRod)
		{
			onFocus = true;
			lastMouseX = Input.mouseX();
			WidgetFactory.suspendScroll = true;
		}
		else if (mouse.justPressed && hoverBG && !hoverRod)
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
