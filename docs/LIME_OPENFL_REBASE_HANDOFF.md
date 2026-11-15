# lime/openfl fork 换底迁移交接文档

> 状态：**进行中**（长期任务，跨会话执行。每次续做前先读本文档，完成后更新「进度日志」区）
> 创建：2026-11-15 ｜ 最后更新：2026-11-15（Phase 0 启动）
> 关联记忆：`nf-lime-openfl-fork-anatomy`（项目记忆，含 fork 解剖结论）

## 1. 背景与目标

NF 的 lime/openfl 依赖是自建 fork（基线 = 官方 lime 8.3.0 / openfl 9.5.0 发布快照，2025-11-15 种子，历史与上游无共同祖先）。经全面调查：

- **零上游吸收**：patch-id 比对，8.3.1(33)/8.3.2(35)/develop(507) 与 openfl 9.5.1(48)/9.5.2(30)/develop(83) 的提交**一个都没进入 NF fork**。
- fork 内的"CNE/Origin 兼容 API"大部分是从 cne-lime / FunkinCrew/lime 抄的 API 面，**NF 引擎源码实际零消费**（详见 §5.3 死壳清单）。
- **渲染线程有真实驱动风险**：NF 开发者反馈"显卡驱动容易被卡掉"（玩其他游戏正常）。代码审查发现 4 个风险点（§5.5）。
- 目标：**换底到上游 8.4.0 级（FE fork 已 merge 的 develop），逐步回加 NF 真实需要的特性**，渲染线程降级为可选模块。

## 2. 已拍板决策（2026-11-15 用户确认）

| 决策项 | 结论 |
|---|---|
| 底仓库 | **FE fork**：`IceTheAxe/lime`（merge 上游 develop 至 027c323da，merge 点 `274f0297`，label 8.4.0，**已含 win-arm64 目标**）+ `TieGao/openfl`（已 merge 上游 9.6.0-dev，`fedf3d79b`） |
| 事件泵/帧时序 | **上游新帧时序为基**（`SetMainLoop/DispatchFrame/IsFrameDue` 体系），NF 的 renderFrameRate/lockRender 分频作为增量叠回；NF 泵骨架丢弃 |
| openfl | **lime + openfl 一起换底** |
| 渲染线程 | **不进主路径**，做成可选模块（编译开关/运行时开关，默认关），修掉 §5.5 风险点后再考虑默认 |
| 死壳 API | **不带**（零消费，见 §5.3；NF fork 上的两个未合 PR pr-1/pr-2 也是大删除方向，可互证） |
| 验收 | 用户本人真机验收；机器约定不自动跑游戏，编译验证用 **release**（debug 构建因 hxvlc×hxcpp 冲突损坏） |

## 3. 资产清单（commit hash 速查）

| 资产 | 位置 | 关键 ref |
|---|---|---|
| NF lime fork（旧） | github `NovaFlare-Engine-haxelib/lime-8.3.0`；本地克隆 `F:\FNF-NovaFlare-Engine\.haxelib\lime\git` | tip `e4adfed0`（2026-10-03）；远端 main 曾被强推（孤立提交 `e988b54c "push"`）；**未合 PR：`pr-1`=9e72cd7e（ios test，116f −5488 行）、`pr-2`=136b441a（cne+origin 清理，86f −3974 行），已 fetch 到本地同名 remote ref** |
| NF openfl fork（旧） | github `NovaFlare-Engine-haxelib/openfl-9.5.0`；本地 `.haxelib\openfl\git` | tip `89a29e6`，远端无新提交无 PR |
| FE lime fork（新底） | 本地 `E:\HaxeToolkit\haxe\lib\lime\lime`（develop 分支） | tip `274f0297` = merge 上游 `027c323da`；上游 develop tip = `091f76d69`（2026-11-13，比 FE merge 点新约 2 天）；FE 自有提交 7 个（win-arm64：`tools/platforms/WindowsPlatform.hx`、`.github/workflows/main.yml` windows-arm64 job、openal 子模块指 `TieGao/openal-soft` arm64 分支） |
| FE openfl fork（新底） | 本地 `E:\HaxeToolkit\haxe\lib\openfl\git`（develop） | tip `fedf3d79b` = merge 上游 9.6.0-dev |
| 上游 8.3.0 tag | E 盘 lime 仓库有完整上游历史 | `8.3.0` = NF 旧 fork 基线（`800946f04`） |
| cne-lime 参考 | `D:\funkin-sources\CodenameEngine\.haxelib\lime\git` | 版本 8.3.1，6185 commits，音频大改（FilterEffect/decoders drlibs 实现） |
| FunkinCrew fork 参考 | `/tmp/forkin-compare/funkin-lime`、`funkin-openfl`（浅克隆 @268dacfb / @74a51908，临时） | Vslice 官方 pin |
| NF 引擎合并点 | `F:\FNF-NovaFlare-Engine` | `35150418` = merge upstream/main（db34faba，13 提交）后的 main |

**新 fork 仓库（本次新建，Phase 0 完成）**：直接入驻 NF 的 haxelib 仓库（用户拍板"丢进 D:\HaxeToolkit"，照 FE 布局 `lime/git`）：
- `D:\HaxeToolkit\haxe\lib\lime\git`（分支 `develop`=FE 基点 `274f0297`，工作分支 **`nf-port`**；remote：`fe`=E 盘 FE 仓库、`nf`=NF 旧 fork、`upstream`=gh-proxy 上游；`nf-src` 分支 = 旧 fork 真正 tip `e4adfed0`）
- `D:\HaxeToolkit\haxe\lib\openfl\git`（同布局，分支 `nf-port`，`nf/main`=旧 fork tip `89a29e6`）
- 推 GitHub：创建 `NovaFlare-Engine-haxelib/lime-8.4.0`、`openfl-9.6.0` 后 `git push` + 改 hmm.json URL（用户操作 GitHub）
- ⚠️ lime 仓库里的 `ndll/` 是**临时桥接**（FE 预编译树 + 从 NF 旧 fork 复制的 `Windows/lime.ndll` 仅给 neko 工具用）——**在 Phase 5 重建 ndll 之前，编译出的游戏不可直接运行**（CFFI 原语集是 8.3.0 代的，与 8.4.0 Haxe 层不匹配）；Phase 1/2 改动原生代码后也必须删掉对应 ndll 强制源码重编或重取 FE 新二进制。

## 4. 冲突裁决日志（已获用户确认"符合预期"）

NF 引擎仓库 merge upstream/main（e5a1c759→db34faba，MaoPou 13 提交：加回手柄支持/tea-time 音乐/谱面转化器/NoteSplash 重写/Tracy 修复/CNE 1.1.0-rc4/Origin 0.9-preview）：

