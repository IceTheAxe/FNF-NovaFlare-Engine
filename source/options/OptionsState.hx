package options;

import states.mainMenuState.MainMenuState;
import states.freeplayState.FreeplayState;

import options.base.NewControlsSubState;

import mobile.substates.MobileControlSelectSubState;
import mobile.substates.MobileExtraControl;
#if mobile
import mobile.states.CopyState;
#end

import games.backend.StageData;
import general.backend.ui.PsychUIInputText;

import openfl.Lib;

class OptionsState extends MusicBeatState
{
	public static var instance:OptionsState;

	var filePath:String = 'menuExtend/OptionsState/';

	var naviArray:Array<NaviData> = [];

	////////////////////////////////////////////////////////////////////////////////////////////
	// 统一高度设定系统
	////////////////////////////////////////////////////////////////////////////////////////////

	/**
	 * 集中管理所有布局尺寸。
	 * 所有数值都基于屏幕宽高按比例派生，避免散落的魔法数字。
	 */
	public static class LayoutMetrics
	{
		// ---- 垂直方向 ----
		public static inline function naviTop():Float return FlxG.height * 0.005;
		public static inline function naviItemHeight():Float return FlxG.height * 0.1;
		public static inline function naviBottomPadding():Float return FlxG.height * 0.005;
		public static inline function naviVisibleHeight():Float return FlxG.height - naviTop() - naviBottomPadding();

		public static inline function topBarHeight():Float return Std.int(FlxG.height * 0.1);
		public static inline function bottomBarHeight():Float return Std.int(FlxG.height * 0.1);
		public static inline function bottomBarY():Float return FlxG.height - bottomBarHeight();
		public static inline function contentTop():Float return topBarHeight();
		public static inline function contentBottom():Float return FlxG.height - bottomBarHeight();
		public static inline function contentVisibleHeight():Float return contentBottom() - contentTop();

		// ---- 水平方向 ----
		public static inline function naviWidth():Float return FlxG.width * 0.2;
		public static inline function contentLeft():Float return naviWidth();
		public static inline function contentWidth():Float return FlxG.width - contentLeft();
		public static inline function cataWidth():Float return FlxG.width * (0.8 - (0.8 / 20 * 2));
		public static inline function cataGapX():Float return FlxG.width * (0.8 / 20);

		// ---- 展开项 ----
		public static inline function expandedItemHeight():Float return 50;
		public static inline function expandedPadding():Float return 15;
		public static inline function expandedExtra(navi:NaviGroup):Float
			return navi.parent.length * expandedItemHeight() + expandedPadding();

		// ---- 底部按钮 ----
		public static inline function tipButtonGap():Float return FlxG.height * 0.01;
		public static inline function tipButtonHeight():Float return Std.int(FlxG.height * 0.08);
		public static inline function specButtonWidth():Float return Std.int(FlxG.width * 0.15);
	}

	////////////////////////////////////////////////////////////////////////////////////////////

	public var baseColor = 0x302E3A;
	public var mainColor = 0x24232C;

	////////////////////////////////////////////////////////////////////////////////////////////

	public var mouseEvent:MouseEvent;

	var naviBG:Rect;
	var naviGroup:Array<NaviGroup> = [];
	var naviMove:MouseMove;

	public var cataGroup:Array<OptionCata> = [];
	public var cataMove:MouseMove;
	public var stringCount:Array<StringSelect> = []; //string开启的检测

	public var downBG:Rect;
	var tipButton:TipButton;
	var specButton:FuncButton;

	public var specBG:Rect;
	var searchButton:SearchButton;
	var resetButton:ResetButton;
	var backButton:GeneralBack;

