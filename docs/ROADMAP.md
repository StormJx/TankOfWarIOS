# 开发路线图

9 个阶段，每个阶段结束时项目必须能在真机上编译运行、且是「可玩」状态，不安排纯重构或纯搭架子的阶段。每阶段做完先在手机上玩 5 分钟，确认验收清单全绿再进下一阶段。

预估工期以「每天投入 2-3 小时」为基准，仅供排期参考。

| 阶段 | 内容 | 预估 |
| --- | --- | --- |
| 0 | 环境与工程骨架 | 0.5 天 |
| 1 | 网格地图与渲染 | 1 天 |
| 2 | 玩家坦克与操控 | 2 天 |
| 3 | 敌方坦克与 AI | 2-3 天 |
| 4 | 道具系统 | 1-2 天 |
| 5 | 关卡流程与 10 关数据 | 2 天 |
| 6 | Boss 战 | 2-3 天 |
| 7 | 美术与音效润色 | 2 天 |
| 8 | 平衡、性能与真机发布 | 1-2 天 |

---

## 阶段 0 — 环境与工程骨架

**目标**：Xcode 工程能编译，真机上竖屏显示一个黑色战场区域和一个 16x16 的黄色像素方块。

### 0.1 在 Xcode 中创建工程（需要你手动操作）

AI 不适合直接生成 `.xcodeproj`（pbxproj 格式极易损坏），这一步必须在 GUI 里完成：

1. Xcode → `File` → `New` → `Project`
2. 选 `iOS` → `App`（**不要**选 Game 模板，它会生成一堆用不上的 `.sks` 文件）
3. 填写：
   - Product Name: `war of tank`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Storage: `None`，测试选项都不勾
4. 保存位置选到本仓库根目录 `war of tank/`，**取消勾选** "Create Git repository"（仓库已存在）
5. 选中 TARGETS → `war of tank` → `General` → `Minimum Deployments` 设为 `iOS 16.0`
6. 同一页 `Deployment Info` → Device Orientation 只保留 `Portrait`，取消 Landscape Left / Right / Upside Down

> **实际执行情况（2026-08-01）**：工程当初误用了 Game 模板创建，产出的是 UIKit 生命周期
> （`AppDelegate` + `Main.storyboard` + `GameScene.sks` + `Actions.sks`），最低版本 18.2，
> 横竖屏都开着。因为签名与 bundle id（`JiXiang.war-of-tank`）已经配好，选择原地转换而不是重建，
> 转换动作见下面的 0.4。上面的步骤 1-6 保留作为将来重建工程时的参照。

### 0.2 免费签名 + 真机调试

1. Xcode → `Settings` → `Accounts` → `+` → 添加你的 Apple ID（个人账号即可，无需 99 美元）
2. TARGETS → `Signing & Capabilities`：
   - 勾选 `Automatically manage signing`
   - Team 选你的 `(Personal Team)`
   - Bundle Identifier 改成全球唯一的，例如 `com.jixiang.tankbattle`
3. iPhone 用数据线连上 Mac，手机上点「信任此电脑」
4. iPhone → `设置` → `隐私与安全性` → 拉到底 → 打开 `开发者模式`，重启手机
5. Xcode 顶部设备选择器选中你的 iPhone，`Cmd + R` 运行
6. 首次运行会报「不受信任的开发者」：iPhone → `设置` → `通用` → `VPN 与设备管理` → 点开发者 App → `信任`

免费签名的证书 **7 天过期**，过期后重新 `Cmd + R` 覆盖安装即可，进度不丢（存在 `UserDefaults` 里）。

### 0.3 代码产出

以下路径都相对于 target 源码目录 `war of tank/war of tank/`。

- `App/WarOfTankApp.swift` — SwiftUI `@main`，`WindowGroup` 里放根视图
- `App/GameContainerView.swift` — 用 `GeometryReader` 计算战场缩放，`SpriteView(scene:)` 承载场景，上方 HUD 占位、下方控制区占位
- `Scenes/GameScene.swift` — `SKScene` 子类，`size = CGSize(width: 208, height: 208)`，`scaleMode = .aspectFit`，`anchorPoint = .zero`，背景黑色，中心放一个黄色 `SKSpriteNode`
- `Data/GameConfig.swift` — 常量集中地，先放 `tileSize = 16`、`gridCount = 13`、`playerSpeed = 48`