| 文件 | 裁决 | 理由 |
|---|---|---|
| `ClientPrefs.hx` ×3 | **取上游** | NF 官方"加回手柄支持"（gamepadBinds/defaultButtons/resetKeys 双路径/loadDefaultButtons） |
| `MasterEditorMenu.hx` | 取上游 | 内容相同（4 个编辑器项含 Stage Converter），仅缩进修正 |
| `GamePlayGroup.hx` fixLNL | **保留本地** `[0, 10, 'Length']` | 两边消费逻辑相同（PlayState 减法），纯 UI 范围差异，0-10 是 fork 特性 |
| `PauseSubState.hx` | **保留本地** | artistText/charterText 是 fork 署名系统（SongCredits），上游没有 |
| `Project.xml` | 保留本地 moonchart 行 | fork 需要；haxe-concurrent（上游新增）在 237 行已干净合入 |
| `hmm.json` | **moonchart + haxe-concurrent 都保留** | 两个依赖用途不同 |
| `README.md` | 两边章节都保留 | 上游 Next Version 日志 + fork 声明 |

## 5. 调查结论（换底依据，浓缩）

### 5.1 Haxe API 重叠表（lime）

**上游已有等价物 → 换用上游（NF 实现删除）**：

| NF API | 上游等价物 | 备注 |
|---|---|---|
| `Window.getNativeHandle():Dynamic` | `Window.nativeHandle` 属性 + `WindowHandle/WindowHandleType`（类型化） | NF 调用点改读属性 |
| `Window.setVSyncMode(WindowVSyncMode):Bool` | `Window.vsyncMode` 属性 + `lime.app.VSyncMode`（OFF/ON/ADAPTIVE/**AUTO** 四档，String 枚举） | NF `ui/WindowVSyncMode.hx` 删除 |
| `Window.alwaysOnTop` | 上游原生 `alwaysOnTop(get,set)` | |
| `window.onTextEdit` 接线补丁 | 上游原生就有（签名 `Event<String->Int->Int->Void>` 不变） | 补丁可删 |
| `Promise.completeAsync` | 上游 `app/Promise.hx:171` **签名完全一致**（FutureWork/ThreadMode） | 直接删 NF 侧 |

**上游没有 → NF 保留（换底后必须存在）**：
`Window.lockRender`、`Window.drawFrameRate:Int`、`Window.onlyUpdate`(Event，openfl ENTER_UPDATE 消费)、`Window.disabledKeys:Array<KeyCode>`、`Window.alert(...):Int`（SDL 式按钮返回，上游 alert 是两参 Void）、`Window.onDropFile` compat abstract（宏兼容 NF 1 参/CNE 4 参）、`System.getTimerNano():Float`、`System.getHint/setHint`、`system/BackendThread`（CFFI 原语级）、`Image.setMaxTextureSize`、`ImageBuffer.graphicScale`、`AudioSource.currentTime:Float`（上游仍 Int；NF openfl SoundChannel 依赖）、`AudioBuffer.fromDecoder/getCodec/loadAsync/loadFromDecoder/dataFormat`、`Future.all/allResolved/any/race`、`Promises.hx`（NF 风格版）、`lime.graphics.AnimationDecoder*`、`_internal/format/GIF/WEBP`、`utils/DroppedFile`、`_internal/compat/Callable.hx/DropFileEvent.hx`、`media/AudioDecoder+decoders/*`（注意：这些在 NF 是薄壳，原生侧 LimeCompat stub 返回 null；保留壳满足 API 面，不实现真解码）。

### 5.2 原生层冲突热度（E↔F 差异行，换底真实冲突面）

| 文件 | 差异行 | 风险 | 处理 |
|---|---|---|---|
| SDLApplication.cpp/.h | ~1000+（全文件级） | **高** | NF 泵骨架**丢弃**，分频语义在 §Phase 2 重新实现 |
| SDLWindow.cpp/.h | 1729 | **高** | `SetVSyncMode/alwaysOnTop` 上游已有→删 NF 版；`CreateContext/GetHandle/ContextMakeCurrent(void*)/Pause/ResumeRendering` 纯增量→Phase 2 随渲染线程搬 |
| ExternalInterface.cpp | 上游 14991 行 vs NF 4926 行 | **高** | 上游大扩容（menu/tray/vulkan/dock…）；NF "Group A" 原语**逐个核对**：上游已有（kerning/theme/locales/touch/gamepad led/rumble/hints…）不重植，只补上游缺的（`backend_thread_*`、`application_set_render_frame_rate`/`set_split_update`、`image_set_max_texture_size`、`bytes_write_file`、`window_alert_compat`、`*_file_dialog_*_compat`） |
| OpenGLBindings.cpp/.h | 4943（NF 包壳 ~395 处为主） | 中 | 上游只加了 EMSCRIPTEN BGRA 帮手 + `gc_gl_object` 指针追踪 → NF 包壳用 `git apply -3`（`git diff 8.3.0 e4adfed0 -- <file>` | `git apply -3`，pre-image 是 8.3.0 blob，新仓库历史里有）机械重放，人工点仅 gc_gl_object 区 |
| OpenALBindings.cpp | 1749 | 中 | 上游也动了（HRTF 默认关、设备恢复、**上游也有 capture**）；NF 的 SOFT 扩展逐个查重后叠加 |
| PNG.cpp | 356 | 中 | NF 全面 spng 重写 → 整文件取 NF + `project/lib/spng-files.xml` + spng 库 + Build.xml 段 |
| JPEG.cpp | 54 | 低 | NF BGRA 预乘输出，手工合并 |
| CURLBindings.cpp | 736 | 中 | 上游已线程化；NF 的 UB 修复（`char stringValue`→`char*` 等）先查上游是否已修 |
| Font.cpp/HarfbuzzBindings | 252 | 中 | NF `GetKerning`/`lime_hb_ft_font_changed`；上游已加 kerning → 查重 |
| KeyEvent/GamepadEvent/DropEvent/ApplicationEvent | 13-28 | 低 | 上游已有 timestamp/windowID/sensor → 跳过 NF stub |
| RenderEvent | 0± | 无 | NF `RENDER_UPDATE` 枚举是 openfl ENTER_UPDATE 依赖 → 保留 |
| ImageBuffer.cpp/Image.cpp/CFFIExt/AudioBuffer.cpp | ~0 | 无 | 仅行尾 |

NF 纯新增（直接拷贝 + Build.xml 登记）：`RenderThread.cpp/.h`、`BackendThread.cpp/.h`、`SharedBufferManager.*`、`PerformanceMonitor.*`、`LimeCompat.cpp`、`src/compat/`、spng、`DoubleBuffer.h`、`ReadOnlyView.h`（后两个未接线，可一并带走或留旧 fork）。

### 5.3 NF 引擎真实消费面（必须存活；其余为零消费）

- **lime 侧**（NF source* 全量 grep）：`lockRender`（ClientPrefs/GraphicsGroup/DataCalc/ExtraCounter）、`drawFrameRate`、`disabledKeys`（KeyBlocker）、`BackendThread.run`（import.hx/GameAnalytics/FreeplayState/BackButton）、`System.getTimerNano`（TimingSystem）、`System.getHint`（FNFCProvider）、`Image.setMaxTextureSize`（InitState）、`window.onTextEdit`（PsychUIInputText/CNE UIState）、`NOVAGC_PERF_TRACE` 环境变量。注意 `WindowUtil.hx:214` 的 setVSyncMode 是 NF 自己的空壳 stub。
- **openfl 侧**：`disposeOnUpload`（Paths.hx ×6 + FunkinLua 透传 + LoadingState —— **高频核心**）、`Event.ENTER_UPDATE`（FPSViewer/GraphMonitor）。NF 自带 `source/openfl/display/` 类覆写（OpenGLRenderer/Shader/ErrorHandledShader）——换 openfl 底时注意覆写签名。
- **零消费可丢**：`overrideDepthTest/MultiBufferTexture/toHardware/fromContext/toReadable/uploadFromArray/AsyncTextureUploader(直接引用)/GLSLSourceAssembler/openfl.utils.BitmapDataUtil/TextEditEvent/graphicScale(openfl 内部保留)/SecurityPanel/XMLDocument/XMLNode` + lime 侧 `Promises/Future.all/AudioEffect/设备事件/getLatency/Gesture/Theme/FileDialogFilter/MessageBoxType/AdaptiveIcon/AudioDecoder/AnimationDecoder/DroppedFile/fromDecoder/getCodec/loadAsync/fromBytesStream/NOVAFLARE_* 环境变量/FallbackOverlay`。
  ⚠️ 注意两档：**"API 面保留"**（Origin/CNE 兼容需要编译过的壳，如 AudioDecoder/Gesture/Theme/Promises——从 FunkinCrew/cne-lime 抄的文件成本低，可按需带回）与**"彻底不带"**（NF 自造死壳 GIF/WEBP/AnimationDecoder/DroppedFile/Callable）。Phase 3 时按"编译 Origin/CNE 兼容层是否报错"决定带回哪些。

### 5.4 上游破坏性变化（换底后 NF 侧必撞/需处理）

1. **Vulkan**：Windows/Linux cpp 默认 `vulkan` define（include.xml:27-29）。NF 初期 **`no-vulkan` 锁 OpenGL**，稳定后单独评估。
2. **SDL_QUIT → cancelable WINDOW_CLOSE**（逐窗口 close 请求）：NF 退出/存档路径要过 `Window.onClose` 链。
3. **deltaTime 仍是 Int**：NF 的 Float 是 fork 语义；换底后 `Application.update/onUpdate` 回 Int，NF 引擎/脚本层如报编译错逐个适配。
4. **HTTPS 强制证书校验**（`HTTPRequest.verifyCertificates=false` 或 `lime-insecure-https` 可关）：模组下载/自签服务器场景留意。
5. 音频：native 加载改 **SDL_sound 优先**、可返回"未知长度"流、`fromBytes` 行为修复、OpenAL HRTF 默认关、设备代际 `__contextGeneration`。
6. 嵌入资源不再复制到输出目录；HTML5 frameRate=0 每帧 update；iOS Safari visibilitychange。
7. `lime_disable_window_scale_change` 可退回高 DPI 行为（NF 移动端缩放回归测试点）。

### 5.5 渲染线程驱动风险点（重做时必须修）

1. `RenderThread.cpp:113-117` RebindContext 每次 resume **两次 MakeCurrent**。
2. `:249-279` pause 期间反复解绑/重绑（Android EGL surface 重建场景，:270 注释自证）。
3. `:377-392` worker 推 `SDL_USEREVENT code=1` —— 与 NF 旧主循环分频事件语义共用；上游 `DispatchFrame` 模型下落入 default 分支被丢弃（pacing 失效）→ 必须改用上游事件或专用 user event code。
4. `SDLWindow.cpp:40-47` PauseRendering 450ms 超时后强夺 context → 可能撕帧。
5. 跨线程 GL 查询（promise + 5s 超时）任何期望同步结果的调用读到陈旧值；`glGetString/glGetIntegerv` 类在 worker 执行。
6. `isMultiThreaded=false` 时 ContextFlip 主线程 swap 与 worker 持有 context 并存 → 非持有人 MakeCurrent/Swap 驱动警告风险。

### 5.6 上游白嫖清单（换底直接获得的高价值项）

`Promise.completeAsync`、增量 GC + 每帧步进（NovaGC 直接受益）、FrameProfile/FrameOptions/UncapMode 帧调度档位、`lime_skip_invisible_windows`、SDL_sound 流式音频、OpenAL 设备热插拔恢复、类型化 `nativeHandle`、`onDisplayScaleChange` + Display 生命周期、`preciseMouseWheel/mouseRect/keyboardGrab/flash()`、appearance 明暗模式、可变字体/stemDarkening/DPI 字形、Gamepad type/传感器/触板/扳机震动、VideoSource/VideoDecoder 原生视频、AudioInput 麦克风、LocalSocket/WebSocket、TLS1.3、WASM 复活（8.3.2）、openfl 9.5.2 Stage align/scaleMode 修复 + scale9Grid 重修。

## 6. 分阶段计划

> 每阶段 = 一个独立分支/提交序列，完成后在本表打勾并写进度日志（§8）。
> 机械搬运主手法：在新仓库 `git fetch nf F:\FNF-NovaFlare-Engine\.haxelib\lime\git` 后 `git diff 8.3.0 e4adfed0 -- <path> | git apply -3`（NF 侧改动对上游树的 3 方应用，8.3.0 blob 在上游历史中存在）。

- [ ] **Phase 0 建底**：clone FE lime/openfl 到 `D:\NF-forks\`，配 remote（`fe`/`nf`/`upstream`=gh-proxy）。验证：`git log` 基点正确、win-arm64 存在。
- [ ] **Phase 0.5 编译基线**：hmm 临时指到新 fork（`haxelib dev`），NF 引擎 release 构建一次，记录纯 FE 底下 NF 的编译错误清单（预期：deltaTime Int、WINDOW_CLOSE、lime._internal 布局 ×16 处 import）。这是后续所有阶段的对照基线。
- [ ] **Phase 1 低冲突原生搬运**（§5.2 中/低风险项 + 纯新增文件）：spng+BGRA 预乘、OpenAL SOFT、BackendThread、LimeCompat.cpp（瘦身）、ExternalInterface 查重补缺、curl/Font 查重、RenderEvent.RENDER_UPDATE。
- [ ] **Phase 2 帧调度叠回**：在上游 `SetMainLoop/DispatchFrame` 上实现 `renderFrameRate/lockRender`（`Window.drawFrameRate` 门控下沉 C++），修 §5.5-3 事件语义；渲染线程作为可选模块搬入（默认关，`lime-render-thread` define 或运行时开关），同时修 §5.5 其余风险点。
- [ ] **Phase 3 lime Haxe API**：§5.1 表逐项落地（5 个换上游删 NF 实现 + 保留清单带回），`CFFI.compatMethod` + `_compat` 原生变体按需。
- [ ] **Phase 4 openfl 换底**：base = TieGao fork `fedf3d79b`，回加 `disposeOnUpload/AsyncTextureUploader(机制)/ENTER_UPDATE/onlyUpdate 接线/graphicScale/NFShaderCompat 宏/OVERRIDE_DEPTH_TEST(可选)`，处理 §5.3 openfl↔lime 编译破坏点（onlyUpdate/graphicScale/currentTime Float）。
- [ ] **Phase 5 ndll + 切换**：ndll 重建（win-x64、**win-arm64**（FE CI 现成）、android arm64/armv7/x86_64）；GitHub 建 `NovaFlare-Engine-haxelib/lime-8.4.0`、`openfl-9.6.0`（用户操作）；hmm.json 换 URL+ref；全量 release 构建多平台。
- [ ] **Phase 6 引擎适配与验收**：编译错误清零 → 用户真机验收（渲染线程默认关先验主路径，再单独开开关验）。

## 7. 验证与约定

- 编译验证：`haxelib run lime build windows`（release；debug 构建损坏勿用）。**不自动运行游戏**，验收由用户真机进行。ndll 桥接期（Phase 5 前）编译产物不可运行。
- 并行会话安全：不杀 haxe.exe；PCH Permission denied 先怀疑别的会话在编译。
- **haxelib 指针现状（2026-11-15 起）**：机器级指针已切到 **D:/HaxeToolkit/haxe/lib**（NF 状态，切回 FE 用 `echo "E:/HaxeToolkit/haxe/lib" | haxelib setup`）。NF 项目本地 `.haxelib/` 中：`lime`/`openfl` 旧 fork 目录已改名为 `_old-lime-8.3.0-fork`/`_old-openfl-9.5.0-fork`（保留可随时改回），现在用 `.current="dev"` + `.dev` 指向 D 仓库的 `lime/git`、`openfl/git`。注意 `haxelib run` 的 dev 解析在项目本地仓库下有坑（曾报 Could not find），D 仓库原生 `git` 条目 + haxelib.json 剥掉 dependencies 后正常。
- D 仓库新增的lime 工具链依赖：`hxp 1.3.1`（最新版，旧 git 克隆缺 HostPlatform/Haxelib API）、`crossbyte 1.0.1 + emitter 2.0.0`（上游工具链依赖）、`format 3.5.0→3.8.0`（crossbyte 需要）。工具本体用 FE 预编译 `tools.n`（FE 无 crossbyte 也能跑的原因），lime 工具 ndll 用 NF 旧 fork 的 Windows64 lime.ndll 桥接。
- 每阶段产物：新 fork 仓库里的独立 commit（信息注明 phase），引擎仓库不动（除 Phase 6 适配提交）。

## 8. 进度日志

### 2026-11-15
- 交接文档创建。NF 引擎 merge upstream/main 完成（`35150418`，裁决见 §4，用户确认符合预期）。
- NF lime fork pr-1/pr-2 已 fetch 到本地（未合，供参考）。
- **Phase 0 完成**：新 fork 入驻 D 仓库（`lime/git`@`274f0297`+nf-port 分支、`openfl/git`@`fedf3d79b`+nf-port 分支），remote 三件套配好，`nf-src` ref 保存旧 fork 真实 tip。旧孤立提交 `e988b54c "push"` 查明 = e4adfed0 + Android ndll 重打包（被强推回退，无代码价值）。
- **工具链启动**（lime 工具从源码运行需要的全套）：FE 预编译 tools.n 复制、hxp 1.3.1/crossbyte/emitter/format 3.8.0 装入 D 仓库、ndll 桥接（见 §3 警告）。`haxelib run lime help` 已通。
- **Phase 0.5 进行中 + Phase 1 部分完成**（新 fork 提交 `d61de0a6d`、`071e6d8c1`）：
  - 已移植：BackendThread（原生+Haxe）、system get/set_hint + preferred_locales、Image.setMaxTextureSize + 加载降采样（graphicScale 字段）、AudioDecoder 全家壳 + LimeCompat.cpp 原生 stub、NativeCFFI 绑定（14 处冲突已解：双保留为主；joystick 错位块丢弃；window vsync 原语推迟到 Phase 3）。
  - 移植手法沉淀：`git diff 8.3.0 nf-src -- <file> | git apply -3` 对小文件有效（PNG/OpenAL 级别的中等冲突可用）；ExternalInterface/NativeCFFI 这类上游大改文件用**外科手术式**（提取 NF 块手工插入 + 3-way 后逐块裁决）。
  - **新发现**：NF 的 flixel fork（项目本地 .haxelib/flixel）也消费 `lime.media.AudioDecoder`（FlxSoundData.hx:8）——音频解码壳不是死代码，必须带。
  - **Origin 编辑器布局已解决（无需完整资源包）**：`tools/setup-origin-editor-layouts.ps1` pin 了 `FunkinCrew/funkin.assets@0b281066` 的 95 份 XML/CSS。本机 funkin.assets 仓库（D:\funkin-sources\funkin.assets）本地历史没有该提交 → `git fetch --filter=blob:none origin 0b281066...`（走 gh-proxy.org，按需拉 blob）→ 按清单逐个 `git show` 提取到 `_build/origin-editor-build-assets/` 并逐一通过 blob SHA+大小校验（95/95）。编译用 `lime build windows -DORIGIN_ASSETS_PATH=F:/FNF-NovaFlare-Engine/_build/origin-editor-build-assets`。**运行时的完整 Origin 资源包（gameplay/ui/mods-vslice）仍需另行提供**（docs/upstream-migration.md:60-80 结构）。
  - **Phase 0.5 编译门通过（2026-11-15）**：`lime build windows -DORIGIN_ASSETS_PATH=...` 完整走通 Haxe→hxcpp→链接，产出 `export/release/windows/bin/NovaFlare Engine.exe`（139MB）。**NF 引擎已在 FE lime 8.4.0 级 + openfl 9.6.0-dev 级底上完整编译**。
- **依赖同步完成**：hxp/crypto/json2object/polymod/flixel 全部更新到 hmm.json pin（polymod 经 gh-proxy；flixel 4a45067e 大克隆）；hmm.json 已摘除 lime/openfl 条目（dev 指针代管，Phase 5 恢复 git 条目）；**polymod 克隆内有本地提交**（setClassObjectField 加 ?bypassAccessor，Origin LegacyRuntime 消费）——hmm update 会重置它，Phase 5 需固化（fork 到 NovaFlare-Engine-haxelib 或换 pin）。
- **Phase 1/3 lime 侧移植清单（nf-port 分支，d61de0a6d→16c8e418a 约 15 个提交）**：BackendThread（原生+Haxe）、system hint/locales、Image.setMaxTextureSize+加载降采样 graphicScale、AudioDecoder 全家壳+AudioFormat、LimeCompat.cpp、FileDialogFilter+FileDialog 静态便捷、Promises/Future 聚合、Window lockRender/drawFrameRate/disabledKeys/onDropText/Begin/Complete/Position/onKey*Precise/onlyUpdate、NativeWindow setLockRender/setDrawFrameRate（防护）、setVSyncMode shim（桥上游 vsyncMode）、DroppedFile+DropFileEvent 兼容抽象、AnimationDecoder+GIF/WEBP 壳、AudioEffect/FilterEffect/AudioSource 扩展、AudioBuffer loaders、AudioManager 设备 API+__refresh+__formatDeviceName+muted/gain、AL/ALC 扩展常量与函数、NativeAudioSource latency、Gamepad setLED、GL.setMultiThreaded 链（NativeOpenGLRenderContext 防护+WebGL2 blendBarrier）、spng+BGRA 预乘、JPEG、OpenAL SOFT、CURL UB 修复、Font GetKerning、RenderEvent.RENDER_UPDATE、Bytes.toFile+lime_bytes_write_file、Theme、NativeCFFI 绑定全家（含大量去重——NF 平行根缩进声明段已清）。
- **Phase 4 openfl 侧移植清单（nf-port 分支，7bd785a34→7118c0f2f）**：Event.ENTER_UPDATE、Stage onlyUpdate/逻辑分辨率 configureBackBuffer、Graphics buffer API+transform 字段、Context3DTextureFormat 枚举、BitmapData disposeOnUpload/graphicScale/fromFile+AsyncTextureUploader、TextureBase resize/__memory*/__updateGLFramebuffer、DisplayObject/Container/Bitmap/MovieClip/Tilemap/Timeline deltaTime Float、OVERRIDE_DEPTH_TEST 命令三件套、Context3DState attrib 缓存、Context3D ASTC/S3TC/MultiBuffer API、Assets 压缩纹理开关、Shader/ShaderParameter/OpenGLRenderer、GameInputDevice setLED（1 参 shim）、Video deltaTime、TextEditEvent、Event 池 @:allow(openfl) 修复（上游潜伏 bug）、setProgramConstantsFromArray 去重。
- **重要修正**：AudioDecoder/AnimationDecoder/ASTC/overrideDepthTest/polymod bypassAccessor 等"疑似死壳"实际都有消费者（NF flixel fork、NF 引擎 FoxliteCompat/Paths、Origin compat、上游 db34faba 新代码）——以编译器为准确认，比静态 grep 可靠。
- **剩余工作**：Phase 2（SDLApplication 原生分频+渲染线程可选模块，Haxe 侧已通但 native dispatch 未接——onlyUpdate/lockRender/drawFrameRate 当前为空转）；Phase 5（ndll 从源码重建：删 `D:\HaxeToolkit\haxe\lib\lime\git\ndll\` 强制 hxcpp 编译 lime C++，或等 FE 出新 ndll；GitHub 建仓+push+hmm.json 恢复 git 条目）；Phase 6（运行时验收：**编译产物不可直接跑**——ndll 是 8.3.0 桥接，缺新原语；必须先完成 Phase 5 或临时接受 lime 功能回退）。

### 2026-11-15（第二批）
- **polymod 固化问题已解除**：NF 引擎上游（MaoPou）把 polymod 指到兼容 fork `NovaFlare-Engine-haxelib/polymod`（hmm.json ref `af3daf30`，提交 651f0c91+82ba41b2）。该 fork = FunkinCrew `4740cb2` + 1 个修正提交 `af3daf3`（setClassObjectField 加 bypassAccessor 第四参，比本地旧提交 2e9d911 完善：保留 finals 检查、同时覆盖 class fields 与 class-object fields）。本地 .haxelib/polymod/git 已 checkout 到 `af3daf3`，旧本地提交存为分支 `nf-local-port`。**注意**：该 fork 不含 FunkinCrew develop 新提交（interpolate 层完整 bypassAccessor 实现等）——上游 NF 拍板的最小兼容 fork。
- NF 引擎 merge upstream/main（db34faba→dc95098f，8 提交：西班牙语翻译、CNE 兼容修复 CNEAbstractHandler/Config、polymod fork pin、私有占位清理）→ 本地 `15c9ffbe`，无冲突。合并前先提交了本地 hmm.json lime/openfl 摘除状态（`e80c3d02`）。
- Phase 2 调研完成（结论供实现用）：
  - 上游模型：`ApplyMainLoopSettings` 算 framePeriod/vsync 分档（含 swapPaced 交换节流）→ `IsFrameDue(now)` 门控 → `DispatchFrame(now, renderFrame=true)`（UPDATE+内联 RENDER）→ `AdvanceNextUpdate`；Windows 主循环 WaitEvent 按 `nextUpdate` 睡眠。
  - NF 语义（须保留）：`lockRender=true` 时 UPDATE/RENDER **独立分频**（drawFrameRate 可高于或低于 framerate，NF 默认 framerate=1000/drawFramerate=1000，或 240/1200 组合）；`lockRender=false` = 上游内联渲染。旧 fork 每次 UPDATE 后无条件派发 RENDER_UPDATE（openfl ENTER_UPDATE 消费）。
  - nf-port Haxe 侧已就绪：NativeCFFI.hx 两个绑定声明（`lime_application_set_render_frame_rate`/`_set_split_update`，try/catch 防护）、NativeApplication.handleRenderEvent 已处理 RENDER_UPDATE→`window.onlyUpdate.dispatch()`、openfl Stage 已订阅。缺的只有原生 C++。
  - 实现方案：SDLApplication 加 `lockRender/renderFramePeriod/nextRenderUpdate` 字段 + `SetRenderFrameRate/SetLockRender`（Application.h 基类加空默认，同旧 fork）；`IsFrameDue` 与 WaitEvent 睡眠期限纳入 `nextRenderUpdate`（取 min）；DispatchFrame 在 lockRender 时不内联渲染、改为按 render deadline 派发 RENDER（swap pacing 随 render 走）；UPDATE 派发后派发 RENDER_UPDATE。ExternalInterface 补两个原语（CFFI+HL+DEFINE_PRIME）。NOVAFLARE_DRAW_RATE/NOVAFLARE_SPLIT_RENDER 环境变量不移植（§5.3 零消费）。
- **Phase 2 核心已提交（lime nf-port `ce9ac29de`）**：分频调度叠回完成（SDLApplication.h/.cpp、Application.h、ExternalInterface.cpp 共 4 文件 158 行）。要点：lockRender 时 ApplyMainLoopSettings 走专用分支（update 严格 framePeriod 节奏，不用 swapPaced/display-driven——否则 swap 只发生在 render 侧、update 会失控空转）；DispatchFrame 顺序 = UPDATE → RENDER_UPDATE →（lockRender ? 按 deadline DispatchRenderFrame : 内联 RENDER）；WaitEvent/忙等/事件批处理唤醒均用 `NextFrameDeadline()`；渲染 backlog 恢复用独立派发点（Update 尾部 `else if (IsRenderDue)`）。
- **Phase 2 渲染线程移植方案（已定，待编译门过后执行）**：
  1. OpenGLBindings：`git diff 8.3.0 nf-src -- project/src/graphics/opengl/OpenGLBindings.cpp | git apply -3`（7186 行 187 hunk，冲突人工点仅 gc_gl_object/EMSCRIPTEN 区），带出 `lime_gl_set_multithreaded` 原语（旧 fork OpenGLBindings.cpp:9111）。
  2. 拷贝：`RenderThread.h`→include/graphics/，`RenderThread.cpp`/`PerformanceMonitor.{h,cpp}`/`SharedBufferManager.{h,cpp}`→src/graphics/，`DoubleBuffer.h`/`ReadOnlyView.h`→include/graphics/（后两个未接线，一并带走）。
  3. §5.5 修法：①RebindContext 删 MakeCurrent(NULL)（worker 上直接重绑同一 context）；②pause 循环按 contextHeld 防重入解绑/重绑；③worker 渲染请求事件：SDL_RegisterEvents 注册专用类型（SDLApplication ctor），HandleEvent 收到后 `nextRenderUpdate = now` 让常规派发点接手（替代 SDL_USEREVENT code=1 落入 default 被丢弃）；④PauseRendering 450ms 超时不再强夺 context，只跳过并打日志；⑤context 创建期初始化（OpenGLBindings::Init+版本检查）移到主线程、worker Start 之前（消除 5s future 跨线程等待，旧 SDLWindow.cpp:331-386）；⑥`s_contextFlips` 改 atomic（worker 侧 swap 也调 NoteContextFlip）。
  4. SDLWindow：`renderThread` 成员/SetGLContext/ContextFlip 分支/~dtor 与 Close 的 Stop/PauseRendering/ResumeRendering/OnRenderDeviceReset，全部 `#ifdef LIME_RENDER_THREAD` 门控（成员含内，无 define 零足迹）；WILLENTERBACKGROUND/DIDENTERFOREGROUND 挂 Pause/ResumeRendering（同样门控）。
  5. Build.xml：`<set name="LIME_RENDER_THREAD" value="1" if="lime-render-thread" />`（照 LIME_VULKAN 先例，Build.xml:41）+ 三个 cpp `if="lime-render-thread"`。NF Project.xml 暂不加 haxedef（默认关），验证时 `-Dlime-render-thread` 手动开。
  6. DispatchRenderFrame 加 worker 背压检查（`activePendingFrames >= MaxPendingFrames` → hasPendingRenderRequest + 跳过，worker 事件恢复），仅 LIME_RENDER_THREAD 时编译。

