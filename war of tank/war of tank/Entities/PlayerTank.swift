//
//  PlayerTank.swift
//  war of tank
//

import SpriteKit
import UIKit

final class PlayerTank: Tank {

    var firepower: Int {
        didSet {
            let clamped = min(max(firepower, 0), GameConfig.playerFirepowerMax)
            if firepower != clamped {
                firepower = clamped
                return
            }
            applyFirepowerStats()
        }
    }

    var hasShield = false

    override var maxSimultaneousBullets: Int {
        firepower >= GameConfig.playerFirepowerDualShot
            ? GameConfig.playerMaxBulletsHigh
            : GameConfig.playerMaxBulletsLow
    }

    init(at position: CGPoint) {
        let startingFirepower = min(
            max(GameConfig.debugStartingFirepower, 0),
            GameConfig.playerFirepowerMax
        )
        self.firepower = startingFirepower
        super.init(
            texture: Self.bodyTexture,
            size: GameConfig.tileNodeSize,
            moveSpeed: GameConfig.playerSpeed,
            hp: GameConfig.playerHitPoints,
            fireCooldown: GameConfig.playerFireCooldown,
            faction: .player,
            bulletSpeed: Self.bulletSpeed(for: startingFirepower)
        )
        self.position = position
        applyFirepowerStats()
        let frames = SpriteProvider.playerFrames()
        if !frames.isEmpty {
            applyTrackFrames(frames, cacheKey: "player")
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("PlayerTank 不支持从归档初始化")
    }

    func resetPowerUps() {
        firepower = 0
        hasShield = false
        isFrozen = false
        isStunned = false
    }

    override func takeDamage(_ amount: Int = 1) {
        if hasShield || isInvincible { return }
        super.takeDamage(amount)
    }

    func restoreAfterRespawn(at position: CGPoint) {
        hp = GameConfig.playerHitPoints
        self.position = position
        direction = .up
        commandedDirection = nil
        isHidden = false
        alpha = 1
        resetPowerUps()
    }

    private func applyFirepowerStats() {
        bulletSpeed = Self.bulletSpeed(for: firepower)
        canBreakSteel = firepower >= GameConfig.playerFirepowerBreakSteel
    }

    static func bulletSpeed(for firepower: Int) -> CGFloat {
        firepower == 0 ? GameConfig.playerBulletSpeedLevel0 : GameConfig.playerBulletSpeedUpgraded
    }

    private static let bodyTexture: SKTexture = {
        let side = GameConfig.tileSize
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
        let image = renderer.image { context in
            let cg = context.cgContext
            cg.setFillColor(GameConfig.playerColor.cgColor)
            cg.fill(CGRect(x: 0, y: 0, width: side, height: side))

            // 炮管画在贴图上方，靠 zRotation 表示朝向，避免四个方向各做一张
            let barrelWidth = side / 4
            let barrelHeight = side / 2
            cg.setFillColor(GameConfig.tankBarrelColor.cgColor)
            cg.fill(
                CGRect(
                    x: (side - barrelWidth) / 2,
                    y: 0,
                    width: barrelWidth,
                    height: barrelHeight
                )
            )
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }()
}
