//
//  GameConfig.swift
//  war of tank
//

import CoreGraphics
import SpriteKit

/// 全部可调数值的唯一定义处，改数值只改这里和 docs/GAME_DESIGN.md。
/// 用 enum 而不是 struct，因为它不应该被实例化。
enum GameConfig {

    // MARK: - 网格与场景

    static let tileSize: CGFloat = 16
    static let gridCount: Int = 13

    /// 场景边长恒等于 tile 尺寸乘网格数，写成计算式而不是字面量 208，
    /// 避免将来调 tileSize 时两处数值失去同步
    static let sceneSide: CGFloat = tileSize * CGFloat(gridCount)

    static var sceneSize: CGSize { CGSize(width: sceneSide, height: sceneSide) }

    static var tileNodeSize: CGSize { CGSize(width: tileSize, height: tileSize) }

    /// 坦克转向时垂直轴的吸附粒度（半 tile），阶段 2 起生效
    static let alignmentGranularity: CGFloat = tileSize / 2

    // MARK: - 固定网格位置（见 GAME_DESIGN 第 2 节）

    /// 基地每关唯一且固定，地图缺少 E 时用它兜底
    static let baseGridPoint = GridPoint(col: 6, row: 12)

    /// 地图缺少 P 时的玩家出生点兜底
    static let defaultPlayerSpawn = GridPoint(col: 4, row: 12)

    // MARK: - 渲染分层

    /// 草丛在坦克之上形成视觉遮蔽，特效在子弹之上，调试叠加层永远最高
    enum Layer {
        static let terrain: CGFloat = 0
        static let powerUp: CGFloat = 10
        static let tank: CGFloat = 20
        static let bullet: CGFloat = 30
        static let grass: CGFloat = 40
        static let effect: CGFloat = 50
        static let ui: CGFloat = 60
    }

    // MARK: - 竖屏布局

    static let hudHeight: CGFloat = 44

    /// 控制区高度下限：摇杆底盘直径 88 加射击键与上下留白后的底线，
    /// 战场让位给它以保证 iPhone SE 上摇杆不被挤掉
    static let controlAreaMinHeight: CGFloat = 180

    /// 把可用边长收到 sceneSide 的整数倍，避免像素坦克被非整数倍拉伸发糊。
    /// 可用边长小于一倍逻辑尺寸时退回 available，优先保证完整可见。
    static func integerScaledBattlefieldSide(available: CGFloat) -> CGFloat {
        let logical = sceneSide
        guard available > 0, logical > 0 else { return 0 }
        let scale = max(1, floor(available / logical))
        let snapped = scale * logical
        return snapped <= available + 0.5 ? snapped : available
    }

    // MARK: - 帧率

    static let preferredFramesPerSecond: Int = 60

    // MARK: - 时间步

    /// 首帧之后每帧 dt 的上限。卡顿时若不夹紧，坦克或子弹会一次跨过整面墙
    static let maxFrameDelta: TimeInterval = 1.0 / 30.0

    // MARK: - 玩家

    static let playerSpeed: CGFloat = 48
    static let playerHitPoints = 1
    static let playerLives = 3
    static let playerFireCooldown: TimeInterval = 0
    static let playerRespawnDelay: TimeInterval = 3
    static let playerRespawnInvincibility: TimeInterval = 3

    static let playerFirepowerMax = 3
    static let playerFirepowerDualShot = 2
    static let playerFirepowerBreakSteel = 3

    static let playerMaxBulletsLow = 1
    static let playerMaxBulletsHigh = 2

    static let playerBulletSpeedLevel0: CGFloat = 120
    static let playerBulletSpeedUpgraded: CGFloat = 144

    /// 调试用：把起始火力设成 3 可直接验证钢墙摧毁。发布前必须为 0
    static let debugStartingFirepower = 0

    // MARK: - 子弹与碰撞

    static let bulletSize: CGFloat = 4
    static let bulletMaxStep: CGFloat = 4
    static let collisionEpsilon: CGFloat = 0.01

