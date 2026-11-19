package mobile.backend;

import flixel.FlxG;
import general.backend.ClientPrefs;
import lime.system.System;

/**
 * 边缘安全区（刘海 / 灵动岛 / 挖孔 / 圆角 / Home 条）的内缩量（自 FE 移动版移植）。
 *
 * 数据源：lime 的 `System.getDisplay(0).safeArea`——
 *   Android 走 GameActivity JNI 的 DisplayCutout insets，
 *   iOS 走 `UIWindow.safeAreaInsets`（系统报多少就是多少，不需要机型表）。
 * 需要配合 Project.xml 的 `layoutInDisplayCutoutMode="shortEdges"`，
 * 否则窗口根本不延伸进刘海区，safeArea 恒等于全屏。
 *
 * 两个取值域：
 *   get()     —— 画布 px 域，主要入口。物理内缩按 画布宽/窗口宽 折算成画布 px。
 *                仅 wideScreen 非零：16:9 画布由 MobileScaleMode 居中留黑边，
 *                画布根本伸不到刘海里，内缩反而白浪费操作区。
 *   getStage() —— openfl stage 逻辑坐标域。NF 与 FE 的差异：NF 的分辨率设置
 *                （setLogicalSize）会让 stage 逻辑坐标 ≠ 物理 px，这里按
 *                stage 宽/窗口宽 折算；且不做 wideScreen 门控——stage 域元素
 *                （FPSViewer / Watermark / 虚拟鼠标辅助条）在 16:9 信箱模式下
 *                也贴窗口边缘，同样会被刘海挡住。
 *
 * 手动叠加：ClientPrefs.data.edgeSafeOffset（自动检测之外的补充内缩），
 * 仅 get() 里叠加，改后下一个界面生效。
 */
class SafeArea
{
	public var left:Float = 0;
	public var top:Float = 0;
	public var right:Float = 0;
	public var bottom:Float = 0;

	public function new()
	{
	}

	public inline function hasAny():Bool
		return left > 0 || top > 0 || right > 0 || bottom > 0;

	public static function get():SafeArea
	{
		var out:SafeArea = new SafeArea();

		#if mobile
		var phys = physicalInsets(true);
		if (phys == null) return out;

		// 物理 px → 画布 px（画布等比映射到窗口，横向比例即统一比例）
		var win = FlxG.stage.window;
		var f:Float = FlxG.width / win.width;

		var manual:Float = ClientPrefs.data.edgeSafeOffset;
		out.left = Math.max(0, phys.l * f) + manual;
		out.top = Math.max(0, phys.t * f) + manual;
		out.right = Math.max(0, phys.r * f) + manual;
		out.bottom = Math.max(0, phys.b * f) + manual;

		// 兜底：内缩总量吃掉半个屏幕以上必然是读数异常，直接不缩
		if (out.left + out.right >= FlxG.width * 0.5 || out.top + out.bottom >= FlxG.height * 0.5)
		{
			out.left = out.top = out.right = out.bottom = 0;
		}
		#end

		return out;
	}

	/**
	 * stage 逻辑坐标域的四边内缩：不折算画布、不叠手动量。
	 * 给活在 openfl stage 坐标系里的贴边元素用（FPSViewer / Watermark / 虚拟鼠标辅助条）。
	 */
	public static function getStage():SafeArea
	{
		var out:SafeArea = new SafeArea();

		#if mobile
		var stage = FlxG.stage;
		var win = stage != null ? stage.window : null;
		if (win == null || win.width <= 0) return out;

		var phys = physicalInsets(false);
		if (phys == null) return out;

		// 物理 px → stage 逻辑 px（setLogicalSize 会缩放 stage 坐标系）
		var f:Float = stage.stageWidth / win.width;
		out.left = Math.max(0, phys.l * f);
		out.top = Math.max(0, phys.t * f);
		out.right = Math.max(0, phys.r * f);
		out.bottom = Math.max(0, phys.b * f);
		#end

		return out;
	}

	#if mobile
	/**
	 * 四边物理内缩（display 坐标系 → 相对窗口）。取不到读数返回 null。
	 * requireWide = true（画布域）：仅 wideScreen 非零，16:9 画布伸不到刘海（黑边在外）。
	 * requireWide = false（stage 域）：窗口本身贴满屏幕，信箱模式刘海也压在窗口边上。
	 */
	static function physicalInsets(requireWide:Bool):{l:Float, t:Float, r:Float, b:Float}
	{
		if (requireWide && (ClientPrefs.data == null || !ClientPrefs.data.wideScreen)) return null;

		// Window 类型在 NF 的 lime fork 里与上游包路径不同，这里不写死类型，直接从 stage 取
		var stage = FlxG.stage;
		var win = stage != null ? stage.window : null;
		if (win == null || win.width <= 0 || win.height <= 0) return null;

		var display = System.getDisplay(0);
		var safe = display != null ? display.safeArea : null;
		if (safe == null || safe.width <= 0 || safe.height <= 0) return null; // 桌面/取不到 → 无遮挡

		return {
			l: safe.x - win.x,
			t: safe.y - win.y,
			r: (win.x + win.width) - (safe.x + safe.width),
			b: (win.y + win.height) - (safe.y + safe.height)
		};
	}
	#end
}