### 2026-11-15（第三批）
- **Phase 2 核心编译门通过**：`ce9ac29de` 在 NF 引擎完整 release 构建（139MB exe）中编译链接成功。
- **⚠️ 分支去向**：并行 ndll 重建会话在共享 D 仓库新建了工作分支 **`NF-Lime-8.4.0`**（基于 nf-port tip `ce9ac29de`），本批 Phase 2 提交都落在该分支上（线性历史，nf-port 是其祖先）。完成后可 fast-forward 合回 nf-port；下一会话续做前先 `git branch` 确认所在分支。
- **OpenGLBindings 3-way 重放完成**（`5ad234e78`）：`git diff 8.3.0 nf-src -- OpenGLBindings.cpp | git apply -3`，187 hunk 中 130 干净应用、57 冲突全部解决（脚本机械合并 50 + 手工 7）。冲突全在 GLES3-API 函数：上游改守卫结构（`LIME_GLES3_API || !LIME_GLES`、空指针防护、macOS APPLE 分支）+ NF 加包壳，解法=两者叠加。保留：上游 EMSCRIPTEN BGRA 路径、copy_image_sub_data 两函数、`hl_gc_gl_object` finalizer（fence_sync 包壳内）。glDrawBuffers 用 NF 堆拷贝方案（alloca 在异步派发下悬垂）。头文件（src/graphics/opengl/OpenGLBindings.h）+5 行单独 apply -3（与上游新增 Reload 声明合并）。`lime_gl_set_multithreaded` 原语随 diff 带出。
- **渲染线程模块搬入完成（待编译验证）**：
  - 拷贝 RenderThread.h/.cpp、PerformanceMonitor、SharedBufferManager、DoubleBuffer.h、ReadOnlyView.h。
  - §5.5 修复落地：①RebindContext 单次绑定（删 NULL unbind）；②pause 循环按 contextHeld 防重入；③**worker 渲染请求事件整体删除**——背压恢复改为"DispatchRenderFrame 被压时 deadline 前移一个周期、下个周期自动重试"（比注册事件方案更简单，无跨文件耦合）；④PauseRendering 450→5000ms、Resume 2000ms（不让 worker 与主线程赛跑单 context）；⑤context 创建期初始化上游已是主线程（CreateOpenGLContext），无需改；⑥`s_contextFlips` 改 atomic。
  - **懒启动改造（设计变更，比交接方案更进一步）**：不再用编译开关，改纯运行时开关——`isMultiThreaded` 默认 **false**（旧 fork 默认 true 是因为创建 context 即启线程；懒启动下 true 会让包壳向未启动 worker 推命令→黑屏）。`SetMultiThreaded(true)` 首次调用时才 `Start(window, context)`（当前 context 转移给 worker），false 时 Pause+收回 context。NF Project.xml 无需加 haxedef，ClientPrefs.renderThread=false = 真·零 worker 线程。
  - SDLWindow：`renderThread` 成员 + `windows` 静态表 + SetGLContext/PauseRendering/ResumeRendering/OnRenderDeviceReset（timeout 加大版）+ ContextFlip worker 分支（worker 内 swap + NoteContextFlip 保 swap pacing）+ ctor/dtor/Close 登记/停线程。SDLApplication：WILLENTERBACKGROUND/DIDENTERFOREGROUND 挂 Pause/ResumeRendering；DispatchFrame 内联渲染遇 worker 满载丢弃（同旧 fork code=0 语义）。
  - PerformanceMonitor 编译带过、不接帧路径（无外部消费面，纯统计单例）。
  - Haxe 侧零改动（GL.setMultiThreaded→lime_gl_set_multithreaded 原语已在）。

