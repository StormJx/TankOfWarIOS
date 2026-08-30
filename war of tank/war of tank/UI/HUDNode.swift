//
//  HUDNode.swift
//  war of tank
//

import SpriteKit

final class HUDNode: SKNode {

    private let label = SKLabelNode(fontNamed: GameConfig.debugGridLabelFontName)

    override init() {
        super.init()
        zPosition = GameConfig.Layer.ui
        label.fontSize = GameConfig.hudIconFontSize
        label.fontColor = GameConfig.hudTextColor
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("HUDNode 不支持从归档初始化")
    }

    func render(_ state: GameHUDState) {
        label.text = L10n.hudLine(
            lives: state.lives,
            stage: state.stage,
            remainingEnemies: state.remainingEnemies,
            firepower: state.firepower,
            score: state.score,
            effects: state.effects
        )
    }
}

final class HUDScene: SKScene {
    private let hud: GameHUDState
    private let node = HUDNode()

    init(hud: GameHUDState) {
        self.hud = hud
        super.init(size: CGSize(width: 1, height: GameConfig.hudHeight))
        scaleMode = .resizeFill
        backgroundColor = GameConfig.hudPlaceholderColor
        anchorPoint = .zero
        addChild(node)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("HUDScene 不支持从归档初始化")
    }

    override func didChangeSize(_ oldSize: CGSize) {
        node.position = CGPoint(x: 8, y: size.height / 2)
    }

    override func update(_ currentTime: TimeInterval) {
        node.render(hud)
    }
}
