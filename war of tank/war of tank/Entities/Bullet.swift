//
//  Bullet.swift
//  war of tank
//

import SpriteKit
import UIKit

enum Faction {
    case player
    case enemy
}

final class Bullet: SKSpriteNode {

    let direction: Direction
    /// 不用 SKNode.speed：那是动画速率倍率，和子弹飞行速度不是一回事
    let moveSpeed: CGFloat
    let canBreakSteel: Bool
    let canPierceBrick: Bool
    let owner: Faction
    /// 散射和环状弹幕需要任意方向，不能只走四向 Direction
    let travel: CGVector
    private(set) var isDestroyed = false

    init(
        direction: Direction,
        moveSpeed: CGFloat,
        canBreakSteel: Bool,
        owner: Faction,
        canPierceBrick: Bool = false,
        travel: CGVector? = nil
    ) {
        self.direction = direction
        self.moveSpeed = moveSpeed
        self.canBreakSteel = canBreakSteel
        self.canPierceBrick = canPierceBrick
        self.owner = owner
        if let travel {
            let length = hypot(travel.dx, travel.dy)
            self.travel = length > 0
                ? CGVector(dx: travel.dx / length, dy: travel.dy / length)
                : direction.vector
        } else {
            self.travel = direction.vector
        }

        super.init(
            texture: SpriteProvider.bullet() ?? Self.texture,
            color: .clear,
            size: CGSize(width: GameConfig.bulletSize, height: GameConfig.bulletSize)
        )
        zPosition = GameConfig.Layer.bullet
        zRotation = direction.zRotation
        texture?.filteringMode = .nearest
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Bullet 不支持从归档初始化")
    }

    var collisionRect: CGRect {
        let half = GameConfig.bulletSize / 2
        return CGRect(
            x: position.x - half,
            y: position.y - half,
            width: GameConfig.bulletSize,
            height: GameConfig.bulletSize
        )
    }

    func markDestroyed() {
        isDestroyed = true
        removeFromParent()
    }

    private static let texture: SKTexture = {
        let side = GameConfig.bulletSize
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
        let image = renderer.image { context in
            context.cgContext.setFillColor(GameConfig.bulletColor.cgColor)
            context.cgContext.fill(CGRect(x: 0, y: 0, width: side, height: side))
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }()
}
