package win8;

/**
 * Win8 面板里选项的类型。
 *
 * 只保留面板用得到的那几种：ACTION 是"动作按钮"，KEYBIND / COLOR 不搬（NF 的 GameplayChanger 没有这类选项）。
 */
enum OptionType
{
	BOOL;
	INT;
	FLOAT;
	PERCENT;
	STRING;
	ACTION;
}