### 0.4 Game 模板 → SwiftUI 生命周期的原地转换（已完成）

在 Xcode 里删掉 6 个模板文件：`AppDelegate.swift`、`GameViewController.swift`、
`GameScene.swift`（模板那个，在 target 根目录）、`GameScene.sks`、`Actions.sks`、
`Base.lproj/Main.storyboard`。`LaunchScreen.storyboard` 与 `Assets.xcassets` 保留。

配套改的 build settings（`project.pbxproj`）：

| 设置 | 改前 | 改后 | 原因 |
| --- | --- | --- | --- |
| `INFOPLIST_KEY_UIMainStoryboardFile` | `Main` | 删除 | storyboard 已删，留着会启动即闪退 |
| `IPHONEOS_DEPLOYMENT_TARGET` | `18.2` | `16.0` | 规格要求 iOS 16+ |
| `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone` | 竖屏 + 横屏左右 | 仅 `UIInterfaceOrientationPortrait` | 竖屏锁定 |
| `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad` | 四方向 | 删除 | 不再支持 iPad |
| `TARGETED_DEVICE_FAMILY` | `1,2` | `1` | iPad 会要求支持全部四方向，与竖屏锁定冲突 |

签名相关的 `DEVELOPMENT_TEAM`、`CODE_SIGN_STYLE`、`PRODUCT_BUNDLE_IDENTIFIER` 一律没动。

### 0.5 关于新增源文件（重要，影响后续所有阶段）

本工程是 `objectVersion = 77`，用的是 Xcode 16 的 **同步文件夹**
（`PBXFileSystemSynchronizedRootGroup`）：`war of tank/war of tank/` 目录下的文件由 Xcode 自动
纳入 target，**不需要 `File > Add Files`**，`project.pbxproj` 里也不会出现单个文件的引用。

所以后续阶段新建源文件只要放进对应目录就会被编译，删文件也只要从磁盘删掉。如果 Xcode 正开着而没有
立刻看到新文件，退出重开一次即可。

### 验收清单

- 真机竖屏运行，战场是正方形且没有被拉伸
- 黄色方块边缘锐利无模糊（`filteringMode = .nearest` 生效）
- 旋转手机画面不跟着转
- 在 iPhone SE 尺寸的模拟器上，战场和控制区都完整可见不被裁切

---

## 阶段 1 — 网格地图与渲染

**目标**：读入字符地图并渲染出 6 种地形，肉眼能看出一张完整关卡。

### 代码产出

- `Systems/GridMap.swift` — 核心数据结构
  - `enum TileType { empty, brick, steel, water, grass, ice, base }`
  - `struct GridPoint { let col: Int; let row: Int }`
  - `init(rows: [String])` 解析字符地图，同时抽出 `playerSpawn`、`enemySpawns: [GridPoint]`、`basePosition`
  - `func center(of: GridPoint) -> CGPoint` / `func gridPoint(at: CGPoint) -> GridPoint`（唯一的坐标转换入口）
  - `func blocksTank(at:) -> Bool` / `func blocksBullet(at:) -> Bool`
  - `func destroyTile(at:) -> Bool` 返回是否真的被摧毁
- `Systems/MapRenderer.swift` — 把 `GridMap` 渲染成节点；草丛加进独立的 `grassLayer`（`zPosition` 高于坦克），其余进 `terrainLayer`
- `Data/Levels.swift` — 先只放第 1 关的字符地图
- `Data/TileTextures.swift` — 用 `SKTexture` 由代码生成的占位纯色贴图，带缓存避免重复生成

### 验收清单

- 第 1 关地图正确渲染，砖墙/钢墙/河流/草丛/冰面/基地颜色可区分
- 草丛能遮住放在它下面的测试方块
- `GameConfig.debugShowGrid = true` 时叠加显示 13x13 网格线和行列号
- 单元测试或临时断言验证 `gridPoint(at: center(of: p)) == p` 对全部 169 个 tile 成立

