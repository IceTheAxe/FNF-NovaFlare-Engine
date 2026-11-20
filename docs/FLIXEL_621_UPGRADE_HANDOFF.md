# Flixel 5.9.0 → 6.2.1 升级交接说明书（长期任务）

> 立项日期：2026-11-20。可行性探查已完成（结论见下），本文档是后续接手者的唯一入口。
> 探查当日未改任何仓库代码；所有验证工件在仓库外的 F 盘临时目录（见 §8）。
> 对照锚点：**FE（Frozen Engine）从 flixel 5.6.2 升 6.2.1 只有废弃函数问题**（FE 侧探查结论）。
> NF 的困难全部来自自有 fork 对 Flx 5.9.0 的深度魔改——6.x 本身不是问题源。

---

## 1. 一句话结论

**可行，但不是"API 改名级"升级，而是"fork 特性重移植级"升级。**
正确路径：**以 pristine 6.2.1 为基线重建 NF fork，按特性逐个重移植**。不要 git rebase。

## 2. 为什么不能 rebase

- NF 的 flixel fork 是独立仓库 `TieGao/flixel`（分支 `NF-Flixel-5.9.0`），43 个提交，种子 = pristine 5.9.0（非 GitHub fork，无上游历史可 merge）。
- fork 真实 delta（对 pristine 5.9.0 树 diff）：**87 改 / 33 增 / 11 删**（删的全是 CI/test 配置），核心 delta ≈ **4565 行**。
- **87 个改动文件中 68 个上游 6.x 也改了（78% 重叠）**，且集中在 fork 与上游各自重写的同一批子系统（音频、固定步长、相机、批渲染）。重放 43 个提交 = 冲突地狱。
- 上游 6.x 版本线：5.9.0 → **6.1.0（2025-04，第一个稳定 6.x，破坏性变更都在它的 changelog 里）** → 6.2.0 → 6.2.1（2026-11-03）。

### 2.1 冲突矩阵（forkΔ / 上游Δ，倒序）

| 文件 | forkΔ | 上游Δ | fork 特性 |
|---|---|---|---|
| `flixel/sound/FlxSound.hx` | +530/-18 | +307/-126 | hxvlc 流式（`addTrack/_initVlc/releaseMedia`） |
| `flixel/FlxCamera.hx` | +372/-12 | +428/-218 | CNE shader 尺寸、批量绘制分析器、`updateLerp` |
| `flixel/system/frontEnds/SoundFrontEnd.hx` | +311/-1 | +273/-111 | FlxSoundData 缓存体系（addCache/clearUnused/findKeyForBuffer） |
| `flixel/FlxSprite.hx` | +308/-13 | +532/-142 | 黑块偏移、`rawClipRect`、`doAdditionalMatrixStuff` |
| `flixel/FlxGame.hx` | +289/-30 | +8/-73 | 固定步长、渲染/更新拆分（`onEnterUpdate/updateDrawElapsed`）、`addShader` |
| `flixel/math/FlxPoint.hx` | +258/-0 | +380/-188 | CNE 兼容方法（findIntersection/bounceWithFriction/set_length） |
| `flixel/system/ui/FlxSoundTray.hx` | +243/-44 | +97/-57 | NF 音量条重写（barsAmount/reloadText/saveSoundPreferences） |
| `flixel/input/mouse/FlxMouse.hx` | +136/-5 | +10/-3 | FE 鼠标约定（justMoved*/swipeDelta/ticksDelta） |
| `flixel/graphics/frames/FlxFrame.hx` | +123/-4 | +404/-114 | UVRect 相关适配 |
| `flixel/util/FlxColorTransformUtil.hx` | +114/-0 | +154/-6 | CNE 兼容 |

完整 68 行矩阵：`F:\nf-flixel-feasibility-tmp\conflict-matrix.tsv`（列：forkΔ / 上游Δ / 文件）。

### 2.2 fork 新增文件（33 个，有效的代码文件）

`FlxLayer.hx`（CNE 批渲染）、`FlxTypes.hx`（CNE typedef）、`IFlxGroupable.hx`、`FlxSoundData.hx`（lime AudioBuffer 流式包装，源自 FunkinCrew 方案）、`FlxFlick.hx`、`FlxGyroscope.hx`、`SoundCompat.hx`（宏，过滤 FunkinSound.paused 字段）、`FlxCompatSoundAsset.hx`、`OneOfFive.hx`/`OneOfSix.hx`、debugger 的 `Icon.hx`/`ScrollSprite.hx`（6.2.1 已有自己的版本，不用移植）。

