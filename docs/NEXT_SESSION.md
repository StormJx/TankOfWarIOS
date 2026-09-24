# 新窗口交接提示词（本地验收 → 阶段 8）

用法：新开一个对话，先贴「项目宪法」（`docs/PROMPTS.md` 开头那段），再整段复制下面对应的【本阶段提示词】。`.cursor/rules/tank-battle.mdc` 会自动注入技术栈约束。

权威规格仍是 `docs/GAME_DESIGN.md` 与 `docs/ROADMAP.md`。本文件只描述**当前代码事实**和**下一窗口必须做的事**。

云端 Cursor 环境**不能**把工作区同步到你的 Mac。本地要测，必须自己从 GitHub 拉分支，不要等云端推文件过来。

---

## 项目现状（到 2026-09-05）

阶段 0–7 已全部落地。试玩反馈 4 条已做完。坦克视觉 P0–P3 已做完（整数倍缩放、重绘精灵、阴影、2 主色 + 道具四态、1px 缩进、履带/抖动/转向插值、炮口闪/受击闪/无敌红蓝闪）。

**未升 24×24。** 16×16 碰撞未改。这不是阶段 8，也不是重做 0–7。

路线图下一正式阶段是 **阶段 8：平衡、性能与真机发布**。在开阶段 8 之前，先在 **本机 Mac + Xcode** 跑单测并肉眼看 P2/P3。

相关 PR：

- 可玩版基线：`master`（`f7e50a8`）
- 视觉 P0+P1：https://github.com/StormJx/TankOfWarIOS/pull/1 （`cursor/tank-visual-polish-fe43`）
- 视觉 P2+P3（含 P0/P1 提交）：https://github.com/StormJx/TankOfWarIOS/pull/2  
  分支 `cursor/tank-visual-p2-p3-a658`，当前 tip `73eb5db`  
  「坦克视觉 P3：炮口闪、受击闪和无敌红蓝交替」

`docs/ROADMAP.md` 底部勾选以本文件与源码为准，不要按旧勾选回退重做 2–7，也不要重做菜单/语言/钢墙/视觉 P0–P3。

---

## 已完成（不要重写）

### 阶段 0–7 + 试玩反馈

| 阶段 | 结果 |
| --- | --- |
| 0 | SwiftUI 生命周期，`GameContainerView` + 两个 `SpriteView`（战场 / 操控） |
| 1 | `GridMap` + `MapRenderer`，13×13，tile 16pt，场景 208×208 |
| 2 | 玩家、摇杆、射击、自研 AABB、打砖 |
| 3 | 3 台敌人、AI、出生闪烁、死亡复活、GAME OVER |
| 4 | 6 种双向道具 + `StatusEffectManager` |
| 5 | 10 关、菜单、结算、存档、暂停、`GameFlow` |
| 6 | 小 Boss 2×2 / 8HP、大 Boss 3×3 / 20HP、多 tile AABB、血条、冲撞碾砖、8 向弹幕 |
| 7 | NES 像素 atlas、WAV、履带/水波/爆炸、BGM、静音、震动、STAGE N、击杀顿帧 |
| 试玩 | 菜单/结算深蓝底、中英文、炮管加粗、第 3 关起连续钢墙；弹速 120、道具 6–12 秒、击杀飘分、模拟器键盘 |

### 坦克视觉 P0–P3（刚做完，不要回退）

**P0**

- 战场边长吸附到 `sceneSide` 整数倍：`GameConfig.integerScaledBattlefieldSide(available:)`
- `trackFrameDuration = 0.06`
- `tank()` 已重画：黑描边、独立炮塔、3px 履带

**P1 配色（必须遵守）**

