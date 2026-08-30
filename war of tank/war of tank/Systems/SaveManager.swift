//
//  SaveManager.swift
//  war of tank
//

import Foundation

enum SaveManager {

    /// 单测可换成独立 suite，避免写进真机存档
    static var store = UserDefaults.standard

    static var maxUnlockedLevel: Int {
        get {
            let stored = store.integer(forKey: GameConfig.saveMaxUnlockedKey)
            return max(1, min(stored == 0 ? 1 : stored, GameConfig.levelCount))
        }
        set {
            store.set(min(max(newValue, 1), GameConfig.levelCount), forKey: GameConfig.saveMaxUnlockedKey)
        }
    }

    static var highScore: Int {
        get { store.integer(forKey: GameConfig.saveHighScoreKey) }
        set { store.set(max(0, newValue), forKey: GameConfig.saveHighScoreKey) }
    }

    static var language: AppLanguage {
        get {
            guard let raw = store.string(forKey: GameConfig.saveLanguageKey),
                  let value = AppLanguage(rawValue: raw) else {
                return .chinese
            }
            return value
        }
        set {
            store.set(newValue.rawValue, forKey: GameConfig.saveLanguageKey)
        }
    }

    static func unlock(levelNumber: Int) {
        maxUnlockedLevel = max(maxUnlockedLevel, levelNumber)
    }

    static func recordScore(_ score: Int) {
        if score > highScore {
            highScore = score
        }
    }
}