**其中 4 个被 NF 源码 import**（升级必须继续提供）：
- `flixel.group.IFlxGroupable` — `source-originFunkin/funkin/group/FunkinGroup.hx`
- `flixel.FlxTypes` — `source-codename/codename/funkin/menus/ui/Alphabet.hx`
- `flixel.FlxLayer` — `source-codename/.../Charter.hx`（已注释，保留兼容面）
- `flixel.sound.FlxSoundData` — `source-codename/codename/funkin/game/PlayState.hx:822,985,1243`、`StrumLine.hx:197`

## 3. 实测基线：6.2.1 下的编译错误清单

方法：隔离 haxelib 仓库（`HAXELIB_PATH=F:/nf-haxelib-62` 前缀注入）+ `lime display windows` 生成 hxml + `haxe --no-output`。基线（5.9.0 fork）= **0 错误**；6.2.1 + 4 文件 shim = **21 错误 / 10 文件**（日志：`typecheck-62-full7.log`）。

### 3.1 fork 添加 API 被 NF 直接使用（Phase 1/4 恢复）

| 错误 | 位置 | 处理 |
|---|---|---|
| `FlxG.isFullFrame` 不存在 ×2 | `source/games/objects/Note.hx:806,854` | fork 字段恢复（Phase 1 补字段，Phase 4b 补语义） |
| `FlxG.fixedStepMS/fixedStepMSExact` ×3 | `source/general/backend/ClientPrefs.hx:478,495,496` | 同上 |
| `Character has no field additionalX/Y` ×6 | `source/games/PlayState.hx:3545-3572` | `additionalX/Y` 是 fork 加在 FlxObject/FlxSprite 的黑块偏移字段（fork FlxObject.hx:624、FlxSprite.hx:883,1466,1568），Phase 1 恢复 |
| `FlxSound.releaseMedia` ×3 | `source/states/freeplayState/FreeplayState.hx:1708-1710` | Phase 4a 音频重移植时实现 |
| `handleInput`（FlxSprite/FlxInput）×3 | `source/mobile/flixel/FlxButton.hx:335,337,371` | fork 的虚拟按键直映射接口，Phase 4d |
| `FunkinSound.load` 静态/实例撞名 ×2 | `source-originFunkin/funkin/audio/FunkinSound.hx:469,601` | 6.2.1 给 FlxSound 加了实例 `load`；把 FunkinSound 静态 `load` 改名（如 `loadCached`），引擎侧修 |

### 3.2 上游确定性删除（API 迁移）

| 项 | 位置 | 处理 |
|---|---|---|
| `FlxState.switchTo` 已删（实锤报错） | addons `FlxTransitionableState.hx:199` | 迁移到 `startOutro(onOutroComplete)`（6.2.1 FlxState:196）；需确认 addons 4.0.2 是否已修，没修就 fork 里修 |
| 同上（include() 吞错未显示，但同型必炸） | codename `MusicBeatState.hx:446`、`MusicBeatSubstate.hx:381`、`MainMenuState.hx:171-177` | 三处 override 全部裸写无版本守卫，必改 `startOutro` |
| `FlxText.FlxTextFormatRange` 变 private（实锤致命） | `source-codename/codenamechain/CodeNameScriptRuntime.hx:4`（import）、`codename/funkin/game/PlayState.hx:43`（@:access） | **新 fork 里把 6.2.1 FlxText.hx:1362 的 `private class` 改回 `class`，一行修** |
| flixel-ui `FlxInputText` switch 缺 `OUTLINE_CARDINAL` case（实锤） | `flixel-ui git flixel/addons/ui/FlxInputText.hx:800` | 升 flixel-ui 2.6.5 自带修复 |

### 3.3 意外的好消息（不用动的）

