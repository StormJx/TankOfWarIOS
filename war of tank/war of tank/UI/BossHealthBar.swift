//
//  BossHealthBar.swift
//  war of tank
//

import SpriteKit

final class BossHealthBar: SKNode {

    private var segments: [SKSpriteNode] = []
    private var lastPhase = 0

    override init() {
        super.init()
        zPosition = GameConfig.Layer.ui
        isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("BossHealthBar 不支持从归档初始化")
    }

    func render(hp: Int, maxHP: Int, phase: Int) {
        guard maxHP > 0, hp > 0 else {
            isHidden = true
            return
        }
        isHidden = false
        if segments.count != maxHP {
            rebuild(maxHP: maxHP)
        }
        lastPhase = phase
        let color = barColor(for: phase)
        for (index, segment) in segments.enumerated() {
            segment.color = index < hp ? color : GameConfig.bossHealthEmptyColor
        }
    }

    private func rebuild(maxHP: Int) {
        removeAllChildren()
        segments.removeAll()
        let step = GameConfig.bossHealthSegmentWidth + GameConfig.bossHealthSegmentSpacing
        let totalWidth = CGFloat(maxHP) * GameConfig.bossHealthSegmentWidth
            + CGFloat(max(maxHP - 1, 0)) * GameConfig.bossHealthSegmentSpacing
        let startX = -totalWidth / 2 + GameConfig.bossHealthSegmentWidth / 2
        for index in 0..<maxHP {
            let segment = SKSpriteNode(
                color: GameConfig.bossPhase1BarColor,
                size: CGSize(
                    width: GameConfig.bossHealthSegmentWidth,
                    height: GameConfig.bossHealthSegmentHeight
                )
            )
            segment.position = CGPoint(x: startX + CGFloat(index) * step, y: 0)
            addChild(segment)
            segments.append(segment)
        }
    }

    private func barColor(for phase: Int) -> SKColor {
        switch phase {
        case 3: return GameConfig.bossPhase3BarColor
        case 2: return GameConfig.bossPhase2BarColor
        default: return GameConfig.bossPhase1BarColor
        }
    }
}
