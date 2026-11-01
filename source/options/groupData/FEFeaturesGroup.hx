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

		var option:Option = new Option(this, 'pauseSkipFadeIn', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'pauseSkipFadeOut', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'pauseDoubleEnterSkip', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'pauseUnlockInputDuringAnim', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'coolBackdrop', BOOL);
		addOption(option);

		// 老版谱面编辑器已下线，谱面编辑器固定走 PE 版，此开关不再需要
		// var option:Option = new Option(this, 'peChartEditor', BOOL);
		// addOption(option);
		
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

		// FLOAT 的 data 是 [min, max, decimals]：decimals 同时决定步进（0.1^decimals）
		// 和写入前的取整位数（backend/NumButton.hx）。给 0 的话只能 0 / 1 两档。
		var option:Option = new Option(this, 'guideLineAlpha', FLOAT, [0, 1, 1]);
		addOption(option);

		var option:Option = new Option(this, 'noteOffsetChangingAllowed', BOOL);
		addOption(option);

		// 开局判定信息提示的停留秒数，0 = 不显示
		var option:Option = new Option(this, 'startInfoTime', FLOAT, [0, 10, 1]);
		addOption(option);

		#if RELAX_ALLOWED
		var option:Option = new Option(this, 'relaxIdleMinutes', INT, [0, 60, 1]);
		addOption(option);
		#end

		changeHeight(0);
	}

}
