//
//  LevelClearScene.swift
//  war of tank
//

import SpriteKit

final class LevelClearScene: SKScene {

    private let flow: GameFlow
    private var lastUpdateTime: TimeInterval = 0
    private var remaining = GameConfig.levelClearDisplayDuration
    private var didContinue = false

    init(flow: GameFlow) {
        self.flow = flow
        super.init(size: GameConfig.sceneSize)
        scaleMode = .aspectFit
        anchorPoint = .zero
        backgroundColor = GameConfig.menuBackgroundColor

        let title = SKLabelNode(fontNamed: GameConfig.debugGridLabelFontName)
        title.text = L10n.stageTitle(flow.levels.stageNumber)
        title.fontSize = GameConfig.menuTitleFontSize
        title.fontColor = GameConfig.hudTextColor
        title.position = CGPoint(x: GameConfig.sceneSide / 2, y: GameConfig.menuStartY)
        title.zPosition = GameConfig.Layer.ui
        addChild(title)

        let score = SKLabelNode(fontNamed: GameConfig.debugGridLabelFontName)
        score.text = L10n.score(flow.lastClearScore)
        score.fontSize = GameConfig.menuItemFontSize
        score.fontColor = GameConfig.hudTextColor
        score.position = CGPoint(x: GameConfig.sceneSide / 2, y: GameConfig.menuStageTopY)
        score.zPosition = GameConfig.Layer.ui
        addChild(score)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("LevelClearScene 不支持从归档初始化")
    }

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }
        let dt = min(currentTime - lastUpdateTime, GameConfig.maxFrameDelta)
        lastUpdateTime = currentTime
        remaining -= dt
        if remaining <= 0, !didContinue {
            didContinue = true
            flow.continueAfterClear()
        }
    }
}
