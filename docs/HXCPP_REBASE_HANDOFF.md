# hxcpp 换底交接（给接手的会话）

> 状态：**待执行**（2026-11-16 立）
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
| **CI 用分支** | `TieGao/hxcpp` `nf-ci` = `6d48dd35` | `master` + Linker 绝对路径修复（见 §4） |
| 引擎侧 pin | `FNF-NovaFlare-Engine/hmm.json` → `TieGao/hxcpp` `6d48dd35` | 换底完成后更新 |

本地工作树：`D:\HaxeToolkit\haxe\lib\hxcpp\git`（haxelib 的 `git` 条目，`.current=git`）。
注意它当前停在 `master`（`f54b15af`），`nf-ci` 是独立分支。

## 3. 已知差异（线索，需自行核实）

对比"官方 v4.3.184"与"merge 后的 master"，**保留**的 NF 定制只有 30 个文件，其中真正有功能意义的：

- `include/HxcppVersion.h`：多了 `#define HXCPP_VERSION "4.3.176"`（官方没有这个宏）
- `toolchain/msvc-arm64-setup.bat`：`VsDevCmd -arch=arm64` → `vcvarsall amd64_arm64`（Windows ARM64 必需）
- `src/hx/cppia/ArrayBuiltin.cpp`、`CppiaCompiler.cpp`：`SLJIT_FUNC` → `SLJIT_CALL`
- `hxcpp/Builder.hx`：349 行全删全加，实为 **CRLF/LF 行尾差异**，逻辑无变化
- 其余是删 CI/`.gitignore`、提交预编译 `bin/*/Cppia`、`haxelib.json` 格式重排

对比"旧 NF fork"与"官方分叉点"，**被官方覆盖**的 41 个文件里，大部分不是损失：

- `include/hx/Unordered.h` 删除 + `Immix.cpp` 改 `std::unordered_set/map` → 官方 v4.3.184 也这么做了
- `HXCPP_ARMV7` / `armv7` 支持（`BuildTool.hx`、`linux-toolchain.xml`）→ 官方已内置
- `RunMain.hx` 的 `#if haxe4` 条件导入 → 引擎用 4.3.7，不需要

**仍需逐项确认的**（这些是"被覆盖但可能还有用"的）：
`include/hxcpp.h`、`include/hxString.h`、`src/String.cpp`、`src/hx/cppia/*`、
`toolchain/android-toolchain-clang.xml`、`toolchain/common-defines.xml`、
`tools/hxcpp/Compiler.hx`、`tools/hxcpp/Setup.hx`、`tools/run/RunMain.hx`。

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
