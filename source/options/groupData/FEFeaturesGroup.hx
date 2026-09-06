package options.groupData;

class FEFeaturesGroup extends OptionCata
{
	public function new(X:Float, Y:Float, width:Float, height:Float)
	{
		super(X, Y, width, height);

		var pauseArray:Array<String> = ['NF', 'FE', 'Psych'];
		var option:Option = new Option(this, 'FEFeatures', TITLE);
		addOption(option);

		var option:Option = new Option(this, 'pauseType', STRING , pauseArray);
		addOption(option);

		var option:Option = new Option(this, 'coolBackdrop', BOOL);
		addOption(option);
		
		var option:Option = new Option(this, 'showMS', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'gradientTimeBar', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'customColor', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'luaDebugPrint', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'hitErrorBarVisible', BOOL);
		addOption(option);
		
		var option:Option = new Option(this, 'hitBarLines', INT, [0, 30, 5]);
		addOption(option);	

		var option:Option = new Option(this, 'hitBarLineTime', FLOAT, [0, 10, 0]);
		addOption(option);

		var option:Option = new Option(this, 'hitErrorBarOffsetX', FLOAT, [-200, 200, 0]);
		addOption(option);

		var option:Option = new Option(this, 'hitErrorBarOffsetY', FLOAT, [-200, 200, 0]);
		addOption(option);

		var option:Option = new Option(this, 'msInErrorBar', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'pointerType', STRING, ['triangle', 'inverted', 'thick_line']);
		addOption(option);

		var option:Option = new Option(this, 'guideLineAlpha', FLOAT, [0, 1, 0]);
		addOption(option);

		var option:Option = new Option(this, 'noteOffsetChangingAllowed', BOOL);
		addOption(option);

		changeHeight(0);
	}

}
