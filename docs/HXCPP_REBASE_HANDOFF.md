# hxcpp 换底交接（给接手的会话）

> 状态：**已完成**（2026-11-16 立，同日执行）
> 结果：`TieGao/hxcpp` 分支 `nf-ci` / `nf-hxcpp-rebase` = `9af555ad`；
> 引擎侧 `no_gameplay_gc` 已删；Windows release 构建通过，`Immix.obj` 含全部 7 个 `__hxcpp_gc_*gameplay*` 符号。
> 目标：把 NF 在旧 hxcpp fork 上的定制功能，移植进"官方 hxcpp + 少量 NF 定制"的新基线。
> 本文只说明**要做什么**和**已知线索**；具体实现由接手会话自行探索确认。

## 1. 任务

NF 的 hxcpp 从自建 fork 换到官方主线（v4.3.184 级），把 NF 真正需要的东西补回去。
换底完成后，引擎的 `Project.xml` 里那个临时开关 `<haxedef name="no_gameplay_gc"/>` 要删掉。

## 2. 仓库与分支现状

| 角色 | 位置 | 说明 |
|---|---|---|
| 旧 NF fork | `NovaFlare-Engine-haxelib/hxcpp-4.3.2-new`（`3f50506`，原 hmm pin）；`TieGao/hxcpp-4.3.2-new`（`ca655fb`，同一份 + Linker 修复） | NF 的全部历史定制在这里 |
| **新基线** | `TieGao/hxcpp` `master` = `f54b15af` | 官方 v4.3.184（`1c065ad8`）merge 进来的结果，已保留一部分 NF 定制 |
| **CI 用分支** | `TieGao/hxcpp` `nf-ci` = `9af555ad` | `master` + Linker 绝对路径修复（见 §4） |
| 引擎侧 pin | `FNF-NovaFlare-Engine/hmm.json` → `TieGao/hxcpp` `9af555ad` | 已更新 |

本地工作树：`D:\HaxeToolkit\haxe\lib\hxcpp\git`（haxelib 的 `git` 条目，`.current=git`）。
注意它当前停在 `master`（`f54b15af`），`nf-ci` 是独立分支。

## 3. 已知差异（已核实）

旧 fork 的基底实际是官方 **v4.3.90**（仓库名里的 "4.3.2" 与版本无关）。`2d8c5f6`（首提交）与 `v4.3.90`
逐字节一致，说明 git init 之前没有 NF 改动。`2d8c5f6..ca655fb` 的 NF 净改动只有 **10 条路径**：

| 路径 | 内容 | 处理 |
|---|---|---|
| `src/hx/gc/Immix.cpp`、`include/hx/GC.h` | GameplayGC + Immix 优化 + 进程 RSS 统计 | 已移植 |
| `toolchain/msvc-toolchain.xml` | 三个 linker 加 `psapi.lib` | 已移植 |
| `tools/hxcpp/Compiler.hx`、`BuildTool.hx`、`Progress.hx`、`hxcpp.n` | 编译进度 | 已移植（并重建 `hxcpp.n`） |
| `tools/hxcpp/Linker.hx` | 绝对路径产物不拼 libdir | 已在 `nf-ci` |
| `src/hx/gc/GcCommon.cpp` | 移动端最小工作内存 8/4MB → 20/10MB | 未补：无实测依据，移动端常驻 +12MB |
| `toolchain/common-defines.xml` | `HXCPP_STACK_TRACE`/`HXCPP_STACK_LINE` 去掉 `tag="haxe"` | 未补：会让全部 TU 的 `-D` 变化、编译缓存整体失效，等复现再动 |
| `tools/hxcpp/BuildTool.hx`（macOS SDK 扫描） | 官方 `90b879ed` 已独立修同一问题 | 不补 |

`include/hxcpp.h`、`include/hxString.h`、`src/String.cpp`、`src/hx/cppia/*`、
`toolchain/android-toolchain-clang.xml`、`tools/hxcpp/Setup.hx`、`tools/run/RunMain.hx`
与 v4.3.90 完全一致，**从未被 NF 改过**。

另：`hxcpp.n` 是仓库里跟踪的预编译构建工具，`run.n` 只在它缺失时才重建 —— `tools/hxcpp/*.hx`
的任何改动不重建 `hxcpp.n` 就是死代码。换底时已一并重建。

## 4. 必须补的核心：GameplayGC native API

引擎 `source/general/backend/gc/GCManager.hx` 用 `@:native` 声明了一批 hxcpp runtime 函数，
官方 hxcpp 里**一个都没有**，导致 hxcpp 编 Haxe 生成的 `GameplayGC.cpp` 时报 C3861：

```
__hxcpp_gc_enter_gameplay(int reserveBytes, int maxHeadroomBytes)
__hxcpp_gc_leave_gameplay(bool collectNow)
__hxcpp_gc_is_gameplay_mode()            -> bool
__hxcpp_gc_last_pause_ms()               -> double
__hxcpp_gc_gameplay_max_pause_ms()       -> double
__hxcpp_gc_gameplay_deferred_full_count()-> int
__hxcpp_gc_gameplay_emergency_full_count()-> int
```

这些的**实现**在旧 fork 里（`Immix` 的低延迟 gameplay 模式：进入前做一次 full GC、
按 reserve/headroom 预留、期间推迟 full collection、退出时在安全点收集）。
接手会话需要：定位旧 fork 的实现文件与声明头 → 移植到新基线 → 保持 ABI 与语义。

**移植完成的判据**：删掉引擎 `Project.xml` 的 `<haxedef name="no_gameplay_gc"/>` 后，
Windows 构建能编过，且 `GCManager.GameplayGC.active` 在进歌后为 true。

引擎侧目前的做法是临时降级：`GCManager.hx` 里四处 `#if (cpp && !hxcpp_zgc)` 都加了
`&& !no_gameplay_gc`，`get_active()` 直接返回 false，其余方法变成空操作。
`hxcpp_zgc`（NovaGC 构建）本来就走另一套策略，不受影响。

## 5. Linker 修复（已在 `nf-ci`，不要丢）

`tools/hxcpp/Linker.hx` 两处：绝对路径的产物不再拼 `libdir`。

原因：`HXCPP_COMPILE_CACHE` 打开时，hxcpp 把 runtime 组编成库，输出路径是缓存目录的绝对路径；
带 `<libdir>` 的构建文件（例如 StageWebView 的 `project/Build.xml`）会把它拼成
`obj/lib/D:/.../xxx.lib`，MSVC 直接 LNK1104。本地不设缓存永远碰不到，只有 CI 会撞。

换底时把这个修复保留在 master 或继续沿用 `nf-ci` 分支。

## 6. 验证

- 引擎 CI 全平台：Windows / Linux / Linux ARM64 / macOS ARM64 / macOS x86_64 / Android / iOS
- 本地：`haxelib run lime build windows`（release，debug 构建因 hxvlc×hxcpp 冲突不可用）
- 打开 GameplayGC 后跑一局，确认进歌/退歌不崩、`lastPauseMs` 有值

## 7. 不要做的事

- 不要为了让它编过而删引擎的 GC 功能代码 —— 临时开关已经有了，换底完成就删开关
- 不要动 `lime` / `openfl` 仓库（那是另一条线，见 `LIME_OPENFL_REBASE_HANDOFF.md`）
- 不要改引擎的 `hmm.json` 之外的依赖 pin