- 每辆坦克只用 2 个主色 + 黑描边，禁止再加白炮口 / 灰高光 / 第三杂色
- 玩家基础：金 `playerColor` + 橙 `playerShadeColor`
- 普通敌：浅灰 + 深灰；快速敌：青 + 蓝；装甲：按血量绿/黄/灰/红（各态仍两色）；Boss：红 + 暗红
- 火力（星星，`firepower > 0`）：只改炮管 → `playerBarrelPoweredColor` 热红
- 护盾（头盔，`hasShield`）：外壳换成钢蓝 `playerShieldBodyColor` / `playerShieldShadeColor`
- 火力+护盾：钢蓝外壳 + 热红炮管
- 玩家 4 态 × 2 履带帧已在 atlas：`tank_player_{0,1}` / `_fire_` / `_shield_` / `_fire_shield_`
- `SpriteProvider.playerFrames(firepower:shielded:)` + `PlayerTank.refreshAppearance()`
- `Tank.replaceTrackFrames` 换装时若正在履带动画会先停再重启
- `Tank.attachGroundShadow()` 脚下椭圆软阴影，不进碰撞盒

**P2**

- 碰撞盒继续 16×16；缩进画在 `tank()` / `TankPlaceholderTextures` 像素里，节点 `size` 仍是 `tileNodeSize`
- `muzzlePoint` 仍从碰撞边打出
- 履带 2px 横带整带换相；移动时视觉子节点 `visualNode` 轻抖 ±0.5px / 0.1s
- 转向 `zRotation` 用约 0.05s `SKAction` 插值；`commandedDirection` / 子弹仍离散四向
- 抖动和转向禁止独立 Timer；暂停随 `SKScene.isPaused` 停
- 走廊吸附 `alignedPosition` 未改

**P3**

- 开火：炮口 1 帧闪光，颜色跟当前炮管（`Tank.muzzleFlashColor`）
- 被击中：车身闪白 2 帧；护盾挡住时钢蓝闪
- 无敌：红蓝交替 + 轻度 alpha；`isInvincible` 时跳过受击闪
- 特效走 `EffectFactory` + `GameConfig.Layer.effect`，复用静态 `SKAction` / `SKTexture`
- **未升 24×24**。Boss 碰撞仍等于视觉占地（2×2 / 3×3），只是外圈多了 1px 透明

### 目录与硬约束（仍有效）

源码根：`war of tank/war of tank/`  
`App/` `Scenes/` `Entities/` `Systems/` `Input/` `UI/` `Data/` `Resources/`

Xcode 16 同步文件夹：文件放进对应目录就自动进 target，**不要改 `project.pbxproj` 加引用**。

- 流程：`GameFlow` / `AppScreen` = menu / playing / levelClear / gameOver / victory
- 切关：离开对局必须 `gameScene = nil`；`playGeneration` 强制换新 `GameScene`
- 结算画面必须 one-shot，否则会连跳两关
- 暂停恢复必须 `prepareForResume()` 把 `lastUpdateTime = 0`
- 操控是独立 `ControlScene` + 下方第二个 `SpriteView`，共享 `ControlInput`
- 子弹速度字段必须叫 `moveSpeed`，不能叫 `speed`
- 有时限状态只走 `StatusEffectManager`
- 主循环 BFS 每帧最多 1 次，路径缓存 0.5 秒
- 坐标互转只走 `GridMap.center(of:)` / `GridMap.gridPoint(at:)`
- 禁止 `physicsBody` 驱动坦克或子弹
- 数值只放 `Data/GameConfig.swift`，`zPosition` 用 `GameConfig.Layer`
- 贴图 `filteringMode = .nearest`
- 换图：改 `scripts/generate_presentation_assets.py` 后用 `--skip-audio` 重跑，或直接换 atlas 同名文件。不要无故重写 WAV
- 存档：`maxUnlockedLevel`、`highScore`、`isMuted`、`appLanguage`
- 文案：`L10n`，默认中文
- 调试：`debugShowStats = false`，`debugStartingFirepower = 0`，`debugTerrainShowcase = false`

### 地形规则（已实现，不要推翻）

