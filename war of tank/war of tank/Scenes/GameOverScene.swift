//
//  GameOverScene.swift
//  war of tank
//

import SpriteKit

final class GameOverScene: SKScene {

    private let flow: GameFlow

    init(flow: GameFlow) {
        self.flow = flow
        super.init(size: GameConfig.sceneSize)
        scaleMode = .aspectFit
        anchorPoint = .zero
        backgroundColor = GameConfig.menuBackgroundColor
        isUserInteractionEnabled = true

        addLabel(L10n.gameOver, y: GameConfig.menuStartY, size: GameConfig.menuTitleFontSize)
        addLabel(L10n.score(flow.score.score), y: GameConfig.menuStageTopY, size: GameConfig.menuItemFontSize)
        addButton(L10n.retry, y: GameConfig.menuStageTopY - GameConfig.menuStageRowSpacing * 2, name: "retry")
        addButton(L10n.menu, y: GameConfig.menuStageTopY - GameConfig.menuStageRowSpacing * 3, name: "menu")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("GameOverScene 不支持从归档初始化")
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
        switch nodes(at: point).compactMap(\.name).first {
        case "retry":
            flow.restartCurrentLevel()
        case "menu":
            flow.backToMenu()
        default:
            break
        }
    }
}
