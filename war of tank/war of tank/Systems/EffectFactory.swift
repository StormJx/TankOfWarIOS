//
//  EffectFactory.swift
//  war of tank
//

import SpriteKit
import UIKit

enum EffectFactory {

    private static let flickerKey = "invincibleFlicker"
    private static let shakeKey = "screenShake"
    private static let chargeWarningKey = "chargeWarning"
    private static let flashKey = "whiteFlash"
    private static let muzzleFlashName = "muzzleFlash"

    private static let smallExplosionAction: SKAction = {
        SKAction.group([
            SKAction.scale(to: GameConfig.explosionEndScale, duration: GameConfig.explosionDuration),
            SKAction.fadeOut(withDuration: GameConfig.explosionDuration)
        ])
    }()

    private static let bigExplosionAction: SKAction = {
        SKAction.group([
            SKAction.scale(to: GameConfig.bigExplosionEndScale, duration: GameConfig.bigExplosionDuration),
            SKAction.fadeOut(withDuration: GameConfig.bigExplosionDuration)
        ])
    }()

    private static let sparkAction: SKAction = {
        SKAction.group([
            SKAction.scale(to: GameConfig.explosionEndScale, duration: GameConfig.sparkDuration),
            SKAction.fadeOut(withDuration: GameConfig.sparkDuration)
        ])
    }()

    private static let flickerAction: SKAction = {
        let half = GameConfig.invincibleFlickerPeriod / 2
        return SKAction.repeatForever(
            SKAction.sequence([
                SKAction.group([
                    SKAction.colorize(
                        with: GameConfig.invincibleTintRed,
                        colorBlendFactor: GameConfig.invincibleColorBlend,
                        duration: half
                    ),
                    SKAction.fadeAlpha(to: 0.55, duration: half)
                ]),
                SKAction.group([
                    SKAction.colorize(
                        with: GameConfig.invincibleTintBlue,
                        colorBlendFactor: GameConfig.invincibleColorBlend,
                        duration: half
                    ),
                    SKAction.fadeAlpha(to: 1, duration: half)
                ])
            ])
        )
    }()

    private static let muzzleFlashAction: SKAction = {
        SKAction.sequence([
            SKAction.wait(forDuration: GameConfig.muzzleFlashDuration),
            .removeFromParent()
        ])
    }()

    private static let hitFlashAction: SKAction = {
        SKAction.sequence([
            SKAction.fadeOut(withDuration: GameConfig.hitFlashDuration),
            .removeFromParent()
        ])
    }()

