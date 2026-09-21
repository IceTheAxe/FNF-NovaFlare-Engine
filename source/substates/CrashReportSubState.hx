package substates;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

/**
 * 崩溃报告界面。
 *
 * 直接继承 flixel.FlxSubState 而不是 MusicBeatSubstate：后者的 create() 会走
 * ColorblindFilter.UpdateColors() -> ClientPrefs.data，启动早期崩溃时这些可能还是 null，
 * 会让"显示崩溃"这一步自己再抛一次异常。这里只依赖 FlxText 和内建相机，
 * 每一步单独包 try，保证 create() 永远不会抛。
 */
class CrashReportSubState extends FlxSubState
{
	static final CLOSE_DELAY:Float = 15;
	static final TITLE_HEIGHT:Float = 34;
	static final FOOTER_HEIGHT:Float = 30;

	var reportText:String;
	var restorePersistentUpdate:Bool;

	var title:FlxText;
	var body:FlxText;
	var hint:FlxText;

	var dragging:Bool = false;
	var dragOffset:Float = 0;

	/**
	 * @param reportText 报告正文
	 * @param restorePersistentUpdate 父 state 原本的 persistentUpdate 值，关闭时还原
	 */
	public function new(reportText:String, restorePersistentUpdate:Bool)
	{
		super(0xD9000000);
		this.reportText = reportText;
		this.restorePersistentUpdate = restorePersistentUpdate;
	}

	override function create():Void
	{
		try
		{
			super.create();

			// 不设 cameras 时会落到 FlxCamera._defaultCameras（通常只有 camGame），
			// 在 PlayState 里会被 camGame 的 zoom/scroll 推偏。取列表最后一台（camOther）。
			if (FlxG.cameras.list != null && FlxG.cameras.list.length > 0)
				cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

			title = new FlxText(12, 8, FlxG.width - 24, 'NovaFlare Engine - Error', 22);
			title.color = FlxColor.WHITE;
			add(title);

			body = new FlxText(12, TITLE_HEIGHT + 8, FlxG.width - 24, reportText, 14);
			body.color = FlxColor.WHITE;
			add(body);

			hint = new FlxText(12, FlxG.height - FOOTER_HEIGHT + 4, FlxG.width - 24, 'Press ENTER / BACK to close', 13);
			hint.color = FlxColor.WHITE;
			hint.alpha = 0.7;
			add(hint);

			new FlxTimer().start(CLOSE_DELAY, function(_) close());
		}
		catch (_:Dynamic) {}
	}

	override function update(elapsed:Float):Void
	{
		try
		{
			var wantsClose:Bool = FlxG.keys.justPressed.ENTER;
			#if android
			if (!wantsClose) wantsClose = FlxG.android.justReleased.BACK;
			#end
			if (wantsClose)
			{
				close();
				return;
			}

			updateDragScroll();
			super.update(elapsed);
		}
		catch (_:Dynamic) {}
	}

	/**
	 * 文本超出可视区域时可以拖动滚动，方便查看完整堆栈。
	 */
	private function updateDragScroll():Void
	{
		if (body == null)
			return;

		var minY:Float = (FlxG.height - FOOTER_HEIGHT) - body.height;
		var maxY:Float = TITLE_HEIGHT + 8;
		if (body.height <= FlxG.height - FOOTER_HEIGHT - maxY)
		{
			dragging = false;
			return;
		}

		if (FlxG.mouse.justPressed)
		{
			dragging = true;
			dragOffset = FlxG.mouse.gameY - body.y;
		}
		else if (FlxG.mouse.justReleased)
			dragging = false;

		if (!dragging)
			return;

		// 本界面画在 zoom=1 / scroll=0 的相机上，gameY 就是屏幕坐标。
		body.y = FlxG.mouse.gameY - dragOffset;
		if (body.y < minY) body.y = minY;
		if (body.y > maxY) body.y = maxY;
	}

	override function close():Void
	{
		try
		{
			if (FlxG.state != null)
				FlxG.state.persistentUpdate = restorePersistentUpdate;
		}
		catch (_:Dynamic) {}
		super.close();
	}
}
