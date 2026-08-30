//
//  CollisionSystem.swift
//  war of tank
//

import CoreGraphics

enum HitResult {
    case none
    case outOfBounds
    case terrain(GridPoint)
    case tank(Tank)
    case bullet(Bullet)
}

struct ChargeMoveResult {
    let delta: CGPoint
    let crushed: [GridPoint]
    let hitSolid: Bool
    let hitPlayer: PlayerTank?
}

enum CollisionSystem {

    /// 先裁剪再移动：返回值才是本帧真正落地的位移，调用方不得先改 position 再弹回
    static func resolveTankMove(
        tank: Tank,
        desiredDelta: CGPoint,
        map: GridMap,
        others: [Tank]
    ) -> CGPoint {
        var dx = desiredDelta.x
        var dy = desiredDelta.y
        if dx != 0 {
            dx = clip(
                tank: tank,
                delta: dx,
                horizontal: true,
                map: map,
                others: others
            )
        }
        if dy != 0 {
            dy = clip(
                tank: tank,
                delta: dy,
                horizontal: false,
                map: map,
                others: others
            )
        }
        return CGPoint(x: dx, y: dy)
    }

    /// 冲撞把砖墙当可碾过，钢/河/基地/边界仍裁剪
    static func resolveChargeMove(
        tank: Tank,
        desiredDelta: CGPoint,
        map: GridMap,
        others: [Tank]
    ) -> ChargeMoveResult {
        var dx = desiredDelta.x
        var dy = desiredDelta.y
        if dx != 0 {
            dx = clipCharge(tank: tank, delta: dx, horizontal: true, map: map, others: others)
        }
        if dy != 0 {
            dy = clipCharge(tank: tank, delta: dy, horizontal: false, map: map, others: others)
        }

        let dest = tank.collisionRect.offsetBy(dx: dx, dy: dy)
        var crushed: [GridPoint] = []
        for point in coveredTiles(dest, map: map) where map.tile(at: point) == .brick {
            crushed.append(point)
        }

        let wantedMove = abs(desiredDelta.x) > GameConfig.collisionEpsilon
            || abs(desiredDelta.y) > GameConfig.collisionEpsilon
        let movedLess = abs(dx - desiredDelta.x) > GameConfig.collisionEpsilon
            || abs(dy - desiredDelta.y) > GameConfig.collisionEpsilon
        let hitSolid = wantedMove && (movedLess || (abs(dx) < GameConfig.collisionEpsilon && abs(dy) < GameConfig.collisionEpsilon))

        let hitPlayer = others.compactMap { $0 as? PlayerTank }.first { player in
            player.hp > 0 && dest.intersects(player.collisionRect)
        }

        return ChargeMoveResult(delta: CGPoint(x: dx, y: dy), crushed: crushed, hitSolid: hitSolid, hitPlayer: hitPlayer)
    }

    static func coveredTiles(_ rect: CGRect, map: GridMap) -> [GridPoint] {
        tilesOverlapping(rect, map: map)
    }

    static func bulletHitTest(
        bullet: Bullet,
        map: GridMap,
        tanks: [Tank],
        bullets: [Bullet]
    ) -> HitResult {
        let position = bullet.position
        if !isInsideBattlefield(position) {
            return .outOfBounds
        }

        let tilePoint = map.gridPoint(at: position)
        if map.blocksBullet(at: tilePoint) {
            if bullet.canPierceBrick && map.tile(at: tilePoint) == .brick {
                // 敌人吃星星后子弹穿过砖墙，不在这里截停
            } else {
                return .terrain(tilePoint)
            }
        }

        let bulletRect = bullet.collisionRect
        for tank in tanks where tank.hp > 0 && !tank.isInvincible && tank.faction != bullet.owner {
            if bulletRect.intersects(tank.collisionRect) {
                return .tank(tank)
            }
        }

        for other in bullets where other !== bullet && !other.isDestroyed && other.owner != bullet.owner {
            if bulletRect.intersects(other.collisionRect) {
                return .bullet(other)
            }
        }

        return .none
    }

    // MARK: - 坦克轴向裁剪

    private static func clip(
        tank: Tank,
        delta: CGFloat,
        horizontal: Bool,
        map: GridMap,
        others: [Tank]
    ) -> CGFloat {
        let current = tank.collisionRect
        var allowed = clipAgainstWorldBounds(
            current: current,
            delta: delta,
            horizontal: horizontal
        )

        let clippedCandidate = horizontal
            ? current.offsetBy(dx: allowed, dy: 0)
            : current.offsetBy(dx: 0, dy: allowed)

        for point in tilesOverlapping(clippedCandidate, map: map) where map.blocksTank(at: point) {
            let blocker = tileRect(at: point, map: map)
            allowed = clipAgainst(
                current: current,
                blocker: blocker,
                delta: allowed,
                horizontal: horizontal
            )
        }

        for other in others where other !== tank && other.hp > 0 {
            allowed = clipAgainst(
                current: current,
                blocker: other.collisionRect,
                delta: allowed,
                horizontal: horizontal
            )
        }

        if abs(allowed) < GameConfig.collisionEpsilon {
            return 0
        }
        return allowed
    }

