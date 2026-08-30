//
//  Levels.swift
//  war of tank
//

/// 每关敌人总量里各类型的数量，三者之和应等于 totalEnemies
struct EnemyMix {
    let normal: Int
    let fast: Int
    let armored: Int

    var total: Int { normal + fast + armored }
}

enum BossType {
    case mini
    case final
}

/// bossType 为 nil 表示普通关卡；totalEnemies 不含 Boss
struct LevelData {
    let rows: [String]
    let totalEnemies: Int
    let enemyMix: EnemyMix
    let bossType: BossType?
}

enum Levels {

    /// 第 1 关 训练场：少量砖墙、无钢墙、主干道敞开，保证新手一次通过。
    /// 敌人从顶部三个出生点下来，基地由五格砖墙护住。
    static let level1 = LevelData(
        rows: [
            "1.....2.....3",
            ".............",
            "..B.B...B.B..",
            "..B.B...B.B..",
            ".............",
            ".BB.......BB.",
            ".............",
            ".BB.......BB.",
            ".............",
            "..B.BBBBB.B..",
            ".............",
            ".....BBB.....",
            "....PBEB....."
        ],
        totalEnemies: 6,
        enemyMix: EnemyMix(normal: 6, fast: 0, armored: 0),
        bossType: nil
    )

    static let all: [LevelData] = [level1]

    /// 只给 GameConfig.debugTerrainShowcase 用：把 6 种地形和基地一次全摆出来，
    /// 方便肉眼核对贴图与草丛遮挡。不参与正式流程。
    static let terrainShowcase = LevelData(
        rows: [
            "1.....2.....3",
            ".............",
            ".BBBB...SSSS.",
            ".BBBB...SSSS.",
            ".............",
            ".WWWW...IIII.",
            ".WWWW...IIII.",
            ".............",
            ".GGGG...GGGG.",
            ".GGGG...GGGG.",
            ".............",
            ".....BBB.....",
            "....PBEB....."
        ],
        totalEnemies: 6,
        enemyMix: EnemyMix(normal: 6, fast: 0, armored: 0),
        bossType: nil
    )
}
