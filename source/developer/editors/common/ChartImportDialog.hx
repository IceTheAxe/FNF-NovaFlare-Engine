package developer.editors.common;

import flixel.util.FlxColor;
import flixel.text.FlxText;
import developer.editors.common.MidiTrackReader.MidiPart;
// PsychUI 组件、Language、MusicBeatSubstate、ClientPrefs、Paths 都走 source/import.hx 的全局导入

/**
 * 转换结果，由 onConfirm 回传。
 * 导入用 action/diff/convertKeys/targetKeys/extractAudio，导出只用 action/format/diff。
 */
typedef ChartConvertOptions =
{
	var action:Int;
	var format:Null<String>; // 导出目标格式；导入时为 null
	var diff:String;
	var convertKeys:Bool;
	var targetKeys:Int;
	/** true = 转成 FNF 经典 4K+4K 双人布局（每侧 4 轨），优先于 convertKeys/targetKeys */
	var funkinKeys:Bool;
	var extractAudio:Bool;
	/** 仅 MIDI：选中的声部 id（null = 不适用 / 全不选时退回默认） */
	var midiParts:Array<Int>;
	/** 仅 MIDI：音高 → 轨道映射（range / mod） */
	var midiLaneMode:String;
}

/**
 * 通用谱面导入/导出对话框（双向共用一个界面）。
 * 导入：StepMania(.sm/.ssc)、osu!mania(.osu/.osz)、Quaver(.qua/.qp)、MIDI(.mid)、Malody(.mc)
 *   曲名/格式提示 + MIDI 多声部选择 + 难度选择（多难度时）+ 目标键数转换 + Funkin Keys 4K+4K
 *   + .osz 音频提取 + 载入编辑器/保存 JSON 两种去向
 * 导出：StepMania(.sm/.ssc)、osu!mania(.osu)、Quaver(.qua)
 *
 * 与 FE 版差异：下拉框用 PsychUIDropDownMenu（NF 没有 Win8DropDown/UIControlTheme），
 * 弹层展开期间其它组件的点击挂起与弹层置顶跟随缺失（旧组件的已知行为）。
 */
class ChartImportDialog extends MusicBeatSubstate implements PsychUIEventHandler.PsychUIEvent
{
	// 对话框模式
	public static inline var MODE_IMPORT:Int = 0;
	public static inline var MODE_EXPORT:Int = 1;

	// options.action 的取值
	public static inline var ACTION_LOAD:Int = 0;   // 导入：载入编辑器
	public static inline var ACTION_SAVE:Int = 1;   // 导入：保存为 Psych JSON
	public static inline var ACTION_EXPORT:Int = 2; // 导出模式固定回传

	public var onConfirm:Null<ChartConvertOptions->Void> = null;
	public var onCancel:Null<Void->Void> = null;

	// UI 元素
	private var bg:FlxSprite;
	private var titleText:FlxText;
	private var infoText:FlxText;
	private var mode:Int;

	// 导入相关
	private var convertKeysCheck:PsychUICheckBox;
	private var funkinKeysCheck:PsychUICheckBox;
	private var targetKeysLabel:FlxText;
	private var targetKeysDropDown:PsychUIDropDownMenu;
	private var diffDropDown:PsychUIDropDownMenu;
	private var extractAudioCheck:PsychUICheckBox;
	private var diffs:Array<String>;
	private var formatLabel:String;
	private var sourceFormat:String;
	private var songTitle:String;

	// MIDI 多声部选择（列表行数超过窗口时滚轮翻页）
	private var midiParts:Array<MidiPart> = null;
	private var midiSelected:Array<Bool> = [];
	private var midiRows:Array<PsychUICheckBox> = [];
	private var midiListBg:FlxSprite = null;
	private var midiScrollThumb:FlxSprite = null;
	private var midiScrollRow:Int = 0;
	private var midiViewRows:Int = 0;
	/** 上次算滚动条拇指几何时的行号（-1 = 还没算过），避免每帧重设缩放 */
	private var midiThumbRow:Int = -1;
	private var laneModeDropDown:PsychUIDropDownMenu = null;

	// 导出相关
	private var formatDropDown:PsychUIDropDownMenu;
	private var difficultyDropDown:PsychUIDropDownMenu;
	private var exportFormats:Array<String>;

	private var cancelBtn:PsychUIButton;

	// 检测到的键数（导入时）
	private var detectedKeys:Int;
	// 当前歌曲的键数（导出时）
	private var currentKeys:Int;