    private static func clipCharge(
        tank: Tank,
        delta: CGFloat,
        horizontal: Bool,
        map: GridMap,
        others: [Tank]
    ) -> CGFloat {
        let current = tank.collisionRect
        var allowed = clipAgainstWorldBounds(
            current: current,
            delta: delta,
            horizontal: horizontal
        )

        let clippedCandidate = horizontal
            ? current.offsetBy(dx: allowed, dy: 0)
            : current.offsetBy(dx: 0, dy: allowed)

        for point in tilesOverlapping(clippedCandidate, map: map) where blocksCharge(map.tile(at: point)) {
            let blocker = tileRect(at: point, map: map)
            allowed = clipAgainst(
                current: current,
                blocker: blocker,
                delta: allowed,
                horizontal: horizontal
            )
        }

        for other in others where other !== tank && other.hp > 0 && !(other is PlayerTank) {
            allowed = clipAgainst(
                current: current,
                blocker: other.collisionRect,
                delta: allowed,
                horizontal: horizontal
            )
        }

        if abs(allowed) < GameConfig.collisionEpsilon {
            return 0
        }
        return allowed
    }

    private static func blocksCharge(_ tile: TileType) -> Bool {
        switch tile {
        case .steel, .water, .base:
            return true
        case .brick, .empty, .grass, .ice:
            return false
        }
    }

    private static func clipAgainstWorldBounds(
        current: CGRect,
        delta: CGFloat,
        horizontal: Bool
    ) -> CGFloat {
        let side = GameConfig.sceneSide
        if horizontal {
            if delta > 0 {
                return min(delta, max(0, side - current.maxX))
            }
            if delta < 0 {
                return max(delta, min(0, -current.minX))
            }
        } else {
            if delta > 0 {
                return min(delta, max(0, side - current.maxY))
            }
            if delta < 0 {
                return max(delta, min(0, -current.minY))
            }
        }
        return 0
    }

    private static func clipAgainst(
        current: CGRect,
        blocker: CGRect,
        delta: CGFloat,
        horizontal: Bool
    ) -> CGFloat {
        let candidate = horizontal
            ? current.offsetBy(dx: delta, dy: 0)
            : current.offsetBy(dx: 0, dy: delta)
        guard candidate.intersects(blocker) else { return delta }

        if horizontal {
            if delta > 0 {
                return min(delta, max(0, blocker.minX - current.maxX))
            }
            if delta < 0 {
                return max(delta, min(0, blocker.maxX - current.minX))
            }
        } else {
            if delta > 0 {
                return min(delta, max(0, blocker.minY - current.maxY))
            }
            if delta < 0 {
                return max(delta, min(0, blocker.maxY - current.minY))
            }
        }
        return 0
    }

    /// 用 GridMap.gridPoint 取覆盖到的格子，避免在碰撞里手写行列公式
    private static func tilesOverlapping(_ rect: CGRect, map: GridMap) -> [GridPoint] {
        let inset = GameConfig.collisionEpsilon
        guard rect.width > inset * 2, rect.height > inset * 2 else { return [] }

        let a = map.gridPoint(at: CGPoint(x: rect.minX + inset, y: rect.minY + inset))
        let b = map.gridPoint(at: CGPoint(x: rect.maxX - inset, y: rect.maxY - inset))
        let cols = min(a.col, b.col)...max(a.col, b.col)
        let rows = min(a.row, b.row)...max(a.row, b.row)

        var points: [GridPoint] = []
        for row in rows {
            for col in cols {
                points.append(GridPoint(col: col, row: row))
            }
        }
        return points
    }

    private static func tileRect(at point: GridPoint, map: GridMap) -> CGRect {
        let center = map.center(of: point)
        let half = GameConfig.tileSize / 2
        return CGRect(
            x: center.x - half,
            y: center.y - half,
            width: GameConfig.tileSize,
            height: GameConfig.tileSize
        )
    }

    private static func isInsideBattlefield(_ position: CGPoint) -> Bool {
        let side = GameConfig.sceneSide
        return position.x >= 0
            && position.x <= side
            && position.y >= 0
            && position.y <= side
    }
}
