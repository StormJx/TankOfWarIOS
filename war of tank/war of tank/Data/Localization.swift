//
//  Localization.swift
//  war of tank
//

enum AppLanguage: String {
    case chinese
    case english

    mutating func toggle() {
        self = self == .chinese ? .english : .chinese
    }
}

/// 可见文案的唯一切换入口，读 SaveManager 当前语言。
enum L10n {

    static var language: AppLanguage { SaveManager.language }

    static var isChinese: Bool { language == .chinese }

    static var menuTitle: String { isChinese ? "坦克大战" : "TANK OF WAR" }

    static func highScore(_ value: Int) -> String {
        isChinese ? "最高分 \(value)" : "HI \(value)"
    }

    static var start: String { isChinese ? "开始" : "START" }

    static var languageButton: String { isChinese ? "中文" : "EN" }

    static var simulatorHint: String {
        isChinese ? "方向键移动 空格射击" : "ARROWS MOVE  SPACE FIRE"
    }

    static func sound(isMuted: Bool) -> String {
        if isChinese {
            return isMuted ? "音效关" : "音效开"
        }
        return isMuted ? "SND OFF" : "SND ON"
    }

    static func stageButton(number: Int, locked: Bool) -> String {
        if isChinese {
            return locked ? "第\(number)关--" : "第\(number)关"
        }
        return locked ? "ST\(number)--" : "ST\(number)"
    }

    static func stageTitle(_ number: Int) -> String {
        isChinese ? "第 \(number) 关" : "STAGE \(number)"
    }

    static func score(_ value: Int) -> String {
        isChinese ? "分数 \(value)" : "SCORE \(value)"
    }

    static var gameOver: String { isChinese ? "游戏结束" : "GAME OVER" }

    static var youWin: String { isChinese ? "通关" : "YOU WIN" }

    static var retry: String { isChinese ? "重试" : "RETRY" }

    static var menu: String { isChinese ? "菜单" : "MENU" }

    static var paused: String { isChinese ? "暂停" : "PAUSED" }

    static var continueGame: String { isChinese ? "继续" : "CONTINUE" }

    static var restart: String { isChinese ? "重开" : "RESTART" }

    static func pauseSound(isMuted: Bool) -> String {
        if isChinese {
            return isMuted ? "音效关" : "音效开"
        }
        return isMuted ? "SOUND OFF" : "SOUND ON"
    }

    static func hudLine(
        lives: Int,
        stage: Int,
        remainingEnemies: Int,
        firepower: Int,
        score: Int,
        effects: [String]
    ) -> String {
        let extras = effects.isEmpty ? "" : " " + effects.joined(separator: " ")
        if isChinese {
            return "命数\(lives)  关卡\(stage)  敌军\(remainingEnemies)  火力\(firepower)  分数\(score)\(extras)"
        }
        return "L\(lives)  ST\(stage)  EN\(remainingEnemies)  POW\(firepower)  SC\(score)\(extras)"
    }

    static var hudShield: String { isChinese ? "护盾" : "SHLD" }
    static var hudInvincible: String { isChinese ? "无敌" : "INV" }
    static var hudFreeze: String { isChinese ? "冻结" : "FRZ" }
    static var hudStun: String { isChinese ? "僵直" : "STN" }
    static var hudShovel: String { isChinese ? "铲子" : "SHV" }
}
