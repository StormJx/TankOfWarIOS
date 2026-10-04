//
//  MenuWidgets.swift
//  war of tank
//

import SpriteKit

enum MenuWidgets {

    static func makeLabel(_ text: String, size: CGFloat) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: GameConfig.debugGridLabelFontName)
        label.text = text
        label.fontSize = size
        label.fontColor = GameConfig.hudTextColor
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = GameConfig.Layer.ui
        return label
    }

    static func framedButton(text: String, name: String, at position: CGPoint, locked: Bool = false) -> SKNode {
        let hit = SKSpriteNode(color: SKColor(white: 1, alpha: 0.001), size: GameConfig.menuButtonHitSize)
        hit.name = name
        hit.position = position
        hit.zPosition = GameConfig.Layer.ui

        let frame = SKShapeNode(rectOf: GameConfig.menuButtonFrameSize)
        frame.fillColor = GameConfig.menuButtonFillColor
        frame.strokeColor = locked ? GameConfig.menuLockedColor : GameConfig.menuButtonStrokeColor
        frame.lineWidth = GameConfig.menuButtonLineWidth
        frame.zPosition = GameConfig.Layer.ui
        hit.addChild(frame)

        let label = makeLabel(text, size: GameConfig.menuItemFontSize)
        label.fontColor = locked ? GameConfig.menuLockedColor : GameConfig.hudTextColor
        label.zPosition = GameConfig.Layer.ui + 1
        hit.addChild(label)
        return hit
    }

    /// 标题左侧的玩家坦克，只作装饰
    static func titleTank(at position: CGPoint) -> SKSpriteNode {
        let texture = SpriteProvider.playerFrames().first
        let node = SKSpriteNode(texture: texture, color: texture == nil ? GameConfig.playerColor : .clear, size: GameConfig.tileNodeSize)
        node.setScale(GameConfig.menuTitleTankScale)
        node.position = position
        node.zPosition = GameConfig.Layer.ui
        node.texture?.filteringMode = .nearest
        return node
    }
}