### 2026-11-15（第四批，ndll/Phase-5 会话）
- **Phase 5 推送完成，方案落地为「CI 编译全平台出库」**：
  - `NF-Lime-8.4.0` 分支已推 `IceTheAxe/lime`：`11f75c54b`（库形态 haxelib.json + workflow 4.3.7 + nf-haxelib 发布目标）→ CI run 43700722627；`3d4cb59df`（CI 修复三件）→ run 43702804137。`NF-OpenFL-9.6.0` 已推 `TieGao/openfl`（nf-port 1ec1f8c8b，openfl 纯 Haxe 无 ndll 无 CI，haxelib.json version 9.6.0）。
  - **发布机制（复用 FE）**：CI 7 平台 job 全绿 → package-haxelib 收 ndll 产物 → publish-haxelib-branch 镜像打包树到同仓库孤儿分支 `nf-haxelib`（FE 用 `haxelib`，互不覆盖；已加 branches-ignore 防死循环）。消费者 `haxelib git lime https://github.com/IceTheAxe/lime nf-haxelib`。
  - **推送路由**：本机直连 github.com 可达（无需代理）；D lime 仓库配了 `url.https://github.com/.pushInsteadOf`（push 直连、fetch 走代理）；`~/.gitconfig` 的 credential.helper 指向不存在的 workbuddy GCM（报错元凶，待用户清理）；SSH 22 被封、`ssh.github.com:443` 可用（Hi TieGao!）；github.com 有 TieGao 已存凭据。
