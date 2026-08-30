//
//  SpriteProvider.swift
//  war of tank
//

import SpriteKit
import UIKit

/// 优先读 atlas；缺图时退回代码占位。所有出口贴图都是 nearest。
enum SpriteProvider {

    private static var textureCache: [String: SKTexture] = [:]
    private static var trackActions: [String: SKAction] = [:]

    static func named(_ name: String) -> SKTexture? {
        if let cached = textureCache[name] { return cached }
        guard let image = UIImage(named: name) else { return nil }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        textureCache[name] = texture
        return texture
    }

    static func tile(_ type: TileType, frame: Int = 0) -> SKTexture? {
        switch type {
        case .empty: return nil
        case .brick: return named("tile_brick")
        case .steel: return named("tile_steel")
        case .water: return named(frame == 0 ? "tile_water_0" : "tile_water_1")
        case .grass: return named("tile_grass")
        case .ice: return named("tile_ice")
        case .base: return named("tile_base")
        }
    }

    static func playerFrames() -> [SKTexture] {
        frames("tank_player_0", "tank_player_1")
    }

    static func enemyFrames(type: EnemyType, hp: Int) -> [SKTexture] {
        switch type {
        case .normal:
            return frames("tank_normal_0", "tank_normal_1")
        case .fast:
            return frames("tank_fast_0", "tank_fast_1")
        case .armored:
            switch hp {
            case 4: return frames("tank_armored_green_0", "tank_armored_green_1")
            case 3: return frames("tank_armored_yellow_0", "tank_armored_yellow_1")
            case 2: return frames("tank_armored_gray_0", "tank_armored_gray_1")
            default: return frames("tank_armored_red_0", "tank_armored_red_1")
            }
        }
    }

    static func miniBossFrames() -> [SKTexture] {
        frames("boss_mini_0", "boss_mini_1")
    }

    static func finalBossFrames() -> [SKTexture] {
        frames("boss_final_0", "boss_final_1")
    }

    static func bullet() -> SKTexture? {
        named("bullet")
    }

    static func powerUp(_ type: PowerUpType) -> SKTexture? {
        switch type {
        case .star: return named("powerup_star")
        case .helmet: return named("powerup_helmet")
        case .tank: return named("powerup_tank")
        case .grenade: return named("powerup_grenade")
        case .timer: return named("powerup_timer")
        case .shovel: return named("powerup_shovel")
        }
    }

    static func explosionFrames() -> [SKTexture] {
        (0..<GameConfig.explosionFrameCount).compactMap { named("explosion_\($0)") }
    }

    static func trackAction(for frames: [SKTexture], cacheKey: String) -> SKAction {
        if let cached = trackActions[cacheKey] { return cached }
        let action = SKAction.repeatForever(
            SKAction.animate(
                with: frames,
                timePerFrame: GameConfig.trackFrameDuration,
                resize: false,
                restore: true
            )
        )
        trackActions[cacheKey] = action
        return action
    }

    static func applyNearest(_ texture: SKTexture?) -> SKTexture? {
        texture?.filteringMode = .nearest
        return texture
    }

    private static func frames(_ first: String, _ second: String) -> [SKTexture] {
        [named(first), named(second)].compactMap { $0 }
    }
}
