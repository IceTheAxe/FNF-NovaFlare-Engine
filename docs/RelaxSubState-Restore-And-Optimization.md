# RelaxSubState 恢复与性能审计

> 对象：`source/substates/RelaxSubState.hx` + `source/general/objects/state/relaxState/**` + `source/general/objects/AudioCircleDisplay.hx`  
> 背景：原作者在 `9a505a73`（2026-02-09「删除relax」）把整套功能删掉，理由是性能差、难维护。本文记录恢复过程与可优化点。

---

## 一、即

| 项目                                | 状态                                                  |
| --------------------------------- | --------------------------------------------------- |
| 圆形频谱（`AudioCircleDisplay`）        | 已恢复，按 `ClientPrefs.data.theme` 切换 Circle / Straight |
| 旋转唱片（`recordPicture` + `camPic`）  | 已恢复，含 300px 圆形遮罩与 `enableRecordRotation`            |
| 圆形遮罩（`circleMask` / `updateMask`） | 已恢复，并修复切回直条主题后遮罩不撤销的问题                              |
| 虚拟按键相机（`camVpad`）                 | 已恢复，`rock` 锁定按钮重新生效（`camVpad.alpha`）                |
| 切歌过渡（唱片旋出 + 频谱淡出）                 | 已恢复                                                 |
| 选项面板实时重建                          | 已恢复，且主题/对称/条数/画质变化都能触发重建                            |
| 类型检查                              | `haxe --no-output` 全项目通过                            |

**为什么之前"只剩个顶栏"**：砍掉的那 176 行里，`createNewElements()` 被换成无条件创建直条频谱，`actualRecordImage` 算完就丢，`theme` 字段全库无人读取。而 `ClientPrefs.theme` 默认值恰恰是 `"Circle"`、`enableRecordRotation` 默认 `true` —— 配置说要圆环，代码只会画直条，唱片压根没建。加上 `backButtons` 从 `camVpad` 挪到 `camHUD`，锁定键变成空操作。所以观感上只剩顶部那条梯形栏是"活"的。

---

## 二、性能审计（按预期收益排序）

### P0-1 · 三轨音频全部整段解码

`loadSongs()` 里：

```haxe
Sound1.loadEmbedded(Paths.returnSound(songInfo.sound[1], ...), false, true);
Sound2.loadEmbedded(Paths.returnSound(songInfo.sound[2], ...), false, true);
```

`loadEmbedded` 走的是整段解码（`FlxSound.loadHelper(asset, true)` + `resolveSound`），而 Flixel 6.2 已经提供 `loadStreamed()`（原生平台 + OGG 分块流式）。当前一首歌同时在内存里摊着 Inst + 两条 Voices 的完整 PCM。

- 影响：单曲峰值内存可达数十 MB 级；切歌时集中解码，正是"切歌卡一下"的来源。
- 建议：`#if FLX_STREAM_SOUND` 下把两条人声轨换成 `Sound1.loadStreamed(path)`。
- **注意**：流式启动有几十毫秒延迟，可能和 Inst 轨错位。若采用，需要在 `loadSongs` 里对齐 `Sound1.time = FlxG.sound.music.time`，或干脆保留嵌入解码、只把 Voices 做成可选开关。

### P0-2 · 环形频谱是 120 个独立 FlxSprite —— 已修

`AudioCircleDisplay` 原本构造 `line * Number` 个 `Rect`（`line = 120 / Number`，乘积恒为 **120**），每个都是独立 `FlxSprite`：每帧 120 次 draw call，且 120 个对象各跑一遍 `update()`。

现在整个类重写成 `FlxSprite` 子类：

- 全部谱条写进同一份顶点/索引缓冲，`draw()` 里一次 `camera.drawTriangles()` 画完
- 索引与 uv 只建一次，顶点每帧原地覆盖（每根 8 个 float × 120），**零临时分配**
- 几何直接算方向角 `φ = i*360/barCount + 1 - 90`（与旧实现的 `angle - 90` 完全等价），省掉每根条的矩阵旋转
- 贴图用共享的 4×4 纯白 `FlxG.bitmap.create(..., 'relaxSpectrumBarTexture')`，uv 全取纹理中心；颜色与 alpha 走 `colorTransform`（`FlxDrawTrianglesItem` 会把 `alphaMultiplier` 展开成逐顶点 alphas，所以切歌淡入淡出照旧生效）
- 顺手修掉一个隐性 bug：`clearUpdate()` 原本把 120 根条统一写成 `y = 组.y - len/2`，也就是**每次切歌重绑分析器时整圈频谱塌到屏幕中线**；现在只重置长度
- 删掉死代码：`FluentMode` / `rate` / `rateNum` / `stepSize` 分支（全库无人设置）、`addAnalyzer`（无人调用）