    // MARK: - 爆炸占位

    static var explosionNodeSize: CGSize { CGSize(width: tileSize * 0.75, height: tileSize * 0.75) }
    static let explosionDuration: TimeInterval = 0.18
    static let explosionEndScale: CGFloat = 1.6
    static let explosionColor = SKColor(red: 1, green: 0.72, blue: 0.22, alpha: 1)

    // MARK: - 虚拟摇杆与射击键

    static let joystickBaseRadius: CGFloat = 44
    static let joystickKnobRadius: CGFloat = 20
    static let joystickTouchRadiusMultiplier: CGFloat = 1.5
    static let joystickDeadZone: CGFloat = 8

    static var joystickTouchRadius: CGFloat { joystickBaseRadius * joystickTouchRadiusMultiplier }

    static let fireButtonRadius: CGFloat = 32
    static let fireButtonRepeatInterval: TimeInterval = 0.18

    static let controlSidePadding: CGFloat = 24

    static let joystickBaseColor = SKColor(white: 0.28, alpha: 0.92)
    static let joystickBaseStrokeColor = SKColor(white: 0.48, alpha: 1)
    static let joystickKnobColor = SKColor(white: 0.78, alpha: 1)
    static let fireButtonColor = SKColor(red: 0.78, green: 0.22, blue: 0.18, alpha: 0.95)
    static let fireButtonStrokeColor = SKColor(red: 0.95, green: 0.42, blue: 0.32, alpha: 1)
    static let fireButtonPressedColor = SKColor(red: 0.95, green: 0.38, blue: 0.28, alpha: 1)

    static let joystickLineWidth: CGFloat = 2
    static let fireButtonLineWidth: CGFloat = 2

    static let tankBarrelColor = SKColor(red: 0.82, green: 0.62, blue: 0.08, alpha: 1)
    static let bulletColor = SKColor(white: 0.95, alpha: 1)

    // MARK: - 敌人（见 GAME_DESIGN 第 4 节）

    static let enemyOnScreenCap = 3
    static let enemyMaxBullets = 1
    static let enemySpawnFlashDuration: TimeInterval = 1.5
    static let enemyBulletSpeed: CGFloat = 84

    static let enemyNormalHitPoints = 1
    static let enemyNormalSpeed: CGFloat = 40
    static let enemyNormalScore = 100
    static let enemyNormalFireCooldown: TimeInterval = 1.2

    static let enemyFastHitPoints = 1
    static let enemyFastSpeed: CGFloat = 72
    static let enemyFastScore = 200
    static let enemyFastFireCooldown: TimeInterval = 0.9

    static let enemyArmoredHitPoints = 4
    static let enemyArmoredSpeed: CGFloat = 32
    static let enemyArmoredScore = 400
    static let enemyArmoredFireCooldown: TimeInterval = 1.2

    static let enemyNormalColor = SKColor(white: 0.86, alpha: 1)
    static let enemyFastColor = SKColor(red: 0.20, green: 0.78, blue: 0.82, alpha: 1)
    static let enemyArmoredColorGreen = SKColor(red: 0.22, green: 0.68, blue: 0.28, alpha: 1)
    static let enemyArmoredColorYellow = SKColor(red: 0.90, green: 0.80, blue: 0.18, alpha: 1)
    static let enemyArmoredColorGray = SKColor(white: 0.55, alpha: 1)
    static let enemyArmoredColorRed = SKColor(red: 0.82, green: 0.18, blue: 0.16, alpha: 1)
    static let enemyBarrelDarkenFactor: CGFloat = 0.62

    static let spawnBeaconColor = SKColor(white: 0.92, alpha: 1)
    static let spawnBeaconBlinkPeriod: TimeInterval = 0.15

    // MARK: - AI

