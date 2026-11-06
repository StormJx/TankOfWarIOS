//
//  PowerUpSystem.swift
//  war of tank
//

import CoreGraphics
import SpriteKit

final class PowerUpSystem {

    private(set) var current: PowerUp?
    private struct ShovelCell {
        let original: TileType
        let effect: TileType
    }

    private var shovelSnapshot: [GridPoint: ShovelCell] = [:]
    private var shovelShowingOriginal = false
    let isBossLevel: Bool
    let allowsEnemyPickup: Bool

    init(isBossLevel: Bool = false, allowsEnemyPickup: Bool = false) {
        self.isBossLevel = isBossLevel
        self.allowsEnemyPickup = allowsEnemyPickup
    }

    func canCollect(_ tank: Tank) -> Bool {
        tank is PlayerTank || allowsEnemyPickup
    }

    static func weights(isBossLevel: Bool) -> [(PowerUpType, Int)] {
        [
            (.star, GameConfig.powerUpWeightStar),
            (.helmet, GameConfig.powerUpWeightHelmet),
            (.tank, GameConfig.powerUpWeightTank),
            (.grenade, isBossLevel ? GameConfig.powerUpWeightGrenadeBoss : GameConfig.powerUpWeightGrenade),
            (.timer, GameConfig.powerUpWeightTimer),
            (.shovel, GameConfig.powerUpWeightShovel)
        ]
    }

    static func pickType(isBossLevel: Bool, roll: Int? = nil) -> PowerUpType {
        let table = weights(isBossLevel: isBossLevel)
        let total = table.reduce(0) { $0 + $1.1 }
        var ticket = roll ?? Int.random(in: 0..<max(total, 1))
        for (type, weight) in table {
            if ticket < weight { return type }
            ticket -= weight
        }
        return .star
    }

    static func isLegalSpawn(
        _ point: GridPoint,
        map: GridMap,
        tanks: [Tank]
    ) -> Bool {
        guard map.isInside(point), map.tile(at: point) == .empty else { return false }
        let blocked = Set(
            [map.basePosition, map.playerSpawn]
            + map.basePosition.adjacentEight
            + tanks.filter { $0.hp > 0 }.flatMap { tank in
                CollisionSystem.coveredTiles(tank.collisionRect, map: map).flatMap { cell in
                    [cell] + cell.adjacentEight
                }
            }
        )
        return !blocked.contains(point)
    }

    func update(
        dt: TimeInterval,
        map _: GridMap,
        parent _: SKNode,
        tanks _: [Tank]
    ) {
        if let powerUp = current {
            powerUp.tick(dt: dt)
            if powerUp.isExpired {
                despawn()
            }
        }
    }

    /// 闪红敌人被击毁时调用。场上已有道具会被换掉
    func drop(at position: CGPoint, map: GridMap, parent: SKNode, tanks: [Tank]) {
        despawn()
        let origin = map.gridPoint(at: position)
        let point = Self.isLegalSpawn(origin, map: map, tanks: tanks)
            ? origin
            : nearestLegalSpawn(to: origin, map: map, tanks: tanks)
        guard let point else { return }
        let powerUp = PowerUp(type: Self.pickType(isBossLevel: isBossLevel), at: map.center(of: point))
        parent.addChild(powerUp)
        current = powerUp
        PresentationCues.powerUpAppeared()
    }

    func collectIfNeeded(tanks: [Tank], map: GridMap) -> (PowerUpType, Tank)? {
        guard let powerUp = current else { return nil }
        let cell = map.gridPoint(at: powerUp.position)
        for tank in tanks where tank.hp > 0 && canCollect(tank) {
            if map.gridPoint(at: tank.position) == cell
                || tank.collisionRect.intersects(powerUp.frame) {
                let type = powerUp.type
                despawn()
                return (type, tank)
            }
        }
        return nil
    }

    func despawn() {
        current?.removeFromParent()
        current = nil
    }

    func applyShovel(asPlayer: Bool, map: GridMap, renderer: MapRenderer) {
        let walls = map.baseWallPoints()
        shovelSnapshot = Dictionary(uniqueKeysWithValues: walls.map { point in
            let original = map.tile(at: point)
            let effect: TileType = asPlayer ? .steel : (original == .brick ? .empty : .brick)
            return (point, ShovelCell(original: original, effect: effect))
        })
        shovelShowingOriginal = false
        for (point, cell) in shovelSnapshot {
            map.setTile(cell.effect, at: point)
            renderer.refreshTile(at: point)
        }
    }

    func restoreShovel(map: GridMap, renderer: MapRenderer) {
        for (point, cell) in shovelSnapshot {
            map.setTile(cell.original, at: point)
            renderer.refreshTile(at: point)
        }
        shovelSnapshot.removeAll()
        shovelShowingOriginal = false
    }

    func blinkShovelIfNeeded(remaining: TimeInterval, map: GridMap, renderer: MapRenderer) {
        guard remaining > 0, remaining <= GameConfig.shovelBlinkLead, !shovelSnapshot.isEmpty else { return }
        let showOriginal = Int(remaining / GameConfig.shovelBlinkPeriod) % 2 == 0
        guard showOriginal != shovelShowingOriginal else { return }
        shovelShowingOriginal = showOriginal
        for (point, cell) in shovelSnapshot {
            map.setTile(showOriginal ? cell.original : cell.effect, at: point)
            renderer.refreshTile(at: point)
        }
    }

    private func nearestLegalSpawn(to origin: GridPoint, map: GridMap, tanks: [Tank]) -> GridPoint? {
        var best: GridPoint?
        var bestDistance = Int.max
        for row in 0..<GameConfig.gridCount {
            for col in 0..<GameConfig.gridCount {
                let point = GridPoint(col: col, row: row)
                guard Self.isLegalSpawn(point, map: map, tanks: tanks) else { continue }
                let distance = origin.manhattanDistance(to: point)
                if distance < bestDistance {
                    best = point
                    bestDistance = distance
                }
            }
        }
        return best
    }
}
