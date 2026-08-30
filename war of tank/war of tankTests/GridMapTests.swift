//
//  GridMapTests.swift
//  war of tankTests
//

import CoreGraphics
import Testing
@testable import war_of_tank

struct GridMapTests {

    private func makeLevel1Map() -> GridMap {
        GridMap(rows: Levels.level1.rows)
    }

    @Test("全部 169 个 tile 的坐标互转都能原样回到出发点")
    func gridPointRoundTripCoversEveryTile() {
        let map = makeLevel1Map()

        for row in 0..<GameConfig.gridCount {
            for col in 0..<GameConfig.gridCount {
                let point = GridPoint(col: col, row: row)
                #expect(map.gridPoint(at: map.center(of: point)) == point)
            }
        }
    }

    @Test("四个角的中心坐标符合左下角原点的换算公式")
    func cornerCentersMatchFormula() {
        let map = makeLevel1Map()
        let last = GameConfig.gridCount - 1
        let half = GameConfig.tileSize / 2
        let far = GameConfig.sceneSide - half

        #expect(map.center(of: GridPoint(col: 0, row: 0)) == CGPoint(x: half, y: far))
        #expect(map.center(of: GridPoint(col: last, row: 0)) == CGPoint(x: far, y: far))
        #expect(map.center(of: GridPoint(col: 0, row: last)) == CGPoint(x: half, y: half))
        #expect(map.center(of: GridPoint(col: last, row: last)) == CGPoint(x: far, y: half))
    }

    @Test("tile 中心以外的任意点也落在正确的格子里")
    func gridPointHandlesOffCenterAndOutOfBounds() {
        let map = makeLevel1Map()
        let last = GameConfig.gridCount - 1

        // 紧贴 tile 边界的内侧
        #expect(map.gridPoint(at: CGPoint(x: 0, y: GameConfig.sceneSide)) == GridPoint(col: 0, row: 0))
        #expect(map.gridPoint(at: CGPoint(x: GameConfig.tileSize, y: GameConfig.sceneSide - GameConfig.tileSize))
                == GridPoint(col: 1, row: 1))

        // 越界要夹回场内，避免调用方拿到负数下标
        #expect(map.gridPoint(at: CGPoint(x: -GameConfig.sceneSide, y: GameConfig.sceneSide * 2))
                == GridPoint(col: 0, row: 0))
        #expect(map.gridPoint(at: CGPoint(x: GameConfig.sceneSide * 2, y: -GameConfig.sceneSide))
                == GridPoint(col: last, row: last))
    }

    @Test("第 1 关地图恰好 13x13")
    func level1HasSquareShape() {
        #expect(Levels.level1.rows.count == GameConfig.gridCount)
        for row in Levels.level1.rows {
            #expect(row.count == GameConfig.gridCount)
        }
    }

    @Test("第 1 关解析出的基地、玩家出生点与敌方出生点都在设计位置")
    func level1SpawnsAreParsed() {
        let map = makeLevel1Map()

        #expect(map.basePosition == GameConfig.baseGridPoint)
        #expect(map.playerSpawn == GameConfig.defaultPlayerSpawn)
        #expect(map.enemySpawns.count == 3)
        #expect(map.enemySpawns.allSatisfy { $0.row == 0 })

        // 出生点渲染成空地，不能挡住坦克
        #expect(map.blocksTank(at: map.playerSpawn) == false)
        #expect(map.enemySpawns.allSatisfy { map.blocksTank(at: $0) == false })
    }

    @Test("训练场没有钢墙，敌人配比与总量一致")
    func level1MatchesDesignTheme() {
        let map = makeLevel1Map()

        #expect(map.firstPoint(of: .steel) == nil)
        #expect(Levels.level1.enemyMix.total == Levels.level1.totalEnemies)
        #expect(Levels.level1.bossType == nil)
    }

    @Test("坦克与子弹的阻挡规则符合设计文档第 2 节")
    func blockingRulesFollowDesign() {
        let map = GridMap(rows: Levels.terrainShowcase.rows)

        let brick = map.firstPoint(of: .brick)!
        let steel = map.firstPoint(of: .steel)!
        let water = map.firstPoint(of: .water)!
        let grass = map.firstPoint(of: .grass)!
        let ice = map.firstPoint(of: .ice)!
        let base = map.basePosition

        for blocking in [brick, steel, water, base] {
            #expect(map.blocksTank(at: blocking))
        }
        for passable in [grass, ice] {
            #expect(map.blocksTank(at: passable) == false)
        }

        for blocking in [brick, steel, base] {
            #expect(map.blocksBullet(at: blocking))
        }
        // 子弹能飞过河流与草丛
        for passable in [water, grass, ice] {
            #expect(map.blocksBullet(at: passable) == false)
        }
    }

    @Test("砖墙任意子弹可摧毁，钢墙只有 Lv3 子弹能打掉")
    func destroyRulesFollowFirepower() {
        let map = GridMap(rows: Levels.terrainShowcase.rows)

        let brick = map.firstPoint(of: .brick)!
        #expect(map.destroyTile(at: brick, byLevel3Bullet: false))
        #expect(map.tile(at: brick) == .empty)
        // 已经空了，再打一次不应该再报「真的摧毁了」
        #expect(map.destroyTile(at: brick, byLevel3Bullet: true) == false)

        let steel = map.firstPoint(of: .steel)!
        #expect(map.destroyTile(at: steel, byLevel3Bullet: false) == false)
        #expect(map.tile(at: steel) == .steel)
        #expect(map.destroyTile(at: steel, byLevel3Bullet: true))
        #expect(map.tile(at: steel) == .empty)

        // 河流、草丛、冰面、基地都不该被 destroyTile 改动
        let water = map.firstPoint(of: .water)!
        #expect(map.destroyTile(at: water, byLevel3Bullet: true) == false)
        #expect(map.destroyTile(at: map.basePosition, byLevel3Bullet: true) == false)
    }

    @Test("越界格子一律当作阻挡，不会越界崩溃")
    func outOfBoundsIsTreatedAsBlocking() {
        let map = makeLevel1Map()
        let outside = GridPoint(col: GameConfig.gridCount, row: -1)

        #expect(map.isInside(outside) == false)
        #expect(map.blocksTank(at: outside))
        #expect(map.blocksBullet(at: outside))
        #expect(map.destroyTile(at: outside, byLevel3Bullet: true) == false)
    }
}