- **CI run1 失败根因（tools 构建宏上下文连锁）**：`-lib crossbyte` 的 extraParams 宏使宏解释器把 lime.ui.Window/ThreadPool/NativeApplication/AudioManager 一串拉进宏上下文编译，NF 的 compat 移植三处不宏安全：①`DropFileEvent` 构造器在 `#if !macro` 内 → "does not have a constructor"；②`AudioManager.__refresh` 的 14 个 `__*Supported` 赋值没套 `#if lime_openal` 门（声明有门赋值没有）；③`NativeApplication` 宏上下文调 `dispatch`。修复：DropFileEvent 加宏孪生构造器/类、`__refresh` 赋值补门、**tools.hxml 摘除 `-lib crossbyte`**（工具源码只有运行时 `Haxelib.getPath("crossbyte")` 字符串查找，无编译期 import；html5 eval 在 crossbyte 已装时不受影响；FE 分支保留 -lib）。摘除后 tools.hxml `--no-output` 全绿。
  - 排查手法沉淀：`haxe tools.hxml --no-output` 本地等价复现 CI tools 构建；`-v` 对比失败/通过运行的 `Typing macro` 行定位宏上下文入侵点；haxelib `-lib` 与手工 `-cp` 的差异（cp 顺序/依赖传递/extraParams/版本化 define）必须整体复刻。
