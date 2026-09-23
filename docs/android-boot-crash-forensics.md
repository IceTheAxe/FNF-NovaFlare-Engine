# Android 模拟器启动崩溃 —— 取证记录

日期：2026-09-22　commit：`a16bf467`（"android fix"）
设备：`emulator-5554` = `sdk_gphone16k_x86_64`（Android 17 / API 37 / x86_64 / **PAGE_SIZE=16384**）
包名：`com.NovaFlareEngineNew`　`primaryCpuAbi=arm64-v8a`（走 `libndk_translation.so` 翻译）

---

## 一、为什么你贴的报告是空的

不是 CrashHandler 坏了，是 **Android 上按设计不生成 Haxe 栈**。

`Project.xml:311-312`：

```xml
<haxedef name="HXCPP_STACK_LINE"  unless="android" />
<haxedef name="HXCPP_STACK_TRACE" unless="android" />
```

没有 `HXCPP_STACK_TRACE` → `HX_STACKFRAME` 展开成空 → `hx::Throw` 不记录帧 →
`__hxcpp_get_exception_stack()` 返回**空数组**。于是：

| 字段 | 为什么空 |
|---|---|
| `[haxe_exception_stack]` | `haxe.CallStack.exceptionStack(true)` → 空 |
| `[haxe_runtime_snapshot]` | 上面为空 → `captureHaxeStackSnapshot` 直接 `return ''` |
| `[haxe_call_stack]` | `haxe.CallStack.callStack()` → 空 |
| `[native_hxcpp_exception_stack]` | 输出 `[]` 而非 `null` —— **这就是指纹** |

`Project.xml:309-310` 给这条写的理由是"Android 走 NativeCrashHandler，读不回 Haxe 栈"。
**实测不成立**：本次崩的就是 Haxe 路径（`kind=uncaught_error`，CrashHandler 落盘），
进程没死（`preventDefault()` 生效，pid 11502 一直活着）。Android 只是**生不出**栈，不是读不回。

## 二、日志通道（三个，都不用 root）

1. **logcat，tag `trace`** —— `writeHaxeCrashReport` 末尾的 `Sys.println(saveError)`
   被 lime 重定向进 logcat，**整份报告逐行都在里面**。这是最快的通道。
2. **`/sdcard/.NovaFlare-Engine/crash/<时间戳>.txt`** —— cwd 由 `Main.hx:323`
   `Sys.setCwd(storageDirectory)` 设定。
3. 原生报告同目录 `native-crash-*.txt`（本次没有 → 证实走的 Haxe 路径）。

`/sdcard/Android/data/<pkg>/files/` **不存在**，别在那儿找。

```bash
ADB="/c/Users/Ice_Axe/AppData/Local/Android/Sdk/platform-tools/adb.exe"
"$ADB" logcat -c
"$ADB" shell am force-stop com.NovaFlareEngineNew
"$ADB" shell am start -W -n com.NovaFlareEngineNew/.MainActivity
sleep 25
"$ADB" logcat -d -v time > logcat_full.txt
"$ADB" logcat -d -b crash -v time > logcat_crash.txt
"$ADB" shell "cat /sdcard/.NovaFlare-Engine/crash/2026-09-22-12\\'19\\'40.txt"
"$ADB" exec-out screencap -p > screen.png
```

## 三、崩溃时序（pid 11502，实测）

```
12:19:36.808  V/SDL      nativeRunMain()
12:19:37.352  I/haxe plugin   Got Load Proc
12:19:38.199  D/openal   AL lib: Initializing library v1.20.1-f5e0eef3
12:19:38.297  D/openal   AL lib: Created context 0x...          ← 音频初始化成功
              (中间 2 秒无任何日志)
12:19:40.339  I/trace    haxe:uncaught_error message=Null Object Reference   ← 崩点
12:19:40.340  I/trace    (整份报告)
12:19:40.472  V/SDL      onWindowFocusChanged(): false          ← 原生模态弹窗抢焦点
```

之后进程一直活着，屏幕**纯黑** + 报错弹窗 —— 这就是"无法启动"的实际形态。

**阶段判定**：`[heap] used_bytes=6655088`（≈6.6 MB）。
- 启动早期崩 ≈ 6–7 MB；进游戏后崩是 100 MB+。
- 本次 6.6 MB → 崩在 `FlxGame` 构造之后、首个 state 的 create/首帧附近。
- 与你 12:16:53 那份的 `used_bytes` **一模一样** → 确定性复现，同一个点。
- 中间那 2 秒空档大概是首个 state 的资源加载。

## 四、16 KB 对齐这条已经好了（a16bf467 生效）

从设备拉出的 `libApplicationMain.so`：

```
4 × PT_LOAD  p_align = 0x4000 (16384)          MIN >= 16384 → True
GNU_RELRO (vaddr+memsz) % 0x4000 = 0           → 完全合规
note.android.ident: API level=21  NDK=r28c
```

所以本次启动失败**不是**页对齐问题，是 Haxe 层的空引用。

## 五、下一步（按成本排序）

**A. 撒面包屑（最省，一轮就能缩范围）**
`trace()` 和 `Sys.println()` 在 Android 上都进 logcat（`TraceInterceptor.customTrace`
会 `callOriginalTrace`，没吞掉原始 trace）。在启动链路分段打点：
`CrashHandler.init()` → `init()` → `setupGame()` → `Toolkit.init()` → `new FlxGame()` → 首个 state 的 `create()`。
跑一次看最后一条是哪句。**不用重建栈宏。**

**B. 给 Android 打开栈宏（兜底，能直接拿到行号）**
把 `unless="android"` 去掉（或加一段 android+debug 专用），然后：
- ⚠️ **必须先删 `obj/`**：hxcpp 的对象名不含编译参数（`Compiler.hx getObjName`），
  旧 `.obj` 不会被判失效 → 混链会报 `undefined symbol: _hx_pos_*` /
  `hx::ExceptionStackFrame::ExceptionStackFrame(...)`。
- ⚠️ `HXCPP_STACK_TRACE` 有实打实的每调用开销（pushFrame/popFrame），验完关掉。
- ⚠️ `Project.xml` 里目前**没有** `&&` 复合条件的先例，`if="android && debug"` 能不能被
  lime 求值器吃下未经验证；最稳是先临时整条去掉 `unless="android"`。

**C. 试 Windows 复现** —— 桌面有完整栈，能复现就秒定位。
但 Android 崩在 6.6 MB 堆（很早期），桌面启动路径不完全一样，不一定复现。

## 六、顺手发现（不在本次任务范围）

`export/legacy-gc/windows/bin/crash/2026-09-22-10'56'30.txt` 是**另一个** bug：
`message=Null Object Reference`，栈指向 `substates/PsychCreditsSubState.create() [line 97]`，
堆 186 MB。与 Android 这次无关。

另外 `export/legacy-gc/windows/bin/crash/` 下 09-21 18:24 与 23:06/23:12 那几份报告
栈也是空的（`[]`），说明那两个时间点的 Windows 构建**还没开**栈宏 ——
宏是 09-22 上午之后才打开的（10:56 那份有栈）。

---

## 附：本次用到的临时产物

`.workbuddy-ai/tmp-android/`
- `logcat_full.txt`（896 KB，全量）
- `logcat_crash.txt`（38 KB，crash buffer，全是 uwb-service 噪声，与本问题无关）
- `screen.png`（纯黑）
- `libApplicationMain.so`（106 MB，对齐取证用）
- `check_elf.py`（已沉淀进 skill：`scripts/check_elf_alignment.py`）
