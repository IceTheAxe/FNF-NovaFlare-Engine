package mobile.backend;

import openfl.events.UncaughtErrorEvent;
import openfl.events.ErrorEvent;
import openfl.errors.Error;

#if sys
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
#end

#if cpp
import cpp.vm.Gc;
#end

using general.backend.CoolUtil;

/**
 * Crash Handler.
 * @author YoshiCrafter29, Ne_Eo and MAJigsaw77
 */
class CrashHandler
{
	public static function init():Void
	{
		// 先注册 Haxe 层异常监听
		openfl.Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
		
		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onError);
		#elseif hl
		hl.Api.setErrorHandler(onError);
		#end
		
		// 延迟初始化原生崩溃处理器（等 Haxe 层处理完再启动）
		#if (cpp && (windows || android))
		// 使用延迟初始化，让 Haxe 层先处理异常
		haxe.Timer.delay(function() {
			general.backend.NativeCrashHandler.init(
				states.mainMenuState.MainMenuState.novaFlareEngineCommit
			);
		}, 100); // 延迟 100ms 确保 Haxe 层已就绪
		#end
	}

	public static function refreshNativeCrashDirectory():Void
	{
		#if (cpp && (windows || android))
		general.backend.NativeCrashHandler.refreshDirectory();
		#end
	}

	/**
	 * Haxe 层未捕获异常的总入口。
	 *
	 * 本函数运行在 openfl.display.Stage.__handleError() 内部，而 __handleError 是从
	 * Stage.__broadcastEvent() 的 catch 块里调用的、自身没有被 try 包住。所以这里抛出的
	 * 任何异常都会穿过 Lime 的原生渲染回调逃到操作系统，最终被 NativeCrashHandler 当成
	 * 原生崩溃处理（写 native-crash-*.txt 并杀掉进程）。因此必须是严格的 no-throw 区域。
	 */
	private static function onUncaughtError(e:UncaughtErrorEvent):Void
	{
		try
		{
			if (e != null)
			{
				// 必须在任何可能失败的操作之前调用：__handleError 只在 __preventDefault
				// 为 false 时才 Log.println 并重新抛出异常，而这正是"游戏还能继续跑"的依据。
				e.preventDefault();
				e.stopPropagation();
				e.stopImmediatePropagation();
			}
			reportUncaughtError(e);
		}
		catch (_:Dynamic)
		{
			// 故意留空。Std.string / trace / Sys.println 自身都可能抛异常
			// （TraceInterceptor、失效的 stdio），所以这里什么都不碰。
		}
	}

	private static function reportUncaughtError(e:UncaughtErrorEvent):Void
	{
		var m:String = '<unknown error>';
		try if (e != null) m = Std.string(e.error) catch (_:Dynamic) {}

		if (e != null && Std.isOfType(e.error, Error))
		{
			try m = '${cast(e.error, Error).message}' catch (_:Dynamic) {}
		}
		else if (e != null && Std.isOfType(e.error, ErrorEvent))
		{
			try m = '${cast(e.error, ErrorEvent).text}' catch (_:Dynamic) {}
		}

		var stack:Array<haxe.CallStack.StackItem> = [];
		var callStack:Array<haxe.CallStack.StackItem> = [];
		try stack = haxe.CallStack.exceptionStack(true) catch (_:Dynamic) {}
		try callStack = haxe.CallStack.callStack() catch (_:Dynamic) {}

		var stackLabelArr:Array<String> = [];
		try
		{
			for (item in stack)
			{
				switch (item)
				{
					case CFunction:
						stackLabelArr.push("Non-Haxe (C) Function");
					case Module(c):
						stackLabelArr.push('Module ${c}');
					case FilePos(parent, file, line, col):
						// 裁剪过的栈上 file 可能为 null，直接 replace 会抛 NullReference。
						var where:String = (file != null) ? file.replace('.hx', '') : '<unknown>';
						switch (parent)
						{
							case Method(owner, func):
								stackLabelArr.push('$where.$func() [line $line]');
							case _:
								stackLabelArr.push('$where [line $line]');
						}
					case LocalFunction(v):
						stackLabelArr.push('Local Function ${v}');
					case Method(owner, methodName):
						stackLabelArr.push('${owner} - ${methodName}');
				}
			}
		}
		catch (_:Dynamic) {}

		var stackLabel:String = "";
		try stackLabel = stackLabelArr.join('\r\n') catch (_:Dynamic) {}

		#if sys
		var savedCrashPath:String = writeHaxeCrashReport("uncaught_error", m, stackLabel, stack, callStack);

		// 优先在游戏内展示，非阻塞。原生模态对话框会阻塞渲染线程，与"继续运行"的目标矛盾。
		var shown:Bool = false;
		try shown = showInGameErrorReport(savedCrashPath, m, stackLabel) catch (_:Dynamic) {}

		// 兜底原生弹窗：只在游戏内报告完全没法展示、且本进程还没弹过时才出现。
		// SUtil.showPopUp 在桌面端是 lime 的 SDL_ShowSimpleMessageBox —— 阻塞主线程的
		// 原生模态框。错误每帧都在抛时逐帧调用，结果就是"关掉立刻再弹"，看起来像关不掉。
		if (!shown && !nativePopupShown)
		{
			nativePopupShown = true;
			try
			{
				var popupMessage:String = savedCrashPath != null
					? '程序发生致命错误。\n错误信息已保存至：\n$savedCrashPath\n\nA fatal error occurred.\nThe error report was saved to:\n$savedCrashPath'
					: '程序发生致命错误，但错误报告保存失败。\n\nA fatal error occurred, but the report could not be saved.';
				try mobile.backend.SUtil.showPopUp(popupMessage, "NovaFlare Engine - Error") catch (_:Dynamic) {}
			}
			catch (_:Dynamic) {}
		}

		try general.backend.NativeCrashHandler.setHaxeRuntimeSnapshot("") catch (_:Dynamic) {}
		#end
	}

	#if sys
	/**
	 * 同一条消息在这个时间窗口内重复出现时复用已有的报告文件，
	 * 避免"每帧一个崩溃文件"把 crash 目录塞爆。
	 */
	private static final REPORT_DEDUP_WINDOW_MS:Float = 2000;

	private static var lastReportMessage:String = null;
	private static var lastReportTime:Float = 0;
	private static var lastReportPath:String = null;
	private static var inGameReportActive:Bool = false;
	private static var inGameReportMessage:String = null;
	private static var inGameReportStatus:String = "not-attempted";
	private static var nativePopupShown:Bool = false;

	/**
	 * 把一份崩溃报告写到磁盘并返回报告绝对路径。
	 *
	 * 本函数永不抛异常：调用方都在异常处理路径上，从这里逃逸出去的异常会变成原生崩溃。
	 * @param kind 报告类型标记，例如 "uncaught_error" / "hxcpp_critical_error"
	 * @return 报告绝对路径；同消息去重时返回上一次的路径；完全写不出去时返回 null
	 */
	private static function writeHaxeCrashReport(kind:String, message:String, stackLabel:String,
			stack:Array<haxe.CallStack.StackItem>, callStack:Array<haxe.CallStack.StackItem>):String
	{
		var savedCrashPath:String = null;
		try
		{
			var now:Float = haxe.Timer.stamp() * 1000;
			if (message == lastReportMessage && now - lastReportTime < REPORT_DEDUP_WINDOW_MS)
				return lastReportPath;

			lastReportMessage = message;
			lastReportTime = now;

			var haxeSnapshot:String = "";
			try haxeSnapshot = captureHaxeStackSnapshot(stack)
			catch (snapshotError:Dynamic)
				haxeSnapshot = '[snapshot_capture_failed] ${Std.string(snapshotError)}';

			// 让原生崩溃处理器也能读到这份 Haxe 上下文。
			try general.backend.NativeCrashHandler.setHaxeRuntimeSnapshot(haxeSnapshot) catch (_:Dynamic) {}

			var diagnosticRoot = Sys.getEnv("NOVAFLARE_DIAGNOSTIC_DIR");
			var crashDirectory = diagnosticRoot != null && diagnosticRoot.length > 0
				? Path.join([diagnosticRoot, "haxe-crash"])
				: "crash";
			if (!FileSystem.exists(crashDirectory))
				FileSystem.createDirectory(crashDirectory);

			var nativeExceptionStack = "";
			#if cpp
			try nativeExceptionStack = Std.string(haxe.NativeStackTrace.exceptionStack()) catch (_:Dynamic) {}
			#end

			var heapSnapshot = "unavailable";
			#if cpp
			try
			{
				#if hxcpp_zgc
				heapSnapshot =
					'used_bytes=${Gc.memInfo64(2)}\n' +
					'committed_bytes=${Gc.memInfo64(4)}\n' +
					'application_bytes=${Gc.memInfo64(8)}';
				#else
				heapSnapshot =
					'used_bytes=${Gc.memInfo64(2)}\n' +
					'committed_bytes=${Gc.memInfo64(1)}\n' +
					'application_bytes=${Gc.memInfo64(4)}';
				#end
			}
			catch (_:Dynamic) {}
			#end

			var saveError =
				'kind=$kind\n' +
				'commit=${states.mainMenuState.MainMenuState.novaFlareEngineCommit}\n' +
				'timestamp=${Date.now()}\n' +
				'message=$message\n' +
				// 上一次游戏内展示的结果。写报告发生在展示之前，所以这里记的是上一轮，
				// 错误每帧都在抛时下一份报告就能看到失败原因。
				'in_game_report=$inGameReportStatus\n' +
				'\n[haxe_exception_stack]\n$stackLabel\n' +
				'\n[haxe_runtime_snapshot]\n$haxeSnapshot\n' +
				'\n[haxe_exception_stack_raw]\n${haxe.CallStack.toString(stack)}\n' +
				'\n[haxe_call_stack]\n${haxe.CallStack.toString(callStack)}\n' +
				'\n[native_hxcpp_exception_stack]\n$nativeExceptionStack\n' +
				'\n[heap]\n$heapSnapshot\n';
			var fileName = Date.now().toString()
				.replace(' ', '-')
				.replace(':', "'") + '.txt';
			var crashPath = FileSystem.absolutePath(Path.join([crashDirectory, fileName]));
			File.saveContent(crashPath, saveError);
			savedCrashPath = crashPath;
			lastReportPath = crashPath;
			try Sys.println('haxe:$kind message=$message') catch (_:Dynamic) {}
			try Sys.println(saveError) catch (_:Dynamic) {}
		}
		catch (_:Dynamic)
		{
			// 报告写盘失败。吞掉：调用方不允许抛异常。
		}
		return savedCrashPath;
	}

	/**
	 * 尝试在游戏内展示崩溃报告，返回 true 表示"已经处理，不要再弹原生对话框"。
	 *
	 * 本函数永不抛异常，任何一步失败都返回 false，让调用方退回原生弹窗兜底。
	 */
	private static function showInGameErrorReport(savedCrashPath:String, message:String, stackLabel:String):Bool
	{
		// 防重入。错误界面自身再触发异常时会重新进入本函数，必须抑制：
		// 每帧重建一次界面会不断分配对象，而且会连带每帧弹一次原生框。
		if (inGameReportActive)
		{
			// 界面还在屏上 → 直接抑制。
			if (flixel.FlxG.state != null && flixel.FlxG.state.subState != null)
				return true;

			// 界面已被用户关掉。同一条错误不再重新展示（错误每帧都在抛，重展等于界面关不掉），
			// 但照样返回 true 抑制原生弹窗。
			if (message == inGameReportMessage)
				return true;

			inGameReportActive = false;
		}

		try
		{
			if (flixel.FlxG.game == null)
			{
				inGameReportStatus = "skipped: FlxG.game is null";
				return false;
			}

			var current = flixel.FlxG.state;
			if (current == null)
			{
				inGameReportStatus = "skipped: FlxG.state is null";
				return false;
			}

			#if CODENAME_ENGINE_COMPAT
			if (codenamechain.CodeNameMode.active)
			{
				// 不调用 Sys.exit：那会直接放弃"继续运行"。
				codename.funkin.backend.utils.NativeAPI.showMessageBox(
					"NovaFlare Engine - CodeName Error",
					message,
					codename.funkin.backend.utils.NativeAPI.MessageBoxIcon.MSG_ERROR);
				inGameReportActive = true;
				inGameReportMessage = message;
				inGameReportStatus = "shown: codename message box";
				return true;
			}
			#end

			if (originfunkin.OriginFunkinMode.active)
			{
				originfunkin.OriginFunkinMode.reportRuntimeError(message);
				flixel.FlxG.switchState(new originfunkin.OriginFunkinErrorState());
				inGameReportActive = true;
				inGameReportMessage = message;
				inGameReportStatus = "shown: origin error state";
				return true;
			}

			var body:String = (savedCrashPath != null ? 'Error report saved to:\n$savedCrashPath\n\n' : '')
				+ message
				+ (stackLabel.length > 0 ? '\n\n$stackLabel' : '');

			var report = new substates.ErrorSubState(body);

			// openSubState() 只是把请求排进队列，真正安装发生在 FlxState.tryUpdate() 里的
			// resetSubState() —— 而它排在 update() 之后。父 state 的 update() 每帧抛异常时
			// resetSubState() 永远执行不到，报错界面就永远建不出来（只剩原生弹窗兜底）。
			// 所以这里同步补一次 resetSubState()，让下一帧 tryUpdate 直接走 subState 分支。
			current.openSubState(report);
			current.resetSubState();

			// resetSubState() 会清掉 _requestedSubState，但 openSubState() 留下的
			// _requestSubStateReset 还挂着。不清掉的话下一帧 tryUpdate 会再跑一次
			// resetSubState()，此时 _requestedSubState 已是 null，subState 会被赋成 null，
			// 报错界面只闪一帧就消失。flixel 没提供公开的清除方式，只能直接写这个私有字段。
			untyped current._requestSubStateReset = false;

			if (current.subState == null)
			{
				inGameReportStatus = "failed: subState not installed";
				return false;
			}

			inGameReportActive = true;
			inGameReportMessage = message;
			inGameReportStatus = "shown: ErrorSubState";
			return true;
		}
		catch (reportError:Dynamic)
		{
			try inGameReportStatus = 'failed: ${Std.string(reportError)}' catch (_:Dynamic) {}
			return false;
		}
	}
	#end

	#if sys
	private static final HAXE_RUNTIME_SNAPSHOT_LIMIT:Int = 24;

	private static function captureHaxeStackSnapshot(stack:Array<haxe.CallStack.StackItem>):String
	{
		if (stack == null || stack.length == 0)
			return '';

		var lines:Array<String> = [];
		var index = 0;
		for (item in stack)
		{
			if (index >= HAXE_RUNTIME_SNAPSHOT_LIMIT)
				break;

			var file:String = '';
			var line:Int = 0;
			var column:Int = 0;
			var method:String = '<unknown>';

			switch (item)
			{
				case CFunction:
					method = 'CFunction';
				case FilePos(parent, stackFile, stackLine, stackColumn):
					file = stackFile;
					line = stackLine;
					column = stackColumn;
					method = switch (parent)
					{
						case Method(owner, name): '$owner.$name';
						case Module(owner): 'module $owner';
						case LocalFunction(name): 'local function $name';
						case _: '<unknown>';
					}
				case Method(owner, methodName):
					method = '$owner.$methodName';
				case Module(owner):
					method = 'module $owner';
				case LocalFunction(name):
					method = 'local function $name';
			}

			var location = file.length > 0 ? '$file:$line' : '<no-location>';
			if (column > 0) location += ':$column';
			var sourceLine = readSourceLine(file, line);
			if (sourceLine.length > 0) location += ' -> ${sourceLine}';
			lines.push('#${indexToSnapshotTag(index)} $location in $method');

			index++;
		}

		return lines.length == 0 ? '[no_haxe_runtime_snapshot]' : lines.join('\r\n');
	}

	private static function indexToSnapshotTag(value:Int):String
	{
		return value < 10 ? '0$value' : Std.string(value);
	}

	private static function readSourceLine(path:String, line:Int):String
	{
		if (path == null || path.length == 0 || line <= 0)
			return '';

		var sourcePath = resolveSourcePath(path);
		if (sourcePath == null || sourcePath.length == 0 || !FileSystem.exists(sourcePath))
			return '';

		try
		{
			var lines = File.getContent(sourcePath).split('\n');
			var index = line - 1;
			if (index >= 0 && index < lines.length)
				return lines[index].replace('\r', '').trim();
		}
		catch (_:Dynamic) {}

		return '';
	}

	private static function resolveSourcePath(path:String):String
	{
		if (FileSystem.exists(path))
			return path;

		var cwd = Sys.getCwd();
		var altPath = Path.join([cwd, path]);
		if (FileSystem.exists(altPath))
			return altPath;

		var sourcePath = Path.join([cwd, "source", path]);
		if (FileSystem.exists(sourcePath))
			return sourcePath;

		return path;
	}
	#end

	#if (cpp || hl)
	/**
	 * hxcpp 临界错误回调，由 init() 里的 __hxcpp_set_critical_error_handler 注册。
	 *
	 * hxcpp 的 CriticalErrorHandler 调用本回调时没有 try 包住，回调正常返回后一定会走到
	 * MessageBoxA + __builtin_trap() + exit(1)。所以"返回"等于必然终止进程，唯一能跳过
	 * 默认动作的办法是抛出异常来解绑那一帧。因此这里先落盘一份 Haxe 报告（该步骤不允许
	 * 抛），再抛出可捕获的值，交给最近的 catch(Dynamic) 接住，让游戏继续跑。
	 */
	private static function onError(message:Dynamic):Void
	{
		var text:String = "unknown critical error";
		try text = Std.string(message) catch (_:Dynamic) {}

		#if sys
		try writeHaxeCrashReport("hxcpp_critical_error", text, "", [], []) catch (_:Dynamic) {}
		try Sys.println('hxcpp:critical_error $text') catch (_:Dynamic) {}
		#end

		throw text;
	}
	#end
}