- **⚠️ 当前分支 C++ 编译阻塞（等 Phase 2 会话落库）**：`OpenGLBindings.cpp/.h`（`5ad234e78`+暂存卷入 `3d4cb59df`）引用 RenderThread 模块，但 **RenderThread.h/.cpp、SharedBufferManager、DoubleBuffer.h、ReadOnlyView.h、PerformanceMonitor 实体文件 + Build.xml 接线全部未提交**（`git ls-files` 只查到 patches/PerformanceMonitor.patch）。CI 的 ndll job 会在 C++ 阶段报缺 include/缺符号，直到 Phase 2 会话把 WIP 提交到 `NF-Lime-8.4.0`。其暂存的 OpenGLBindings.h 已随 `3d4cb59df` 入库（cpp 定义 `5ad234e78` 已在，内容自洽，只是 include 目标未跟踪）。
- **polymod 固化无需再做**：上游已建 `NovaFlare-Engine-haxelib/polymod`（main=af3daf3）且本地 hmm.json 已指向（本会话早前对 nfh 的 push 403 无关紧要——commit 已在 fork 里）。
- **D lime 仓库子模块待修**：`--depth 1` 误检出到分支 tip（openal 应锁 FE arm64 分支 `b8cb80bf`）；22 个记录 SHA 清单 `/tmp/submod-shas.txt`，修复脚本 `C:/Users/Ice_Axe/AppData/Local/Temp/fix-submodules.sh`（cairo 已 OK-FULL，其余待跑；对另一会话编译窗口错开执行）。
- **下一步**：①Phase 2 会话提交 WIP → CI 过 C++ → nf-haxelib 发布；②hmm.json 恢复 lime（ref=nf-haxelib）/openfl（ref=NF-OpenFL-9.6.0）条目 + hmm install 换 dev 指针；③引擎 release 构建验证（CI 产物 ndll，本地重建仅备用）；④用户真机验收。

