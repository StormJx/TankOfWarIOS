//
//  BossTank.swift
//  war of tank
//

import SpriteKit
import UIKit

class BossTank: EnemyTank {

    private(set) var phase = 1
    var onPhaseChange: ((Int) -> Void)?
    var cruiseSpeed: CGFloat
    var isSlowed = false

    init(
        score: Int,
        at position: CGPoint,
        size: CGSize,
        moveSpeed: CGFloat,
        hp: Int,
        fireCooldown: TimeInterval
    ) {
        self.cruiseSpeed = moveSpeed
        super.init(
            type: .normal,
            score: score,
            at: position,
            size: size,
            moveSpeed: moveSpeed,
            hp: hp,
            fireCooldown: fireCooldown,
            texture: Self.bodyTexture(side: size.width),
            isBoss: true
        )
        let frames = footprintTiles >= GameConfig.finalBossFootprintTiles
            ? SpriteProvider.finalBossFrames()
            : SpriteProvider.miniBossFrames()
        if !frames.isEmpty {
            applyTrackFrames(
                frames,
                cacheKey: footprintTiles >= GameConfig.finalBossFootprintTiles ? "final" : "mini"
            )
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("BossTank 不支持从归档初始化")
    }

    func refreshSpeed() {
        var speed = cruiseSpeed * phaseSpeedMultiplier
        if isSlowed, self is MiniBoss {
            speed *= GameConfig.miniBossTimerSlowFactor
        }
        moveSpeed = speed
    }

    var phaseSpeedMultiplier: CGFloat { 1 }

    func syncPhase() {
        let next = phase(for: hp)
        guard next != phase else { return }
        phase = next
        fireCooldown = fireCooldownForPhase
        refreshSpeed()
        onPhaseChange?(phase)
    }

    func phase(for hp: Int) -> Int { 1 }

    var fireCooldownForPhase: TimeInterval { fireCooldown }

    override func takeDamage(_ amount: Int = 1) {
        super.takeDamage(amount)
        syncPhase()
    }

    override func fireVolley() -> [Bullet] {
        guard canFire else { return [] }
        fireCooldownRemaining = fireCooldown
        return makeVolley(travels: volleyTravels())
    }

    func volleyTravels() -> [CGVector] {
        [direction.vector]
    }

    func makeVolley(travels: [CGVector]) -> [Bullet] {
        travels.map { travel in
            let facing = Direction.fromVector(CGPoint(x: travel.dx, y: travel.dy), deadZone: 0) ?? direction
            let bullet = Bullet(
                direction: facing,
                moveSpeed: bulletSpeed,
                canBreakSteel: canBreakSteel,
                owner: faction,
                canPierceBrick: canPierceBrick,
                travel: travel
            )
            bullet.position = muzzlePoint(along: travel)
            return bullet
        }
    }

    static func scatterTravels(facing: Direction) -> [CGVector] {
        let forward = facing.vector
        return [
            rotated(forward, by: -GameConfig.bossScatterAngle),
            forward,
            rotated(forward, by: GameConfig.bossScatterAngle)
        ]
    }

    static func ringTravels() -> [CGVector] {
        (0..<GameConfig.finalBossBarrageCount).map { index in
            let angle = CGFloat(index) * (.pi * 2 / CGFloat(GameConfig.finalBossBarrageCount))
            return CGVector(dx: sin(angle), dy: cos(angle))
        }
    }

    static func rotated(_ vector: CGVector, by radians: CGFloat) -> CGVector {
        let cosA = cos(radians)
        let sinA = sin(radians)
        return CGVector(
            dx: vector.dx * cosA - vector.dy * sinA,
            dy: vector.dx * sinA + vector.dy * cosA
        )
    }

    private static var textureCache: [CGFloat: SKTexture] = [:]

    static func bodyTexture(side: CGFloat) -> SKTexture {
        if let cached = textureCache[side] { return cached }
        let texture = TankPlaceholderTextures.make(
            body: GameConfig.bossColor,
            track: GameConfig.bossColor.adjustingBrightness(by: GameConfig.enemyBarrelDarkenFactor),
            barrel: .white,
            side: side
        )
        textureCache[side] = texture
        return texture
    }
}


private extension SKColor {
    func adjustingBrightness(by factor: CGFloat) -> SKColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        guard getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return self
        }
        return SKColor(hue: hue, saturation: saturation, brightness: min(brightness * factor, 1), alpha: alpha)
    }
}
