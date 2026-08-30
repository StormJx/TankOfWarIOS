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

    // MARK: - 帧率

    static let preferredFramesPerSecond: Int = 60

    // MARK: - 玩家

    static let playerSpeed: CGFloat = 48

    // MARK: - 占位配色（阶段 7 换成 texture atlas 时移除）

    static let battlefieldColor = SKColor.black
    static let playerColor = SKColor.yellow
    static let hudPlaceholderColor = SKColor(white: 0.20, alpha: 1)
    static let controlAreaPlaceholderColor = SKColor(white: 0.12, alpha: 1)
    static let placeholderLabelColor = SKColor(white: 0.55, alpha: 1)

    static let brickColor = SKColor(red: 0.62, green: 0.35, blue: 0.20, alpha: 1)
    static let steelColor = SKColor(red: 0.72, green: 0.73, blue: 0.76, alpha: 1)
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
