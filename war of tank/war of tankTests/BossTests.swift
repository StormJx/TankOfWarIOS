//
//  BossTests.swift
//  war of tankTests
//

import CoreGraphics
import SpriteKit
import Testing
@testable import war_of_tank

@Suite(.serialized)
struct BossTests {

    @Test("小 Boss 占 2x2，大 Boss 占 3x3，碰撞盒与视觉尺寸一致")
    func footprintMatchesCollisionBox() {
        let mini = MiniBoss(at: .zero, trait: .none)
        #expect(mini.size.width == GameConfig.tileSize * 2)
        #expect(mini.collisionRect.width == mini.size.width)
        #expect(mini.collisionRect.height == mini.size.height)
        #expect(mini.hp == GameConfig.miniBossHitPoints)
        #expect(mini.isBoss)
        #expect(mini.score == GameConfig.miniBossScore)

        let final = FinalBoss(at: .zero)
        #expect(final.size.width == GameConfig.tileSize * 3)
        #expect(final.collisionRect.width == final.size.width)
        #expect(final.hp == GameConfig.finalBossHitPoints)
        #expect(final.score == GameConfig.finalBossScore)
    }

    @Test("小 Boss 半血后进入阶段 2 并改为三向散射")
    func miniBossPhasesAndScatter() {
        let mini = MiniBoss(at: .zero, trait: .none)
        #expect(mini.phase == 1)
        #expect(mini.volleyTravels().count == 1)
        mini.takeDamage(4)
        #expect(mini.hp == 4)
        #expect(mini.phase == 2)
        #expect(mini.volleyTravels().count == 3)
        #expect(mini.moveSpeed == GameConfig.miniBossSpeed * GameConfig.miniBossPhase2SpeedMultiplier)
    }

    @Test("L6 小 Boss 移速 +20%，L9 带召唤特质")
    func miniBossTraits() {
        let swift = MiniBoss(at: .zero, trait: .swift)
        #expect(swift.moveSpeed == GameConfig.miniBossSpeed * GameConfig.miniBossSwiftSpeedMultiplier)
        let summoner = MiniBoss(at: .zero, trait: .summoner)
        #expect(summoner.trait == .summoner)
    }

    @Test("大 Boss 三相与眩晕双倍伤害")
    func finalBossPhasesAndStunDamage() {
        let boss = FinalBoss(at: .zero)
        #expect(boss.phase == 1)
        boss.takeDamage(7)
        #expect(boss.hp == 13)
        #expect(boss.phase == 2)
        boss.takeDamage(7)
        #expect(boss.hp == 6)
        #expect(boss.phase == 3)

        let stunned = FinalBoss(at: .zero)
        stunned.isStunned = true
        stunned.takeDamage(1)
        #expect(stunned.hp == GameConfig.finalBossHitPoints - GameConfig.finalBossStunDamageMultiplier)
    }

    @Test("手雷对 Boss 只掉 3 血")
    func grenadeCapsBossDamage() {
        let mini = MiniBoss(at: .zero, trait: .none)
        mini.takeDamage(GameConfig.grenadeBossDamage)
        #expect(mini.hp == GameConfig.miniBossHitPoints - GameConfig.grenadeBossDamage)
        let final = FinalBoss(at: .zero)
        final.takeDamage(GameConfig.grenadeBossDamage)
        #expect(final.hp == GameConfig.finalBossHitPoints - GameConfig.grenadeBossDamage)
    }

    @Test("计时器只减速小 Boss，大 Boss 不受影响")
    func timerSlowsMiniButIgnoresFinal() {
        let mini = MiniBoss(at: .zero, trait: .none)
        let base = mini.moveSpeed
        mini.isSlowed = true
        mini.refreshSpeed()
        #expect(mini.moveSpeed == base * GameConfig.miniBossTimerSlowFactor)
        #expect(mini.canMove)
        #expect(mini.canFire)

        let final = FinalBoss(at: .zero)
        let before = final.moveSpeed
        final.isSlowed = true
        final.refreshSpeed()
        #expect(final.moveSpeed == before)
        #expect(final.canMove)
    }

    @Test("冲撞碾碎砖墙，钢墙会挡住")
    func chargeCrushesBrickNotSteel() {
        let map = GridMap(rows: Levels.level10.rows)
        guard let origin = map.firstOpenFootprint(tiles: GameConfig.finalBossFootprintTiles) else {
            Issue.record("第 10 关放不下大 Boss")
            return
        }
        let boss = FinalBoss(at: map.centerOfFootprint(origin: origin, tiles: GameConfig.finalBossFootprintTiles))
        let covered = CollisionSystem.coveredTiles(boss.collisionRect, map: map)
        let maxCol = covered.map(\.col).max() ?? origin.col
        let row = covered.map(\.row).min() ?? origin.row
        let brick = GridPoint(col: maxCol + 1, row: row)
        let steel = GridPoint(col: maxCol + 2, row: row)
        map.setTile(.brick, at: brick)
        map.setTile(.steel, at: steel)
        let result = CollisionSystem.resolveChargeMove(
            tank: boss,
            desiredDelta: CGPoint(x: GameConfig.tileSize * 4, y: 0),
            map: map,
            others: []
        )
        #expect(result.crushed.contains(brick))
        #expect(result.hitSolid)
        #expect(map.tile(at: steel) == .steel)
    }

    @Test("环状弹幕是 8 向，同屏子弹有上限")
    func barrageIsEightWayAndCapped() {
        let boss = FinalBoss(at: .zero)
        boss.takeDamage(14)
        #expect(boss.phase == 3)
        #expect(boss.volleyTravels().count == GameConfig.finalBossBarrageCount)
        #expect(boss.maxSimultaneousBullets == GameConfig.bossMaxSimultaneousBullets)
    }

    @Test("Boss 关能放下对应 footprint，通关要等 Boss 死")
    func bossLevelsFitAndClearWaitsForBoss() {
        for (index, level) in Levels.all.enumerated() where level.bossType != nil {
            #expect(LevelValidator.issues(in: level, index: index).isEmpty)
        }
        let manager = LevelManager()
        #expect(manager.isCleared(remainingQueue: 0, pending: 0, liveEnemies: 1) == false)
        #expect(manager.isCleared(remainingQueue: 0, pending: 0, liveEnemies: 0))
    }

    @Test("同屏上限不把 Boss 算进去")
    func spawnCapIgnoresBoss() {
        let map = GridMap(rows: Levels.level3.rows)
        let system = SpawnSystem(mix: EnemyMix(normal: 6, fast: 0, armored: 0))
        guard let origin = map.firstOpenFootprint(tiles: GameConfig.miniBossFootprintTiles) else {
            Issue.record("第 3 关放不下小 Boss")
            return
        }
        let boss = MiniBoss(
            at: map.centerOfFootprint(origin: origin, tiles: GameConfig.miniBossFootprintTiles),
            trait: .none
        )
        let regular = (0..<3).map { _ in EnemyTank(type: .normal, at: map.center(of: GridPoint(col: 0, row: 4))) }
        let born = system.update(
            dt: 0,
            map: map,
            parent: SKNode(),
            liveEnemies: regular + [boss],
            blockingTanks: regular + [boss]
        )
        #expect(born.isEmpty)
        #expect(system.pendingCount == 0)
    }
}
