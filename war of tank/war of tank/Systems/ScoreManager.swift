//
//  ScoreManager.swift
//  war of tank
//

final class ScoreManager {
    private(set) var score = 0
    private(set) var stageKills = 0

    func reset() {
        score = 0
        stageKills = 0
    }

    func beginStage() {
        stageKills = 0
    }

    func addKill(score value: Int) {
        score += value
        stageKills += 1
    }
}