	// 版面量测结果（create 里算好，内容区构建函数直接用）
	private var infoMsg:String = '';
	private var infoH:Int = 0;
	private var hintMsg:String = '';
	private var hintH:Int = 0;

	// 关闭语义：确认按钮先把 confirmed 置 true，close() 据此决定要不要回调 onCancel
	private var confirmed:Bool = false;
	private var cancelFired:Bool = false;

	// 对话框尺寸
	private static inline var DIALOG_WIDTH:Int = 540;
	private static inline var PADDING:Int = 24;
	private static inline var BUTTON_WIDTH:Int = 170;
	private static inline var BUTTON_HEIGHT:Int = 32;
	private static inline var CANCEL_HEIGHT:Int = 28;
	private static inline var DROPDOWN_WIDTH:Int = 220;
	// MIDI 轨道列表
	private static inline var MIDI_ROW_H:Int = 22;
	private static inline var MIDI_LIST_PAD:Int = 4;
	private static inline var MIDI_BTN_H:Int = 22;
	private static var MIDI_MAX_ROWS:Int = 6;
	private static inline var INFO_SIZE:Int = 16;
	private static inline var HINT_SIZE:Int = 13;
	private static var EXPORT_DIFFS:Array<String> = ['Beginner', 'Easy', 'Medium', 'Hard', 'Challenge', 'Edit'];

	/**
	 * @param mode MODE_IMPORT 或 MODE_EXPORT
	 * @param detectedKeys 导入时检测到的源键数
	 * @param currentKeys 导出时当前歌曲的键数
	 * @param diffs 导入时源文件的难度列表
	 * @param formatLabel 导入时源格式显示名（如 'osu!mania (.osu)'）
	 * @param sourceFormat 导入时源格式 tag（如 'osz'），用于决定是否显示音频提取选项
	 * @param songTitle 导入时源曲名（可为空；'Unknown' 视为没有）
	 * @param midiParts 仅 MIDI：可选的声部列表（已按优先级排序，鼓组垫底）
	 */
	public function new(mode:Int, ?detectedKeys:Int = 4, ?currentKeys:Int = 4, ?diffs:Array<String> = null, ?formatLabel:String = '',
			?sourceFormat:String = '', ?songTitle:String = '', ?midiParts:Array<MidiPart> = null)
	{
		super();
		this.mode = mode;
		this.detectedKeys = detectedKeys;
		this.currentKeys = currentKeys;
		this.diffs = (diffs != null && diffs.length > 0) ? diffs : ['default'];
		this.formatLabel = formatLabel;
		this.sourceFormat = sourceFormat;
		this.songTitle = songTitle;
		this.exportFormats = ChartConvertCore.EXPORT_FORMATS;
		this.midiParts = midiParts;

		if(midiParts != null && midiParts.length > 0)
		{
			midiViewRows = (midiParts.length < MIDI_MAX_ROWS) ? midiParts.length : MIDI_MAX_ROWS;
			for(i in 0...midiParts.length)
				midiSelected.push(i == 0); // 默认只勾优先级最高的那一条（与旧版只读 1 号通道一致）
		}
	}

