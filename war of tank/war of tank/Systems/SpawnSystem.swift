//
//  SpawnSystem.swift
//  war of tank
//

import SpriteKit

final class SpawnSystem {

    private struct PendingSpawn {
        let type: EnemyType
        let point: GridPoint
        var remaining: TimeInterval
        let beacon: SKNode
    }

    private var queue: [EnemyType]
    private var pending: [PendingSpawn] = []
    private var nextSpawnIndex = 0
    private var extraSlots = 0

    var onScreenCap: Int { GameConfig.enemyOnScreenCap + extraSlots }

    init(mix: EnemyMix) {
        queue = Array(repeating: .normal, count: mix.normal)
            + Array(repeating: .fast, count: mix.fast)
            + Array(repeating: .armored, count: mix.armored)
    }

    var remainingInQueue: Int { queue.count }
    var pendingCount: Int { pending.count }

    func update(
        dt: TimeInterval,
        map: GridMap,
        parent: SKNode,
        liveEnemies: [EnemyTank],
        blockingTanks: [Tank]
    ) -> [EnemyTank] {
        startFlashesIfNeeded(
            map: map,
            parent: parent,
            liveEnemies: liveEnemies.filter { !$0.isBoss },
            blockingTanks: blockingTanks
        )

        var born: [EnemyTank] = []
        var kept: [PendingSpawn] = []
        for var item in pending {
            item.remaining -= dt
            if item.remaining > 0 {
                kept.append(item)
                continue
            }
            if isOccupied(item.point, map: map, tanks: blockingTanks + liveEnemies) {
                item.remaining = GameConfig.enemySpawnFlashDuration
                kept.append(item)
                continue
            }
            item.beacon.removeFromParent()
            let tank = EnemyTank(type: item.type, at: map.center(of: item.point))
            born.append(tank)
        }
        pending = kept
        return born
    }

    func spawnReinforcement(
        type: EnemyType = .normal,
        map: GridMap,
        liveEnemies: [EnemyTank],
        blockingTanks: [Tank]
    ) -> EnemyTank? {
        extraSlots += 1
        guard let point = nextFreeSpawn(map: map, tanks: blockingTanks + liveEnemies) else {
            extraSlots = max(0, extraSlots - 1)
            return nil
        }
        let tank = EnemyTank(type: type, at: map.center(of: point))
        tank.isReinforcement = true
        return tank
    }

    func released(_ enemy: EnemyTank) {
        if enemy.isReinforcement {
            extraSlots = max(0, extraSlots - 1)
        }
    }

    private func startFlashesIfNeeded(
        map: GridMap,
        parent: SKNode,
        liveEnemies: [EnemyTank],
        blockingTanks: [Tank]
    ) {
        while !queue.isEmpty
            && liveEnemies.count + pending.count < onScreenCap {
            guard let point = nextFreeSpawn(map: map, tanks: blockingTanks + liveEnemies) else { break }
            let type = queue.removeFirst()
            let beacon = EffectFactory.spawnBeacon(at: map.center(of: point))
            parent.addChild(beacon)
            pending.append(
                PendingSpawn(
                    type: type,
                    point: point,
                    remaining: GameConfig.enemySpawnFlashDuration,
                    beacon: beacon
                )
            )
        }
    }

    private func nextFreeSpawn(map: GridMap, tanks: [Tank]) -> GridPoint? {
        let points = map.enemySpawns
        guard !points.isEmpty else { return nil }
        for offset in 0..<points.count {
            let point = points[(nextSpawnIndex + offset) % points.count]
            if pending.contains(where: { $0.point == point }) { continue }
            if isOccupied(point, map: map, tanks: tanks) { continue }
            nextSpawnIndex = (nextSpawnIndex + offset + 1) % points.count
            return point
        }
        return nil
    }

    private func isOccupied(_ point: GridPoint, map: GridMap, tanks: [Tank]) -> Bool {
        let center = map.center(of: point)
        let half = GameConfig.tileSize / 2
        let tile = CGRect(
            x: center.x - half,
            y: center.y - half,
            width: GameConfig.tileSize,
            height: GameConfig.tileSize
        )
        return tanks.contains { tank in
            tank.hp > 0 && tank.collisionRect.intersects(tile)
        }
    }
}
