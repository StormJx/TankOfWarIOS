//
//  LevelManager.swift
//  war of tank
//

final class LevelManager {
    private(set) var currentIndex = 0

    var currentLevel: LevelData { Levels.level(at: currentIndex) }
    var stageNumber: Int { currentIndex + 1 }
    var isLastStage: Bool { currentIndex >= Levels.all.count - 1 }

    func start(at index: Int) {
        currentIndex = min(max(index, 0), Levels.all.count - 1)
    }

    func advance() -> Bool {
        guard !isLastStage else { return false }
        currentIndex += 1
        return true
    }

    func isCleared(remainingQueue: Int, pending: Int, liveEnemies: Int) -> Bool {
        remainingQueue == 0 && pending == 0 && liveEnemies == 0
    }

    func isFailed(lives: Int, baseDestroyed: Bool) -> Bool {
        baseDestroyed || lives <= 0
    }
}