### 2026-11-15（第五批，Phase 2 会话）
- **CI 阻塞已解除**：渲染线程 WIP 已提交 `7243fba04` 并推送到 `IceTheAxe/lime` NF-Lime-8.4.0（15 文件：8 个模块实体 + SDLWindow/SDLApplication/OpenGLBindings/OpenAL/ExternalInterface/Build.xml），CI 自动重跑。
- **C++ 全量验证早于 CI 完成**：独立 hxcpp 源码构建全链接通过，产物 `F:/FNF-NovaFlare-Engine/_build/lime-verify-ndll/Windows64/lime.ndll`（10.4MB，含全部 NF 原语，二进制确认 set_render_frame_rate/set_split_update/set_multithreaded/backend_thread_start/alert_compat 各 2 处注册）。
- **⚠️ 本地已换入该 ndll**：`D:\HaxeToolkit\haxe\lib\lime\git\ndll\Windows64\lime.ndll` 已替换为 NF 验证版，FE 预编译原件备份为同目录 `lime.ndll.fe-prebuilt-backup`（8.9MB）。**本地 `export/release/windows/bin/NovaFlare Engine.exe` 现在可以直接启动**（exe 无需重编——ndll 动态加载；exe 是 17:52 构建的 NF 完整 Haxe 侧）。lime-debug.ndll 仍是 FE 预编译（debug 构建本来就损坏，忽略）。
- **排查手法沉淀（重要）**：`lime build windows` **从不编译 lime 的 C++**——游戏链接/加载的是 ndll/ 下的预编译产物，Haxe 侧编译门不验证原生改动。验证 lime 原生的独立命令：`cd lime/git/project && haxelib run hxcpp Build.xml -Dwindows -DHXCPP_M64 -DOUTPUT_DIR=<隔离目录> "-DNATIVE_DESKTOP_PATH=<native-desktop 路径>" "-DNATIVE_IPC_PATH=<native-ipc 路径>" "-DSTAGEWEBVIEW_PATH=<StageWebView 路径>"`（预定义 resolved 路径绕过 `${haxelib:}` 解析；OUTPUT_DIR 隔离不碰 ndll/ 产物）。
- **本轮修复的源码编译期遗留**（CI 全平台构建同样会撞）：①Build.xml `native-toolkit-png` → `native-toolkit-spng`（上游 PNG 残留指向未注册文件组）；②OpenALBindings 8 个函数定义体 + 注册块重复（Phase 1 平行段去重遗漏，已脚本化清除）；③ExternalInterface BackendThread 原语前向声明缺失、HL 变体缺失、LimeCompat 依赖的 5 参 `lime_application_alert` 未移植。
- **用户真机验收（Phase 6）要点**：①基本启动/主菜单/进歌；②GraphicsGroup 的 lockRender/drawFrameRate 开关 + ExtraCounter 的 Draw Frame 监视（lockRender=true 时 update 严格 framePeriod 节奏、vsync 交换自然节流 render）；③renderThread 开关（懒启动 worker，关=主线程直渲）；④窗口关闭链（上游 cancelable WINDOW_CLOSE 变化）；⑤音频（SDL_sound 优先/HRTF 默认关）。
- **剩余**：CI 7 平台绿 → nf-haxelib 发布 → hmm.json 恢复 lime/openfl 条目 → 本地换回 CI 产物（或确认与本地 ndll 同源后保留）→ polymod/子模块遗留（第四批清单）。

