//
//  LevelFlowTests.swift
//  war of tankTests
//

import Foundation
import Testing
@testable import war_of_tank

@Suite(.serialized)
struct LevelFlowTests {

    @Test("10 关都是 13x13，配比正确，出生点到基地有通路")
    func allCampaignLevelsAreValid() {
        #expect(Levels.all.count == GameConfig.levelCount)
        for (index, level) in Levels.all.enumerated() {
            #expect(LevelValidator.issues(in: level, index: index).isEmpty)
        }
    }

    @Test("关卡主题与设计文档第 7 节一致")
    func campaignThemesMatchDesign() {
        #expect(Levels.level1.bossType == nil)
        #expect(Levels.level1.enemyMix.total == 6)
        #expect(GridMap(rows: Levels.level1.rows).firstPoint(of: .steel) == nil)

        #expect(Levels.level2.enemyMix.fast == 3)
        #expect(GridMap(rows: Levels.level2.rows).firstPoint(of: .steel) == nil)

        #expect(Levels.level3.bossType == .mini)
        #expect(GridMap(rows: Levels.level3.rows).firstPoint(of: .steel) != nil)

        #expect(Levels.level4.enemyMix.armored == 2)
        #expect(GridMap(rows: Levels.level4.rows).firstPoint(of: .water) != nil)

        #expect(Levels.level5.totalEnemies == 12)
        #expect(GridMap(rows: Levels.level5.rows).firstPoint(of: .grass) != nil)

        #expect(Levels.level6.bossType == .mini)
        #expect(GridMap(rows: Levels.level6.rows).firstPoint(of: .ice) != nil)
        #expect(GridMap(rows: Levels.level6.rows).firstPoint(of: .steel) != nil)

        #expect(Levels.level7.totalEnemies == 14)
        #expect(GridMap(rows: Levels.level7.rows).firstPoint(of: .steel) != nil)

        #expect(Levels.level8.enemyMix.armored == 5)
        #expect(GridMap(rows: Levels.level8.rows).firstPoint(of: .steel) != nil)

        #expect(Levels.level9.bossType == .mini)
        let nine = GridMap(rows: Levels.level9.rows)
        #expect(nine.firstPoint(of: .ice) != nil)
        #expect(nine.firstPoint(of: .water) != nil)
        #expect(nine.firstPoint(of: .steel) != nil)

        #expect(Levels.level10.bossType == .final)
        #expect(Levels.level10.enemyMix.total == 8)
        #expect(GridMap(rows: Levels.level4.rows).firstPoint(of: .steel) != nil)
        #expect(GridMap(rows: Levels.level5.rows).firstPoint(of: .steel) != nil)
        #expect(GridMap(rows: Levels.level10.rows).firstPoint(of: .steel) != nil)
    }

    @Test("通关判定要等队列、闪烁和场上敌人都清空")
    func clearRequiresEmptyField() {
        let manager = LevelManager()
        #expect(manager.isCleared(remainingQueue: 0, pending: 0, liveEnemies: 0))
        #expect(manager.isCleared(remainingQueue: 1, pending: 0, liveEnemies: 0) == false)
        #expect(manager.isFailed(lives: 0, baseDestroyed: false))
        #expect(manager.isFailed(lives: 2, baseDestroyed: true))
        #expect(manager.isFailed(lives: 2, baseDestroyed: false) == false)
    }

    @Test("LevelManager 能推进到第 10 关并停在最后一关")
    func levelManagerAdvancesThenStops() {
        let manager = LevelManager()
        manager.start(at: 0)
        var steps = 0
        while manager.advance() {
            steps += 1
        }
        #expect(steps == 9)
        #expect(manager.isLastStage)
        #expect(manager.stageNumber == 10)
    }

    @Test("存档解锁与最高分写在隔离的 UserDefaults 里")
    func saveManagerUsesIsolatedStore() {
        withIsolatedSave {
            #expect(SaveManager.maxUnlockedLevel == 1)
            #expect(SaveManager.highScore == 0)
            SaveManager.unlock(levelNumber: 4)
            SaveManager.unlock(levelNumber: 2)
            #expect(SaveManager.maxUnlockedLevel == 4)
            SaveManager.recordScore(1200)
            SaveManager.recordScore(800)
            #expect(SaveManager.highScore == 1200)
        }
    }

    @Test("语言切换写进隔离存档，HUD 和菜单文案一起变")
    func languagePersistsAndReloadsCopy() {
        withIsolatedSave {
            #expect(SaveManager.language == .chinese)
            #expect(L10n.start == "开始")
            #expect(L10n.hudLine(lives: 3, stage: 1, remainingEnemies: 6, firepower: 0, score: 0, effects: []).contains("命数"))
            SaveManager.language = .english
            #expect(SaveManager.language == .english)
            #expect(L10n.start == "START")
            #expect(L10n.hudLine(lives: 3, stage: 1, remainingEnemies: 6, firepower: 0, score: 0, effects: []).contains("L3"))
            SaveManager.language = .chinese
            #expect(L10n.languageButton == "中文")
        }
    }

    @Test("未解锁关卡不能开打，通关会解锁下一关，第 10 关直接胜利")
    func flowUnlocksThenWinsOnLastStage() {
        withIsolatedSave {
            let flow = GameFlow()
            flow.startSelectedLevel(3)
            #expect(flow.screen == .menu)

            flow.startNewGame()
            #expect(flow.screen == .playing)
            flow.handleLevelCleared()
            #expect(flow.screen == .levelClear)
            #expect(SaveManager.maxUnlockedLevel == 2)
            #expect(flow.levels.stageNumber == 1)

            flow.continueAfterClear()
            #expect(flow.screen == .playing)
            #expect(flow.levels.stageNumber == 2)

            SaveManager.unlock(levelNumber: 10)
            flow.startSelectedLevel(9)
            #expect(flow.levels.stageNumber == 10)
            flow.handleLevelCleared()
            #expect(flow.screen == .victory)
        }
    }

    @Test("重开本关会换新的对局世代，火力与命数由新场景重置")
    func restartBumpsPlayGeneration() {
        withIsolatedSave {
            let flow = GameFlow()
            flow.startNewGame()
            let generation = flow.playGeneration
            flow.restartCurrentLevel()
            #expect(flow.playGeneration == generation + 1)
            #expect(flow.levels.stageNumber == 1)
            #expect(flow.screen == .playing)
        }
    }
}

private func withIsolatedSave(_ body: () -> Void) {
    let suite = "war.of.tank.tests.save.\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: suite) else {
        Issue.record("无法创建隔离 UserDefaults")
        return
    }
    defaults.removePersistentDomain(forName: suite)
    let previous = SaveManager.store
    SaveManager.store = defaults
    defer {
        SaveManager.store = previous
        defaults.removePersistentDomain(forName: suite)
    }
    body()
}
