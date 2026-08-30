//
//  VictoryScene.swift
//  war of tank
//

import SpriteKit

final class VictoryScene: SKScene {

    private let flow: GameFlow

    init(flow: GameFlow) {
        self.flow = flow
        super.init(size: GameConfig.sceneSize)
        scaleMode = .aspectFit
        anchorPoint = .zero
        backgroundColor = GameConfig.menuBackgroundColor
        isUserInteractionEnabled = true

        addLabel(L10n.youWin, y: GameConfig.menuStartY, size: GameConfig.menuTitleFontSize)
        addLabel(L10n.score(flow.score.score), y: GameConfig.menuStageTopY, size: GameConfig.menuItemFontSize)
        addLabel(
            L10n.highScore(SaveManager.highScore),
            y: GameConfig.menuStageTopY - GameConfig.menuStageRowSpacing,
            size: GameConfig.menuItemFontSize
        )
        addButton(L10n.menu, y: GameConfig.menuStageTopY - GameConfig.menuStageRowSpacing * 3, name: "menu")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("VictoryScene 不支持从归档初始化")
    }

    private func addLabel(_ text: String, y: CGFloat, size: CGFloat) {
        let label = SKLabelNode(fontNamed: GameConfig.debugGridLabelFontName)
        label.text = text
        label.fontSize = size
        label.fontColor = GameConfig.hudTextColor
        label.position = CGPoint(x: GameConfig.sceneSide / 2, y: y)
        label.zPosition = GameConfig.Layer.ui
        addChild(label)
    }

    private func addButton(_ text: String, y: CGFloat, name: String) {
        let hit = SKSpriteNode(color: SKColor(white: 1, alpha: 0.001), size: GameConfig.menuButtonHitSize)
        hit.name = name
        hit.position = CGPoint(x: GameConfig.sceneSide / 2, y: y)
        hit.zPosition = GameConfig.Layer.ui
        addChild(hit)

        let label = SKLabelNode(fontNamed: GameConfig.debugGridLabelFontName)
        label.text = text
        label.fontSize = GameConfig.menuItemFontSize
        label.fontColor = GameConfig.hudTextColor
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        hit.addChild(label)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        if nodes(at: point).contains(where: { $0.name == "menu" }) {
            flow.backToMenu()
        }
    }
}