	override function create()
	{
		if (stateType != 2) {
			Paths.clearStoredMemory();
			Paths.clearUnusedMemory();
		}

		FlxG.mouse.visible = !ClientPrefs.data.needMobileControl;

		persistentUpdate = persistentDraw = true;
		instance = this;

		naviArray = [
			new NaviData('NovaFlare Engine', ['Language','General','User Interface','GamePlay','Game UI','Skin','Input','Audio','Graphics','Maintenance','FEFeatures'])
		];

		var path = Paths.mods('stageScripts/options/');
		if (FileSystem.exists(path) && FileSystem.isDirectory(path)){
			var naviData = new NaviData('Global mod', []);

			var group:Array<String> = [];
			for (file in FileSystem.readDirectory(path))
			{
				if (file.toLowerCase().endsWith('.hx'))
					group.push(StringTools.replace(file, ".hx", ""));
			}
			naviData.group = group;
			naviData.extraPath = path;
			naviArray.push(naviData);
		}

		for (mod in Mods.parseList().enabled)
		{
			var path = Paths.mods(mod + '/stageScripts/options/');
			if (FileSystem.exists(path) && FileSystem.isDirectory(path)){
				var naviData = new NaviData(mod, []);

				var group:Array<String> = [];
				for (file in FileSystem.readDirectory(path))
				{
					if (file.toLowerCase().endsWith('.hx'))
						group.push(StringTools.replace(file, ".hx", ""));
				}
				naviData.group = group;
				naviData.extraPath = path;
				naviArray.push(naviData);
			}
		}

		mouseEvent = new MouseEvent();
		add(mouseEvent);

		var background = new ChangeSprite(0, 0).load(Paths.image('menuDesat'), 1.05);
		background.antialiasing = ClientPrefs.data.antialiasing;
		add(background);

		naviBG = new Rect(0, 0, LayoutMetrics.naviWidth(), FlxG.height, 0, 0, mainColor, 0.75);
		add(naviBG);

		// ---- 创建导航组 ----
		for (i in 0...naviArray.length)
		{
			var naviSprite = new NaviGroup(
				LayoutMetrics.naviTop() * 1, // x 偏移 (原 0.005 * width 改为统一的 y 间距对齐)
				LayoutMetrics.naviTop() + i * LayoutMetrics.naviItemHeight(),
				LayoutMetrics.naviWidth() - LayoutMetrics.naviTop(),
				LayoutMetrics.naviItemHeight() * 0.9,
				naviArray[i], i, false
			);
			naviSprite.antialiasing = ClientPrefs.data.antialiasing;
			add(naviSprite);
			naviGroup.push(naviSprite);
		}

		// ---- 初始化导航滚动控制器 ----
		initNaviScrolling();

		naviGroup[0].moveParent(0.01);

		/////////////////////////////////////////////////////////////////

		for (data in 0...naviArray.length) {
			var naviData:NaviData = naviArray[data];
			for (mem in 0...naviData.group.length) {
				if (naviData.extraPath != '') addCata(naviData.group[mem], naviGroup[data], naviGroup[data].parent[mem], naviData.extraPath);
				else addCata(naviData.group[mem], naviGroup[data], naviGroup[data].parent[mem]);
			}
		}

		// ---- 初始化内容滚动控制器 ----
		initCataScrolling();

		/////////////////////////////////////////////////////////////

		downBG = new Rect(0, LayoutMetrics.bottomBarY(), FlxG.width, LayoutMetrics.bottomBarHeight(), 0, 0, mainColor, 0.75);
		add(downBG);

		tipButton = new TipButton(
			LayoutMetrics.contentLeft() + LayoutMetrics.tipButtonGap(),
			downBG.y + LayoutMetrics.tipButtonGap(),
			FlxG.width - LayoutMetrics.contentLeft() - LayoutMetrics.tipButtonGap()
				- LayoutMetrics.specButtonWidth() - LayoutMetrics.tipButtonGap() * 2,
			LayoutMetrics.tipButtonHeight()
		);
		add(tipButton);

		specButton = new FuncButton(
			FlxG.width - LayoutMetrics.specButtonWidth() - LayoutMetrics.tipButtonGap(),
			downBG.y + LayoutMetrics.tipButtonGap(),
			LayoutMetrics.specButtonWidth(),
			LayoutMetrics.tipButtonHeight(),
			specChange
		);
		specButton.alpha = 0.5;
		add(specButton);

		//////////////////////////////////////////////////////////////////////

		specBG = new Rect(LayoutMetrics.contentLeft(), 0, LayoutMetrics.contentWidth(), LayoutMetrics.topBarHeight(), 0, 0, mainColor, 0.75);
		add(specBG);

		searchButton = new SearchButton(
			specBG.x + specBG.height * 0.2,
			specBG.height * 0.2,
			specBG.width * 0.5,
			specBG.height * 0.6
		);
		add(searchButton);

		resetButton = new ResetButton(
			specBG.x + specBG.height * 0.2 * 2 + searchButton.width,
			specBG.height * 0.2,
			specBG.width - (specBG.height * 0.2 * 3 + searchButton.width),
			specBG.height * 0.6
		);
		add(resetButton);

		backButton = new GeneralBack(
			0, 720 - 72,
			LayoutMetrics.naviWidth(),
			LayoutMetrics.bottomBarHeight(),
			Language.get('back', 'main'), EngineSet.mainColor, backMenu
		);
		add(backButton);

		super.create();
	}

