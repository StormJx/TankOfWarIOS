//
//  PowerUp.swift
//  war of tank
//

import SpriteKit
import UIKit

enum PowerUpType: CaseIterable {
    case star
    case helmet
    case tank
    case grenade
    case timer
    case shovel

    var mark: String {
        switch self {
        case .star: return "S"
        case .helmet: return "H"
        case .tank: return "T"
        case .grenade: return "G"
        case .timer: return "C"
        case .shovel: return "V"
        }
    }

    var color: SKColor {
        switch self {
        case .star: return GameConfig.powerUpStarColor
        case .helmet: return GameConfig.powerUpHelmetColor
        case .tank: return GameConfig.powerUpTankColor
        case .grenade: return GameConfig.powerUpGrenadeColor
        case .timer: return GameConfig.powerUpTimerColor
        case .shovel: return GameConfig.powerUpShovelColor
        }
    }
}

final class PowerUp: SKSpriteNode {

    let type: PowerUpType
    private(set) var remaining: TimeInterval
    private var isBlinking = false

    private static let blinkAction: SKAction = {
        let half = GameConfig.powerUpBlinkPeriod / 2
        return SKAction.repeatForever(
            SKAction.sequence([
                SKAction.fadeAlpha(to: 0.2, duration: half),
                SKAction.fadeAlpha(to: 1, duration: half)
            ])
        )
    }()

    init(type: PowerUpType, at position: CGPoint) {
        self.type = type
        self.remaining = GameConfig.powerUpLifetime
        super.init(texture: SpriteProvider.powerUp(type) ?? Self.texture(for: type), color: .clear, size: GameConfig.tileNodeSize)
        self.position = position
        zPosition = GameConfig.Layer.powerUp
        texture?.filteringMode = .nearest
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("PowerUp 不支持从归档初始化")
    }

    var isExpired: Bool { remaining <= 0 }

    func tick(dt: TimeInterval) {
        remaining -= dt
        if remaining <= GameConfig.powerUpBlinkLead, !isBlinking {
            isBlinking = true
            run(Self.blinkAction.copy() as! SKAction)
        }
    }

    private static var cache: [PowerUpType: SKTexture] = [:]

    private static func texture(for type: PowerUpType) -> SKTexture {
        if let cached = cache[type] { return cached }
        let side = GameConfig.tileSize
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
        let image = renderer.image { context in
            let cg = context.cgContext
            cg.setFillColor(type.color.cgColor)
            cg.fill(CGRect(x: 0, y: 0, width: side, height: side))
            cg.setStrokeColor(GameConfig.powerUpMarkColor.cgColor)
            cg.setLineWidth(GameConfig.tileDetailThickness)
            cg.stroke(CGRect(x: 1, y: 1, width: side - 2, height: side - 2))
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        cache[type] = texture
        return texture
    }
}
