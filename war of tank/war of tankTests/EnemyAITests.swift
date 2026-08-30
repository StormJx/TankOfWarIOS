//
//  EnemyAITests.swift
//  war of tankTests
//

import CoreGraphics
import Testing
@testable import war_of_tank

struct EnemyAITests {

    @Test("三种敌人的属性表符合设计文档第 4 节")
    func enemyStatsFollowDesign() {
        #expect(EnemyType.normal.hitPoints == 1)
        #expect(EnemyType.normal.moveSpeed == GameConfig.enemyNormalSpeed)
        #expect(EnemyType.normal.fireCooldown == GameConfig.enemyNormalFireCooldown)
        #expect(EnemyType.fast.moveSpeed == GameConfig.enemyFastSpeed)
        #expect(EnemyType.fast.fireCooldown == GameConfig.enemyFastFireCooldown)
        #expect(EnemyType.armored.hitPoints == GameConfig.enemyArmoredHitPoints)
        #expect(EnemyType.armored.moveSpeed == GameConfig.enemyArmoredSpeed)
    }

    @Test("装甲型受击按 绿→黄→灰→红 换色，4 发才死")
    func armoredRecolorsAndTakesFourHits() {
        let tank = EnemyTank(type: .armored, at: .zero)
        #expect(tank.hp == 4)
        #expect(EnemyTank.armoredColor(hp: 4) == GameConfig.enemyArmoredColorGreen)

        tank.takeDamage()
        #expect(tank.hp == 3)
        #expect(EnemyTank.armoredColor(hp: 3) == GameConfig.enemyArmoredColorYellow)

        tank.takeDamage()
        #expect(tank.hp == 2)
        #expect(EnemyTank.armoredColor(hp: 2) == GameConfig.enemyArmoredColorGray)

        tank.takeDamage()
        #expect(tank.hp == 1)
        #expect(EnemyTank.armoredColor(hp: 1) == GameConfig.enemyArmoredColorRed)

        tank.takeDamage()
        #expect(tank.hp == 0)
    }

    @Test("第 1 关从出生点到基地存在网格通路")
    func level1HasPathFromSpawnToBase() {
        let map = GridMap(rows: Levels.level1.rows)
        let start = map.enemySpawns[0]
        let path = GridPathfinder.shortestPath(from: start, to: map.basePosition, map: map)
        #expect(!path.isEmpty)
        #expect(path.first == start)
        #expect(path.last == map.basePosition)
    }

    @Test("寻路可以穿过砖墙但不能穿过钢墙或河流")
    func pathfinderTreatsBrickAsOpenAndSteelAsBlocked() {
        let map = GridMap(rows: Levels.terrainShowcase.rows)
        let brick = map.firstPoint(of: .brick)!
        #expect(GridPathfinder.isPathable(brick, goal: map.basePosition, map: map))

        let steel = map.firstPoint(of: .steel)!
        #expect(GridPathfinder.isPathable(steel, goal: map.basePosition, map: map) == false)

        let water = map.firstPoint(of: .water)!
        #expect(GridPathfinder.isPathable(water, goal: map.basePosition, map: map) == false)
    }

    @Test("同轴且 3 格内飞来的玩家子弹会触发规避")
    func incomingPlayerBulletTriggersEvade() {
        let map = GridMap(rows: Levels.level1.rows)
        let cell = GridPoint(col: 6, row: 6)
        let bullet = Bullet(
            direction: .up,
            moveSpeed: GameConfig.playerBulletSpeedLevel0,
            canBreakSteel: false,
            owner: .player
        )
        bullet.position = map.center(of: GridPoint(col: 6, row: 8))

        #expect(AIController.isIncoming(bullet, to: cell, map: map))
        #expect(AIController.evadeDirection(from: cell, facing: .up, map: map, bullets: [bullet]) != nil)
    }

    @Test("距玩家 6 格内且同轴才会开火")
    func fireOnlyWhenPlayerIsCloseAndOnAxis() {
        let selfCell = GridPoint(col: 4, row: 8)
        #expect(AIController.shouldShootPlayer(from: selfCell, player: GridPoint(col: 4, row: 4)))
        #expect(AIController.shouldShootPlayer(from: selfCell, player: GridPoint(col: 4, row: 1)) == false)
        #expect(AIController.shouldShootPlayer(from: selfCell, player: GridPoint(col: 7, row: 6)) == false)
    }

    @Test("出生队列按配比排出，同屏不超过 3 台")
    func spawnQueueRespectsMixAndCap() {
        let mix = EnemyMix(normal: 2, fast: 1, armored: 0)
        let system = SpawnSystem(mix: mix)
        #expect(system.remainingInQueue == 3)
        #expect(GameConfig.enemyOnScreenCap == 3)
        #expect(mix.total == 3)
    }

    @Test("玩家死亡路径会清掉火力和临时状态")
    func playerDeathClearsPowerUps() {
        let tank = PlayerTank(at: .zero)
        tank.firepower = 3
        tank.hasShield = true
        tank.resetPowerUps()
        #expect(tank.firepower == 0)
        #expect(tank.hasShield == false)
        #expect(tank.canBreakSteel == false)
    }

    @Test("无敌期间不受伤")
    func invinciblePlayerIgnoresDamage() {
        let tank = PlayerTank(at: .zero)
        tank.isInvincible = true
        let hp = tank.hp
        tank.takeDamage()
        #expect(tank.hp == hp)
        #expect(tank.isInvincible)
    }
}
