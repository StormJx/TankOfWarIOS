//
//  PresentationCues.swift
//  war of tank
//

import SpriteKit

/// 只负责音效、震动和演出，不改胜负或碰撞。
enum PresentationCues {

    private static let bannerFade: SKAction = {
        SKAction.sequence([
            SKAction.wait(forDuration: GameConfig.stageBannerDuration * 0.55),
            SKAction.fadeOut(withDuration: GameConfig.stageBannerDuration * 0.45),
            SKAction.removeFromParent()
        ])
    }()

    private static let bossIntro: SKAction = {
        SKAction.sequence([
            SKAction.scale(to: GameConfig.bossIntroScale, duration: GameConfig.bossIntroDuration * 0.4),
            SKAction.scale(to: 1, duration: GameConfig.bossIntroDuration * 0.6)
        ])
    }()

    static func fired() {
        AudioManager.play(.fire)
    }

    static func hitTerrain(_ tile: TileType) {
        switch tile {
        case .brick:
            AudioManager.play(.hitBrick)
        case .steel:
            AudioManager.play(.hitSteel)
        case .base:
            AudioManager.play(.explosionBig)
        default:
            break
        }
    }

    static func smallExplosion() {
        AudioManager.play(.explosionSmall)
    }

    static func bigExplosion() {
        AudioManager.play(.explosionBig)
    }

    static func playerHit() {
        AudioManager.play(.playerDeath)
        AudioManager.hapticHeavy()
    }

    static func powerUpAppeared() {
        AudioManager.play(.powerUpAppear)
    }

    static func powerUpPicked(byPlayer: Bool) {
        AudioManager.play(.powerUpPickup)
        if byPlayer {
            AudioManager.hapticLight()
        }
    }

    static func bossPhaseChanged() {
        AudioManager.play(.bossPhase)
        AudioManager.hapticRigid()
    }

    static func stageStarted(number: Int, in scene: SKScene, isBoss: Bool) {
        AudioManager.play(.stageStart)
        AudioManager.playMusic(isBoss ? .boss : .battle)
        let banner = SKLabelNode(fontNamed: GameConfig.debugGridLabelFontName)
        banner.text = L10n.stageTitle(number)
        banner.fontSize = GameConfig.stageBannerFontSize
        banner.fontColor = GameConfig.hudTextColor
        banner.horizontalAlignmentMode = .center
        banner.verticalAlignmentMode = .center
        banner.position = CGPoint(x: GameConfig.sceneSide / 2, y: GameConfig.sceneSide / 2)
        banner.zPosition = GameConfig.Layer.ui
        scene.addChild(banner)
        banner.run(bannerFade.copy() as! SKAction)
    }

    static func bossIntro(on node: SKNode, in scene: SKScene) {
        node.setScale(1)
        node.run(bossIntro.copy() as! SKAction)
        EffectFactory.flashWhite(in: scene)
    }

    static func gameOver() {
        AudioManager.play(.gameOver)
        AudioManager.playMusic(.menu)
    }

    static func menu() {
        AudioManager.playMusic(.menu)
    }
}