	override function create()
	{
		persistentUpdate = false;
		persistentDraw = true;

		// 编辑器的 camUI 是最后加入的那台相机（ChartMinimap、各面板都画在它上面）。
		// 弹窗不设相机会画默认相机（主相机），被 camUI 整层盖住 —— 谱面缩略图浮到
		// 弹窗上面就是这个原因。对齐到最后一台相机后 substate 后于父 state 绘制，
		// 弹窗必然盖过小地图（BasePrompt / ChartSourceSelectSubstate 同款做法）。
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		var showAudioOption:Bool = (mode == MODE_IMPORT && sourceFormat == 'osz');
		var showDiffOption:Bool = (mode == MODE_IMPORT) ? (diffs.length > 1) : true;

		// 先把文本内容与真实高度算出来，再决定对话框多高（曲名/格式/难度都可能多一行）
		infoMsg = buildInfoText(showDiffOption);
		hintMsg = buildHintText();
		infoH = measureTextHeight(infoMsg, INFO_SIZE);
		hintH = measureTextHeight(hintMsg, HINT_SIZE);
		var dialogHeight:Int = contentHeight(showDiffOption, showAudioOption);
		// 对话框不能比屏幕高：轨道列表先按 6 行算，超出就减行数（滚轮照样能翻）
		while(hasMidiTracks() && midiViewRows > 2 && dialogHeight > FlxG.height - 20)
		{
			midiViewRows--;
			dialogHeight = contentHeight(showDiffOption, showAudioOption);
		}

		// 背景半透明遮罩：1×1 拉伸（整屏 makeGraphic 会真分配一张全屏位图）
		bg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0.6;
		bg.scrollFactor.set();
		bg.cameras = cameras;
		add(bg);

		// 对话框背景
		var boxBg:FlxSprite = new FlxSprite().makeGraphic(DIALOG_WIDTH, dialogHeight, FlxColor.fromString('0xFF2A2A2A'));
		boxBg.screenCenter();
		boxBg.scrollFactor.set();
		boxBg.cameras = cameras;

		// 边框
		var border:FlxSprite = new FlxSprite(boxBg.x - 2, boxBg.y - 2).makeGraphic(DIALOG_WIDTH + 4, dialogHeight + 4, FlxColor.fromString('0xFF444444'));
		border.scrollFactor.set();
		border.cameras = cameras;
		add(border);
		add(boxBg);

		var centerX:Float = boxBg.x + DIALOG_WIDTH / 2;
		var currentY:Float = boxBg.y + PADDING;

		// 标题
		var titleTextStr:String = (mode == MODE_IMPORT)
			? Language.getPhrase('chart_import_title', 'Import Chart')
			: Language.getPhrase('chart_export_title', 'Export Chart');

		titleText = makeText(0, currentY, DIALOG_WIDTH, titleTextStr, 28, FlxColor.WHITE, CENTER);
		titleText.screenCenter(X);
		currentY += 44;

		// 分隔线
		var divider1:FlxSprite = new FlxSprite(boxBg.x + 40, currentY).makeGraphic(DIALOG_WIDTH - 80, 1, FlxColor.fromString('0xFF555555'));
		divider1.scrollFactor.set();
		divider1.cameras = cameras;
		add(divider1);
		currentY += 16;

		if(mode == MODE_IMPORT)
			createImportUI(boxBg, centerX, currentY, showDiffOption, showAudioOption);
		else
			createExportUI(boxBg, centerX, currentY);

		// 取消按钮 - 底部居中（onCancel 由 close() 统一触发，这里只管关）
		var cancelLabel:String = Language.getPhrase('chart_convert_cancel', 'Cancel');
		cancelBtn = new PsychUIButton(0, boxBg.y + dialogHeight - PADDING - CANCEL_HEIGHT, cancelLabel, function()
		{
			close();
		});
		cancelBtn.normalStyle.bgColor = FlxColor.fromString('0xFFEF4444');
		cancelBtn.text.font = Paths.font('vcr.ttf');
		cancelBtn.normalStyle.textColor = FlxColor.WHITE;
		cancelBtn.resize(120, CANCEL_HEIGHT);
		cancelBtn.x = centerX - cancelBtn.width / 2;
		cancelBtn.scrollFactor.set();
		cancelBtn.cameras = cameras;
		add(cancelBtn);

		// 两个导入下拉是并列的：目标键数只有在勾了"转换键数"时才有意义
		syncTargetKeysState();

		super.create();
	}

	/**
	 * 用同字号的临时文本量出真实高度（含换行后的行数），末尾补 8px 与下一项隔开。
	 * 对话框高度全由它决定，别再写死 66 / 38 这种魔法数字。
	 */
	private function measureTextHeight(msg:String, size:Int):Int
	{
		var probe:FlxText = new FlxText(0, 0, DIALOG_WIDTH - PADDING * 2, msg, size);
		probe.setFormat(Paths.font('vcr.ttf'), size, FlxColor.WHITE, CENTER);
		var h:Int = Std.int(probe.height) + 8;
		probe.destroy();
		return (h < size + 12) ? size + 12 : h; // 字体还没注册好时 height 可能为 0
	}

	/** 内容区高度，决定对话框整体高度（避免选项多时按钮和取消键重叠） */
	private function contentHeight(showDiffOption:Bool, showAudioOption:Bool):Int
	{
		var content:Int = infoH;
		if(mode == MODE_IMPORT)
		{
			if(hasMidiTracks())
				content += 22 + (midiViewRows * MIDI_ROW_H + MIDI_LIST_PAD * 2) + 6 + MIDI_BTN_H + 8 + 48;
			if(showDiffOption) content += 44;
			content += 36 + 36 + 48; // 键数复选框 + Funkin Keys 复选框 + 目标键数
			if(showAudioOption) content += 36;
			content += hintH;
		}
		else
		{
			content += 44 + 48; // 格式 + 难度名
			content += hintH;
		}
		content += 18; // 分隔线
		return PADDING + 44 + 16 + content + BUTTON_HEIGHT + 12 + CANCEL_HEIGHT + PADDING;
	}

