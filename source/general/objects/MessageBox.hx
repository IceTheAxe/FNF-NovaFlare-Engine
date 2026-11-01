package general.objects;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;

import general.backend.MetroEase;
import win8.Theme;

/**
 * 全局 Metro/Win8 风格消息通知（toast），自 Frozen Engine 的 MessageBox 移植。
 *
 * FE 原版是 openfl.Sprite 挂 FlxG.game；这里改成 FlxSpriteGroup，
 * 直接 `FlxG.state.add()` 挂到当前 state 上（随 state 销毁，不需要全局保活），
 * 动画全部在自己的 update() 里驱动，不依赖 FlxTween/FlxTimer。
 *
 * 贴屏幕右边缘（直角、无阴影），从右侧推入并淡入，停留计时结束后向右滑出并淡出。
 * 缓动走 Win8 官方的两条 cubic-bezier（见 MetroEase）。
 *
 * 通过静态方法 `MessageBox.show(标题, 正文, 停留秒数)` 调用，
 * 内部用 `activeList` 队列维护多条堆叠，关闭后其余自动上移重排。
 * duration <= 0 时直接不创建。
 */
class MessageBox extends FlxSpriteGroup
{
	// 注意：不能叫 active —— FlxBasic.active:Bool 会遮蔽静态字段
	public static var activeList:Array<MessageBox> = [];

	/** 设计尺寸（game 坐标），Win8 通知条宽 480（比 FE 原版宽一档，装得下一行判定窗口），高按正文自适应（最低 80） */
	static var WIDTH:Float = 480;
	static var PAD:Float = 16;
	static var TOP_MARGIN:Float = 24;
	static var SIDE_MARGIN:Float = 0; // 紧贴右边缘
	static var STACK_GAP:Float = 8;

	// Win8 动效时长：入场 333ms，出场 200ms
	static var SLIDE_IN_TIME:Float = 0.33;
	static var SLIDE_OUT_TIME:Float = 0.20;
	static var FADE_IN_TIME:Float = 0.16;
	static var FADE_OUT_TIME:Float = 0.20;

	public var duration:Float;
	/** 堆叠队列里的目标 y（update 里平滑跟随） */
	public var targetY:Float = TOP_MARGIN;

	var boxH:Float = 80;
	var timeLeft:Float;
	var progress:Float = 1;
	var state:Int = 0; // 0=SLIDE_IN, 1=HOLD, 2=SLIDE_OUT
	var phaseT:Float = 0;
	var killed:Bool = false;

	var fillBar:FlxSprite;

	/**
	 * 弹一条通知。duration 为停留秒数（不含滑入滑出），<= 0 不创建并返回 null。
	 * 返回实例以便调用方调整（如 PlayState 里改挂 camHUD）。
	 */
	public static function show(title:String, body:String, ?duration:Float = 5.0):MessageBox
	{
		if (duration <= 0) return null;

		var mb = new MessageBox(title, body, duration);
		activeList.push(mb);
		recalcTargets();
		mb.y = mb.targetY; // 新条直接落自己的槽位，只做横向推入
		FlxG.state.add(mb);
		return mb;
	}

	static function recalcTargets():Void
	{
		for (i in 0...activeList.length)
			activeList[i].targetY = TOP_MARGIN + i * (activeList[i].boxH + STACK_GAP);
	}

	public function new(title:String, body:String, ?duration:Float = 5.0)
	{
		super();

		this.duration = Math.max(0.1, duration);
		timeLeft = this.duration;

		var textW:Float = WIDTH - PAD * 2;

		var titleTxt:FlxText = new FlxText(PAD, 6, textW, title, 17);
		titleTxt.setFormat(Paths.font('Lang-ZH.ttf'), 17, Theme.text(), LEFT);
		titleTxt.antialiasing = ClientPrefs.data.antialiasing;

		var bodyTxt:FlxText = new FlxText(PAD, 28, textW, body, 14);
		bodyTxt.setFormat(Paths.font('Lang-ZH.ttf'), 14, Theme.textSecondary(), LEFT);
		bodyTxt.antialiasing = ClientPrefs.data.antialiasing;
		bodyTxt.updateHitbox();

		boxH = Math.max(80, 28 + bodyTxt.height + 12);

		// 背景（Metro 扁平直角），底部一条停留倒计时进度条
		var bg:FlxSprite = new FlxSprite().makeGraphic(Std.int(WIDTH), Std.int(boxH), Theme.panelBG());
		var trackBar:FlxSprite = new FlxSprite(0, boxH - 3).makeGraphic(Std.int(WIDTH), 3, Theme.track());
		fillBar = new FlxSprite(0, boxH - 3).makeGraphic(Std.int(WIDTH), 3, Theme.accent());
		fillBar.origin.set(0, fillBar.height / 2); // 从左端向右收缩

		add(bg);
		add(trackBar);
		add(fillBar);
		add(titleTxt);
		add(bodyTxt);

		x = FlxG.width + 8;
		alpha = 0;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		phaseT += elapsed;

		switch (state)
		{
			case 0: // SLIDE_IN：从右侧推入并淡入
				var k:Float = Math.min(1, phaseT / SLIDE_IN_TIME);
				x = FlxMath.lerp(FlxG.width + 8, FlxG.width - WIDTH - SIDE_MARGIN, MetroEase.ENTRANCE(k));
				alpha = Math.min(1, phaseT / FADE_IN_TIME);
				if (k >= 1)
				{
					state = 1;
					phaseT = 0;
				}
			case 1: // HOLD：停留倒计时（进度条同步排空）
				timeLeft -= elapsed;
				progress = Math.max(0, timeLeft / duration);
				if (timeLeft <= 0) slideOut();
			case 2: // SLIDE_OUT：向右滑出并淡出，结束后自毁
				var k:Float = Math.min(1, phaseT / SLIDE_OUT_TIME);
				x = FlxMath.lerp(FlxG.width - WIDTH - SIDE_MARGIN, FlxG.width + 8, MetroEase.EXIT(k));
				alpha = 1 - Math.min(1, phaseT / FADE_OUT_TIME);
				if (k >= 1)
				{
					destroy();
					return;
				}
		}

		// 竖直方向平滑跟随堆叠重排
		y += (targetY - y) * Math.min(1, elapsed * 11);

		fillBar.scale.x = Math.max(0.0001, progress);
	}

	/** 立刻滑出（不等停留倒计时） */
	public function slideOut():Void
	{
		if (state == 2) return;
		state = 2;
		phaseT = 0;
	}

	override public function destroy():Void
	{
		if (killed) return;
		killed = true;
		exists = false; // 自毁后立刻从所属 state 的更新/绘制里退出
		activeList.remove(this);
		recalcTargets();
		super.destroy();
	}
}
