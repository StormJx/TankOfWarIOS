//
//  AIController.swift
//  war of tank
//

import CoreGraphics
import Foundation

enum AIState {
    case patrol
    case huntBase
    case huntPlayer
    case evade
    case seekPowerUp
}

struct AICommand {
    var direction: Direction?
    var shouldFire: Bool
    var isCharging: Bool = false
    var startWindup: Direction? = nil
    var summonCount: Int = 0
}

final class AIController {

    private struct PathCache {
        var path: [GridPoint]
        var goal: GridPoint
        var age: TimeInterval
    }

    private struct Memory {
        var state: AIState = .patrol
        var decisionAge: TimeInterval = 0
        var path: PathCache?
        var lastCell: GridPoint?
        var summonAge: TimeInterval = 0
        var barrageAge: TimeInterval = 0
        var patrolDir: Direction = .left
    }

    private var memories: [ObjectIdentifier: Memory] = [:]
    private var bfsUsedThisFrame = false

    func beginFrame() {
        bfsUsedThisFrame = false
    }

    func forget(_ tank: Tank) {
        memories[ObjectIdentifier(tank)] = nil
    }

    func command(
        for enemy: EnemyTank,
        dt: TimeInterval,
        map: GridMap,
        player: PlayerTank?,
        bullets: [Bullet],
        powerUp: PowerUp?
    ) -> AICommand {
        if enemy is BossTank {
            return commandBoss(enemy, dt: dt, map: map, player: player)
        }

        let id = ObjectIdentifier(enemy)
        var memory = memories[id] ?? Memory()
        memory.decisionAge += dt
        if var cache = memory.path {
            cache.age += dt
            memory.path = cache
        }

        let cell = map.gridPoint(at: enemy.position)
        let playerCell = player.flatMap { $0.hp > 0 ? map.gridPoint(at: $0.position) : nil }

        if let evadeDirection = Self.evadeDirection(
            from: cell,
            facing: enemy.direction,
            map: map,
            bullets: bullets
        ) {
            memory.state = .evade
            memory.decisionAge = 0
            memories[id] = memory
            return AICommand(direction: evadeDirection, shouldFire: Self.shouldShootPlayer(from: cell, player: playerCell))
        }

        if let powerUp {
            let target = map.gridPoint(at: powerUp.position)
            if Self.isInSeekRange(from: cell, to: target),
               let found = path(to: target, from: cell, map: map, memory: &memory),
               !found.isEmpty {
                memory.state = .seekPowerUp
                let command = followPath(
                    to: target,
                    cell: cell,
                    map: map,
                    enemy: enemy,
                    memory: &memory
                )
                memories[id] = memory
                return command
            }
        }

        if memory.decisionAge >= GameConfig.aiDecisionInterval {
            memory.state = pickState(playerCell: playerCell, from: cell)
            memory.decisionAge = 0
        }

        var command = execute(
            memory.state,
            enemy: enemy,
            cell: cell,
            playerCell: playerCell,
            map: map,
            memory: &memory
        )

        if Self.shouldShootPlayer(from: cell, player: playerCell) {
            if !command.shouldFire, let playerCell, let face = Direction.toward(from: cell, to: playerCell) {
                command.direction = face
            }
            command.shouldFire = true
        }

        memory.lastCell = cell
        memories[id] = memory
        return command
    }

    // MARK: - 决策

    private func pickState(playerCell: GridPoint?, from cell: GridPoint) -> AIState {
        var weights: [(AIState, Int)] = [
            (.patrol, GameConfig.aiPatrolWeight),
            (.huntBase, GameConfig.aiHuntBaseWeight)
        ]
        if let playerCell, cell.manhattanDistance(to: playerCell) <= GameConfig.aiHuntPlayerRangeInTiles {
            weights.append((.huntPlayer, GameConfig.aiHuntPlayerWeight))
        }
        let total = weights.reduce(0) { $0 + $1.1 }
        var ticket = Int.random(in: 0..<max(total, 1))
        for (state, weight) in weights {
            if ticket < weight { return state }
            ticket -= weight
        }
        return .huntBase
    }

