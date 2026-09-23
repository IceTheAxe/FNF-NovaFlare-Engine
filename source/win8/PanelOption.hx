package win8;

/**
 * Win8 面板里一个选项的数据模型。
 *
 * 只管"值 + 元数据 + 回调"，本身不含任何显示对象 —— 控件由 WidgetFactory 按 type 造，
 * 显示交给 OptionRow。子类通常只重写 getValue / setValue 去指定值的存放位置。
 */
class PanelOption
{
	public var name:String = 'Unknown';
	public var description:String = '';
	public var variable(default, null):String = null;
	public var type:OptionType = BOOL;

	public var defaultValue:Dynamic = null;
	public var curOption:Int = 0;
	public var options:Array<String> = null;
	public var changeValue:Dynamic = 1;
	public var minValue:Dynamic = null;
	public var maxValue:Dynamic = null;
	public var decimals:Int = 1;

	public var displayFormat:String = '%v';
	/** 自定义数值文本（可选）。设了之后 NumButton 会用它格式化当前值 */
	public var valueFormatter:Float->String = null;

	public var onChange:Void->Void = null;
	/** ACTION 类型按下时执行 */
	public var action:Void->Void = null;
	public var actionLabel:String = '';

	/** 面板滑动 / 有弹层展开时置 false，控件就不响应输入 */
	public var allowUpdate:Bool = true;

	public function new(name:String, variable:String, type:OptionType = BOOL, ?options:Array<String>, ?description:String = null)
	{
		this.name = name;
		this.variable = variable;
		this.type = type;
		this.options = options;
		this.description = (description != null) ? description : '';

		switch (type)
		{
			case BOOL:
				defaultValue = false;
			case INT, FLOAT:
				defaultValue = 0;
			case PERCENT:
				defaultValue = 1;
				displayFormat = '%v%';
				changeValue = 0.01;
				minValue = 0;
				maxValue = 1;
				decimals = 2;
			case STRING:
				defaultValue = (options != null && options.length > 0) ? options[0] : '';
			case ACTION:
				defaultValue = null;
		}
	}

	public function change():Void
	{
		if (onChange != null) onChange();
	}

	/** 下拉里某一项的显示文字。默认原样返回，子类可以换成翻译过的名字 */
	public function getOptionText(value:Dynamic):String
	{
		if (value == null) return '';
		return Std.string(value);
	}

	dynamic public function getValue():Dynamic
		return null;

	dynamic public function setValue(value:Dynamic):Void {}

	/**
	 * 值变化后的落盘钩子。
	 *
	 * NF 的 ClientPrefs.saveSettings() 会重写主存档 + 按键存档 + 箭头颜色文件，成本不低，
	 * 所以这里不做即时落盘 —— 面板关闭时（closeCharmBar）统一存一次，
	 * 跟 NF 原来的 GameplayChanger 行为一致。
	 */
	public function saveCurrentValue():Void {}
}
