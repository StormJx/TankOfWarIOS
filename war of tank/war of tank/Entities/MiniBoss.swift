//
//  MiniBoss.swift
//  war of tank
//

import CoreGraphics
import SpriteKit

enum MiniBossTrait {
    case none
    case swift
    case summoner
}

final class MiniBoss: BossTank {

    let trait: MiniBossTrait

    init(at position: CGPoint, trait: MiniBossTrait) {
        self.trait = trait
        let speed = GameConfig.miniBossSpeed * (trait == .swift ? GameConfig.miniBossSwiftSpeedMultiplier : 1)
        super.init(
            score: GameConfig.miniBossScore,
            at: position,
            size: CGSize(
                width: GameConfig.tileSize * CGFloat(GameConfig.miniBossFootprintTiles),
                height: GameConfig.tileSize * CGFloat(GameConfig.miniBossFootprintTiles)
            ),
            moveSpeed: speed,
            hp: GameConfig.miniBossHitPoints,
            fireCooldown: GameConfig.miniBossPhase1FireCooldown
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("MiniBoss 不支持从归档初始化")
    }

    override var phaseSpeedMultiplier: CGFloat {
        phase >= 2 ? GameConfig.miniBossPhase2SpeedMultiplier : 1
    }

    override func phase(for hp: Int) -> Int {
        hp <= GameConfig.miniBossPhase2HPMax ? 2 : 1
    }

    override var fireCooldownForPhase: TimeInterval {
        phase >= 2 ? GameConfig.miniBossPhase2FireCooldown : GameConfig.miniBossPhase1FireCooldown
    }

    override func volleyTravels() -> [CGVector] {
        phase >= 2 ? Self.scatterTravels(facing: direction) : [direction.vector]
    }
}
