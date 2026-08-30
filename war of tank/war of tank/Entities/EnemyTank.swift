//
//  EnemyTank.swift
//  war of tank
//

import SpriteKit
import UIKit

enum EnemyType: CaseIterable {
    case normal
    case fast
    case armored

    var hitPoints: Int {
        switch self {
        case .normal: return GameConfig.enemyNormalHitPoints
        case .fast: return GameConfig.enemyFastHitPoints
        case .armored: return GameConfig.enemyArmoredHitPoints
        }
    }

    var moveSpeed: CGFloat {
        switch self {
        case .normal: return GameConfig.enemyNormalSpeed
        case .fast: return GameConfig.enemyFastSpeed
        case .armored: return GameConfig.enemyArmoredSpeed
        }
    }

    var score: Int {
        switch self {
        case .normal: return GameConfig.enemyNormalScore
        case .fast: return GameConfig.enemyFastScore
        case .armored: return GameConfig.enemyArmoredScore
        }
    }

    var fireCooldown: TimeInterval {
        switch self {
        case .fast: return GameConfig.enemyFastFireCooldown
        case .normal, .armored: return GameConfig.enemyNormalFireCooldown
        }
    }

    var maxSimultaneousBullets: Int { GameConfig.enemyMaxBullets }
}

class EnemyTank: Tank {

    let type: EnemyType
    let score: Int
    var isReinforcement = false
    var isBoss = false

    override var maxSimultaneousBullets: Int {
        isBoss ? GameConfig.bossMaxSimultaneousBullets : type.maxSimultaneousBullets
    }

    convenience init(type: EnemyType, at position: CGPoint) {
        self.init(
            type: type,
            score: type.score,
            at: position,
            size: GameConfig.tileNodeSize,
            moveSpeed: type.moveSpeed,
            hp: type.hitPoints,
            fireCooldown: type.fireCooldown,
            texture: Self.texture(for: type, hp: type.hitPoints),
            isBoss: false
        )
    }

    init(
        type: EnemyType,
        score: Int,
        at position: CGPoint,
        size: CGSize,
        moveSpeed: CGFloat,
        hp: Int,
        fireCooldown: TimeInterval,
        texture: SKTexture,
        isBoss: Bool
    ) {
        self.type = type
        self.score = score
        self.isBoss = isBoss
        super.init(
            texture: texture,
            size: size,
            moveSpeed: moveSpeed,
            hp: hp,
            fireCooldown: fireCooldown,
            faction: .enemy,
            bulletSpeed: GameConfig.enemyBulletSpeed
        )
        self.position = position
        direction = .down
        if !isBoss {
            refreshTrackFrames()
        }
    }

    func refreshTrackFrames() {
        let frames = SpriteProvider.enemyFrames(type: type, hp: hp)
        if !frames.isEmpty {
            applyTrackFrames(frames, cacheKey: "\(type)-\(hp)")
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("EnemyTank 不支持从归档初始化")
    }

    override func takeDamage(_ amount: Int = 1) {
        let before = hp
        super.takeDamage(amount)
        if type == .armored, hp > 0, hp != before {
            refreshTrackFrames()
        }
    }

    private static var cache: [String: SKTexture] = [:]

    static func texture(for type: EnemyType, hp: Int) -> SKTexture {
        let key = "\(type)-\(hp)"
        if let cached = cache[key] { return cached }

        let color: SKColor
        switch type {
        case .normal:
            color = GameConfig.enemyNormalColor
        case .fast:
            color = GameConfig.enemyFastColor
        case .armored:
            color = armoredColor(hp: hp)
        }

        let texture = makeBodyTexture(color: color)
        cache[key] = texture
        return texture
    }

    static func armoredColor(hp: Int) -> SKColor {
        switch hp {
        case 4: return GameConfig.enemyArmoredColorGreen
        case 3: return GameConfig.enemyArmoredColorYellow
        case 2: return GameConfig.enemyArmoredColorGray
        default: return GameConfig.enemyArmoredColorRed
        }
    }

    private static func makeBodyTexture(color: SKColor) -> SKTexture {
        let side = GameConfig.tileSize
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
        let image = renderer.image { context in
            let cg = context.cgContext
            cg.setFillColor(color.cgColor)
            cg.fill(CGRect(x: 0, y: 0, width: side, height: side))

            let barrelWidth = side / 4
            let barrelHeight = side / 2
            cg.setFillColor(color.adjustingBrightness(by: GameConfig.enemyBarrelDarkenFactor).cgColor)
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
