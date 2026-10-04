//
//  HUDNode.swift
//  war of tank
//

import SpriteKit

final class HUDNode: SKNode {

    private let lifeNodes: [SKSpriteNode]
    private let enemyIcon: SKSpriteNode
    private let enemyCount = SKLabelNode(fontNamed: GameConfig.debugGridLabelFontName)
    private let stageLabel = SKLabelNode(fontNamed: GameConfig.debugGridLabelFontName)
    private let scoreLabel = SKLabelNode(fontNamed: GameConfig.debugGridLabelFontName)
    private let effectLabel = SKLabelNode(fontNamed: GameConfig.debugGridLabelFontName)
    private let powerPips: [SKSpriteNode]

    override init() {
        let lifeTexture = SpriteProvider.playerFrames().first
        lifeNodes = (0..<GameConfig.playerLives).map { _ in
            HUDNode.icon(texture: lifeTexture, fallback: GameConfig.playerColor)
        }
        let enemyTexture = SpriteProvider.enemyFrames(type: .normal, hp: 1).first
        enemyIcon = HUDNode.icon(texture: enemyTexture, fallback: GameConfig.enemyNormalColor)
        powerPips = (0..<GameConfig.playerFirepowerMax).map { _ in
            SKSpriteNode(color: GameConfig.playerBarrelPoweredColor, size: CGSize(width: GameConfig.hudPipSize, height: GameConfig.hudPipSize))
        }
        super.init()
        zPosition = GameConfig.Layer.ui
        for life in lifeNodes { addChild(life) }
        addChild(enemyIcon)
        configure(enemyCount)
        configure(stageLabel)
        configure(scoreLabel)
        configure(effectLabel)
        addChild(enemyCount)
        addChild(stageLabel)
        addChild(scoreLabel)
        addChild(effectLabel)
        for pip in powerPips { addChild(pip) }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("HUDNode 不支持从归档初始化")
    }

    func render(_ state: GameHUDState, width: CGFloat) {
        let icon = GameConfig.hudIconSize
        let gap = GameConfig.hudIconSpacing
        let group = GameConfig.hudGroupSpacing
        var x = icon / 2

        for (index, life) in lifeNodes.enumerated() {
            life.position = CGPoint(x: x, y: 0)
            life.alpha = index < state.lives ? 1 : GameConfig.hudDimAlpha
            x += icon + gap
        }
        x += group - gap

        enemyIcon.position = CGPoint(x: x, y: 0)
        x += icon / 2 + gap
        enemyCount.text = "\(state.remainingEnemies)"
        enemyCount.position = CGPoint(x: x + enemyCount.frame.width / 2, y: 0)
        x += max(enemyCount.frame.width, icon) + group

        stageLabel.text = L10n.hudStage(state.stage)
        stageLabel.position = CGPoint(x: x + stageLabel.frame.width / 2, y: 0)
        x += stageLabel.frame.width + group

        scoreLabel.text = L10n.hudScore(state.score)
        scoreLabel.position = CGPoint(x: x + scoreLabel.frame.width / 2, y: 0)

        let pipGap = GameConfig.hudPipSize + gap
        var pipX = width - GameConfig.hudPauseReserve - CGFloat(powerPips.count) * pipGap
        for (index, pip) in powerPips.enumerated() {
            pip.position = CGPoint(x: pipX, y: 0)
            pip.alpha = index < state.firepower ? 1 : GameConfig.hudDimAlpha
            pipX += pipGap
        }

        effectLabel.text = state.effects.joined(separator: " ")
        effectLabel.horizontalAlignmentMode = .left
        let effectX = scoreLabel.position.x + scoreLabel.frame.width / 2 + group
        effectLabel.position = CGPoint(x: effectX, y: 0)
    }

    private func configure(_ label: SKLabelNode) {
        label.fontSize = GameConfig.hudIconFontSize
        label.fontColor = GameConfig.hudTextColor
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
    }

    private static func icon(texture: SKTexture?, fallback: SKColor) -> SKSpriteNode {
        let node = SKSpriteNode(
            texture: texture,
            color: texture == nil ? fallback : .clear,
            size: CGSize(width: GameConfig.hudIconSize, height: GameConfig.hudIconSize)
        )
        node.texture?.filteringMode = .nearest
        return node
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
        node.position = CGPoint(x: GameConfig.hudIconSpacing, y: size.height / 2)
    }

    override func update(_ currentTime: TimeInterval) {
        node.render(hud, width: size.width)
    }
}
