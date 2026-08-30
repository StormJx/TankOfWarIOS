//
//  CollisionSystemTests.swift
//  war of tankTests
//

import CoreGraphics
import Testing
@testable import war_of_tank

struct CollisionSystemTests {

    private func makeLevel1Map() -> GridMap {
        GridMap(rows: Levels.level1.rows)
    }

    private func makeShowcaseMap() -> GridMap {
        GridMap(rows: Levels.terrainShowcase.rows)
    }

    @Test("贴墙时裁剪为 0，且不会先改坦克坐标")
    func touchingWallClipsToZeroWithoutMovingTank() {
        let map = makeLevel1Map()
        let spawn = map.center(of: map.playerSpawn)
        let tank = PlayerTank(at: spawn)

        let clipped = CollisionSystem.resolveTankMove(
            tank: tank,
            desiredDelta: CGPoint(x: GameConfig.tileSize, y: 0),
            map: map,
            others: []
        )

        #expect(clipped == .zero)
        #expect(tank.position == spawn)
    }

    @Test("离墙还有空隙时只允许走到贴合，多出来的位移被丢掉")
    func approachingWallIsClippedToContact() {
        let map = makeLevel1Map()
        let spawn = map.center(of: map.playerSpawn)
        let gap: CGFloat = 2
        let tank = PlayerTank(at: CGPoint(x: spawn.x - gap, y: spawn.y))

        let clipped = CollisionSystem.resolveTankMove(
            tank: tank,
            desiredDelta: CGPoint(x: GameConfig.tileSize, y: 0),
            map: map,
            others: []
        )

        #expect(clipped.x == gap)
        #expect(clipped.y == 0)
        #expect(tank.position.x == spawn.x - gap)
    }

    @Test("空地上的位移不被裁剪")
    func openGroundKeepsFullDelta() {
        let map = makeLevel1Map()
        let tank = PlayerTank(at: map.center(of: GridPoint(col: 0, row: 1)))
        let desired = CGPoint(x: GameConfig.alignmentGranularity, y: 0)

        let clipped = CollisionSystem.resolveTankMove(
            tank: tank,
            desiredDelta: desired,
            map: map,
            others: []
        )

        #expect(clipped == desired)
    }

    @Test("贴着场景边界推不会推出场外")
    func worldBoundsClipTank() {
        let map = makeLevel1Map()
        let half = GameConfig.tileSize / 2
        let tank = PlayerTank(at: CGPoint(x: half, y: GameConfig.sceneSide - half))

        let left = CollisionSystem.resolveTankMove(
            tank: tank,
            desiredDelta: CGPoint(x: -GameConfig.tileSize, y: 0),
            map: map,
            others: []
        )
        let up = CollisionSystem.resolveTankMove(
            tank: tank,
            desiredDelta: CGPoint(x: 0, y: GameConfig.tileSize),
            map: map,
            others: []
        )

        #expect(left == .zero)
        #expect(up == .zero)
    }

    @Test("坦克之间互相阻挡")
    func tanksBlockEachOther() {
        let map = makeLevel1Map()
        let a = PlayerTank(at: map.center(of: GridPoint(col: 0, row: 1)))
        let b = PlayerTank(at: map.center(of: GridPoint(col: 1, row: 1)))

        let clipped = CollisionSystem.resolveTankMove(
            tank: a,
            desiredDelta: CGPoint(x: GameConfig.tileSize, y: 0),
            map: map,
            others: [a, b]
        )

        #expect(clipped == .zero)
    }

    @Test("子弹能飞过河流和草丛，打到砖墙或越界则命中")
    func bulletHitOrderMatchesDesign() {
        let map = makeShowcaseMap()
        let bullet = Bullet(direction: .right, moveSpeed: GameConfig.playerBulletSpeedLevel0, canBreakSteel: false, owner: .player)

        bullet.position = map.center(of: map.firstPoint(of: .water)!)
        #expect(isNone(CollisionSystem.bulletHitTest(bullet: bullet, map: map, tanks: [], bullets: [])))

        bullet.position = map.center(of: map.firstPoint(of: .grass)!)
        #expect(isNone(CollisionSystem.bulletHitTest(bullet: bullet, map: map, tanks: [], bullets: [])))

        let brick = map.firstPoint(of: .brick)!
        bullet.position = map.center(of: brick)
        #expect(isTerrain(CollisionSystem.bulletHitTest(bullet: bullet, map: map, tanks: [], bullets: []), brick))

        let steel = map.firstPoint(of: .steel)!
        bullet.position = map.center(of: steel)
        #expect(isTerrain(CollisionSystem.bulletHitTest(bullet: bullet, map: map, tanks: [], bullets: []), steel))

        bullet.position = CGPoint(x: -1, y: GameConfig.tileSize)
        #expect(isOutOfBounds(CollisionSystem.bulletHitTest(bullet: bullet, map: map, tanks: [], bullets: [])))
    }

    @Test("一次跳过整面砖墙会漏检，按 4pt 步长推进则能打中")
    func substepPreventsTunnelingThroughBrick() {
        let map = makeLevel1Map()
        let brick = firstIsolatedBrick(in: map)
        let brickRectMinX = map.center(of: brick).x - GameConfig.tileSize / 2
        let y = map.center(of: brick).y
        let startX = brickRectMinX - 1
        let jump = GameConfig.tileSize + GameConfig.bulletSize

        let skipped = Bullet(direction: .right, moveSpeed: 200, canBreakSteel: false, owner: .player)
        skipped.position = CGPoint(x: startX + jump, y: y)
        #expect(isNone(CollisionSystem.bulletHitTest(bullet: skipped, map: map, tanks: [], bullets: [])))

        let stepped = Bullet(direction: .right, moveSpeed: 200, canBreakSteel: false, owner: .player)
        stepped.position = CGPoint(x: startX, y: y)
        var hitBrick = false
        let steps = max(1, Int(ceil(jump / GameConfig.bulletMaxStep)))
        let stepLength = jump / CGFloat(steps)
        for _ in 0..<steps {
            stepped.position.x += stepLength
            if isTerrain(
                CollisionSystem.bulletHitTest(bullet: stepped, map: map, tanks: [], bullets: []),
                brick
            ) {
                hitBrick = true
                break
            }
        }
        #expect(hitBrick)
    }

    private func isNone(_ result: HitResult) -> Bool {
        if case .none = result { return true }
        return false
    }

    private func isOutOfBounds(_ result: HitResult) -> Bool {
        if case .outOfBounds = result { return true }
        return false
    }

    private func isTerrain(_ result: HitResult, _ point: GridPoint) -> Bool {
        if case .terrain(let hit) = result { return hit == point }
        return false
    }

    /// 右侧必须是空地，否则一次跳过整格会落到相邻砖上，测不到“漏检”。
    private func firstIsolatedBrick(in map: GridMap) -> GridPoint {
        for row in 0..<GameConfig.gridCount {
            for col in 0..<(GameConfig.gridCount - 1) {
                let point = GridPoint(col: col, row: row)
                let right = GridPoint(col: col + 1, row: row)
                if map.tile(at: point) == .brick, map.tile(at: right) == .empty {
                    return point
                }
            }
        }
        return GridPoint(col: 2, row: 2)
    }
}