### P0-3 · 粒子发射器常驻约 576MB，且从第一帧就熄火 —— 已修

`HollowTriangleEmitter` 比预想的严重：

1. **发射率自乘**：`emissionRate = emissionRate * externalSpeedFactor / 50`。进 Relax 时 `amplitude` 被 `clearUpdate()` 清零，第一帧就把 `emissionRate` 乘成 0，而 0 乘任何数永远是 0 —— **之后再也发不出粒子**。就算振幅正常，0.3 也只能算出 0.006 颗/秒。
2. **出屏判定用错高度**：`y + height < 0` 里的 `height` 是那张 1200×1200 位图的高度，粒子速度只有 5~10px/s，一颗要飘 2~6 分钟才死。
3. **池子无上限**：池满了 `getAvailableTriangle()` 会直接新建，而每颗都是 `makeGraphic(1200, 1200)` = 5.76MB —— 常驻 100 颗就是约 **576MB**，且会越听越多。
4. 每次 spawn 还要 `fillRect` + `drawPolygon` 重画整张 1200²。

现在：粒子退化成纯数据（坐标/尺寸/速度），**0 位图 + 1 次 drawTriangles**；发射率 = 3 颗/秒 × `(0.4 + 1.6×振幅)`，不再自乘；出屏按三角形自身尺寸判；池子固定 100，满了回收最老的一颗；暂停时不发射。视觉保持原实现意图（`drawPolygon` 的 FillColor 就是 `BLACK`，即实心黑三角，"Hollow" 是遗留命名）。

> 注：`FlxSprite` 上 `makeGraphic` 之后 `origin` 是**中心**。用 1×1 精灵靠 `scale` 撑成矩形时必须先 `origin.set(0, 0)`，否则会被"中心缩放"顶偏半个身位。新的磁贴与粒子都踩过这个点。

### P1-1 · 8 个相机叠着渲染

`camBack / camHollow / camMidd / camPic / camText / camHUD / camOption / camVpad` 全部 `FlxG.cameras.add(..., false)`，每帧场景图要按相机遍历 8 次；其中 `camPic` / `camText` 还挂了 `flashSprite.mask`，在原生端会走 stencil 路径。

- 建议：`camVpad` 只为锁定按钮存在，完全可以并进 `camHUD`（用 `alpha` 控制可见性）；`camMidd`（频谱）与 `camHollow`（粒子）图层顺序固定，也可合并。至少能把 8 → 5。

### P1-2 · 环形频谱每个采样周期重建 Bar 数组（已修）

原代码 `analyzer.getLevels()` 没有传复用数组，而 `SpectralAnalyzer.getLevels(?levels)` 是支持复用的。`audioDisplayUpdate = 50` → 20Hz，每次新建约 120 个 `Bar` 对象，等于每秒 2400 个临时对象。

- 已改为 `analyzer.getLevels(getValues)`，和 `AudioDisplay` 保持一致。

### P1-3 · 环形频谱缺少分析器重绑（已修）

`AudioDisplay` 有一整套 `refreshAnalyzerBinding()` / `invalidateAnalyzerBinding()`，注释写得很清楚：`FlxG.sound.playMusic` 换歌会销毁旧 `SoundChannel`，分析器不能继续持有已释放的 `AudioSource`。**环形版完全没这层逻辑** —— 构造函数里抓一次 `snd._channel.__audioSource` 就再也不更新。

- 后果：切歌后环形频谱要么冻住，要么在 `getLevels` 里踩到已释放的 buffer。
- 已补齐同样的重绑逻辑（`lime.media.AudioSource`），并让 `inRelax` 生效于 `RelaxAudioDisplayQuality` 档位。

### P1-4 · 歌词时间戳每帧重建 + 排序（已修）

`update()` 里原来每帧：

```haxe
sortedTimestamps = [for (time in LyricsMap.keys()) time];
sortedTimestamps.sort((a, b) -> a - b);
```

60fps 下等于每秒重建 60 次数组 + 60 次排序，纯 GC 压力。

- 已改为切歌时 `rebuildLyricTimes()` 排一次，`update()` 里只做二分查找。

### P2-1 · 遮罩每帧重画矢量（已修）

`updateMask()` 原本每帧 `graphics.clear()` + `beginFill` + `drawCircle` + `endFill`。舞台尺寸不变时这是纯浪费，而且会让 `flashSprite.mask` 每帧失效重建。