	////////////////////////////////////////////////////////////////////////////
	// 滚动控制器
	////////////////////////////////////////////////////////////////////////////

	/**
	 * 初始化导航栏滚动。
	 * 计算所有导航组（含已展开项）的总高度，得出最大上滚偏移。
	 */
	private function initNaviScrolling():Void
	{
		naviMove = new MouseMove(OptionsState, 'naviPosiData',
			[0, LayoutMetrics.naviTop()], // moveLimit 稍后由 refreshNavScrollBounds 刷新
			[
				[LayoutMetrics.naviTop(), LayoutMetrics.naviWidth() - LayoutMetrics.naviTop()],
				[0, FlxG.height]
			],
			naviMoveEvent);
		add(naviMove);
		refreshNavScrollBounds();
	}

	/**
	 * 初始化内容区滚动。
	 */
	private function initCataScrolling():Void
	{
		cataMove = new MouseMove(OptionsState, 'cataPosiData',
			[100, 100], // moveLimit 稍后由 refreshCataScrollBounds 刷新
			[
				[LayoutMetrics.contentLeft(), FlxG.width],
				[0, LayoutMetrics.contentBottom()]
			],
			cataMoveEvent);
		add(cataMove);
		cataMove.forceUpdateEvent = true;
		cataMove.useLerp = false;
		cataMove.tweenTime = 0.45;
		cataMove.tweenType = 'expoInOut';

		refreshCataScrollBounds();
		cataMoveEvent();
	}

	/**
	 * 重新计算导航栏滚动边界。
	 * 统一处理：基础高度 + 展开高度 + 可见区域。
	 */
	public function refreshNavScrollBounds():Void
	{
		if (naviMove == null) return;

		var totalHeight:Float = 0;
		for (navi in naviGroup)
		{
			totalHeight += LayoutMetrics.naviItemHeight();
			if (navi.isOpened)
				totalHeight += LayoutMetrics.expandedExtra(navi);
		}

		var visibleHeight:Float = LayoutMetrics.naviVisibleHeight();
		var minScroll:Float = -(totalHeight - visibleHeight);
		if (minScroll > 0) minScroll = 0;

		naviMove.moveLimit[0] = minScroll;
		naviMove.moveLimit[1] = LayoutMetrics.naviTop();

		// 夹紧当前值
		if (naviPosiData < minScroll) naviPosiData = minScroll;
		if (naviPosiData > LayoutMetrics.naviTop()) naviPosiData = LayoutMetrics.naviTop();
	}