	/** 信息区文本：导入显示曲名 / 源格式 / 源键数，导出显示当前键数 */
	private function buildInfoText(showDiffOption:Bool):String
	{
		if(mode == MODE_EXPORT)
			return Language.getPhrase('chart_export_info',
				'Export current chart to an external format.\nCurrent key count: {1}K keys per side',
				[Std.string(currentKeys)]);

		var head:String = '';
		if(songTitle != null && songTitle.length > 0 && songTitle != 'Unknown')
			head += songTitle + '\n';
		if(formatLabel != null && formatLabel.length > 0)
			head += formatLabel + '\n';

		return Language.getPhrase('chart_import_detected',
			'{1}Detected: {2}K keys per side\nChoose difficulty and target key count.',
			[head, Std.string(detectedKeys)]);
	}

	private function buildHintText():String
	{
		if(mode == MODE_EXPORT)
			return Language.getPhrase('chart_export_hint',
				'Note: .sm is widely compatible, .ssc keeps labels and BPM changes.\n.osu and .qua export the player side only.');

		return Language.getPhrase('chart_import_hint',
			'Note: Converting key counts will remap notes to the nearest column.\nHold notes will be preserved when possible.');
	}

	/**
	 * 统一创建 vcr.ttf 文本：抗锯齿跟随 ClientPrefs.data.antialiasing。
	 * 不设的话走 flixel 默认的 ADVANCED + sharpness 400 锐利档，等宽字体小字号下边缘毛刺明显。
	 */
	private function makeText(x:Float, y:Float, width:Float, content:String, size:Int, color:FlxColor, align:FlxTextAlign):FlxText
	{
		var text:FlxText = new FlxText(x, y, width, content, size);
		text.setFormat(Paths.font('vcr.ttf'), size, color, align);
		text.antialiasing = ClientPrefs.data.antialiasing;
		text.scrollFactor.set();
		text.cameras = cameras;
		add(text);
		return text;
	}

