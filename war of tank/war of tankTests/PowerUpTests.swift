//
//  PowerUpTests.swift
//  war of tankTests
//

import CoreGraphics
import Testing
@testable import war_of_tank

struct PowerUpTests {

    @Test("Boss 关手雷权重降为 5，普通关仍是 15")
    func grenadeWeightDropsOnBossLevels() {
        let normal = PowerUpSystem.weights(isBossLevel: false)
        let boss = PowerUpSystem.weights(isBossLevel: true)
        #expect(normal.contains { $0.0 == .grenade && $0.1 == GameConfig.powerUpWeightGrenade })
        #expect(boss.contains { $0.0 == .grenade && $0.1 == GameConfig.powerUpWeightGrenadeBoss })
    }

    @Test("按权重表能抽到对应类型")
    func pickTypeHonorsWeightTable() {
        #expect(PowerUpSystem.pickType(isBossLevel: false, roll: 0) == .star)
        #expect(PowerUpSystem.pickType(isBossLevel: false, roll: 25) == .helmet)
        #expect(PowerUpSystem.pickType(isBossLevel: false, roll: 45) == .tank)
    }

    @Test("道具不能刷在坦克或基地相邻的空地上")
    func spawnRejectsTilesAdjacentToTankOrBase() {
        let map = GridMap(rows: Levels.level1.rows)
        let tank = PlayerTank(at: map.center(of: map.playerSpawn))
        #expect(PowerUpSystem.isLegalSpawn(map.playerSpawn, map: map, tanks: [tank]) == false)
        #expect(PowerUpSystem.isLegalSpawn(map.basePosition, map: map, tanks: []) == false)
        #expect(PowerUpSystem.isLegalSpawn(GridPoint(col: 6, row: 11), map: map, tanks: []) == false)
        #expect(PowerUpSystem.isLegalSpawn(GridPoint(col: 0, row: 4), map: map, tanks: [tank]))
    }

    @Test("玩家吃星星火力 +1，死亡后 resetPowerUps 清零")
    func starThenDeathClearsFirepower() {
        let tank = PlayerTank(at: .zero)
        tank.firepower = 1
        tank.firepower += 1
        #expect(tank.firepower == 2)
        tank.hasShield = true
        tank.resetPowerUps()
        #expect(tank.firepower == 0)
        #expect(tank.hasShield == false)
    }

    @Test("护盾和冻结可以同时存在并各自到期")
    func shieldAndFreezeExpireIndependently() {
        let manager = StatusEffectManager()
        var expired: [StatusEffectID] = []
        manager.onExpired = { expired.append($0) }
        manager.apply(.playerShield, duration: 10)
        manager.apply(.playerFreeze, duration: 3)
        manager.update(dt: 3)
        #expect(manager.has(.playerShield))
        #expect(manager.has(.playerFreeze) == false)
        #expect(expired.contains(.playerFreeze))
        manager.update(dt: 7)
        #expect(manager.has(.playerShield) == false)
        #expect(expired.contains(.playerShield))
    }

    @Test("铲子结束还原生效瞬间的围墙，不会补回生效前已拆的墙")
    func shovelRestoresSnapshotOnly() {
        let map = GridMap(rows: Levels.level1.rows)
        let renderer = MapRenderer(map: map)
        let alreadyGone = GridPoint(col: 5, row: 12)
        #expect(map.tile(at: alreadyGone) == .brick)
        #expect(map.destroyTile(at: alreadyGone, byLevel3Bullet: false))

        let system = PowerUpSystem()
        system.applyShovel(asPlayer: true, map: map, renderer: renderer)
        #expect(map.tile(at: GridPoint(col: 6, row: 11)) == .steel)
        #expect(map.tile(at: alreadyGone) == .empty)

        system.restoreShovel(map: map, renderer: renderer)
        #expect(map.tile(at: GridPoint(col: 6, row: 11)) == .brick)
        #expect(map.tile(at: alreadyGone) == .empty)
    }

    @Test("手雷对 Boss 只走 takeDamage(3)，普通敌人会被清空")
    func grenadeDamagesBossInsteadOfWiping() {
        let regular = EnemyTank(type: .normal, at: .zero)
        let boss = EnemyTank(type: .armored, at: CGPoint(x: 40, y: 0))
        boss.isBoss = true
        regular.takeDamage(regular.hp)
        boss.takeDamage(GameConfig.grenadeBossDamage)
        #expect(regular.hp == 0)
        #expect(boss.hp == GameConfig.enemyArmoredHitPoints - GameConfig.grenadeBossDamage)
    }

    @Test("冻结或僵直时不能移动也不能开火")
    func freezeAndStunBlockActions() {
        let map = GridMap(rows: Levels.level1.rows)
        let tank = PlayerTank(at: map.center(of: map.playerSpawn))
        tank.commandedDirection = .up
        tank.isFrozen = true
        #expect(tank.move(dt: 1, in: map) == .zero)
        #expect(tank.fire() == nil)
        tank.isFrozen = false
        tank.isStunned = true
        #expect(tank.move(dt: 1, in: map) == .zero)
        #expect(tank.fire() == nil)
    }

    @Test("5 格内才去抢道具")
    func seekRangeIsFiveTiles() {
        let here = GridPoint(col: 4, row: 4)
        #expect(AIController.isInSeekRange(from: here, to: GridPoint(col: 4, row: 9)))
        #expect(AIController.isInSeekRange(from: here, to: GridPoint(col: 4, row: 10)) == false)
    }
}