	/**
	 * 重新计算内容区滚动边界。
	 * @param useWaitHeight true 使用目标高度（动画中），false 使用实际高度
	 */
	public function refreshCataScrollBounds(useWaitHeight:Bool = false):Void
	{
		if (cataMove == null) return;

		var contentHeight:Float = 0;
		var gap:Float = LayoutMetrics.cataGapX();
		for (i in 0...cataGroup.length)
		{
			contentHeight += useWaitHeight ? cataGroup[i].bg.waitHeight : cataGroup[i].bg.realHeight;
			if (i < cataGroup.length - 1)
				contentHeight += gap;
		}

		var viewportHeight:Float = LayoutMetrics.contentVisibleHeight();
		var minScroll:Float = LayoutMetrics.contentTop() - Math.max(0, contentHeight - viewportHeight);
		if (minScroll > LayoutMetrics.contentTop()) minScroll = LayoutMetrics.contentTop();

		cataMoveMinLimit = minScroll;
		cataMove.moveLimit[0] = minScroll;
		cataMove.moveLimit[1] = LayoutMetrics.contentTop();

		if (cataPosiData < minScroll) cataPosiData = minScroll;
		if (cataPosiData > LayoutMetrics.contentTop()) cataPosiData = LayoutMetrics.contentTop();
	}

	////////////////////////////////////////////////////////////////////////////

	public var ignoreCheck:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		cataMove.inputAllow = true;
		for (cata in stringCount) {
			if (!cata.isOpend) continue;
			else {
				if (OptionsState.instance.mouseEvent.overlaps(cata.bg)){
					cataMove.inputAllow = false;
					break;
				}
			}
		}

