//
//  GameHUDState.swift
//  war of tank
//

import Combine
import Foundation

final class GameHUDState: ObservableObject {
    @Published var lives: Int = GameConfig.playerLives
    @Published var firepower: Int = 0
    @Published var effects: [String] = []
    @Published var stage: Int = 1
    @Published var remainingEnemies: Int = 0
    @Published var score: Int = 0
    @Published var bossHP: Int = 0
    @Published var bossMaxHP: Int = 0
    @Published var bossPhase: Int = 0
}