---

## 阶段 2 — 玩家坦克与操控

**目标**：能用摇杆开着坦克在地图里跑，开火打碎砖墙，撞墙不抖不穿透。

### 代码产出

- `Entities/Tank.swift` — 坦克基类：`direction`、`speed`、`hp`、`isFrozen`、`isStunned`、`move(dt:)`、`fire()`
- `Entities/PlayerTank.swift` — 火力等级 `firepower: Int`、护盾状态、`resetPowerUps()`（死亡时调用，火力归 0）
- `Entities/Bullet.swift` — 方向、速度、能否破钢墙、所属阵营 `owner: Faction`
- `Systems/CollisionSystem.swift`
  - `func resolveTankMove(tank:desired:) -> CGPoint` 与地形 + 其他坦克做 AABB 裁剪
  - `func bulletHitTest(bullet:) -> HitResult` 依次检测：出界 / 地形 / 坦克 / 其他子弹
- `Input/VirtualJoystick.swift` — `SKNode` 实现，触摸区域比可视区域大 1.5 倍，输出 4 向枚举
- `Input/FireButton.swift` — 支持点按与长按连发（连发间隔 0.3 秒）
- `GameScene` 补上 `update(_:)` 主循环：读输入 → 移动 → 子弹推进 → 碰撞 → 清理

### 验收清单

- 贴着墙持续推摇杆，坦克静止且不抖动、不闪进墙里
- 在 tile 走廊中转向能顺利进入（8 pt 吸附生效），不会卡在墙角
- 子弹打砖墙：砖墙消失、子弹消失、有爆炸小特效
- 子弹打钢墙：Lv0-2 时子弹消失而钢墙不变，Lv3 时钢墙消失
- 子弹能飞过河流和草丛
- Lv0 时同屏只有 1 发子弹，Lv2 后能同时存在 2 发
- 长按射击键持续连发，节奏均匀

---

## 阶段 3 — 敌方坦克与 AI

**目标**：3 台敌人在场上活动、会追你也会去打基地，双方都能被击杀和重生。

### 代码产出

- `Entities/EnemyTank.swift` — 三种类型的属性表驱动初始化，装甲型受击换色
- `Systems/AIController.swift` — 状态机 + BFS 寻路（结果缓存 0.5 秒，每帧限 1 次寻路）
- `Systems/SpawnSystem.swift` — 出生点 1.5 秒闪烁动画后生成，维持同屏 3 台
- `Systems/EffectFactory.swift` — 爆炸动画、击中火花、复活闪烁、屏幕抖动
- `Scenes/GameScene.swift` — 接入敌我子弹分阵营判定；玩家死亡扣命、3 秒后原地复活并 `resetPowerUps()`

### 验收清单

- 场上稳定维持 3 台敌人，被打掉后出生点闪烁再补充
- 敌人会主动往基地方向走，遇砖墙会停下轰开而不是原地卡住
- 玩家靠近时敌人会转向追击
- 玩家子弹与敌方子弹相撞时双方都消失
- 装甲型需要 4 发才炸，每次受击颜色变化
- 玩家被击中后爆炸、命数 -1、3 秒后复活并有无敌闪烁
- 命数耗尽或基地被击中 → GAME OVER
- 3 台敌人同时寻路时帧率仍稳定在 60（用 Xcode 的 FPS 显示确认）

---

## 阶段 4 — 道具系统

**目标**：道具随机出现，你和敌人抢着吃，效果双向且明显。

### 代码产出

- `Entities/PowerUp.swift` — 6 种类型 + 15 秒生命周期 + 末段闪烁
- `Systems/PowerUpSystem.swift` — 按权重随机、找合法空地、`applyToPlayer()` / `applyToEnemy()` 分派
- `Systems/StatusEffectManager.swift` — 统一管理有时限的状态（护盾、冻结、僵直、铲子加固），带剩余时间倒计时与到期回调
- `AIController` 增加 `seekPowerUp` 状态：道具在 5 tile 内且路径通畅时前往拾取

### 验收清单

