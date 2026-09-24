//
//  GameFlow.swift
//  war of tank
//

import Combine
import Foundation

enum AppScreen: Equatable {
    case menu
    case playing
    case levelClear
    case gameOver
    case victory
}

final class GameFlow: ObservableObject {
    @Published var screen: AppScreen = .menu
    @Published var isPaused = false
    @Published var lastClearScore = 0
    @Published var playGeneration = 0

    let levels = LevelManager()
    let score = ScoreManager()
    let input = ControlInput()
    let hud = GameHUDState()

    func startNewGame() {
        score.reset()
        levels.start(at: 0)
        beginPlay()
    }

    func startSelectedLevel(_ index: Int) {
        guard index < SaveManager.maxUnlockedLevel else { return }
        score.reset()
        levels.start(at: index)
        beginPlay()
    }

    func restartCurrentLevel() {
        score.beginStage()
        beginPlay()
    }

    func continueAfterClear() {
        if levels.advance() {
            score.beginStage()
            beginPlay()
        } else {
            SaveManager.recordScore(score.score)
            screen = .victory
        }
    }

    func handleLevelCleared() {
        guard screen == .playing else { return }
        lastClearScore = score.score
        SaveManager.unlock(levelNumber: min(levels.stageNumber + 1, GameConfig.levelCount))
        SaveManager.recordScore(score.score)
        isPaused = false
        if levels.isLastStage {
            screen = .victory
        } else {
            screen = .levelClear
        }
    }

    func handleDefeat() {
        guard screen == .playing else { return }
        SaveManager.recordScore(score.score)
        isPaused = false
        screen = .gameOver
    }

    func backToMenu() {
        isPaused = false
        screen = .menu
    }

    func togglePause() {
        guard screen == .playing else { return }
        isPaused.toggle()
    }

    func resume() {
        isPaused = false
    }

    /// 进后台或来电中断只冻结对局；切回不能自动 resume，否则玩家会面对已经跑掉的战场。
    func pauseWhenAppLeavesForeground() {
        guard screen == .playing else { return }
        isPaused = true
    }

    private func beginPlay() {
        isPaused = false
        input.reset()
        hud.stage = levels.stageNumber
        hud.score = score.score
        playGeneration += 1
        screen = .playing
    }
}
