package win8;

/**
 * 按 PanelOption 的类型造控件。
 *
 * 只保留 Win8 面板用得到的几种：BOOL / INT / FLOAT / PERCENT / STRING / ACTION。
 * （FE 那套还有 KEYBIND / COLOR，本面板用不到，没搬。）
 *
 * 另外这里挂三个静态标记，充当控件与面板之间的小接口 —— 避免控件反向依赖面板：
 *   popupOpen      —— 有下拉展开（面板每帧写入，滑块 / 面板自己读）
 *   scrollVelocity —— 面板滚动条当前速度（面板每帧写入，滑块读，用来判断"现在是在滚面板还是在拖滑块"）
 *   suspendScroll  —— 控件正在自己拖拽（滑块写，面板读后清掉，用来挂起面板滚动）
 */
class WidgetFactory
{
	public static var popupOpen:Bool = false;
	public static var scrollVelocity:Float = 0;
	public static var suspendScroll:Bool = false;

	/**
	 * @param opt      要绑定的选项
	 * @param overlay  下拉弹层的挂载层（不传则挂在控件自己身上）
	 * @param widgetW  数值条 / 下拉条的宽度
	 */
	public static function create(opt:PanelOption, ?overlay:FlxSpriteGroup, widgetW:Float = 240):FlxSpriteGroup
	{
		if (opt == null) return null;

		switch (opt.type)
		{
			case ACTION:
				return createActionButton(opt, 100, 35);

			case BOOL:
				return new BoolButton(0, 0, 56, 24, opt);

			case INT, FLOAT, PERCENT:
				return new NumButton(0, 0, widgetW, 32, opt);

			case STRING:
				return new StringSelect(0, 0, widgetW, 32, opt, overlay);
		}
	}

	/**
	 * 造 ACTION 按钮。宽高由调用方给 —— 面板默认用 100×35 的小按钮，
	 * 想要更大的按钮（跟同列控件等宽对齐）就直接调这个。
	 *
	 * isReset 的判定收在这里，免得调用方各写一份。
	 */
	public static function createActionButton(opt:PanelOption, w:Float, h:Float):OptionButton
	{
		var tag:String = opt.variable != null ? opt.variable.toLowerCase() : '';
		var isReset:Bool = (tag.indexOf('reset') >= 0
			|| (opt.actionLabel != null && opt.actionLabel.toLowerCase() == 'reset'));
		return new OptionButton(0, 0, w, h, opt, isReset);
	}

	/**
	 * 让控件重新读取 follow.getValue() 并刷新显示。
	 * 键盘操作（上下左右）直接改了 Option 的值之后必须调一次，否则界面还是旧值。
	 */
	public static function refreshValue(widget:FlxSpriteGroup):Void
	{
		if (widget == null) return;

		if (Std.isOfType(widget, BoolButton))
			cast(widget, BoolButton).updateDisplay();
		else if (Std.isOfType(widget, NumButton))
			cast(widget, NumButton).refreshValue();
		else if (Std.isOfType(widget, StringSelect))
			cast(widget, StringSelect).refreshValue();
	}

	/** 收掉控件自己展开的弹层（只有带下拉的那种有） */
	public static function closePopup(widget:FlxSpriteGroup):Void
	{
		if (widget == null) return;

		if (Std.isOfType(widget, StringSelect))
			cast(widget, StringSelect).closePopup();
	}
}