    static let aiDecisionInterval: TimeInterval = 0.5
    static let aiPathCacheDuration: TimeInterval = 0.5
    static let aiHuntPlayerRangeInTiles = 6
    static let aiFireRangeInTiles = 6
    static let aiEvadeRangeInTiles = 3
    static let aiPatrolWeight = 20
    static let aiHuntBaseWeight = 40
    static let aiHuntPlayerWeight = 40
    static let aiPatrolDownWeight = 4
    static let aiPatrolSideWeight = 2
    static let aiSeekPowerUpRangeInTiles = 5

    // MARK: - Boss（见 GAME_DESIGN 第 6 节）

    static let miniBossFootprintTiles = 2
    static let miniBossHitPoints = 8
    static let miniBossSpeed: CGFloat = 36
    static let miniBossScore = 1000
    static let miniBossPhase1FireCooldown: TimeInterval = 1.0
    static let miniBossPhase2FireCooldown: TimeInterval = 0.8
    static let miniBossPhase2SpeedMultiplier: CGFloat = 1.3
    static let miniBossPhase2HPMax = 4
    static let miniBossSwiftSpeedMultiplier: CGFloat = 1.2
    static let miniBossTimerSlowFactor: CGFloat = 0.5
    static let miniBossSummonInterval: TimeInterval = 6
    static let miniBossSwiftStage = 6
    static let miniBossSummonStage = 9

    static let finalBossFootprintTiles = 3
    static let finalBossHitPoints = 20
    static let finalBossSpeed: CGFloat = 30
    static let finalBossScore = 5000
    static let finalBossPhase1FireCooldown: TimeInterval = 1.0
    static let finalBossChargeSpeed: CGFloat = 90
    static let finalBossChargeWindup: TimeInterval = 0.8
    static let finalBossChargeStun: TimeInterval = 1.5
    static let finalBossStunDamageMultiplier = 2
    static let finalBossPhase2HPMax = 13
    static let finalBossPhase3HPMax = 6
    static let finalBossSummonInterval: TimeInterval = 10
    static let finalBossSummonCount = 2
    static let finalBossBarrageInterval: TimeInterval = 4
    static let finalBossBarrageCount = 8

    static let bossMaxSimultaneousBullets = 16
    static let bossScatterAngle: CGFloat = .pi / 6
    static let bossPhaseShakeDuration: TimeInterval = 0.4
    static let bossDeathShakeDuration: TimeInterval = 0.6
    static let bossDeathExplosionCount = 5
    static let bossDeathExplosionStagger: TimeInterval = 0.08
    static let bossFlashDuration: TimeInterval = 0.12
    static let bossFlashAlpha: CGFloat = 0.8
    static let bossHealthSegmentWidth: CGFloat = 8
    static let bossHealthSegmentHeight: CGFloat = 4
    static let bossHealthSegmentSpacing: CGFloat = 1
    static let bossHealthBarTopInset: CGFloat = 6
    static let bossColor = SKColor(red: 0.86, green: 0.16, blue: 0.14, alpha: 1)
    static let bossPhase1BarColor = SKColor(red: 0.86, green: 0.16, blue: 0.14, alpha: 1)
    static let bossPhase2BarColor = SKColor(red: 0.92, green: 0.72, blue: 0.16, alpha: 1)
    static let bossPhase3BarColor = SKColor(red: 0.78, green: 0.22, blue: 0.72, alpha: 1)
    static let bossHealthEmptyColor = SKColor(white: 0.22, alpha: 1)
    static let bossChargeWarningColor = SKColor(red: 1, green: 0.2, blue: 0.1, alpha: 1)
    static let bossChargeWarningPeriod: TimeInterval = 0.12

    // MARK: - 道具（见 GAME_DESIGN 第 5 节）

    static let powerUpSpawnMin: TimeInterval = 6
    static let powerUpSpawnMax: TimeInterval = 12
    static let powerUpLifetime: TimeInterval = 15
    static let powerUpBlinkLead: TimeInterval = 3
    static let powerUpOnScreenCap = 1
    static let powerUpBlinkPeriod: TimeInterval = 0.15

