//
//  FinalBoss.swift
//  war of tank
//

import CoreGraphics
import SpriteKit

final class FinalBoss: BossTank {

    var isWindingUp = false
    var isCharging = false
    var chargeDirection: Direction?

    init(at position: CGPoint) {
        super.init(
            score: GameConfig.finalBossScore,
            at: position,
            size: CGSize(
                width: GameConfig.tileSize * CGFloat(GameConfig.finalBossFootprintTiles),
                height: GameConfig.tileSize * CGFloat(GameConfig.finalBossFootprintTiles)
            ),
            moveSpeed: GameConfig.finalBossSpeed,
            hp: GameConfig.finalBossHitPoints,
            fireCooldown: GameConfig.finalBossPhase1FireCooldown
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("FinalBoss 不支持从归档初始化")
    }

    override func phase(for hp: Int) -> Int {
        if hp <= GameConfig.finalBossPhase3HPMax { return 3 }
        if hp <= GameConfig.finalBossPhase2HPMax { return 2 }
        return 1
    }

    override var fireCooldownForPhase: TimeInterval {
        phase >= 3 ? GameConfig.finalBossBarrageInterval : GameConfig.finalBossPhase1FireCooldown
    }

    override func takeDamage(_ amount: Int = 1) {
        let incoming = isStunned ? amount * GameConfig.finalBossStunDamageMultiplier : amount
        super.takeDamage(incoming)
    }

    override func volleyTravels() -> [CGVector] {
        if phase >= 3 {
            return Self.ringTravels()
        }
        return Self.scatterTravels(facing: direction)
    }
}