- 12-20 秒随机出现一个道具，同屏最多 1 个，15 秒后消失且末 3 秒闪烁
- 玩家吃星星火力升级，子弹表现有可感知变化
- 玩家死亡后火力立刻退回 Lv0，护盾消失（核心机制，必须验证）
- 敌人会主动去吃道具，吃到后有对应的负面效果作用到玩家身上
- 敌人吃头盔后闪烁且 5 秒内打不掉
- 吃铲子后基地围墙变钢墙，15 秒结束前闪烁提示
- 冻结/僵直期间玩家或敌人确实无法移动与开火
- 状态叠加不会互相覆盖出错（例如护盾期间吃到冻结）

---

## 阶段 5 — 关卡流程与 10 关数据

**目标**：从主菜单进入，连续打 10 关，胜负与进度都正确。

### 代码产出

- `Data/Levels.swift` — 补齐 10 关字符地图 + 每关的 `totalEnemies` / `enemyMix` / `bossType`
- `Systems/LevelManager.swift` — 关卡加载、通关判定、失败判定、切关
- `Systems/ScoreManager.swift` — 击杀计分与关卡结算
- `Systems/SaveManager.swift` — `UserDefaults` 存 `maxUnlockedLevel` 与 `highScore`
- `Scenes/MenuScene.swift` — 开始游戏 / 选择关卡（只能选已解锁）/ 最高分展示
- `Scenes/LevelClearScene.swift`、`Scenes/GameOverScene.swift`
- `UI/HUDNode.swift` — 命数、当前关卡、剩余敌人数、火力等级图标
- `UI/PauseOverlay.swift` — 暂停、继续、重开本关、回主菜单

### 验收清单

- 10 关地图都能正常加载，无非法字符、每关都恰好 13x13
- 每关地形符合设计文档描述的主题
- 打完一关有结算画面，2 秒后进入下一关
- 通过第 10 关有通关画面
- 失败后重开本关，火力归 0、命数回 3
- 杀掉进程重进，已解锁关卡和最高分还在
- 暂停时游戏完全静止（包括动画与计时器），恢复后状态正确
- HUD 数字与实际状态实时一致

---

## 阶段 6 — Boss 战

**目标**：第 3/6/9 关有小 Boss，第 10 关大 Boss，有血条、有阶段切换的压迫感。

### 代码产出

- `Entities/BossTank.swift` — 多 tile 尺寸的碰撞盒、`phase` 状态、阶段切换回调
- `Entities/MiniBoss.swift` — 8 HP 两阶段，三向散射，L6/L9 的差异化能力
- `Entities/FinalBoss.swift` — 20 HP 三阶段：散射 / 冲撞（碾碎砖墙 + 撞墙眩晕受 2 倍伤害）/ 狂暴（召唤 + 8 向弹幕）
- `UI/BossHealthBar.swift` — 分段血条，换阶段变色
- `CollisionSystem` 扩展多 tile AABB；`PowerUpSystem` 加 Boss 关手雷权重下调与 Boss 伤害上限

### 验收清单

- 小 Boss 占 2x2、大 Boss 占 3x3，碰撞盒与视觉尺寸一致，不会半身穿墙
- Boss 血条实时准确，换阶段变色 + 屏幕抖动
- 小 Boss 半血后三向散射生效
- 大 Boss 冲撞能碾碎砖墙，撞墙后眩晕期间伤害翻倍
- 大 Boss 阶段 3 会召唤快速型并放 8 向弹幕
- 手雷对 Boss 只造成 3 点伤害，不能一发清掉
- 计时器不能完全冻住小 Boss（只减速）、对大 Boss 完全无效
- Boss 死亡有大爆炸 + 长震动，之后正常结算通关

---

## 阶段 7 — 美术与音效润色

**目标**：从「能玩」变成「像一个游戏」。这一阶段不允许改动任何游戏逻辑。

### 工作内容

