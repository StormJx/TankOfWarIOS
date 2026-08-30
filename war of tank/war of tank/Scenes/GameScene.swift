//
//  GameScene.swift
//  war of tank
//

import SpriteKit

/// 阶段 0 的骨架场景：只确立 208x208 的逻辑坐标系和左下角原点，
/// 地图、实体与主循环从阶段 1 起接入。
final class GameScene: SKScene {

    /// 场景尺寸只允许从 GameConfig 推导，避免调用方各自构造 CGSize
    static func battlefield() -> GameScene {
        GameScene(size: GameConfig.sceneSize)
    }

    override init(size: CGSize) {
        super.init(size: size)

        // 原点固定在左下角：GridMap 的 y = sceneSide - (row * tileSize + tileSize/2)
        // 换算公式以此为前提，改成 .center 会让全部行列换算失效
        anchorPoint = .zero
        scaleMode = .aspectFit
        backgroundColor = GameConfig.battlefieldColor

        addChild(makePlaceholderBlock())
    }

    required init?(coder aDecoder: NSCoder) {
        // 场景全部由代码构建，工程里不保留任何 .sks，因此没有反序列化路径
        fatalError("GameScene 不支持从归档初始化")
    }

    /// 阶段 1 接入真实地图后删除
    private func makePlaceholderBlock() -> SKSpriteNode {
        let block = SKSpriteNode(
            color: GameConfig.playerColor,
            size: CGSize(width: GameConfig.tileSize, height: GameConfig.tileSize)
        )
        // 13 是奇数，正中格 (6,6) 的中心恰好落在场景几何中心
        block.position = CGPoint(x: size.width / 2, y: size.height / 2)
        return block
    }
}
