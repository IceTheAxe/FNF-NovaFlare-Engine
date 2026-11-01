# NovaFlare Engine 深入架构参考

补充 SKILL.md 的深度信息。截至 2026-10。

## 兼容层如何共存

- `ORIGIN_FUNKIN_COMPAT`（恒开）让引擎运行官方 Funkin 0.8.7 的模组与脚本：`source-originFunkin/` 提供完整 `funkin.*` 包（PlayState、FreeplayState 等 0.8.7 原版类），并有大量宏把兼容性修改织入 flixel 本体（`@:build(originfunkin.macro.OriginFlixelCompatMacro...)` 给 FlxBasic/FlxSprite 加 zIndex、给 FlxTouch 加兼容方法等）。
- `origin_include_libs` / `origin_include_funkin` 宏（`OriginIncludeMacro.includeFlixel()/includeFunkin()`）会把整个 flixel/openfl/lime 源码强制编进来，用于让宏修改生效——这解释了为什么全量编译极慢。
- `CODENAME_ENGINE_COMPAT`（恒开）加载 `source-codename/`，配合 `HSCRIPT_ABSTRACT_SUPPORT`、`SOFTCODED_STATES`、`hscriptPos`、`CUSTOM_CLASSES` 等 haxedef，让 Codename 的 HScript 表面（如 `FlxColor.fromRGB` 抽象静态）可用。Codename 模组跑在隔离的状态链（`codenamechain/`）上，键盘/手柄/触摸输入在 NF 的移动输入层统一合并。
- `STAR_CLASSES` + `HSCRIPT_ALLOWED` 服务于 NF 自己的 HScript（hscript-iris-improved）。

## GC：NovaGC / ZGC

- `hxcpp/` 是内嵌源码（非 haxelib 安装版），包含自定义 GC 改造。默认 **关闭** zgc（Project.xml 中相关 haxedef 被注释），`HXCPP_GC_GENERATIONAL` 恒开。
- 控制构建通过 `BUILD_DIR` 变量隔离（`export/legacy-gc` 等），避免两套 GC 缓存互相污染。
- 背景文档在 `docs/`：`HXCPP_GC_REWRITE_MASTER_PLAN.md`（总计划）、`HXCPP_ZGC_RUNTIME_CONTRACT.md`（运行时契约）、`HXCPP_ORIGINAL_PARITY_*`（与原版 hxcpp 的对等性审计）、2026-07 系列状态文档。动手改 GC 前先读契约文档。
- 配套工具：`tools/build-hxcpp-zgc-kernel.ps1`、`tools/build-novagc-windows.ps1`、`tools/audit-hxcpp-*.ps1`（审计脚本）。

## 移动端

- `TOUCH_CONTROLS`（mobile）+ `FEATURE_TOUCH_CONTROLS`；Codename 移动资产走独立 library `codename_mobile`。
- 安卓：仅 arm64（`exclude armv7`），NDK 28.2，gradle 版本锁定为本机缓存已有的 8.14.4/8.7.3（Project.xml 有注释说明，避免联网下载）；签名用仓库内 `key.keystore`（密码 novaFlare）。
- 视频用 hxvlc（`VIDEOS_ALLOWED`）；安卓扩展（androidtools、CallbackUtil、FNFCExtension、AudioSession）在 Project.xml 的 android 配置节。
- 安卓启动崩溃排查见 `docs/android-boot-crash-forensics.md`。

## 渲染/性能相关 haxedef

- desktop 恒开：`openfl_enable_experimental_update_queue`、`openfl_pool_events`（避免全树 transform 遍历与每帧事件分配）、`lime_disable_assets_version`（避免 lime 往 AssetCache 注入随机 cache-buster 导致单个 C++ 单元重编）、`HXCPP_ALIGN_ALLOC`。
- 可选 Tracy profiler（`TRACY_ALLOWED`，默认注释）。
- `windows && !debug` 用 `-dce no` 保 HScript 反射；其他平台 debug 也保。

## 游戏功能开关体系

Project.xml 中 `FEATURE_*` define（FUNKVIS、LAG_ADJUSTMENT、NAUGHTYNESS、OPEN_URL、VIDEO_PLAYBACK/SUBTITLES 等）是功能总开关；游戏内选项页在 `source/options/groupData/`（如 `FEFeaturesGroup.hx`、`GamePlayGroup.hx`），选项存取在 `ClientPrefs.hx`。新增选项的完整链路：ClientPrefs 字段 → groupData UI 项 → 需要文案则加 `.lang` 三语 → 使用点读 `ClientPrefs.data.*`。

## 暂停系统（2026-10 重做）

三套暂停并存，由 `ClientPrefs.data.pauseType` 分发：
- `NewPauseSubState.hx`：默认版。支持 4 个动画相关选项（`pauseSkipFadeIn/Out`、`pauseDoubleEnterSkip`、`pauseUnlockInputDuringAnim`），内置 SongCredits 署名行与 `PauseDebugCharm` 调试子面板（跳时间/练习/Botplay/End Song，基于 `win8.Panel`）。
- `PauseSubState.hx`（旧 Psych 风格）与 `LegacyPauseSubState.hx` 也各加了署名行。
- 署名数据源：`SongCredits.hx` 统一取值——优先谱面 JSON 内嵌 `artist`/`charter`，回退 `WeekData` 的扩展元组（week.json 第 4/5 项，`getSongMusican`/`getSongCharters`/`findSongEntry`）。FreeplayState 与编辑器（ChartingState/PEChartingState）共用同一口径。

## 语言文件

- 路径模式：`assets/shared/language/<Chinese|English|Portuguese (Brazil)>/<模块>/<模块>.lang`。目前至少 pause 模块。新增键需三语同步；带参取词：`Language.getPhrase(key, defaultText, args)`，占位符替换。
