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
        let label = MenuWidgets.makeLabel(text, size: size)
        label.position = CGPoint(x: GameConfig.sceneSide / 2, y: y)
        addChild(label)
    }

    private func addButton(_ text: String, y: CGFloat, name: String) {
        addChild(MenuWidgets.framedButton(text: text, name: name, at: CGPoint(x: GameConfig.sceneSide / 2, y: y)))
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
