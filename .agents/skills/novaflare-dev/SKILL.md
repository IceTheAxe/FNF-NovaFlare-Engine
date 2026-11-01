---
name: novaflare-dev
description: NovaFlare Engine（FNF 引擎，Haxe 4.3 / Flixel / lime）本仓库开发必读。凡在本仓库改代码、编译构建（lime/openfl/hxcpp）、管理 haxelib 或 hmm 依赖、处理暂停菜单/谱面/week/语言文件/Lua/HScript 模组、调 GC（NovaGC/ZGC）、或排查编译与运行问题时都应使用本 skill。
---

# NovaFlare Engine 开发指南

一个融合了 Psych Engine 结构、官方 Funkin 0.8.7 兼容层（`ORIGIN_FUNKIN_COMPAT`）和 Codename Engine 兼容层（`CODENAME_ENGINE_COMPAT`）的 Friday Night Funkin' 引擎。当前版本 1.2.1（见 `Project.xml`）。

## 构建与依赖（先读这段）

- Haxe **4.3.7**，haxelib 4.2.0，依赖由 **hmm** 管理：`hmm.json` 记录所有依赖（多为锁 ref 的 git fork，托管在 github.com/NovaFlare-Engine-haxelib），安装到**项目本地仓库** `F:\FNF-NovaFlare-Engine\.haxelib\`。改依赖用 `haxelib run hmm install`（装）/ `hmm update <name>`，不要直接 `haxelib git`。
- **haxelib 出问题时**（库损坏、路径丢失、下载失败）：运行 `haxelib setup D:\HaxeToolkit\haxe\lib` 切换到该备用库（内含 flixel、hxcpp、crypto、foxlite 等常用库）。`NovaSetup/setup-windows.bat` 的标准流程也是 `haxelib setup !HAXE_DIR!\lib`。注意备用库里的版本可能与 hmm 锁定的 fork 版本不同，切换后若编译报 API 不匹配，先怀疑版本差异。
- 常用命令（在仓库根目录）：
  - `haxelib run lime test windows` — 编译并运行（日常验证）
  - `haxelib run lime test windows -debug` — 调试版（含 hxcpp-debug-server，输出到 `export/debug/`）
  - `haxelib run lime build windows` — 仅编译（release 输出到 `export/release/`）
  - `haxelib run lime test android` — 安卓（arm64-only，gradle 8.14.4 + AGP 8.7.3 走本机缓存）
- 编译很慢是正常的：`-dce no` 全开（HScript 需要运行时 `Type.resolveClass`）、`COMPILE_ALL_CLASSES` 宏强制包含全部类。别"优化"掉这些设置。
- 所有构建开关、宏（`--macro` addMetadata/include 系列）都集中在 `Project.xml`，新增全局 haxedef 或宏先看那里，注释多用中文。

## 三大源码 classpath（改代码前先分清该改哪里）

| classpath | 条件 | 角色 |
|---|---|---|
| `source/` | 始终 | **主游戏代码，默认只改这里**。包布局：`Main.hx` 入口、`games/`（PlayState、backend、cutscenes、stages）、`states/`（title/freeplay/storyMenu/mainMenu 等）、`substates/`、`general/backend/`（ClientPrefs、Paths、Conductor、Language）、`options/`、`developer/`（编辑器与调试）、`scripts/`（Lua/HScript 系统）、`mobile/`、`modchart/`、`win8/`（Win8 风格 UI 面板组件） |
| `source-originFunkin/` | `ORIGIN_FUNKIN_COMPAT`（恒开） | 官方 Funkin 0.8.7 兼容层：`funkin/`、`originfunkin/`、`animate/`。Origin 模组/脚本兼容用，一般不动 |
| `source-codename/` | `CODENAME_ENGINE_COMPAT`（恒开） | Codename Engine 兼容层：`codename/`、`codenamechain/`、`hscript/` 等，输入桥接到 NF 的移动端层。Codename 模组以软编码状态运行 |

状态流：`Main.hx` → `InitState`（初始化，可能经过 OutdatedState 等）→ `TitleState` → `MainMenuState` → `FreeplayState`/`StoryMenuState` → `games/PlayState.hx`。

## 关键代码地图

- 谱面/歌曲数据：`source/games/backend/Song.hx`（SwagSong，含可选 `artist`/`charter` 字段）、`WeekData.hx`（week.json 解析，扩展元组支持曲师/谱师）、`Difficulty.hx`、`Highscore.hx`
- 署名统一入口：`source/games/backend/SongCredits.hx`（优先谱面 JSON 内嵌，回退 week.json）
- 设置存档：`source/general/backend/ClientPrefs.hx`（新增游戏选项同时在 `source/options/groupData/` 对应 Group 里加 UI 项）
- 多语言：`assets/shared/language/<语言>/<模块>/<模块>.lang`（如 `pause/pause.lang`，中/英/巴西葡语三份要同步改）；取词用 `Language.hx` 的 `getPhrase(key, default, args)`（支持占位符）
- 暂停：三套并存于 `source/substates/` —— `PauseSubState.hx`（旧版）、`NewPauseSubState.hx`（默认，按 `ClientPrefs.data.pauseType` 选择）、`LegacyPauseSubState.hx`；暂停内调试面板是 `PauseDebugCharm.hx`（基于 `win8.Panel`）
- Lua/HScript 模组：`source/scripts/`，模板见 `docs/TemplateScript.lua`、`docs/TemplateScript.hx`、`docs/stageScripts/`；玩家侧文档见 `NovaSetup/FunkinMods-ZH.md` / `-EN.md`

## 文档与工具

- `docs/`：NovaGC/ZGC（HXCPP 自定义 GC）审计与状态文档、GameAnalytics 接入、安卓启动崩溃取证、更新日志（`UPDATE-*.md` 中英双语）+ 文档站（index.html，CNAME 自定义域名）
- `tools/`：PowerShell/cmd 诊断脚本集（minidump 分析、ZGC 内核构建、帧率/硬件监控、GDB 调试脚本）
- `hxcpp/`：内嵌的 hxcpp 源码，含 NovaGC/ZGC 改造；GC 相关改动配套 tools/ 里的构建与审计脚本
- `example_mods/`：随构建打包为 `mods/` 目录

## 约定

- 代码注释和提交信息常见中文，沿用周围风格即可。
- 播放器可见的新 UI 文案必须走 Language 体系并同步三个语言文件，不要硬编码英文。
- `PSYCH_WATERMARKS`、`MODS_ALLOWED`、`LUA_ALLOWED`（desktop/mobile）、`HSCRIPT_ALLOWED` 等特性开关都在 `Project.xml` 顶部，条件编译差异导致的"某平台编译不过"先查 define 条件。
- 本地 `.haxelib/` 里有大量 dev/git 指向，属于正常状态（hmm 管理），不要当作损坏去修复。

## 深入架构

需要更详细的系统说明（GC 方案、移动端输入、Origin/Codename 兼容细节、进行中工作的历史背景）时，读本 skill 目录下的 `references/architecture.md`。
