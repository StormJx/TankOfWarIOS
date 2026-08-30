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

    /// 第 1 关 训练场：两块砖墙、中央大道、无钢墙。
    static let level1 = LevelData(
        rows: [
            "1.....2.....3",
            ".............",
            "..BB.....BB..",
            "..BB.....BB..",
            ".............",
            ".............",
            ".............",
            "..BB.....BB..",
            "..BB.....BB..",
            ".............",
            ".....BBB.....",
            ".....BBB.....",
            "....PBEB....."
        ],
        totalEnemies: 6,
        enemyMix: EnemyMix(normal: 6, fast: 0, armored: 0),
        bossType: nil
    )

    /// 第 2 关 砖墙迷宫：三条纵廊，砖墙成块，没有钢墙。
    static let level2 = LevelData(
        rows: [
            "1.....2.....3",
            ".BB.B...B.BB.",
            ".B.........B.",
            ".B.BBBBBBB.B.",
            ".B.........B.",
            ".B.BB...BB.B.",
            ".............",
            ".B.BB...BB.B.",
            ".B.........B.",
            ".B.BBBBBBB.B.",
            ".B.........B.",
            ".....BBB.....",
            "....PBEB....."
        ],
        totalEnemies: 8,
        enemyMix: EnemyMix(normal: 5, fast: 3, armored: 0),
        bossType: nil
    )

    /// 第 3 关 钢铁前哨：两侧钢柱 + 基地钢护甲，中央留给小 Boss。
    static let level3 = LevelData(
        rows: [
            "1.....2.....3",
            ".............",
            ".SS.......SS.",
            ".S.........S.",
            ".S..BBBBB..S.",
            ".............",
            ".............",
            ".S..BBBBB..S.",
            ".S.........S.",
            ".SS.......SS.",
            ".............",
            "...SSBBBSS...",
            "....PBEB....."
        ],
        totalEnemies: 6,
        enemyMix: EnemyMix(normal: 3, fast: 3, armored: 0),
        bossType: .mini
    )

    /// 第 4 关 河谷：两道河只留中央桥，钢墙护边和基地。
    static let level4 = LevelData(
        rows: [
            "1.....2.....3",
            ".............",
            ".SS.......SS.",
            "WWWWW...WWWWW",
            ".............",
            ".BBB.....BBB.",
            "WWWWW...WWWWW",
            ".BBB.....BBB.",
            ".............",
            "WW.SSBBBSS.WW",
            ".............",
            ".....BBB.....",
            "....PBEB....."
        ],
        totalEnemies: 10,
        enemyMix: EnemyMix(normal: 5, fast: 3, armored: 2),
        bossType: nil
    )

    /// 第 5 关 草原伏击：大块草丛，钢柱卡位。
    static let level5 = LevelData(
        rows: [
            "1.....2.....3",
            ".GGGG...GGGG.",
            ".GGGG...GGGG.",
            ".SS.......SS.",
            ".............",
            ".GG..BBB..GG.",
            ".GG.......GG.",
            ".GG..BBB..GG.",
            ".............",
            ".SS.......SS.",
            ".GGGG...GGGG.",
            "...SSBBBSS...",
            "....PBEB....."
        ],
        totalEnemies: 12,
        enemyMix: EnemyMix(normal: 5, fast: 4, armored: 3),
        bossType: nil
    )

    /// 第 6 关 冰原：成片冰面，钢梁留中央通道。
    static let level6 = LevelData(
        rows: [
            "1.....2.....3",
            ".IIII...IIII.",
            ".IIII...IIII.",
            ".SS.......SS.",
            ".............",
            ".SSSS...SSSS.",
            ".IIII...IIII.",
            ".SSSS...SSSS.",
            ".............",
            ".SS.......SS.",
            ".IIII...IIII.",
            "...SSBBBSS...",
            "....PBEB....."
        ],
        totalEnemies: 8,
        enemyMix: EnemyMix(normal: 3, fast: 3, armored: 2),
        bossType: .mini
    )

    /// 第 7 关 要塞：左右钢堡，只留中央窄道。
    static let level7 = LevelData(
        rows: [
            "1.....2.....3",
            ".SSS.....SSS.",
            ".S.........S.",
            ".S.SS...SS.S.",
            ".S.S.....S.S.",
            ".S.S.BBB.S.S.",
            ".....B.B.....",
            ".S.S.BBB.S.S.",
            ".S.S.....S.S.",
            ".S.SS...SS.S.",
            ".S.........S.",
            ".SSS.BBB.SSS.",
            "....PBEB....."
        ],
        totalEnemies: 14,
        enemyMix: EnemyMix(normal: 5, fast: 5, armored: 4),
        bossType: nil
    )

    /// 第 8 关 十字火线：钢十字骨架，砖墙填十字心。
    static let level8 = LevelData(
        rows: [
            "1.....2.....3",
            "..SS.....SS..",
            "..S.......S..",
            "SSS..BBB..SSS",
            ".....B.B.....",
            "..S..B.B..S..",
            ".....B.B.....",
            "..S..B.B..S..",
            ".....B.B.....",
            "SSS..BBB..SSS",
            "..S.......S..",
            "..SS.BBB.SS..",
            "....PBEB....."
        ],
        totalEnemies: 14,
        enemyMix: EnemyMix(normal: 4, fast: 5, armored: 5),
        bossType: nil
    )

    /// 第 9 关 死亡走廊：左冰右钢，三道河只留中缝。
    static let level9 = LevelData(
        rows: [
            "1.....2.....3",
            ".III.....SSS.",
            ".III.....SSS.",
            "WWW.......WWW",
            ".............",
            ".SSSS...IIII.",
            "WWW.BBBBB.WWW",
            ".IIII...SSSS.",
            ".............",
            "WWW.......WWW",
            ".SSS.....III.",
            "...SSBBBSS...",
            "....PBEB....."
        ],
        totalEnemies: 10,
        enemyMix: EnemyMix(normal: 3, fast: 4, armored: 3),
        bossType: .mini
    )

    /// 第 10 关 最终决战：开阔场 + 四座钢碉堡，顶部留给大 Boss。
    static let level10 = LevelData(
        rows: [
            "1.....2.....3",
            ".............",
            ".............",
            "...SS...SS...",
            "...SS...SS...",
            ".............",
            "....BBBBB....",
            ".............",
            "...SS...SS...",
            "...SS...SS...",
            ".............",
            "...SSBBBSS...",
            "....PBEB....."
        ],
        totalEnemies: 8,
        enemyMix: EnemyMix(normal: 2, fast: 3, armored: 3),
        bossType: .final
    )

    static let all: [LevelData] = [
        level1, level2, level3, level4, level5,
        level6, level7, level8, level9, level10
    ]

    static func level(at index: Int) -> LevelData {
        all[min(max(index, 0), all.count - 1)]
    }

    /// 只给 GameConfig.debugTerrainShowcase 用。
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