- `FlxCamera.defaultCameras` 属性 6.2.1 **仍在**（changelog 说删了，实际代码保留了 get/set）；27 处 `@:privateAccess FlxCamera._defaultCameras` 全部存活。
- `FlxGame._customSoundTray`（`source/Main.hx:413`）仍在。
- `FlxRandom.getObject` 仍在（changelog "Remove generic methods" 只是去 @:generic 标注）。**教训：changelog 推断会误报，编译器才是硬标准。**
- `FlxGame` 构造签名 7 参兼容（`source/Main.hx:271,410`）。
- `FlxG.signals.postGameStart` 等 6.x 新信号名 NF 已在用。

### 3.4 fork 私有 API 泄漏到引擎代码（生态报告发现）

- `source-originFunkin/funkin/audio/visualize/VisShit.hx:122` 与 `ABotVis` 用 `snd._source.buffer`——`_source` 是 **fork 私有 getter**，官方 5.9.0/6.2.1 都没有。改为 `snd._channel.__audioSource`（6.2.1 自己也这么用）。

## 4. 生态库升级清单（全部可平移，无需找替代品）

| 库 | 现状 | 动作 |
|---|---|---|
| flixel-addons 3.3.2（NF fork） | 上游适配 6.x 的版本是 **4.0.0/4.0.1/4.0.2**（无 3.4.0） | 升 4.0.2；NF fork 补丁（"Restore original NF runtime paths" 等）重新移植；验证 FlxTransitionableState switchTo 是否已修 |
| flixel-ui（NF fork，基于 2.6.4） | 上游最新 **2.6.5**（官方已宣布最小维护，推荐 haxeui-flixel） | 升 2.6.5；"输入框聚焦修复" 补丁移植 |
| flxanimate（beihu235 fork @ b8970d2） | 4.0.0，条件编译已覆盖 6.x | **零改动**；可选跟进 Dot-Stuff 上游 |
| flixel-animate 1.5.0（NF fork） | FunkinCrew 原生以 6.x 为基准 | **零改动** |
| haxeui-flixel 1.7.0 | backend API 全部验证存活；上游 2025-06 停更 | 零改动 + 升级后回归 UI |
| FlxPartialSound（NF fork） | 纯静态工具，不碰 FlxSound 内部 | **零改动** |
| flxsoundfilters（NF fork = 事实维护版） | `@:privateAccess sound._channel.__audioSource.__backend.handle` 三层链路已逐一验证 6.2.1 仍在 | 编译零改动；**升级后必须实测 reverb/echo**（6.2.0 动过 _channel 创建时机；6.2.1 destroy 会取消 fadeTween） |
| funkin.vis（funkVis fork） | `SpectralAnalyzer(audioSource:AudioSource,...)` 纯 lime API | **零改动** |
| polymod 2.0.0 / moonchart 0.5.1 | 无 flixel 依赖 | **零改动** |

## 5. 任务清单（按阶段执行，勾选推进）

### Phase 0 — 准备（半天）
- [ ] 新建 fork 分支 `NF-Flixel-6.2.1`：以 **pristine 6.2.1** 为起点（`D:\HaxeToolkit\haxe\lib\flixel\6,2,1` 就是完整源码），重建 NF 补丁层；推 TieGao/flixel（注意 NF CI 缓存坑：flixel 已在依赖重装白名单，新 ref 会被 CI 正确重装）
- [ ] hmm.json 的 flixel ref 切到新分支（**最后一步做**，见 Phase 6；期间全程用 HAXELIB_PATH 隔离环境）
- [ ] 临时移除 `Project.xml:350` 的 `no-deprecation-warnings`，让 6.2.x 弃用警告可见（迁移完再决定是否恢复）
- [ ] 通读 §2 冲突矩阵与 §3 错误清单；确认 `F:\nf-haxelib-62` / `F:\nf-flixel-feasibility-tmp` 工件仍在（丢了可按 §8 重建）