    static let powerUpWeightStar = 25
    static let powerUpWeightHelmet = 20
    static let powerUpWeightTank = 15
    static let powerUpWeightGrenade = 15
    static let powerUpWeightTimer = 15
    static let powerUpWeightShovel = 10
    static let powerUpWeightGrenadeBoss = 5

    static let helmetPlayerDuration: TimeInterval = 10
    static let helmetEnemyDuration: TimeInterval = 5
    static let grenadePlayerStunDuration: TimeInterval = 2
    static let timerEnemyFreezeDuration: TimeInterval = 8
    static let timerPlayerFreezeDuration: TimeInterval = 3
    static let shovelDuration: TimeInterval = 15
    static let shovelBlinkLead: TimeInterval = 3
    static let shovelBlinkPeriod: TimeInterval = 0.2
    static let grenadeBossDamage = 3
    static let enemyStarBulletSpeedMultiplier: CGFloat = 1.5
    static let enemyOnScreenCapBoosted = 4

    static let powerUpStarColor = SKColor(red: 1, green: 0.84, blue: 0.12, alpha: 1)
    static let powerUpHelmetColor = SKColor(white: 0.88, alpha: 1)
    static let powerUpTankColor = SKColor(red: 0.28, green: 0.72, blue: 0.32, alpha: 1)
    static let powerUpGrenadeColor = SKColor(red: 0.86, green: 0.22, blue: 0.18, alpha: 1)
    static let powerUpTimerColor = SKColor(red: 0.28, green: 0.78, blue: 0.86, alpha: 1)
    static let powerUpShovelColor = SKColor(red: 0.72, green: 0.48, blue: 0.18, alpha: 1)
    static let powerUpMarkColor = SKColor.black
    static let hudIconFontSize: CGFloat = 11
    static let hudTextColor = SKColor(white: 0.88, alpha: 1)
    static let hudPauseButtonTrailing: CGFloat = 10

    // MARK: - 流程与存档

    static let levelCount = 10
    static let levelClearDisplayDuration: TimeInterval = 2
    static let saveMaxUnlockedKey = "maxUnlockedLevel"
    static let saveHighScoreKey = "highScore"
    static let saveMutedKey = "isMuted"
    static let saveLanguageKey = "appLanguage"
    static let menuTitleFontSize: CGFloat = 18
    static let menuItemFontSize: CGFloat = 10
    static let menuTitleY: CGFloat = 176
    static let menuScoreY: CGFloat = 156
    static let menuStartY: CGFloat = 132
    static let menuStageTopY: CGFloat = 108
    static let menuStageRowSpacing: CGFloat = 16
    static let menuStageColumnInset: CGFloat = 52
    static var menuStageLeftX: CGFloat { menuStageColumnInset }
    static var menuStageRightX: CGFloat { sceneSide - menuStageColumnInset }
    static let menuButtonHitSize = CGSize(width: 88, height: 16)
    static let menuLockedColor = SKColor(white: 0.35, alpha: 1)
    static let overlayScrimColor = SKColor(white: 0, alpha: 0.55)
    static let pauseOverlaySpacing: CGFloat = 16
    static let menuMuteY: CGFloat = 22
    static let menuHintY: CGFloat = 8
    static let menuHintFontSize: CGFloat = 7

    // MARK: - 表现层（阶段 7，不参与数值平衡）

    static let killHitStop: TimeInterval = 0.08
    static let scorePopupFontSize: CGFloat = 8
    static let scorePopupDuration: TimeInterval = 0.55
    static let scorePopupRise: CGFloat = 12
    static let stageBannerDuration: TimeInterval = 1.2
    static let stageBannerFontSize: CGFloat = 18
    /// 履带两帧切换间隔；略快一点，16px 坦克移动时条纹差才够明显
    static let trackFrameDuration: TimeInterval = 0.06

    // MARK: - 坦克阴影（贴地感，不参与碰撞）