    private func execute(
        _ state: AIState,
        enemy: EnemyTank,
        cell: GridPoint,
        playerCell: GridPoint?,
        map: GridMap,
        memory: inout Memory
    ) -> AICommand {
        switch state {
        case .patrol:
            return patrol(enemy: enemy, cell: cell, map: map, memory: &memory)
        case .huntBase:
            return followPath(
                to: map.basePosition,
                cell: cell,
                map: map,
                enemy: enemy,
                memory: &memory
            )
        case .huntPlayer:
            guard let playerCell else {
                return followPath(
                    to: map.basePosition,
                    cell: cell,
                    map: map,
                    enemy: enemy,
                    memory: &memory
                )
            }
            return followPath(
                to: playerCell,
                cell: cell,
                map: map,
                enemy: enemy,
                memory: &memory
            )
        case .evade:
            return AICommand(direction: enemy.direction, shouldFire: false)
        case .seekPowerUp:
            return AICommand(direction: enemy.direction, shouldFire: false)
        }
    }

    private func patrol(enemy: EnemyTank, cell: GridPoint, map: GridMap, memory: inout Memory) -> AICommand {
        let current = enemy.commandedDirection ?? enemy.direction
        let blocked = !canEnter(cell.neighbor(in: current), map: map)
        let arrivedAtNewCell = memory.lastCell != nil && memory.lastCell != cell
        let atJunction = openDirections(from: cell, map: map).count >= 3
        if blocked || (arrivedAtNewCell && atJunction) || enemy.commandedDirection == nil {
            if let next = pickPatrolDirection(from: cell, map: map, avoiding: blocked ? current : nil) {
                return AICommand(direction: next, shouldFire: false)
            }
            return AICommand(direction: nil, shouldFire: false)
        }
        return AICommand(direction: current, shouldFire: false)
    }

    private func pickPatrolDirection(from cell: GridPoint, map: GridMap, avoiding: Direction?) -> Direction? {
        var pool: [Direction] = []
        for direction in Direction.allCases {
            guard direction != avoiding, canEnter(cell.neighbor(in: direction), map: map) else { continue }
            let copies = direction == .down ? GameConfig.aiPatrolDownWeight : GameConfig.aiPatrolSideWeight
            pool.append(contentsOf: repeatElement(direction, count: copies))
        }
        return pool.randomElement()
    }

    private func followPath(
        to goal: GridPoint,
        cell: GridPoint,
        map: GridMap,
        enemy: EnemyTank,
        memory: inout Memory
    ) -> AICommand {
        guard let path = path(to: goal, from: cell, map: map, memory: &memory), path.count >= 2 else {
            return AICommand(direction: nil, shouldFire: false)
        }
        let next = path[1]
        let tile = map.tile(at: next)
        if tile == .brick || tile == .base {
            // 停下来轰开，不能把朝向写进 commandedDirection 否则会往墙上走
            if let face = Direction.toward(from: cell, to: next) {
                enemy.direction = face
            }
            return AICommand(direction: nil, shouldFire: true)
        }
        return AICommand(direction: Direction.toward(from: cell, to: next), shouldFire: false)
    }

    private func path(to goal: GridPoint, from cell: GridPoint, map: GridMap, memory: inout Memory) -> [GridPoint]? {
        if let cache = memory.path,
           cache.goal == goal,
           cache.age < GameConfig.aiPathCacheDuration,
           !cache.path.isEmpty {
            return trimmed(cache.path, current: cell)
        }
        if bfsUsedThisFrame {
            if let cache = memory.path {
                return trimmed(cache.path, current: cell)
            }
            return nil
        }
        bfsUsedThisFrame = true
        let found = GridPathfinder.shortestPath(from: cell, to: goal, map: map)
        memory.path = PathCache(path: found, goal: goal, age: 0)
        return found
    }

    private func trimmed(_ path: [GridPoint], current: GridPoint) -> [GridPoint] {
        if let index = path.firstIndex(of: current) {
            return Array(path[index...])
        }
        return path
    }

    private func canEnter(_ point: GridPoint, map: GridMap) -> Bool {
        GridPathfinder.isPathable(point, goal: point, map: map) && map.tile(at: point) != .brick
    }

    private func openDirections(from cell: GridPoint, map: GridMap) -> [Direction] {
        Direction.allCases.filter { canEnter(cell.neighbor(in: $0), map: map) }
    }

    // MARK: - 感知（只使用玩家位置与可见子弹，不读草丛外的额外状态）

    static func evadeDirection(
        from cell: GridPoint,
        facing: Direction,
        map: GridMap,
        bullets: [Bullet]
    ) -> Direction? {
        let threats = bullets.filter { bullet in
            guard bullet.owner == .player, !bullet.isDestroyed else { return false }
            return isIncoming(bullet, to: cell, map: map)
        }
        guard !threats.isEmpty else { return nil }

        let options = facing.perpendicular.filter { canStep(cell.neighbor(in: $0), map: map) }
        return options.randomElement() ?? facing.perpendicular.first
    }