### 2026-11-15（第六批，Phase 2 会话——本地启动排障）
- **本地 NF 已可启动**：`export/release/windows/bin/NovaFlare Engine.exe` 完整走通 Preloader→Main.main→Main ctor→setupGame→Origin 路径（prepare 挂载 2075 资产）→FlxGame 创建→游戏循环活跃（CPU ~19%、无报错）。用户真机视觉验收待做（自动化截图受 PrintWindow/GL 黑帧限制）。
- **启动链 5 层障碍及修复**（按暴露顺序）：
  1. **17 个旧 fork 原语缺失**（Origin SDL2 兼容层绑定 touch/theme/joystick/vsync/handle/font/gesture/alert）→ 移植 + 提交 `31592f752`（含 Window 基类 GetHandle/CreateContext/ContextMakeCurrent(void*) 虚函数）。**症状特征**：hxcpp 打 "Could not find primitive X__prime" 然后在 FakeCamera 静态初始化 SEH 崩溃。
  2. **Origin 运行时资源包缺失**（启动即挂载 gameplay/ui）→ 从上游 `0b281066` sparse partial clone 拉取部署（用户自下载 zip 校验等价，仅 git autocrlf 行尾差异）。
  3. **`openfl_pool_events` 事件池**：FakeCamera 静态初始化期 `Event.__pool.get()` 原生崩溃（hxSehException 无消息）→ Project.xml 关闭。真因（静态初始化序 vs 池生命周期）待查，池化收益再评估。
  4. **`lime-vulkan` 新默认**：GL 渲染链拿不到上下文 → `no-vulkan` 锁定（Project.xml）。
  5. **Phase 2 真 bug：RENDER 事件丢失**——DispatchFrame 里 RENDER_UPDATE 派发后内联渲染分支未把 `renderEvent.type` 改回 RENDER（事件对象复用，旧 fork 有显式恢复行、移植时漏掉）→ 修复一行。**症状特征**：事件计数全是 type=3、Stage 帧循环不启动、Preloader 永不完成（openfl 9.6 帧驱动已改为 RENDER 驱动：`__onLimeUpdate` 只存 delta、ENTER_FRAME 全在 `__onLimeRender` 里）。
- **⚠️ 遗留：intro 视频冻结（hxvlc×RDP）**：Origin intro 的 hxvlc 视频在 RDP 会话出帧失败，8 秒看门狗触发 finishIntro 后 hxvlc 原生停止死锁主线程（CPU 归零）。已验证挪走 `assets/videos/menuExtend/titleIntro.mp4`（当前已改名 .bak 保留）即跳过视频正常跑。真机（非 RDP）可能正常；若真机同样冻结，恢复 .bak 改名即可复现，长期方案是 `save.novaSettings.skipVideo=true` 或 NOVIDEO 构建。
- **排障手法沉淀**：
  - hxcpp 崩溃无消息 = hxSehException → 加 stderr 直写标记（stdout 重定向到文件是块缓冲，trace 全憋在 4KB 缓冲里——**这就是"日志空但进程活着"的真相**）；标记助手：`Sys.stderr().writeString()+flush()`。
  - 黑屏三分排查：先查原语缺失（grep 日志 "Could not find primitive"）→ 查 Preloader 完成链（lime utils/Preloader + openfl display/Preloader + FlxBasePreloader 三层事件链，COMPLETE 被 FlxBasePreloader preventDefault 后靠 ENTER_FRAME 累计时间派发 UNLOAD）→ 查 RENDER 事件类型（openfl 9.6 是渲染驱动帧）。
  - `lime build windows` 的 exe 侧 Haxe 编译错误会被 lime 吞掉 exit code（`| tail` 管道时注意）——看 log 里 `[30;41m ERROR`。
- **本地构建产物现状**：bin 里 exe=最新（含 no-vulkan/池关/marker 已回退的干净重建）；lime.ndll=NF 完整版（含全部原语+RENDER 修复）；Origin 资产就位；titleIntro.mp4 已恢复原位。
- **迁移收尾清单**：①上 CI 的 nf-haxelib 产物替换本地 ndll（或确认同源）；②intro 视频真机验收（RDP 冻结是否复现）；③池化根因与恢复评估；④polymod D 盘工作树已修为 af3daf3（嵌合体修复），第五批的"子模块待修"仍开放。
- **补充（同批）**：①`titleIntro.mp4` 已改 `.bak` 让本地（RDP）可启动——hxvlc 在 RDP 会话必挂（视频起播→8 秒看门狗→finishIntro 清理死锁），真机控制台会话可能正常，恢复方法=去掉 `.bak` 后缀；②启动后有一条非致命错误 `no SOUND asset "flixel/sounds/beep.ogg"`（flixel 回退音不在嵌入清单，警告后继续）——待把 beep.ogg 补回嵌入资产。

### 2026-11-15（第七批：清档后渲染线程把 GL 链打死）
- **更正（清单机制）**：`default` 库清单是**运行时从 `bin/manifest/default.json` 读**的，生成的 `ManifestResources.cpp` 只登记字体与各库路径——所以 beep 缺不缺取决于该 json 是否被那次构建重写，不是「嵌入清单陈旧」。重建后 `manifest/default.json` 已含 `flixel/sounds/beep.ogg`。
- **崩溃 1（缺 beep）**：hxvlc 找不到 intro 视频 → `FlxG.log.warn` → flixel 日志样式播 `flixel/sounds/beep` → 清单里没有 → `lime.utils.Assets` 的 `Log.error` 抛（`Log.throwErrors` 默认 true）→ 崩。**不是代码冲突**：`obj/src/ManifestResources.cpp`（16:37）缺 `flixel_sounds_*`，而 `haxe/ManifestResources.hx`（19:03）有 → 该编译单元没被重编/重生成。核对法：`grep -c flixel_sounds export/release/windows/obj/src/ManifestResources.cpp` 应为非 0。
- **崩溃 2（渲染线程）**：清档后 `performanceDefaultsVersion=8` 迁移把 `renderThread` 强制设 true（默认值也是 true），worker 首绑失败（`wglMakeCurrent: 请求的资源在使用中`）→ 主线程已放 context、worker 没拿到 → `GL_VENDOR/RENDERER/VERSION=null`、`maxTextureSize 0` → 首个 shader 编译失败 `Log.error` 抛。与本文档「渲染线程默认关」的决策相反。
- **已修**：①`ClientPrefs.renderThread` 默认 false + 迁移段改 false + `performanceDefaultsVersion` 8→9；②lime fork `OpenGLBindings::SetMultiThreaded(true)` 加回退：`WaitForContext(true,2000)` 失败则 `Stop()+MakeCurrent()` 回主线程、`isMultiThreaded` 保持 false（②需重编 ndll 才生效）。
- 免重编验证：`NOVAFLARE_RENDER_THREAD=0`。
- 未解：渲染线程首绑为何失败（怀疑与 Origin 兼容层 `ContextMakeCurrent(void*)` 用非 SDL 路径绑定有关，待查）。