- 已加 `maskW / maskH / maskApplied` 缓存，只在窗口尺寸变化时重画。

### P2-2 · 每帧重复取鼠标、重复算文本位置（已修）

- `FlxG.mouse.getScreenPosition(camHUD)` 一帧被调 3 次，现统一成 1 次复用。
- `songInfoDisplay.updateSongLengthPosition(...)` 一帧被调 2 次（完全相同的参数），已删掉重复那处。

### P2-3 · 音频资源缓存只增不减

`Paths.returnSound()` 会 `Cache.currentTrackedSounds.set(file, sound)`，`RelaxSubState` 全程没有清理。播完整个歌单，6 首 × 3 轨的 `Sound` 对象一直挂着。

- 建议：切歌后对上一首的三个路径调用 `Cache.clearStoredMemory()` 的定向版本，或至少 `Cache.currentTrackedSounds.remove(path)`。需要先确认 `Cache` 有对外接口，否则改成在 `Paths.returnSound` 里加容量上限。

---

## 三、维护性问题

1. **`inspectFile` 的路径判断和 `Paths.image` 不一致**（已修）：检查写的是 `assets/shared/<path>.png`，而 `Paths.image` 实际读 `assets/shared/images/<path>.png`。放在 `images/` 下的图会被判成"文件不存在"直接中止加载；放在旧位置的图则能过检查但加载返回 `null`，再喂给 `loadGraphic` 会崩。现在两处都兼容，且 `Paths.image` 返回 null 时跳过创建而不是硬塞。
2. **硬编码 `assets/shared/`**：`inspectFile` 直接用相对路径 `FileSystem.exists('assets/shared/...')`，其余代码走 `Paths.modFolders()`。Android 上 `Sys.getCwd()` 不同，这套判断会失效。建议统一改用 `Paths.modFolders()`。
3. **单类 950 行**：相机、音频、过渡、歌词、选项、输入全在一个类里。至少可以把"切歌过渡"和"歌词"抽成独立类——原版正是因为两处 `createSpectrum` 逻辑重复（主流程一份、`updateOptions` 一份），改一处漏一处。本次已收敛为 `createSpectrum()` / `destroySpectrum()` / `currentSpectrumSymmetry()` 三个方法。
4. **布局硬编码**（已修）：原来 `OptionWindow` 按 1280×720 写死坐标。现在设置是 `win8.Panel` 浮出层，宽度按 `panelWidthRatio` 与窗口宽算，行/控件宽都由面板宽推导；歌单窗的磁贴列数也按可视宽度现算。
5. **死配置**：`ClientPrefs.songInfo` 仍然全库无人读取（`theme` / `enableRecordRotation` 现在有用了，`NextSongs` 一直是好的）。
6. **`var mousePos` 曾在同一作用域声明两次**：Haxe 允许遮蔽，不报错，但前一次的值白算——属于典型的"能跑但没意义"的代码。
7. **`FlxSpriteGroup` 的两个坑**（新代码都踩过）：
   - `preAdd` 会把本组 x/y 加进成员坐标，所以子元素必须用**局部**坐标建；`add()` 之后再按绝对坐标摆才会对，两套混用就会偏移一倍。
   - `set_cameras` 会向下递归到整棵子树，但 `preAdd` 在 add 时会把本组 `_cameras`（可能是 null）写给成员 —— 所以"先 add 再设相机"，否则会被覆盖回 null。

---

## 四、本次已落地的改动

