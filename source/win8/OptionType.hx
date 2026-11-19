package win8;

/**
 * Win8 面板里选项的类型。
 *
 * KEYBIND 供 mod 设置用（就地捕获键位，控件见 KeybindButton）。
 * COLOR 仍是 FE 独有，没搬。
 */
enum OptionType
{
	BOOL;
	INT;
	FLOAT;
	PERCENT;
	STRING;
	ACTION;
	KEYBIND;
}