	/**
	 * 创建导入 UI
	 */
	private function createImportUI(boxBg:FlxSprite, centerX:Float, startY:Float, showDiffOption:Bool, showAudioOption:Bool):Void
	{
		var currentY:Float = startY;

		// 曲名 / 格式 / 键数信息
		infoText = makeText(boxBg.x + PADDING, currentY, DIALOG_WIDTH - PADDING * 2, infoMsg, INFO_SIZE,
			FlxColor.fromString('0xFFCCCCCC'), CENTER);
		currentY += infoH;

		// MIDI：多声部选择 + 音高映射
		if(hasMidiTracks()) currentY = createMidiTrackList(boxBg, centerX, currentY);

		// 难度选择（单难度文件不显示）
		if(showDiffOption)
		{
			makeText(centerX - 160, currentY + 6, 120,
				Language.getPhrase('chart_difficulty', 'Difficulty:'), 16, FlxColor.WHITE, LEFT);

			diffDropDown = addDropDown(centerX - 20, currentY, diffs.copy());
			diffDropDown.selectedIndex = 0;
			add(diffDropDown);
			currentY += 44;
		}

		// 转换键数复选框（勾选状态直接决定下面目标键数下拉是否可用）
		convertKeysCheck = new PsychUICheckBox(centerX - 140, currentY,
			Language.getPhrase('chart_convert_keys', 'Convert to different key count'), 220, syncTargetKeysState);
		// MIDI 没有"原始键数"概念，键数永远由这里决定 → 默认打开
		convertKeysCheck.checked = (detectedKeys >= 7) || hasMidiTracks();
		convertKeysCheck.text.font = Paths.font('vcr.ttf');
		convertKeysCheck.scrollFactor.set();
		convertKeysCheck.cameras = cameras;
		add(convertKeysCheck);
		currentY += 36;

		// Funkin Keys 4+4：把多 K 谱转成 FNF 经典「玩家 4 轨 / 对手 4 轨」双人布局。
		// 勾选后忽略上面的「转换键数 / 目标键数」（每侧固定 4 轨）。
		funkinKeysCheck = new PsychUICheckBox(centerX - 170, currentY,
			Language.getPhrase('chart_funkin_keys', 'Convert to Funkin Keys (4K+4K)'), 320, syncTargetKeysState);
		funkinKeysCheck.checked = false;
		funkinKeysCheck.text.font = Paths.font('vcr.ttf');
		funkinKeysCheck.scrollFactor.set();
		funkinKeysCheck.cameras = cameras;
		add(funkinKeysCheck);
		currentY += 36;

		// 目标键数下拉菜单
		targetKeysLabel = makeText(centerX - 160, currentY + 6, 120,
			Language.getPhrase('chart_target_keys', 'Target Keys:'), 16, FlxColor.WHITE, LEFT);

		var keyOptions:Array<String> = [];
		for(i in 4...17) // 4-16K
		{
			var label:String = Std.string(i) + 'K';
			if(i == detectedKeys) label += ' (original)';
			keyOptions.push(label);
		}

		targetKeysDropDown = addDropDown(centerX - 20, currentY, keyOptions);
		var defaultIndex:Int = detectedKeys - 4;
		if(detectedKeys < 4) defaultIndex = 0;
		if(detectedKeys > 16) defaultIndex = 12;
		targetKeysDropDown.selectedIndex = defaultIndex;
		currentY += 48;

		// .osz 才有包内音频可提
		if(showAudioOption)
		{
			extractAudioCheck = new PsychUICheckBox(centerX - 170, currentY,
				Language.getPhrase('chart_import_extract_audio', 'Extract audio from pack (save mode)'), 300);
			extractAudioCheck.checked = true;
			extractAudioCheck.text.font = Paths.font('vcr.ttf');
			extractAudioCheck.scrollFactor.set();
			extractAudioCheck.cameras = cameras;
			add(extractAudioCheck);
			currentY += 36;
		}

		// 转换提示
		makeText(boxBg.x + PADDING, currentY, DIALOG_WIDTH - PADDING * 2, hintMsg, HINT_SIZE,
			FlxColor.fromString('0xFF888888'), CENTER);
		currentY += hintH;

		// 分隔线
		var divider2:FlxSprite = new FlxSprite(boxBg.x + 40, currentY).makeGraphic(DIALOG_WIDTH - 80, 1, FlxColor.fromString('0xFF444444'));
		divider2.scrollFactor.set();
		divider2.cameras = cameras;
		add(divider2);
		currentY += 18;

		// 两个去向按钮：载入编辑器 / 保存 JSON
		var loadLabel:String = Language.getPhrase('chart_load_editor', 'Load to Editor');
		var loadBtn:PsychUIButton = new PsychUIButton(centerX - BUTTON_WIDTH - 10, currentY, loadLabel, function()
		{
			confirm(ACTION_LOAD);
		});
		loadBtn.normalStyle.bgColor = FlxColor.fromString('0xFF3B82F6');
		loadBtn.text.font = Paths.font('vcr.ttf');
		loadBtn.normalStyle.textColor = FlxColor.WHITE;
		loadBtn.resize(BUTTON_WIDTH, BUTTON_HEIGHT);
		loadBtn.scrollFactor.set();
		loadBtn.cameras = cameras;
		add(loadBtn);

		var saveLabel:String = Language.getPhrase('chart_save_json', 'Save JSON');
		var saveBtn:PsychUIButton = new PsychUIButton(centerX + 10, currentY, saveLabel, function()
		{
			confirm(ACTION_SAVE);
		});
		saveBtn.normalStyle.bgColor = FlxColor.fromString('0xFF22C55E');
		saveBtn.text.font = Paths.font('vcr.ttf');
		saveBtn.normalStyle.textColor = FlxColor.WHITE;
		saveBtn.resize(BUTTON_WIDTH, BUTTON_HEIGHT);
		saveBtn.scrollFactor.set();
		saveBtn.cameras = cameras;
		add(saveBtn);
	}

	/** 建下拉：挂相机并统一宽度 */
	private function addDropDown(x:Float, y:Float, opts:Array<String>):PsychUIDropDownMenu
	{
		var dd:PsychUIDropDownMenu = new PsychUIDropDownMenu(x, y, opts, function(id:Int, val:String) {}, DROPDOWN_WIDTH);
		dd.textObj.font = Paths.font('vcr.ttf');
		dd.scrollFactor.set();
		dd.cameras = cameras;
		add(dd);
		return dd;
	}

	/** 没勾"转换键数"时目标键数没有意义：灰掉。Funkin Keys 勾选时整组让位。 */
	private function syncTargetKeysState():Void
	{
		var funkin:Bool = (funkinKeysCheck != null && funkinKeysCheck.checked);

		if(convertKeysCheck != null)
			convertKeysCheck.alpha = funkin ? 0.45 : 1;

		if(targetKeysDropDown == null) return;
		var on:Bool = !funkin && (convertKeysCheck != null && convertKeysCheck.checked);
		// PsychUIDropDownMenu 没有 enabled，用 active 挡输入 + alpha 灰显
		targetKeysDropDown.active = on;
		targetKeysDropDown.alpha = on ? 1 : 0.45;
		if(targetKeysLabel != null)
			targetKeysLabel.color = on ? FlxColor.WHITE : FlxColor.fromString('0xFF666666');
	}