| 字符 | 含义 | 子弹 |
| --- | --- | --- |
| `.` | 空地 | 穿过 |
| `B` | 砖墙 | 销毁子弹并破坏砖 |
| `S` | 钢墙 | 销毁子弹；**仅火力 Lv3 可摧毁** |
| `W` | 河 | 穿过 |
| `G` | 草 | 穿过（画在坦克上） |
| `I` | 冰 | 穿过 |
| `E` | 基地，固定 `(6,12)` | 击中即败 |
| `P` / `1` `2` `3` | 出生点 | 当空地 |

第 1、2 关没有钢墙。钢墙从第 3 关引入。

### 已知坑

- iOS 16 用单参数 `onChange`
- `BossTests` 用 `@Suite(.serialized)`，并行创建 `SKSpriteNode` 曾导致进程崩溃
- 单测：见下方命令；模块名 `war_of_tank`
- 云端是 Linux，没有 Xcode，P2/P3 **没有在云端跑过 `xcodebuild`**
- 不引入第三方依赖、`SKTileMapNode`、GameplayKit 寻路

---

## 后续待完成

按顺序，不要跳。

| 顺序 | 事项 | 谁做 | 状态 |
| --- | --- | --- | --- |
| A | 本机 `git fetch` 拉 `cursor/tank-visual-p2-p3-a658`，跑单测 | 你 / 本地 Cursor | **下一步** |
| B | 模拟器或真机肉眼验 P2/P3（缩进、履带、转向、炮口闪、受击闪、四态换色） | 你 | 等 A |
| C | 若 16×16 仍嫌糊：再开 24×24（碰撞仍 16×16；Boss 不要视觉大于碰撞；四态一起升） | 下一窗口 | 可选，先看 B |
| D | 阶段 8：通关 3 次记死亡，只调 `GameConfig`；后台暂停；Instruments；关调试开关 | 下一窗口 | 正式下一阶段 |
| E | 炮口闪改成 atlas 像素、受击闪挂到 `visualNode` 上跟着抖 | 更后 | 低优先级 |

不要现在做：重做 0–7、改 `CollisionSystem`、改关卡/AI/弹速/刷怪、为好看改碰撞盒。

---

## 本机拉代码（云端不同步到本地）

在 Mac 仓库根目录：

```bash
git fetch origin cursor/tank-visual-p2-p3-a658
git checkout cursor/tank-visual-p2-p3-a658
git log -1 --oneline
# 期望：73eb5db 坦克视觉 P3：炮口闪、受击闪和无敌红蓝交替
```

工程目录是 `war of tank/`。单测必须在这个目录里跑，或把 `-project` 写成带空格的路径：

```bash
cd "war of tank"
xcodebuild test -project "war of tank.xcodeproj" -scheme "war of tank" \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  -only-testing:"war of tankTests"
```

没有 iPhone 16 Pro 模拟器时，改成本机已有的 iPhone 模拟器名字（`xcrun simctl list devices available`）。

---

## 提示词 A — 本地验收（先贴这段；不要开阶段 8，不要改代码除非测试红或肉眼有 bug）