### Phase 1 — 新 fork 最小恢复层（目标：NF 编译错误清零）（1-2 天）
- [ ] FlxText.hx:1362 `private class FlxTextFormatRange` → `class`（一行）
- [ ] FlxObject/FlxSprite 恢复 `additionalX/additionalY` 字段及其参与的位置计算（对照 fork FlxObject.hx:624/1145、FlxSprite.hx:883-886/1466-1468/1568；这是黑块偏移核心，语义要完整不是空字段）
- [ ] FlxG 补 `fixedStepMS/fixedStepMSExact/isFullFrame` 字段（先给默认值让编译过；语义在 4b 补全）
- [ ] FlxSound 补 `releaseMedia` 占位、FlxSprite/FlxInput 补 `handleInput` 占位（4a/4d 实现真身）
- [ ] 引擎侧：FunkinSound 静态 `load` 改名（连带 :601 调用点）
- [ ] shim 4 类并入 fork（IFlxGroupable/FlxTypes 原样；FlxLayer/FlxSoundData 按 6.2.1 内部适配，shim 副本在 `F:\nf-flixel-feasibility-tmp\shim\`）
- [ ] 验证：隔离环境类型检查 0 错误（对齐 59-full7 基线）

### Phase 2 — 状态切换迁移（半天）
- [ ] addons `FlxTransitionableState`：switchTo 逻辑迁 `startOutro`（先查上游 4.0.2 是否已修）
- [ ] codename 三处：`MusicBeatState.hx:446`、`MusicBeatSubstate.hx:381`、`MainMenuState.hx:171`（注意三处都有 `event("onStateSwitch")` 脚本事件语义，不能直接删）
- [ ] 验证：状态切换链路（Title→Menu→Play→暂停→回主菜单）无回归

### Phase 3 — 生态库升级（1-2 天）
- [ ] flixel-addons → 4.0.2（NF 补丁移植；确认 4.0.0 删掉的 FlxRayCastTilemap/FlxMouseControl NF 无引用）
- [ ] flixel-ui → 2.6.5（聚焦补丁移植；FlxInputText 已被上游弃用，长期应转 haxeui-flixel）
- [ ] 验证：flxsoundfilters 的 reverb/echo、haxeui 面板、ABotSpeaker 频谱（涉及 `snd._source`→`_channel.__audioSource` 迁移）

### Phase 4 — fork 特性重移植（主体工作，按风险倒序）
- [ ] **4a 音频子系统（最大块，最优先）**：fork 的 FlxSoundData 缓存体系 + `releaseMedia` + hxvlc 流式，与 6.2.0 的音频初始化大重构（#3558/#3586/#3636）和 `loadStreamed`/`createStreamed` 对接。决策点：fork 的 hxvlc `addTrack` 通道是否保留（NF debug 构建因 hxvlc+hxcpp fork 冲突已损坏，见记忆），还是全面转 6.2.1 原生流式——**需要用户拍板**
- [ ] **4b FlxGame 固定步长**：fork 的渲染/更新拆分（`onEnterUpdate/updateDrawElapsed`、"Fixed-step logic clock tracks wall time"）在 6.2.1 FlxGame 上重做；6.x 相机 lerp 在非固定步长下的行为变化（#2922）要一起调
- [ ] **4c FlxCamera/FlxLayer 批渲染**：CNE shader 尺寸支持、`addShader/removeShader`、批量分析器（`batchProfiler*`）、FlxLayer 对接 6.2.1 的 FlxDrawItem 内部
- [ ] **4d 输入层**：FlxMouse FE 约定（justMoved*/swipeDelta/ticksDeltaSincePress）、`handleInput` 虚拟按键映射、FlxGyroscope/FlxFlick 按需
- [ ] **4e FlxSoundTray**：NF 重写版平移（注意 6.1.0 对 FlxSoundTray 的扩展点变化：`showAnim`/`_label`/`_bg`）
- [ ] **4f 其余机械平移**：FlxPoint/FlxRect/FlxColorTransformUtil 的 CNE 兼容方法、FlxTween/FlickerTween、FlxTilemap、debugger 组件等（对照 conflict-matrix.tsv 里 forkΔ < 60 行的文件，多数可直接搬 fork diff）
- [ ] 每完成一块：隔离环境类型检查 + release 实测

### Phase 5 — 行为回归与验收（编译器抓不到的部分）（与 Phase 4 交错）
- [ ] FlxSpriteGroup origin 重锚定（#2981）：94 个子类（NF 72）抽查；已知 group 上设 origin 的用法目前只有 FlxSprite 级调用，风险低但需跑一遍 UI/编辑器
- [ ] FlxCamera zoom/lerp 变更（#2907/#2922）：NF 的 6 个相机子类（PsychCamera、HudCamera、FunkinCamera 等）
- [ ] `pixelPerfectRender` floor→round（#3638）：像素级 UI 对齐检查
- [ ] 音频：loopCount/loopUntil 替代 fork 的循环处理；6.2.1 `FlxSound.destroy` 会取消 fadeTween（#3639）
- [ ] 弃用警告清零（fastSin/fastCos ×13、`FlxG.sound.load/stream` 弃用等）
- [ ] 全功能手工回归：游戏内玩谱 / 编辑器（PE）/ 移动端 / Lua/HScript 模组（codename 链路的 hscript Config 已用 6.x 新路径，理论兼容）

### Phase 6 — 收尾
- [ ] hmm.json flixel ref 切 `NF-Flixel-6.2.1`；CI 全平台绿
- [ ] 更新本文档状态 + 记忆；评估哪些 fork 补丁值得发上游 PR（参考 NF 回放改键先例）

## 6. 已知坑（接手前必读）

1. **`--macro include('pkg')` 会吞错**：include 的 try/catch 把类型错误的模块静默跳过——用 include 扩 typecheck 覆盖面时，"零报错"可能是假象。codename 的 3 处 switchTo 就是这么漏掉的。对账必须同时跑基线 hxml diff 错误集。
2. **不能 force-include 的库**：flxanimate（2 个坏模块：JsonParser 包声明错、BaseEase.hx interface 里写 static 方法没分号）、modcharts（codename 适配器引用不存在的 `funkin.backend.system.Conductor`）、haxeui（宏模块在 include 上下文解析失败）。它们的覆盖只能靠可达性。
3. **隔离库 `.current` 必须点分格式**：写 `6.2.1` 有效，写 `6,2,1` 报 `Invalid parameter`（目录名才用逗号）。
4. **haxelib 全局指针不能动**：一律 `HAXELIB_PATH=F:/nf-haxelib-62 haxelib run lime ...` 前缀注入。
5. **changelog 会骗人**：以 `lime display windows` + `haxe --no-output` 实测为准。
6. **NF debug 构建本来就坏**（hxvlc+hxcpp fork 冲突），一切验证用 release。
7. 验收由用户本人进行；不要自动跑游戏。

## 7. 工件索引

| 路径 | 内容 |
|---|---|
| `F:\nf-haxelib-62\` | 隔离 haxelib 仓库：52 个库 junction + flixel→6,2,1。复用于 Phase 1-5 全程 |
| `F:\nf-flixel-feasibility-tmp\flixel-5.9.0\` | pristine 5.9.0 对账树（GitHub tag zip 解包） |
| `F:\nf-flixel-feasibility-tmp\conflict-matrix.tsv` | 68 文件冲突矩阵 |
| `F:\nf-flixel-feasibility-tmp\build-62-full7.hxml` / `build-59-full7.hxml` | 目标/基线成对 hxml（全量 include 版，已排除 3 个坏库） |
| `F:\nf-flixel-feasibility-tmp\typecheck-62-full7.log` / `typecheck-59-full7.log` | 21 错误 / 0 错误 的对账证据 |
| `F:\nf-flixel-feasibility-tmp\shim\` | 4 个 fork 新增类副本（IFlxGroupable/FlxLayer/FlxTypes/FlxSoundData） |
| `F:\nf-feasibility-scripts\build-haxelib-62.ps1` | 隔离库重建脚本（工件丢失时用它） |
| fork 源 | `D:\HaxeToolkit\haxe\lib\flixel\git`（5.9.0 fork checkout，branch NF-Flixel-5.9.0，勿动）与 `D:\HaxeToolkit\haxe\lib\flixel\6,2,1`（pristine 6.2.1） |

## 8. 探查方法复刻（如果工件全丢）

```bash
# 1. 隔离库（PowerShell 脚本见 F:\nf-feasibility-scripts）
# 2. 成对生成 hxml：
HAXELIB_PATH=F:/nf-haxelib-62   haxelib run lime display windows > build-62.hxml
HAXELIB_PATH=D:/HaxeToolkit/haxe/lib haxelib run lime display windows > build-59.hxml
# 3. 成对类型检查（后台跑，5-10 分钟/次）：
haxe build-62.hxml --no-output > 62.log 2>&1
haxe build-59.hxml --no-output > 59.log 2>&1
# 4. diff 两份错误集 = 升级增量
# 5. fork delta 对账：下载 pristine 5.9.0 zip，diff -qr --strip-trailing-cr 对 fork checkout（注意 autocrlf 假差异）
```