    static let tankShadowAlpha: CGFloat = 0.32
    static let tankShadowScaleX: CGFloat = 0.92
    static let tankShadowScaleY: CGFloat = 0.42
    static let tankShadowOffsetY: CGFloat = -2
    static let tankShadowColor = SKColor.black
    static let waterFrameDuration: TimeInterval = 0.28
    static let explosionFrameDuration: TimeInterval = 0.06
    static let explosionFrameCount = 5
    static let trackActionKey = "trackFrames"
    static let sfxFireVoiceLimit = 4
    static let sfxHitVoiceLimit = 3
    static let bossIntroScale: CGFloat = 1.35
    static let bossIntroDuration: TimeInterval = 0.35
    static let audioFadeDuration: TimeInterval = 0.2

    // MARK: - 特效

    static var bigExplosionNodeSize: CGSize { CGSize(width: tileSize * 1.4, height: tileSize * 1.4) }
    static let bigExplosionDuration: TimeInterval = 0.32
    static let bigExplosionEndScale: CGFloat = 1.8
    static var sparkNodeSize: CGSize { CGSize(width: tileSize * 0.4, height: tileSize * 0.4) }
    static let sparkDuration: TimeInterval = 0.1
    static let invincibleFlickerPeriod: TimeInterval = 0.12
    static let screenShakeDistance: CGFloat = 2
    static let screenShakeDuration: TimeInterval = 0.18
    static let gameOverLabelFontSize: CGFloat = 16
    static let gameOverLabelColor = SKColor.white

    // MARK: - 占位配色（阶段 7 换成 texture atlas 时移除）

    static let battlefieldColor = SKColor.black
    /// 菜单/结算用 NES 风深蓝，和战场纯黑分开，避免整屏死黑
    static let menuBackgroundColor = SKColor(red: 0.07, green: 0.14, blue: 0.28, alpha: 1)
    static let playerColor = SKColor.yellow
    static let hudPlaceholderColor = SKColor(white: 0.20, alpha: 1)
    static let controlAreaPlaceholderColor = SKColor(white: 0.12, alpha: 1)
    static let placeholderLabelColor = SKColor(white: 0.55, alpha: 1)

    static let brickColor = SKColor(red: 0.62, green: 0.35, blue: 0.20, alpha: 1)
    static let steelColor = SKColor(red: 0.86, green: 0.88, blue: 0.92, alpha: 1)
    static let waterColor = SKColor(red: 0.13, green: 0.34, blue: 0.78, alpha: 1)
    static let grassColor = SKColor(red: 0.09, green: 0.45, blue: 0.16, alpha: 1)
    static let iceColor = SKColor(red: 0.72, green: 0.88, blue: 0.96, alpha: 1)
    static let baseColor = SKColor(red: 0.88, green: 0.76, blue: 0.30, alpha: 1)

    /// 占位贴图的明暗细节由底色乘系数推导，省掉为每种地形再定义一组颜色常量
    static let tileDetailLightenFactor: CGFloat = 1.35
    static let tileDetailDarkenFactor: CGFloat = 0.62

    /// 占位贴图内部描线宽度，1 pt 对应 16x16 贴图里的 1 像素
    static let tileDetailThickness: CGFloat = 1

    // MARK: - 调试开关（发布前必须全部关掉）

    static let debugShowGrid = false
    static let debugShowStats = false

    /// 打开后加载 Levels.terrainShowcase 而不是第 1 关，用于一次性核对
    /// 全部地形的渲染效果与草丛遮挡
    static let debugTerrainShowcase = false

    static let debugGridLineColor = SKColor(white: 1, alpha: 0.22)
    static let debugGridLineWidth: CGFloat = 0.5
    static let debugGridLabelColor = SKColor(white: 1, alpha: 0.55)
    static let debugGridLabelFontSize: CGFloat = 4
    static let debugGridLabelFontName = "Menlo-Regular"
}