```
【当前状态】
阶段 0–7 和试玩反馈 4 条已完成。坦克视觉 P0–P3 已在 GitHub 分支 cursor/tank-visual-p2-p3-a658（PR #2，tip 73eb5db）落地。云端 Linux 没有 Xcode，单测和肉眼效果都还没在本机跑过。权威规格仍是 docs/GAME_DESIGN.md 与 docs/ROADMAP.md。技术栈约束见 .cursor/rules/tank-battle.mdc。完整事实在 docs/NEXT_SESSION.md。

【本阶段目标】
只做本机验收，不要开始阶段 8，不要重做 0–7，不要改玩法数值 / 关卡 / AI / 碰撞。

1) 确认在分支 cursor/tank-visual-p2-p3-a658，HEAD 是 73eb5db。不是的话先：
   git fetch origin cursor/tank-visual-p2-p3-a658
   git checkout cursor/tank-visual-p2-p3-a658
2) 跑单测（工程在 war of tank/ 目录）：
   xcodebuild test -project "war of tank.xcodeproj" -scheme "war of tank" \
     -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
     -only-testing:"war of tankTests"
   没有 16 Pro 就换本机已有的 iPhone 模拟器。
3) 重点看这些测试还绿：firepower / hasShield 换装、转向吸附、碰撞裁剪、PresentationTests 里的缩进常量和炮口/受击闪。
4) Cmd+R 玩一关，按下面清单肉眼看，把结果记给我（通过 / 失败 / 没看）。不要先改代码。

肉眼清单：
- 坦克和砖墙/钢墙之间有 1px 级透气，走廊吸附还在，不会穿墙
- 移动时履带条纹一眼能看出在滚；车身有极轻上下抖；停下立刻停动画、停抖动
- 转向有短插值，子弹仍四向，不会斜着飞
- 暂停后抖动/转向插值不会自己走完
- 开火有炮口闪，闪完不留节点；基础橙 / 吃星星后热红
- 挨打闪白；头盔挡住时钢蓝闪；无敌红蓝闪，不要和受击闪叠成乱闪
- 吃星星：炮管热红；戴头盔：外壳钢蓝；过期或死亡 resetPowerUps 后恢复
- 整数倍缩放仍在，战场不发糊；阴影还在，不进碰撞盒
- 玩家 4 态贴图都对（基础 / 火力 / 护盾 / 火力+护盾）

【硬性约束】
- 测试绿且肉眼没问题：不要改代码，把结果列表发我
- 测试红或肉眼有明确回归：先写根因判断和验证方式，我确认后再改；只修视觉/测试，不动 CollisionSystem 和数值
- 不要升 24×24，除非肉眼确认 16×16 仍然发糊并且我明确说做
- 不要改关卡、AI、弹速、刷怪、平衡
- 不要重做菜单底色 / 语言 / 钢墙 / 阴影 / 现有 4 态换色
- 重跑生成脚本必须带 --skip-audio

【验收标准】
- 单测全绿
- 上面肉眼清单逐条有结论
- 没有为了「再优化一点」擅自开阶段 8 或 24×24
```

---

## 提示词 B — 阶段 8（等 A 通过、并有通关死亡数据后再贴）

```
【当前状态】
阶段 0-7、试玩反馈、坦克视觉 P0–P3 已完成，本机单测和肉眼验收已通过。游戏功能与表现都完整。现在需要调难度、修性能、做发布准备。不要回退视觉 P0–P3。

【本阶段目标】
把游戏调到「能递给别人玩」的完成度。

工作内容：
1. 难度平衡：我会完整通关 3 次并记录每关死亡次数给你，你据此调整 Data/GameConfig.swift 里的数值。目标曲线是：1-2 关几乎不死，3-5 关每关死 0-1 次，6-9 关每关死 1-2 次，第 10 关死 2-4 次后通关。只调 GameConfig，不改逻辑
2. 性能：用 Instruments 的 Time Profiler 和 Allocations 找热点；检查长时间挂机后节点数是否稳定；确认没有 retain cycle（尤其是 SKAction 闭包里的 self、AIController 对 GameScene 的强引用）
3. 生命周期：处理 App 进入后台自动暂停、切回时保持暂停而不是直接继续；来电中断后音频能恢复；低电量模式下的表现
4. 收尾：检查所有 TODO、去掉调试开关默认值、debugShowGrid 关掉、去掉遗留的 print

【硬性约束】
- 平衡调整只允许改 GameConfig 里的数值，不允许改逻辑代码
- 不引入任何第三方分析或崩溃上报 SDK
- 不做内购、不做广告、不做联网
- 不要重做视觉 P0–P3，不要改 CollisionSystem

【验收标准】
- 无崩溃、无内存泄漏、连续玩 30 分钟不掉帧
- 死亡次数曲线符合目标
- 从后台切回保持暂停状态
- 找一个没玩过的人试玩，不用解释就知道怎么操作，且能自己打过第 1 关
```
