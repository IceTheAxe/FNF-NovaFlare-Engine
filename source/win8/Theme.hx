package win8;

import openfl.display.Shape;
import openfl.display.BitmapData;

/**
 * Win8 面板的配色。
 *
 * NF 没有控件主题 / 深浅色体系，所以这里就是一套固定的 Win8 深色配色，
 * 不再有 Win10 分支、也没有 surface / 主题切换那套机制。
 * 强调色取 EngineSet.mainColor —— 跟 NF 自己的设置界面（OptionsState）同一个来源，
 * 其余底色 / 描边 / 文字沿用 Win8 深色的值。
 */
class Theme
{
	/** Win8 控件的描边粗细 */
	public static inline var BORDER_THICKNESS:Float = 2;

	// ---------------------------------------------------------
	// 强调色（= NF 的主色）
	// ---------------------------------------------------------
	public static function accent():FlxColor
		return EngineSet.mainColor;

	public static function accentHover():FlxColor
		return hoverTint(accent());

	public static function accentPress():FlxColor
		return pressTint(accent());

	// ---------------------------------------------------------
	// 控件面 / 描边 / 文字
	// ---------------------------------------------------------
	public static function face():FlxColor
		return 0xFF2B2B2B;

	public static function faceHover():FlxColor
		return hoverTint(face());

	public static function facePress():FlxColor
		return pressTint(face());

	public static function border():FlxColor
		return 0xFF9A9A9A;

	public static function text():FlxColor
		return 0xFFFFFFFF;

	public static function textSecondary():FlxColor
		return 0xFFAAAAAA;

	public static function track():FlxColor
		return 0xFF555555;

	public static function knob():FlxColor
		return accent();

	public static function knobHover():FlxColor
		return accentHover();

	public static function knobPress():FlxColor
		return accentPress();

	public static function off():FlxColor
		return 0xFF666666;

	/** 强调色底上的文字色 */
	public static function onAccent():FlxColor
		return 0xFFFFFFFF;

	// ---------------------------------------------------------
	// 面板
	// ---------------------------------------------------------
	public static function railBG():FlxColor
		return 0xFF1A1A1A;

	public static function railHover():FlxColor
		return 0xFF333333;

	public static function panelBG():FlxColor
		return 0xFF1F1F1F;

	public static function panelHeader():FlxColor
		return 0xFF2B2B2B;

	public static function divider():FlxColor
		return 0xFF3F3F3F;

	/** 键盘选中行的底色 */
	public static function rowSelected():FlxColor
		return FlxColor.interpolate(panelBG(), accent(), 0.22);

	public static function overlay():FlxColor
		return 0xFF000000;

	public static function overlayAlpha():Float
		return 0.62;

	// ---------------------------------------------------------
	// 危险操作（Reset 之类）
	// ---------------------------------------------------------
	public static function danger():FlxColor
		return 0xFFFF6363;

	public static function dangerBase():FlxColor
		return 0xFF5A2B2B;

	public static function dangerHover():FlxColor
		return 0xFF7A3A3A;

	public static function dangerPress():FlxColor
		return 0xFF3A1F1F;

	// ---------------------------------------------------------
	// 悬停 / 按下的通用提亮压暗
	// ---------------------------------------------------------
	public static function hoverTint(c:FlxColor):FlxColor
		return FlxColor.interpolate(c, 0xFFFFFFFF, 0.15);

	public static function pressTint(c:FlxColor):FlxColor
		return FlxColor.interpolate(c, 0xFF000000, 0.20);

	// ---------------------------------------------------------
	// 绘制辅助
	// ---------------------------------------------------------
	/**
	 * 生成一个"空心方框"精灵（白色填充，靠 color 染色）。
	 * 用于给 Win8 控件描边 —— shapeEx.Rect 的 lineStyle 有个静态共享缓存的坑（多处描边会串色），
	 * 所以这里自己画 BitmapData。
	 */
	public static function makeFrameSprite(w:Float, h:Float, ?thickness:Float = BORDER_THICKNESS):FlxSprite
	{
		var iw:Int = Std.int(w);
		var ih:Int = Std.int(h);
		var t:Int = Std.int(Math.max(1, thickness));

		var spr:FlxSprite = new FlxSprite();
		if (iw <= 0 || ih <= 0 || iw <= t * 2 || ih <= t * 2) return spr;

		var shape:Shape = new Shape();
		shape.graphics.beginFill(0xFFFFFFFF);
		shape.graphics.drawRect(0, 0, iw, t);
		shape.graphics.drawRect(0, ih - t, iw, t);
		shape.graphics.drawRect(0, t, t, ih - t * 2);
		shape.graphics.drawRect(iw - t, t, t, ih - t * 2);
		shape.graphics.endFill();

		var bmd:BitmapData = new BitmapData(iw, ih, true, 0x00000000);
		bmd.draw(shape);

		spr.pixels = bmd;
		spr.antialiasing = ClientPrefs.data.antialiasing;
		return spr;
	}
}
