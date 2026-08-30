//
//  MenuScene.swift
//  war of tank
//

import SpriteKit

final class MenuScene: SKScene {

    private let flow: GameFlow

    init(flow: GameFlow) {
        self.flow = flow
        super.init(size: GameConfig.sceneSize)
        scaleMode = .aspectFit
        anchorPoint = .zero
        backgroundColor = GameConfig.menuBackgroundColor
        isUserInteractionEnabled = true
        build()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("MenuScene 不支持从归档初始化")
    }

    private func build() {
        addLabel(L10n.menuTitle, size: GameConfig.menuTitleFontSize, y: GameConfig.menuTitleY)
        addLabel(L10n.highScore(SaveManager.highScore), size: GameConfig.menuItemFontSize, y: GameConfig.menuScoreY)
        addButton(L10n.start, name: "start", x: GameConfig.sceneSide / 2, y: GameConfig.menuStartY)
        addButton(
            L10n.languageButton,
            name: "language",
            x: GameConfig.menuStageLeftX,
            y: GameConfig.menuMuteY
        )
        addButton(
            L10n.sound(isMuted: AudioManager.isMuted),
            name: "mute",
            x: GameConfig.menuStageRightX,
            y: GameConfig.menuMuteY
        )
        #if targetEnvironment(simulator)
        addLabel(L10n.simulatorHint, size: GameConfig.menuHintFontSize, y: GameConfig.menuHintY)
        #endif

        let unlocked = SaveManager.maxUnlockedLevel
        for index in 0..<GameConfig.levelCount {
            let number = index + 1
            let locked = number > unlocked
            let column = index / 5
            let row = index % 5
            let x = column == 0 ? GameConfig.menuStageLeftX : GameConfig.menuStageRightX
            let y = GameConfig.menuStageTopY - CGFloat(row) * GameConfig.menuStageRowSpacing
            addButton(
                L10n.stageButton(number: number, locked: locked),
                name: locked ? "locked" : "stage-\(index)",
                x: x,
                y: y,
                locked: locked
            )
        }
    }

    private func rebuild() {
        removeAllChildren()
        build()
    }

    private func addButton(_ text: String, name: String, x: CGFloat, y: CGFloat, locked: Bool = false) {
        let hit = SKSpriteNode(color: SKColor(white: 1, alpha: 0.001), size: GameConfig.menuButtonHitSize)
        hit.name = name
        hit.position = CGPoint(x: x, y: y)
        hit.zPosition = GameConfig.Layer.ui
        addChild(hit)

        let label = makeLabel(text, size: GameConfig.menuItemFontSize)
        label.fontColor = locked ? GameConfig.menuLockedColor : GameConfig.hudTextColor
        hit.addChild(label)
    }

    private func addLabel(_ text: String, size: CGFloat, y: CGFloat) {
        let label = makeLabel(text, size: size)
        label.position = CGPoint(x: GameConfig.sceneSide / 2, y: y)
        addChild(label)
    }

    private func makeLabel(_ text: String, size: CGFloat) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: GameConfig.debugGridLabelFontName)
        label.text = text
        label.fontSize = size
        label.fontColor = GameConfig.hudTextColor
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = GameConfig.Layer.ui
        return label
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        let hit = nodes(at: point).compactMap(\.name).first
        if hit == "start" {
            flow.startNewGame()
        } else if hit == "mute" {
            AudioManager.isMuted.toggle()
            rebuild()
        } else if hit == "language" {
            var next = SaveManager.language
            next.toggle()
            SaveManager.language = next
            rebuild()
        } else if let hit, hit.hasPrefix("stage-"), let index = Int(hit.dropFirst(6)) {
            flow.startSelectedLevel(index)
        }
    }
}