	// =========================================================
	// MIDI 轨道列表
	// =========================================================

	private function hasMidiTracks():Bool
	{
		return (mode == MODE_IMPORT) && midiParts != null && midiParts.length > 0 && midiViewRows > 0;
	}

	/**
	 * MIDI 多声部选择：标题 + 可滚动勾选列表 + 全选/全不选 + 音高映射下拉。
	 * 行数多于视口时滚轮整行翻页（不出现半行，所以不需要裁剪）。
	 * @return 内容区下一项的 y
	 */
	private function createMidiTrackList(boxBg:FlxSprite, centerX:Float, startY:Float):Float
	{
		var listW:Int = DIALOG_WIDTH - PADDING * 2;
		var listX:Float = boxBg.x + PADDING;
		var listH:Int = midiViewRows * MIDI_ROW_H + MIDI_LIST_PAD * 2;
		var y:Float = startY;

		var head:String = Language.getPhrase('chart_midi_tracks', 'MIDI tracks: {1}', [Std.string(midiParts.length)]);
		if(midiParts.length > midiViewRows)
			head += '  ' + Language.getPhrase('chart_midi_scroll_hint', '(scroll wheel to see all)');
		makeText(listX, y, listW, head, 15, FlxColor.WHITE, LEFT);
		y += 22;

		midiListBg = new FlxSprite(listX, y).makeGraphic(listW, listH, FlxColor.fromString('0xFF1E1E1E'));
		midiListBg.scrollFactor.set();
		midiListBg.cameras = cameras;
		add(midiListBg);

		for(i in 0...midiParts.length)
		{
			var row:PsychUICheckBox = new PsychUICheckBox(listX + 8, y + MIDI_LIST_PAD + i * MIDI_ROW_H,
				buildMidiRowLabel(i, midiParts[i]), listW - 26);
			row.name = Std.string(i);
			row.text.font = Paths.font('vcr.ttf');
			row.text.wordWrap = false;
			row.checked = midiSelected[i];
			row.onClick = function() onMidiRowToggled(row);
			row.scrollFactor.set();
			row.cameras = cameras;
			add(row);
			midiRows.push(row);
		}

		midiScrollThumb = new FlxSprite(0, 0).makeGraphic(3, 1, FlxColor.fromString('0xFF6B7280'));
		midiScrollThumb.scrollFactor.set();
		midiScrollThumb.cameras = cameras;
		add(midiScrollThumb);

		y += listH + 6;

		var allBtn:PsychUIButton = new PsychUIButton(listX + 2, y, Language.getPhrase('chart_midi_all', 'All'),
			function() setAllMidiRows(true), 54, MIDI_BTN_H);
		styleMidiButton(allBtn);
		add(allBtn);

		var noneBtn:PsychUIButton = new PsychUIButton(listX + 62, y, Language.getPhrase('chart_midi_none', 'None'),
			function() setAllMidiRows(false), 54, MIDI_BTN_H);
		styleMidiButton(noneBtn);
		add(noneBtn);

		y += MIDI_BTN_H + 8;

		makeText(centerX - 160, y + 6, 140, Language.getPhrase('chart_midi_lane', 'Lane mapping:'), 16, FlxColor.WHITE, LEFT);
		var laneOptions:Array<String> = [
			Language.getPhrase('chart_midi_lane_range', 'Pitch range'),
			Language.getPhrase('chart_midi_lane_mod', 'Pitch % keys')
		];
		laneModeDropDown = addDropDown(centerX - 20, y, laneOptions);
		laneModeDropDown.selectedIndex = 0;
		y += 48;

		updateMidiScrollBar();
		return y;
	}

	private function styleMidiButton(btn:PsychUIButton):Void
	{
		btn.normalStyle.bgColor = FlxColor.fromString('0xFF4B5563');
		btn.normalStyle.textColor = FlxColor.WHITE;
		btn.text.font = Paths.font('vcr.ttf');
		btn.scrollFactor.set();
		btn.cameras = cameras;
	}