		if (controls.BACK)
		{
			if (PsychUIInputText.focusOn != null)
			{
				//PsychUIInputText.focusOn = null;
				//FlxG.sound.play(Paths.sound('cancelMenu'));
			}
			else
				backMenu();
		}
	}

	private function updateCataVisibility():Void
	{
		var cam = FlxG.camera;
		var l = cam.scroll.x;
		var t = cam.scroll.y;
		var r = l + cam.width / cam.zoom;
		var b = t + cam.height / cam.zoom;
		for (cata in cataGroup)
		{
			var cl = cata.x;
			var ct = cata.y;
			var cr = cl + cata.bg.width;
			var cb = ct + cata.bg.realHeight;
			var inView = (cr > l && cl < r && cb > t && ct < b);
			cata.visible = inView;
			cata.active = inView;
		}
	}

	override function closeSubState()
	{
		super.closeSubState();
		persistentUpdate = true;
	}

	public function startSearch(text:String, time = 0.6) {
		for (cata in cataGroup) {
			cata.startSearch(text, time);
		}
	}

	public function changeCata(cataSort:Int, memSort:Int) {
		var outputData:Float = LayoutMetrics.contentTop();

		var realSort:Int = memSort;
		for (navi in 0...naviGroup.length) {
			if (navi < cataSort) realSort += naviGroup[navi].parent.length;
			else break;
		}

		for (cata in 0...realSort) {
			outputData -= cataGroup[cata].bg.realHeight;
			outputData -= LayoutMetrics.cataGapX();
		}
		outputData = Math.max(outputData, cataMove.moveLimit[0]);
		cataMove.tweenData = outputData;
	}

	public function changeTip(str:String) {
		tipButton.changeText(str);
	}

	public function addCata(type:String, follow:NaviGroup, mem:NaviMember, extraPath:String = '') {
		var obj:OptionCata = null;

		var outputX:Float = LayoutMetrics.contentLeft() + LayoutMetrics.cataGapX();
		var outputWidth:Float = LayoutMetrics.cataWidth();
		var outputY:Float = LayoutMetrics.contentTop(); // 等待被初始化
		var outputHeight:Float = 200; // 等待被初始化

		switch (type)
		{
			case 'General':
				obj = new GeneralGroup(outputX, outputY, outputWidth, outputHeight);
			case 'Language':
				obj = new LanguageGroup(outputX, outputY, outputWidth, outputHeight);
			case 'User Interface':
				obj = new InterfaceGroup(outputX, outputY, outputWidth, outputHeight);
			case 'GamePlay':
				obj = new GamePlayGroup(outputX, outputY, outputWidth, outputHeight);
			case 'Game UI':
				obj = new UIGroup(outputX, outputY, outputWidth, outputHeight);
			case 'Skin':
				obj = new SkinGroup(outputX, outputY, outputWidth, outputHeight);
			case 'Input':
				obj = new InputGroup(outputX, outputY, outputWidth, outputHeight);
			case 'Audio':
				obj = new AudioGroup(outputX, outputY, outputWidth, outputHeight);
			case 'Graphics':
				obj = new GraphicsGroup(outputX, outputY, outputWidth, outputHeight);
			case 'Maintenance':
				obj = new MaintenanceGroup(outputX, outputY, outputWidth, outputHeight);
			case 'FEFeatures':
				obj = new FEFeaturesGroup(outputX, outputY, outputWidth, outputHeight);
			default:
				obj = new HScriptGroup(outputX, outputY, outputWidth, outputHeight, type, extraPath, type);
		}
		cataGroup.push(obj);
		obj.follow = follow;
		obj.mem = mem;
		add(obj);
	}

	public function addMove(tar:MouseMove) {
		add(tar);
	}

	static public var cataPosiData:Float = 100;
	public var cataMoveMinLimit:Float = 100;

	/**
	 * 内容区布局刷新：重新计算每个分类的 y 坐标，并更新滚动边界。
	 */
	public function cataMoveEvent(){
		var gap:Float = LayoutMetrics.cataGapX();
		for (i in 0...cataGroup.length) {
			if (i == 0) cataGroup[i].y = cataPosiData;
			else cataGroup[i].y = cataGroup[i - 1].y + cataGroup[i - 1].bg.realHeight + gap;
		}
		updateCataVisibility();
		updateCurrentCategoryIndicator();
	}

	private function updateCurrentCategoryIndicator():Void
	{
		var selected:OptionCata = null;
		for (cata in cataGroup)
		{
			if (cata.checkPoint())
			{
				selected = cata;
				break;
			}
		}

		for (navi in naviGroup)
		{
			navi.cataChoose = selected != null && selected.follow == navi;
			for (member in navi.parent)
				member.cataChoose = selected != null && selected.mem == member;
		}
	}

	/**
	 * 当某个分类高度变化（如展开/收起）时，刷新滚动边界。
	 */
	public function cataMoveChange()
	{
		refreshCataScrollBounds(true);
	}

	////////////////////////////////////////////////////////////////////////////

	static public var naviPosiData:Float = 0;

	/**
	 * 导航栏布局刷新：按统一高度设定重新排列所有导航项。
	 */
	public function naviMoveEvent(){
		var itemH:Float = LayoutMetrics.naviItemHeight();
		var topPad:Float = LayoutMetrics.naviTop();
		for (i in 0...naviGroup.length) {
			naviGroup[i].y = naviPosiData + topPad + i * itemH + naviGroup[i].offsetY;
		}
	}

	var naviTween:Array<FlxTween> = [];
	var alreadyDetele:Bool = false;

	/**
	 * 展开/收起某个导航组，并统一刷新滚动边界。
	 */
	public function changeNavi(navi:NaviGroup, isOpened:Bool, naviTime:Float = 0.45) {
		for (tween in naviTween) {
			if (tween != null) tween.cancel();
		}
		naviTween = [];

		// 统一刷新滚动边界（基于 isOpened 的最新状态）
		refreshNavScrollBounds();

		var extra:Float = LayoutMetrics.expandedExtra(navi);
		for (i in 0...naviGroup.length) {
			if (i <= navi.optionSort) continue;
			naviGroup[i].offsetWaitY += extra * (isOpened ? -1 : 1);
			var tween = FlxTween.num(
				naviGroup[i].offsetY, naviGroup[i].offsetWaitY, naviTime,
				{ease: FlxEase.expoInOut},
				function(v) { naviGroup[i].offsetY = v; }
			);
			naviTween.push(tween);
		}
	}

	var specOpen:Bool = false;
	var specTween:Array<FlxTween> = [];
	var specTime = 0.6;
	public function specChange() {
		for (tween in specTween) {
			if (tween != null) tween.cancel();
		}

		var newPoint:Float = 0;
		if (!specOpen) {
			newPoint = FlxG.width;
			cataMove.moveLimit[1] = 30;
		} else {
			newPoint = LayoutMetrics.contentLeft();
			cataMove.moveLimit[1] = 100;
		}

		var tween = FlxTween.tween(specBG, {x: newPoint}, specTime, {ease: FlxEase.expoInOut});
		specTween.push(tween);
		var tween = FlxTween.tween(searchButton, {x: newPoint + specBG.height * 0.2}, specTime, {ease: FlxEase.expoInOut});
		specTween.push(tween);
		var tween = FlxTween.tween(resetButton, {x: newPoint + specBG.height * 0.2 + searchButton.width + specBG.height * 0.2}, specTime, {ease: FlxEase.expoInOut});
		specTween.push(tween);

		specOpen = !specOpen;
	}

	public function moveState(type:Int)
	{
		switch (type)
		{
			case 1: // NoteOffsetState
				MusicBeatState.switchState(new NoteOffsetState());
			case 2: // NotesSubState
				persistentUpdate = false;
				openSubState(new NotesSubState());
			case 3: // ControlsSubState
				persistentUpdate = false;
				openSubState(new ControlsSubState());
			case 4: // MobileControlSelectSubState
				persistentUpdate = false;
				openSubState(new MobileControlSelectSubState());
			case 5: // MobileExtraControl
				persistentUpdate = false;
				openSubState(new MobileExtraControl());
			#if mobile
			case 6: // CopyStates
				MusicBeatState.switchState(new CopyState(true));
			#end
			case 7: // NotesSubStateLegacy
				persistentUpdate = false;
				openSubState(new NotesSubStateLegacy());
			case 8:
				persistentUpdate = false;
				openSubState(new SelectGameSubState());
			case 9: // KeyBoardSubState
				persistentUpdate = false;
				openSubState(new KeyBoardSubState());
		}
	}

	public function resetData()
	{
		for (cata in cataGroup) {
			if (cata.checkPoint()) {
				cata.resetData();
				break;
			}
		}
	}

	public function changeLanguage() {
		for (spr in 0...naviGroup.length) {
			naviGroup[spr].changeLanguage();

			for (mem in naviGroup[spr].parent) mem.changeLanguage();
		}

		for (cata in cataGroup) cata.changeLanguage();

		tipButton.changeLanguage();
		resetButton.changeLanguage();
		searchButton.changeLanguage();
		backButton.changeLanguage();
	}

	public static var stateType:Int = 0;
	var backCheck:Bool = false;
	function backMenu()
	{
		if (!backCheck)
		{
			backCheck = true;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			ClientPrefs.saveSettings();
			Main.fpsVar.visible = ClientPrefs.data.showFPS;
			Main.fpsVar.scaleX = Main.fpsVar.scaleY = ClientPrefs.data.fpsScale;
			if (Main.watermark != null)
			{
				Main.watermark.scaleX = Main.watermark.scaleY = ClientPrefs.data.watermarkScale;
				Main.watermark.y = Lib.current.stage.stageHeight - 5 - Main.watermark.scaleY * Main.watermark.bitmapData.height;
				Main.watermark.visible = ClientPrefs.data.showWatermark;
			}
			switch (stateType)
			{
				case 0:
					MusicBeatState.switchState(new MainMenuState());
				case 1:
					MusicBeatState.switchState(new FreeplayState());
				case 2:
					MusicBeatState.switchState(new PlayState());
					FlxG.mouse.visible = false;
			}
			stateType = 0;
		}
	}
}