    private static let muzzleFlashTexture: SKTexture = {
        let side: CGFloat = 8
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
        let image = renderer.image { context in
            let cg = context.cgContext
            cg.setFillColor(SKColor.white.cgColor)
            cg.fill(CGRect(x: 3, y: 0, width: 2, height: 8))
            cg.fill(CGRect(x: 0, y: 3, width: 8, height: 2))
            cg.fill(CGRect(x: 2, y: 2, width: 4, height: 4))
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }()

    private static let beaconBlinkAction: SKAction = {
        let half = GameConfig.spawnBeaconBlinkPeriod / 2
        return SKAction.repeatForever(
            SKAction.sequence([
                SKAction.fadeAlpha(to: 0.15, duration: half),
                SKAction.fadeAlpha(to: 1, duration: half)
            ])
        )
    }()

    private static let shakeAction = makeShake(duration: GameConfig.screenShakeDuration)
    private static let phaseShakeAction = makeShake(duration: GameConfig.bossPhaseShakeDuration)
    private static let deathShakeAction = makeShake(duration: GameConfig.bossDeathShakeDuration)

    private static let flashAction: SKAction = {
        SKAction.fadeOut(withDuration: GameConfig.bossFlashDuration)
    }()

    private static let chargeWarningAction: SKAction = {
        let half = GameConfig.bossChargeWarningPeriod / 2
        return SKAction.repeatForever(
            SKAction.sequence([
                SKAction.fadeAlpha(to: 0.35, duration: half),
                SKAction.fadeAlpha(to: 1, duration: half)
            ])
        )
    }()

    private static func makeShake(duration: TimeInterval) -> SKAction {
        let d = GameConfig.screenShakeDistance
        let slice = duration / 6
        return SKAction.sequence([
            SKAction.moveBy(x: d, y: 0, duration: slice),
            SKAction.moveBy(x: -2 * d, y: d, duration: slice),
            SKAction.moveBy(x: d, y: -2 * d, duration: slice),
            SKAction.moveBy(x: d, y: d, duration: slice),
            SKAction.moveBy(x: -d, y: 0, duration: slice),
            SKAction.move(to: .zero, duration: slice)
        ])
    }

    private static func runShake(_ action: SKAction, on scene: SKScene) {
        scene.removeAction(forKey: shakeKey)
        scene.position = .zero
        scene.run(action.copy() as! SKAction, withKey: shakeKey)
    }

    static func smallExplosion(at position: CGPoint, in parent: SKNode) {
        playExplosion(size: GameConfig.explosionNodeSize, fallback: smallExplosionAction, at: position, in: parent)
    }

    static func bigExplosion(at position: CGPoint, in parent: SKNode) {
        playExplosion(size: GameConfig.bigExplosionNodeSize, fallback: bigExplosionAction, at: position, in: parent)
    }

    static func scorePopup(_ value: Int, at position: CGPoint, in parent: SKNode) {
        let label = SKLabelNode(fontNamed: GameConfig.debugGridLabelFontName)
        label.text = "+\(value)"
        label.fontSize = GameConfig.scorePopupFontSize
        label.fontColor = GameConfig.hudTextColor
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = GameConfig.Layer.ui
        label.position = position
        parent.addChild(label)
        label.run(
            SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: 0, y: GameConfig.scorePopupRise, duration: GameConfig.scorePopupDuration),
                    SKAction.fadeOut(withDuration: GameConfig.scorePopupDuration)
                ]),
                .removeFromParent()
            ])
        )
    }

    static func hitSpark(at position: CGPoint, in parent: SKNode) {
        play(
            color: GameConfig.bulletColor,
            size: GameConfig.sparkNodeSize,
            action: sparkAction,
            at: position,
            in: parent
        )
    }

    static func muzzleFlash(at position: CGPoint, color: SKColor, in parent: SKNode) {
        let node = SKSpriteNode(texture: muzzleFlashTexture, size: GameConfig.muzzleFlashNodeSize)
        node.name = muzzleFlashName
        node.color = color
        node.colorBlendFactor = 1
        node.alpha = GameConfig.muzzleFlashAlpha
        node.zPosition = GameConfig.Layer.effect
        node.position = position
        node.texture?.filteringMode = .nearest
        parent.addChild(node)
        node.run(muzzleFlashAction.copy() as! SKAction)
    }

    static func hitFlash(on tank: Tank, shielded: Bool) {
        // 无敌已经在红蓝闪，再叠白闪会搅成乱闪
        guard !tank.isInvincible else { return }
        tank.childNode(withName: GameConfig.hitFlashNodeName)?.removeFromParent()
        let overlay = SKSpriteNode(
            color: shielded ? GameConfig.playerShieldBodyColor : .white,
            size: tank.size
        )
        overlay.name = GameConfig.hitFlashNodeName
        overlay.alpha = GameConfig.hitFlashAlpha
        overlay.zPosition = GameConfig.tankOverlayZ
        overlay.isUserInteractionEnabled = false
        tank.addChild(overlay)
        overlay.run(hitFlashAction.copy() as! SKAction)
    }

    static func applyInvincibleFlicker(to node: SKNode) {
        node.childNode(withName: GameConfig.hitFlashNodeName)?.removeFromParent()
        let target = spriteTarget(for: node)
        target.removeAction(forKey: flickerKey)
        resetTint(target)
        target.run(flickerAction.copy() as! SKAction, withKey: flickerKey)
    }

    static func stopFlicker(on node: SKNode) {
        let target = spriteTarget(for: node)
        target.removeAction(forKey: flickerKey)
        resetTint(target)
        node.removeAction(forKey: flickerKey)
        node.alpha = 1
    }

    private static func spriteTarget(for node: SKNode) -> SKSpriteNode {
        if let visual = node.childNode(withName: GameConfig.tankVisualNodeName) as? SKSpriteNode {
            return visual
        }
        return node as? SKSpriteNode ?? SKSpriteNode()
    }

    private static func resetTint(_ node: SKSpriteNode) {
        node.removeAction(forKey: flickerKey)
        node.alpha = 1
        node.color = .white
        node.colorBlendFactor = 0
    }

    static func shake(scene: SKScene) {
        runShake(shakeAction, on: scene)
    }

    static func phaseShake(scene: SKScene) {
        runShake(phaseShakeAction, on: scene)
    }

    static func deathShake(scene: SKScene) {
        runShake(deathShakeAction, on: scene)
    }

    static func flashWhite(in scene: SKScene) {
        scene.childNode(withName: flashKey)?.removeFromParent()
        let node = SKSpriteNode(color: .white, size: GameConfig.sceneSize)
        node.name = flashKey
        node.alpha = GameConfig.bossFlashAlpha
        node.zPosition = GameConfig.Layer.effect
        node.position = CGPoint(x: GameConfig.sceneSide / 2, y: GameConfig.sceneSide / 2)
        scene.addChild(node)
        node.run(SKAction.sequence([flashAction.copy() as! SKAction, .removeFromParent()]))
    }

    static func applyChargeWarning(to node: SKNode) {
        node.removeAction(forKey: chargeWarningKey)
        node.run(chargeWarningAction.copy() as! SKAction, withKey: chargeWarningKey)
    }

    static func stopChargeWarning(on node: SKNode) {
        node.removeAction(forKey: chargeWarningKey)
        node.alpha = 1
    }

    static func bossDeath(at position: CGPoint, footprint: CGSize, in scene: SKScene) {
        PresentationCues.bigExplosion()
        deathShake(scene: scene)
        let count = GameConfig.bossDeathExplosionCount
        for index in 0..<count {
            let delay = TimeInterval(index) * GameConfig.bossDeathExplosionStagger
            let ox = footprint.width * (CGFloat(index % 3) - 1) / 3
            let oy = footprint.height * (CGFloat(index / 2) - 1) / 3
            let point = CGPoint(x: position.x + ox, y: position.y + oy)
            scene.run(
                SKAction.sequence([
                    SKAction.wait(forDuration: delay),
                    SKAction.run { bigExplosion(at: point, in: scene) }
                ])
            )
        }
    }

    static func spawnBeacon(at position: CGPoint) -> SKNode {
        let node = SKSpriteNode(color: GameConfig.spawnBeaconColor, size: GameConfig.tileNodeSize)
        node.zPosition = GameConfig.Layer.effect
        node.position = position
        node.run(beaconBlinkAction.copy() as! SKAction)
        return node
    }

    private static let explosionSequence: SKAction = {
        let frames = SpriteProvider.explosionFrames()
        guard frames.count >= 2 else {
            return SKAction.sequence([
                smallExplosionAction.copy() as! SKAction,
                .removeFromParent()
            ])
        }
        return SKAction.sequence([
            SKAction.animate(
                with: frames,
                timePerFrame: GameConfig.explosionFrameDuration,
                resize: false,
                restore: false
            ),
            .removeFromParent()
        ])
    }()

    private static func playExplosion(size: CGSize, fallback: SKAction, at position: CGPoint, in parent: SKNode) {
        let frames = SpriteProvider.explosionFrames()
        if let first = frames.first {
            let node = SKSpriteNode(texture: first, size: size)
            node.zPosition = GameConfig.Layer.effect
            node.position = position
            node.texture?.filteringMode = .nearest
            parent.addChild(node)
            node.run(explosionSequence.copy() as! SKAction)
            return
        }
        play(color: GameConfig.explosionColor, size: size, action: fallback, at: position, in: parent)
    }

    private static func play(
        color: SKColor,
        size: CGSize,
        action: SKAction,
        at position: CGPoint,
        in parent: SKNode
    ) {
        let node = SKSpriteNode(color: color, size: size)
        node.zPosition = GameConfig.Layer.effect
        node.position = position
        parent.addChild(node)
        let animation = action.copy() as! SKAction
        node.run(SKAction.sequence([animation, .removeFromParent()]))
    }
}