	/** 行文案：序号 + 音色族 + 通道 + 音符数 + 音域（回声轨额外标注，免得选了同一段两遍） */
	private function buildMidiRowLabel(index:Int, part:MidiPart):String
	{
		var label:String = '#' + Std.string(index + 1) + '  ' + part.family + '  ch' + Std.string(part.channel + 1)
			+ '  ' + Std.string(part.notes.length) + '  p' + Std.string(part.pitchMin) + '-' + Std.string(part.pitchMax);
		if(part.echo) label += '  ' + Language.getPhrase('chart_midi_echo', '(echo)');
		return label;
	}

	private function onMidiRowToggled(row:PsychUICheckBox):Void
	{
		var index:Null<Int> = Std.parseInt(row.name);
		if(index == null || index < 0 || index >= midiSelected.length) return;
		midiSelected[index] = row.checked;
	}

	private function setAllMidiRows(value:Bool):Void
	{
		for(i in 0...midiRows.length)
		{
			midiRows[i].checked = value;
			midiSelected[i] = value;
		}
	}

	private function maxMidiScrollRow():Int
	{
		if(!hasMidiTracks()) return 0;
		var maxRow:Int = midiParts.length - midiViewRows;
		return (maxRow > 0) ? maxRow : 0;
	}

	private function mouseOverMidiList():Bool
	{
		if(midiListBg == null || cameras == null || cameras.length == 0) return false;
		var mouse:FlxPoint = FlxG.mouse.getViewPosition(cameras[0]);
		return mouse.x >= midiListBg.x && mouse.x <= midiListBg.x + midiListBg.width
			&& mouse.y >= midiListBg.y && mouse.y <= midiListBg.y + midiListBg.height;
	}

	/** 行位置 / 可见性 / 滚动条：视口外的行既不画也不吃点击 */
	private function updateMidiScrollBar():Void
	{
		if(midiListBg == null || midiScrollThumb == null || !hasMidiTracks()) return;

		var maxRow:Int = maxMidiScrollRow();
		if(midiScrollRow > maxRow) midiScrollRow = maxRow;
		if(midiScrollRow < 0) midiScrollRow = 0;

		for(i in 0...midiRows.length)
		{
			var row:PsychUICheckBox = midiRows[i];
			var inView:Bool = (i >= midiScrollRow) && (i < midiScrollRow + midiViewRows);
			row.visible = inView;
			row.active = inView;
			row.y = midiListBg.y + MIDI_LIST_PAD + (i - midiScrollRow) * MIDI_ROW_H;
		}

		if(maxRow <= 0)
		{
			midiScrollThumb.visible = false;
			return;
		}

		midiScrollThumb.visible = true;
		if(midiThumbRow != midiScrollRow)
		{
			// 拇指高度按「可见行 / 总行」算；只有滚动位置变了才重算缩放
			midiThumbRow = midiScrollRow;
			var trackH:Float = midiListBg.height;
			var thumbH:Float = trackH * midiViewRows / midiParts.length;
			if(thumbH < 16) thumbH = 16;
			if(thumbH > trackH) thumbH = trackH;
			midiScrollThumb.setGraphicSize(3, Std.int(thumbH));
			midiScrollThumb.updateHitbox();
			midiScrollThumb.x = midiListBg.x + midiListBg.width - 7;
			midiScrollThumb.y = midiListBg.y + (trackH - thumbH) * midiScrollRow / maxRow;
		}
	}

	// =========================================================
	// 导出 UI
	// =========================================================

