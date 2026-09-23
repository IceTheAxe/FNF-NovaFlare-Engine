package win8;

/**
 * 面板里的分组小标题：一行 13px 的浅色标题 + 一条 1px 分割线。
 *
 * 坐标注意：FlxSpriteGroup 的子元素坐标是绝对的（add() 时会加上本组的 x/y），
 * 所以子元素要在 add() 之前就摆到"组内坐标"上，不要 add 之后再改。
 */
class OptionSection extends FlxSpriteGroup
{
	/** 分组标题行高 */
	public static inline var SECTION_H:Float = 42;
	/** 左右内边距，跟 OptionRow.PAD_X 对齐 */
	static inline var PAD_X:Float = 14;

	/** 这个分组在 entries 数组里的下标 */
	public var entryIndex:Int = 0;
	public var entryId:String = '';

	public var label:FlxText;
	public var line:Rect;

	public var baseY:Float = 0;
	public var rowH:Float = SECTION_H;

	public function new(x:Float, y:Float, w:Float, entryIndex:Int, id:String, text:String)
	{
		super(x, y);

		this.entryIndex = entryIndex;
		this.entryId = id;

		label = new FlxText(PAD_X, 12, w - PAD_X * 2, text != null ? text : '', 13);
		label.setFormat(Paths.font('montserrat.ttf'), 13, Theme.textSecondary(), LEFT);
		label.borderStyle = NONE;
		label.antialiasing = ClientPrefs.data.antialiasing;
		add(label);

		line = new Rect(PAD_X, SECTION_H - 1, w - PAD_X * 2, 1, 0, 0, Theme.divider(), 0.6);
		line.antialiasing = ClientPrefs.data.antialiasing;
		add(line);
	}

	public function setRowMeta(baseY:Float, rowH:Float):Void
	{
		this.baseY = baseY;
		this.rowH = rowH;
	}

	public function setLabel(text:String):Void
	{
		if (label != null) label.text = (text != null) ? text : '';
	}
}