    static func isIncoming(_ bullet: Bullet, to cell: GridPoint, map: GridMap) -> Bool {
        let bulletCell = map.gridPoint(at: bullet.position)
        let range = GameConfig.aiEvadeRangeInTiles
        switch bullet.direction {
        case .up:
            return bulletCell.col == cell.col
                && bulletCell.row > cell.row
                && bulletCell.row - cell.row <= range
        case .down:
            return bulletCell.col == cell.col
                && bulletCell.row < cell.row
                && cell.row - bulletCell.row <= range
        case .left:
            return bulletCell.row == cell.row
                && bulletCell.col > cell.col
                && bulletCell.col - cell.col <= range
        case .right:
            return bulletCell.row == cell.row
                && bulletCell.col < cell.col
                && cell.col - bulletCell.col <= range
        }
    }

    static func isInSeekRange(from cell: GridPoint, to powerUp: GridPoint) -> Bool {
        cell.manhattanDistance(to: powerUp) <= GameConfig.aiSeekPowerUpRangeInTiles
    }

    static func shouldShootPlayer(from cell: GridPoint, player: GridPoint?) -> Bool {
        guard let player, cell.sharesAxis(with: player) else { return false }
        return cell.manhattanDistance(to: player) <= GameConfig.aiFireRangeInTiles
    }

    private static func canStep(_ point: GridPoint, map: GridMap) -> Bool {
        GridPathfinder.isPathable(point, goal: point, map: map) && map.tile(at: point) != .brick
    }

    // MARK: - Boss

    private func commandBoss(
        _ enemy: EnemyTank,
        dt: TimeInterval,
        map: GridMap,
        player: PlayerTank?
    ) -> AICommand {
        let id = ObjectIdentifier(enemy)
        var memory = memories[id] ?? Memory()
        let command: AICommand
        if let mini = enemy as? MiniBoss {
            command = commandMini(mini, dt: dt, map: map, player: player, memory: &memory)
        } else if let final = enemy as? FinalBoss {
            command = commandFinal(final, dt: dt, map: map, player: player, memory: &memory)
        } else {
            command = AICommand(direction: nil, shouldFire: false)
        }
        memories[id] = memory
        return command
    }

    private func commandMini(
        _ mini: MiniBoss,
        dt: TimeInterval,
        map: GridMap,
        player: PlayerTank?,
        memory: inout Memory
    ) -> AICommand {
        var summon = 0
        if mini.trait == .summoner && mini.phase >= 2 {
            memory.summonAge += dt
            if memory.summonAge >= GameConfig.miniBossSummonInterval {
                memory.summonAge = 0
                summon = 1
            }
        }

        let playerCell = player.flatMap { $0.hp > 0 ? map.gridPoint(at: $0.position) : nil }
        let goal: GridPoint
        if let playerCell, bossDistance(mini, to: playerCell, map: map) <= GameConfig.aiHuntPlayerRangeInTiles {
            goal = playerCell
        } else {
            goal = map.basePosition
        }

        var direction = steer(mini, toward: goal, map: map)
        var shouldFire = shouldBossShoot(mini, player: playerCell, map: map)
        if let face = blockedByDestructible(mini, moving: direction, map: map) {
            mini.direction = face
            direction = nil
            shouldFire = true
        }

        return AICommand(direction: direction, shouldFire: shouldFire, summonCount: summon)
    }

    private func commandFinal(
        _ final: FinalBoss,
        dt: TimeInterval,
        map: GridMap,
        player: PlayerTank?,
        memory: inout Memory
    ) -> AICommand {
        if final.isStunned || final.isWindingUp {
            return AICommand(direction: nil, shouldFire: false)
        }
        if final.isCharging {
            return AICommand(
                direction: final.chargeDirection ?? final.direction,
                shouldFire: false,
                isCharging: true
            )
        }

        var summon = 0
        var shouldFire = false
        if final.phase >= 3 {
            memory.summonAge += dt
            memory.barrageAge += dt
            if memory.summonAge >= GameConfig.finalBossSummonInterval {
                memory.summonAge = 0
                summon = GameConfig.finalBossSummonCount
            }
            if memory.barrageAge >= GameConfig.finalBossBarrageInterval {
                memory.barrageAge = 0
                shouldFire = true
            }
        } else if final.phase == 1 {
            shouldFire = true
        }

        if final.phase == 1 {
            let dir = horizontalPatrol(final, map: map, memory: &memory)
            return AICommand(direction: dir, shouldFire: shouldFire, summonCount: summon)
        }

        if let player, player.hp > 0 {
            if let charge = alignedChargeDirection(final, player: player, map: map) {
                return AICommand(
                    direction: nil,
                    shouldFire: shouldFire,
                    startWindup: charge,
                    summonCount: summon
                )
            }
            if let align = alignmentMove(final, player: player, map: map) {
                return AICommand(direction: align, shouldFire: shouldFire, summonCount: summon)
            }
        }

        let dir = horizontalPatrol(final, map: map, memory: &memory)
        return AICommand(direction: dir, shouldFire: shouldFire, summonCount: summon)
    }