| 文件 | 改动 |
| --- | --- |
| `source/substates/RelaxSubState.hx` | 恢复 `camPic`/`camVpad`/`recordPicture`/`circleMask`；主题分支；唱片旋转；遮罩缓存与撤销；频谱创建/销毁收敛；歌词二分；鼠标与文本位置去重；`Paths.image` 空值防护；`inspectFile` 路径兼容；进度条上移；`persistentDraw` / `persistentUpdate` 放行 substate；设置与歌单开合路径改造 |
| `source/general/objects/AudioCircleDisplay.hx` | 整体重写为单次 `drawTriangles`（详见 P0-2） |
| `source/general/objects/state/relaxState/backend/HollowTriangleEmitter.hx` | 整体重写：纯数据粒子 + 单次 `drawTriangles`，修发射率自乘与池子无上限（详见 P0-3） |
| `source/general/objects/state/relaxState/SongProgress.hx` | 重写：上移到按钮块上方、屏幕坐标命中 + 上下各 10px 可抓区、裁源帧代替 scale+updateHitbox、去掉与中键重复的时长文本 |
| `source/general/objects/state/relaxState/windows/RelaxOptionPanel.hx` | 新增：`win8.Panel` 子类，8 项设置改用开关 / 轨道滑块 / 下拉，值经闭包直连 `ClientPrefs`，默认值取 `ClientPrefs.defaultData` |
| `source/general/objects/state/relaxState/windows/TileGridView.hx` | 新增：Metro 磁贴网格（2×2 大磁贴占位、纵向滚动、stagger 入场、变形、命中/三态视觉） |
| `source/general/objects/state/relaxState/windows/PlayListWindow.hx` | 重写：左侧滑入磁贴墙 + 两级导航 + 面包屑 + 返回箭头 |
| `source/general/objects/state/relaxState/windows/TileEntry.hx` | 新增：磁贴数据 typedef |
| **已删除** | `windows/OptionWindow.hx`、`OptionButton.hx`、`optionType/{Array,Bool,Float,Int}Type.hx` + `import.hx`、`windows/{LeftList,RightList,ListButtons}.hx` |
| `assets/shared/language/{Chinese,English}/relax/relax.lang` | 补 13 条：面板标题/分组标题/8 条说明/歌单窗文案 |
| `assets/shared/playlists/demo/List.json` | 官方曲目演示歌单（6 首） |
| `assets/shared/images/playlists/demo/art/*.png` | 6 张唱片面（官方角色图标合成） |

---

## 五、建议的下一步（如果要继续压）

1. ~~把 120 条频谱合成单次 `draw()`~~ —— 已完成（P0-2）。
2. ~~粒子对象池~~ —— 已完成（P0-3）。
3. 相机从 8 个并到 5 个以内（`camVpad` 只为锁定按钮存在，可以并进 `camHUD` 用 alpha 控制）。
4. 决定人声轨走流式还是可选关闭（涉及音画同步，需要实测）。
5. 清理 `Cache.currentTrackedSounds`（整张歌单播完，三轨 `Sound` 对象一直挂着）。
6. `Setting` 的枚举值目前仍直接显示英文原值（`Next` / `Circle` …），可考虑加 `val_*` 语言 key。

---

## 六、界面为什么是"两种壳、一套语言"

设置与歌单都改成了 Win8 语汇，但**壳不一样**，这不是随手决定的：

| | 设置面板 | 歌单窗 |
| --- | --- | --- |
| 形态 | `win8.Panel` 子类，即**substate** | 普通 `FlxSpriteGroup`，挂在 Relax 里 |
| 相机 | `camOption`（显式钉死） | `camOption` |
| 位置 | 右侧滑入，占屏宽 34%，整屏高 | 左侧滑入，占屏宽 62%，**从顶栏下方开始**（y = 44） |
| 为什么这么选 | 复用现成的行/滚动/键盘/说明栏，约 900 行不用重写 | 歌单要常驻、随时滑进滑出，做成 substate 会把父状态反复挂起/唤醒 |

substate 那条路有两个必须显式处理的点，改这块的人容易踩：

1. **`RelaxSubState` 要开 `persistentDraw` / `persistentUpdate`**。`FlxState.draw` / `tryUpdate` 在 `subState != null` 且父状态没开这两个标志时，会**连父状态的绘制一起跳过** —— 不开的话一进设置，唱片、频谱、进度条全冻住（不是变暗，是整块不画）。
2. **`Panel.create()` 只在 `_cameras` 为空时才取"最后一台相机"**。Relax 里最后一台是 `camVpad`，而锁定按钮会改 `camVpad.alpha` —— 面板会跟着一起被隐掉。所以 `RelaxOptionPanel` 在构造期就把 `cameras` 钉成 `camOption`。

歌单窗则是有意避开 substate：它常在、开关频繁，做成 substate 每次都要挂起/唤醒父状态，还要多一套 `persistent*` 状态管理。为了不和顶栏抢点击，面板从 y = 44 开始画（顶栏梯形高 40），底部留 100px 给进度条与控制块 —— 于是三个"别的界面"都能同时用。

磁贴那张网格（`TileGridView`）不依赖任何 tween：位置/尺寸/透明度全部"每帧向目标值逼近"（`x += (tx - x) * k`）。好处是滑入滑出、变形、滚动共用一套收敛逻辑，不会漏 tween；代价是没有 `backOut` 那种回弹质感。要做回弹的话，在 `sizeT` 收敛处换成 `FlxEase.backOut` 的解析式即可。
