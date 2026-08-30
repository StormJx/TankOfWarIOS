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

    /// 坦克转向时垂直轴的吸附粒度（半 tile），阶段 2 起生效
    static let alignmentGranularity: CGFloat = tileSize / 2

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

    // MARK: - 调试开关（发布前必须全部关掉）

    static let debugShowGrid = false
    static let debugShowStats = false
}
