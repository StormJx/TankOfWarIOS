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
        let label = MenuWidgets.makeLabel(text, size: size)
        label.position = CGPoint(x: GameConfig.sceneSide / 2, y: y)
        addChild(label)
    }

    private func addButton(_ text: String, y: CGFloat, name: String) {
        addChild(MenuWidgets.framedButton(text: text, name: name, at: CGPoint(x: GameConfig.sceneSide / 2, y: y)))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        if nodes(at: point).contains(where: { $0.name == "menu" }) {
            flow.backToMenu()
        }
    }
}