    private func horizontalPatrol(_ tank: Tank, map: GridMap, memory: inout Memory) -> Direction? {
        var dir = memory.patrolDir
        if !canFit(tank, moving: dir, map: map) {
            dir = dir.opposite
            memory.patrolDir = dir
        }
        return canFit(tank, moving: dir, map: map) ? dir : nil
    }

    private func steer(_ tank: Tank, toward goal: GridPoint, map: GridMap) -> Direction? {
        let cell = map.gridPoint(at: tank.position)
        if let preferred = Direction.toward(from: cell, to: goal), canFit(tank, moving: preferred, map: map) {
            return preferred
        }
        return Direction.allCases.first { canFit(tank, moving: $0, map: map) }
    }

    private func canFit(_ tank: Tank, moving direction: Direction, map: GridMap) -> Bool {
        let step = GameConfig.tileSize / 2
        let moved = tank.collisionRect.offsetBy(
            dx: direction.vector.dx * step,
            dy: direction.vector.dy * step
        )
        return CollisionSystem.coveredTiles(moved, map: map).allSatisfy { !map.blocksTank(at: $0) }
    }

    private func blockedByDestructible(_ tank: Tank, moving direction: Direction?, map: GridMap) -> Direction? {
        guard let direction else { return nil }
        let step = GameConfig.tileSize / 2
        let moved = tank.collisionRect.offsetBy(
            dx: direction.vector.dx * step,
            dy: direction.vector.dy * step
        )
        let hits = CollisionSystem.coveredTiles(moved, map: map).contains {
            map.tile(at: $0) == .brick || map.tile(at: $0) == .base
        }
        return hits ? direction : nil
    }

    private func shouldBossShoot(_ tank: Tank, player: GridPoint?, map: GridMap) -> Bool {
        guard let player else { return false }
        return bossSharesAxis(tank, with: player, map: map)
            && bossDistance(tank, to: player, map: map) <= GameConfig.aiFireRangeInTiles
    }

    private func bossSharesAxis(_ tank: Tank, with point: GridPoint, map: GridMap) -> Bool {
        CollisionSystem.coveredTiles(tank.collisionRect, map: map).contains {
            $0.col == point.col || $0.row == point.row
        }
    }

    private func bossDistance(_ tank: Tank, to point: GridPoint, map: GridMap) -> Int {
        CollisionSystem.coveredTiles(tank.collisionRect, map: map)
            .map { $0.manhattanDistance(to: point) }
            .min() ?? Int.max
    }

    private func alignedChargeDirection(_ boss: Tank, player: PlayerTank, map: GridMap) -> Direction? {
        let playerCell = map.gridPoint(at: player.position)
        let covered = CollisionSystem.coveredTiles(boss.collisionRect, map: map)
        let cols = Set(covered.map(\.col))
        let rows = Set(covered.map(\.row))
        if cols.contains(playerCell.col) {
            let midRow = rows.min()! + (rows.max()! - rows.min()!) / 2
            return playerCell.row > midRow ? .down : .up
        }
        if rows.contains(playerCell.row) {
            let midCol = cols.min()! + (cols.max()! - cols.min()!) / 2
            return playerCell.col > midCol ? .right : .left
        }
        return nil
    }

    private func alignmentMove(_ boss: Tank, player: PlayerTank, map: GridMap) -> Direction? {
        let playerCell = map.gridPoint(at: player.position)
        let cell = map.gridPoint(at: boss.position)
        let dCol = playerCell.col - cell.col
        let dRow = playerCell.row - cell.row
        let preferred: Direction
        if abs(dCol) <= abs(dRow) {
            preferred = dCol == 0 ? (dRow > 0 ? .down : .up) : (dCol > 0 ? .right : .left)
        } else {
            preferred = dRow == 0 ? (dCol > 0 ? .right : .left) : (dRow > 0 ? .down : .up)
        }
        if canFit(boss, moving: preferred, map: map) {
            return preferred
        }
        return Direction.allCases.first { canFit(boss, moving: $0, map: map) }
    }
}