- 用 texture atlas 替换全部代码生成的占位贴图，接口保持 `TileTextures` / `SpriteProvider` 不变
- 坦克履带 2 帧循环动画、河流水波动画、道具闪烁动画、爆炸 5 帧序列
- 接入 `Systems/AudioManager.swift`：设计文档第 9 节的全部音效 + 3 首 BGM，带总开关与静音记忆
- `UIImpactFeedbackGenerator` 震动反馈
- 屏幕抖动、击杀顿帧（0.05 秒）、Boss 出场演出
- App 图标、启动画面

素材来源建议：Kenney.nl（CC0，可商用免署名）、OpenGameArt 的 CC0 分类，或用 Aseprite 自绘。字体用像素字体（如 Press Start 2P，OFL 协议）。

### 验收清单

- 所有素材都是 `.nearest` 过滤，放大后是硬边像素而不是模糊
- 履带动画只在移动时播放
- 每个动作都有对应音效，音效不会因高频触发而爆音
- 静音设置重启后保留
- 60 fps 未因动画和音频下降

---

## 阶段 8 — 平衡、性能与真机发布

**目标**：能把手机递给别人，他能从第 1 关玩到第 10 关不觉得挫败也不觉得无聊。

### 工作内容

- 完整通关至少 3 次，记录每关死亡次数，据此调 `GameConfig` 里的速度、冷却、HP、道具间隔
- 目标难度曲线：1-2 关几乎不死，3-5 关每关死 0-1 次，6-9 关每关死 1-2 次，第 10 关死 2-4 次后通关
- Xcode Instruments 的 Time Profiler + Allocations 跑一次，确认无内存持续增长（长时间挂机后节点数应稳定）
- 检查 `SKTexture` 与 `SKAction` 是否被复用而不是每帧新建
- 后台切回、来电中断、低电量模式下的表现
- 真机连续玩 30 分钟，观察发热与掉帧

### 验收清单

- 无崩溃、无内存泄漏、无帧率下降
- 难度曲线符合上面的死亡次数预期
- 从后台切回游戏保持暂停状态而不是直接继续
- 找一个没玩过的人试玩，不需要你解释就知道怎么操作

---

## 进度记录

每完成一个阶段，在这里打勾并写一句实际遇到的坑，方便后面回溯。

- [x] 阶段 0 环境与工程骨架 —— 工程误用 Game 模板建的，转 SwiftUI 生命周期时最容易漏掉
  `INFOPLIST_KEY_UIMainStoryboardFile`，留着它会启动即闪退；iPad 设备族会强制要求支持四个方向，
  与竖屏锁定冲突，直接把 `TARGETED_DEVICE_FAMILY` 收成 `1`
- [x] 阶段 1 网格地图与渲染 —— `GAME_DESIGN` 第 7 节的第 1 关只有砖墙，没有钢墙/河流/草丛/冰面，
  所以另加了 `GameConfig.debugTerrainShowcase` 开关加载一张摆满全部地形的调试地图，
  用来核对贴图与草丛遮挡，正式关卡数据不受污染；Xcode 模板自带的 UI 测试里
  `testLaunchPerformance` 单次要跑近 20 分钟，已删除
- [x] 阶段 2 玩家坦克与操控 —— 操控是独立 `ControlScene` + 下方第二个 `SpriteView`；
  `Bullet.moveSpeed` 不能叫 `speed`（与 `SKNode.speed` 冲突）
- [x] 阶段 3 敌方坦克与 AI —— 每帧最多 1 次 BFS，路径缓存 0.5 秒
- [x] 阶段 4 道具系统 —— 有时限状态必须走 `StatusEffectManager`，暂停才不会失效
- [x] 阶段 5 关卡流程与 10 关数据 —— 结算必须 one-shot，离开对局要 `gameScene = nil`；
  第 3/6/9/10 的 `bossType` 先当普通关跑通
- [x] 阶段 6 Boss 战 —— 多 tile 碰撞盒必须等于视觉尺寸；手雷对 Boss 只掉 3 血
- [x] 阶段 7 美术与音效润色 —— 换图换音只需同名替换 atlas / Audio；未改战斗逻辑
- [x] 试玩反馈优化 —— 菜单底色、中英文、炮管、地形钢墙；随后补了弹速/道具节奏、击杀飘分、模拟器键盘
- [ ] 阶段 8 平衡、性能与真机发布
