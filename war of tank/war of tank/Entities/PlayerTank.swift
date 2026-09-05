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
            refreshAppearance()
        }
    }

    /// 头盔道具：外壳换成钢蓝两色；过期后由 GameScene 置回 false
    var hasShield = false {
        didSet {
            guard oldValue != hasShield else { return }
            refreshAppearance()
        }
    }

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
            texture: Self.baseBodyTexture,
            size: GameConfig.tileNodeSize,
            moveSpeed: GameConfig.playerSpeed,
            hp: GameConfig.playerHitPoints,
            fireCooldown: GameConfig.playerFireCooldown,
            faction: .player,
            bulletSpeed: Self.bulletSpeed(for: startingFirepower)
        )
        self.position = position
        applyFirepowerStats()
        refreshAppearance()
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
        presentFacing(.up, animated: false)
        commandedDirection = nil
        isHidden = false
        alpha = 1
        resetPowerUps()
        refreshAppearance()
    }

    private func applyFirepowerStats() {
        bulletSpeed = Self.bulletSpeed(for: firepower)
        canBreakSteel = firepower >= GameConfig.playerFirepowerBreakSteel
    }

    /// 火力 → 炮管热红色；护盾 → 外壳钢蓝。贴图四态由 atlas 预先生成。
    func refreshAppearance() {
        let frames = SpriteProvider.playerFrames(firepower: firepower, shielded: hasShield)
        let key = "player-fp\(firepower > 0 ? 1 : 0)-sh\(hasShield ? 1 : 0)"
        if frames.isEmpty {
            let moving = isShowingMotion
            presentMotion(false)
            displayTexture(Self.placeholderTexture(firepower: firepower, shielded: hasShield))
            trackFrames = []
            trackCacheKey = key
            if moving { presentMotion(true) }
            return
        }
        replaceTrackFrames(frames, cacheKey: key)
    }

    static func bulletSpeed(for firepower: Int) -> CGFloat {
        firepower == 0 ? GameConfig.playerBulletSpeedLevel0 : GameConfig.playerBulletSpeedUpgraded
    }

    private static let baseBodyTexture: SKTexture = {
        placeholderTexture(firepower: 0, shielded: false)
    }()

    private static func placeholderTexture(firepower: Int, shielded: Bool) -> SKTexture {
        let body: SKColor
        let shade: SKColor
        let barrel: SKColor
        if shielded {
            body = GameConfig.playerShieldBodyColor
            shade = GameConfig.playerShieldShadeColor
        } else {
            body = GameConfig.playerColor
            shade = GameConfig.playerShadeColor
        }
        barrel = firepower > 0 ? GameConfig.playerBarrelPoweredColor : shade
        return TankPlaceholderTextures.make(body: body, track: shade, barrel: barrel)
    }
}