	private function createExportUI(boxBg:FlxSprite, centerX:Float, startY:Float):Void
	{
		var currentY:Float = startY;

		// 信息文本
		infoText = makeText(boxBg.x + PADDING, currentY, DIALOG_WIDTH - PADDING * 2, infoMsg, INFO_SIZE,
			FlxColor.fromString('0xFFCCCCCC'), CENTER);
		currentY += infoH;

		// 格式选择
		makeText(centerX - 160, currentY + 6, 100,
			Language.getPhrase('chart_export_format', 'Format:'), 16, FlxColor.WHITE, LEFT);

		var formatOptions:Array<String> = [for(fmt in exportFormats) ChartConvertCore.FORMAT_LABELS.get(fmt) ?? fmt];
		formatDropDown = addDropDown(centerX - 20, currentY, formatOptions);
		formatDropDown.selectedIndex = 0;
		currentY += 44;

		// 难度选择
		makeText(centerX - 160, currentY + 6, 100,
			Language.getPhrase('chart_export_difficulty', 'Difficulty:'), 16, FlxColor.WHITE, LEFT);

		difficultyDropDown = addDropDown(centerX - 20, currentY, EXPORT_DIFFS.copy());
		difficultyDropDown.selectedIndex = 4; // 默认 Challenge
		currentY += 48;

		// 导出选项提示
		makeText(boxBg.x + PADDING, currentY, DIALOG_WIDTH - PADDING * 2, hintMsg, HINT_SIZE,
			FlxColor.fromString('0xFF888888'), CENTER);
		currentY += hintH;

		// 分隔线
		var divider2:FlxSprite = new FlxSprite(boxBg.x + 40, currentY).makeGraphic(DIALOG_WIDTH - 80, 1, FlxColor.fromString('0xFF444444'));
		divider2.scrollFactor.set();
		divider2.cameras = cameras;
		add(divider2);
		currentY += 18;

		// 导出按钮
		var exportLabel:String = Language.getPhrase('chart_export', 'Export');
		var exportBtn:PsychUIButton = new PsychUIButton(centerX - 90, currentY, exportLabel, function()
		{
			confirm(ACTION_EXPORT);
		});
		exportBtn.normalStyle.bgColor = FlxColor.fromString('0xFF22C55E');
		exportBtn.text.font = Paths.font('vcr.ttf');
		exportBtn.normalStyle.textColor = FlxColor.WHITE;
		exportBtn.resize(180, BUTTON_HEIGHT);
		exportBtn.scrollFactor.set();
		exportBtn.cameras = cameras;
		add(exportBtn);
	}

	private function selectedDiff():String
	{
		if(diffDropDown != null)
			return diffs[diffDropDown.selectedIndex] ?? diffs[0];
		return diffs[0];
	}

	private function buildOptions(action:Int):ChartConvertOptions
	{
		var convertKeys:Bool = (convertKeysCheck != null && convertKeysCheck.checked);

		var selectedParts:Array<Int> = null;
		if(hasMidiTracks())
		{
			selectedParts = [];
			for(i in 0...midiParts.length)
				if(midiSelected[i]) selectedParts.push(midiParts[i].id);
			if(selectedParts.length == 0) selectedParts = null; // 一条没勾：交给核心退回默认声部
		}

		return {
			action: action,
			format: (mode == MODE_IMPORT || formatDropDown == null) ? null : exportFormats[formatDropDown.selectedIndex],
			diff: (mode == MODE_IMPORT) ? selectedDiff() : EXPORT_DIFFS[difficultyDropDown.selectedIndex],
			convertKeys: convertKeys,
			targetKeys: (targetKeysDropDown != null) ? targetKeysDropDown.selectedIndex + 4 : detectedKeys,
			funkinKeys: (funkinKeysCheck != null && funkinKeysCheck.checked),
			extractAudio: (extractAudioCheck != null && extractAudioCheck.checked),
			midiParts: selectedParts,
			midiLaneMode: (laneModeDropDown != null && laneModeDropDown.selectedIndex == 1)
				? ChartConvertCore.MIDI_LANE_MOD : ChartConvertCore.MIDI_LANE_RANGE
		};
	}

	/**
	 * 确认出口：先把 confirmed 置位（onConfirm 里可能开新弹窗/原生文件对话框，
	 * 期间本弹窗的 close() 不能再当成"取消"），再回调、再关。
	 */
	private function confirm(action:Int):Void
	{
		var opts:ChartConvertOptions = buildOptions(action);
		confirmed = true;
		if(onConfirm != null) onConfirm(opts);
		close();
	}

	/** 取消只回调一次：Esc / 取消按钮 / 任何 close() 路径都走这里 */
	override public function close():Void
	{
		if(!confirmed && !cancelFired)
		{
			cancelFired = true;
			if(onCancel != null) onCancel();
		}
		super.close();
	}

	// =========================================================
	// 交互
	// =========================================================

	override public function update(elapsed:Float):Void
	{
		// 轨道列表：滚轮翻页（整行滚动，不会出现半行）
		// 注：PsychUIDropDownMenu 没有 isOpen，无法像 FE 的 Win8DropDown 那样在弹层展开时
		// 挂起其它组件，下拉弹层的点击穿透是旧组件的已知行为。
		if(hasMidiTracks() && FlxG.mouse.wheel != 0 && mouseOverMidiList())
		{
			if(maxMidiScrollRow() > 0)
			{
				midiScrollRow -= FlxG.mouse.wheel;
				updateMidiScrollBar();
			}
		}
		else updateMidiScrollBar();

		if(controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
			close();
			return;
		}

		super.update(elapsed);
	}

	public function UIEvent(id:String, sender:Dynamic)
	{
		// 处理 UI 事件
	}
}
