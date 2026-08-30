//
//  LevelValidator.swift
//  war of tank
//

enum LevelValidator {

    static func issues(in level: LevelData, index: Int) -> [String] {
        var found: [String] = []
        if level.rows.count != GameConfig.gridCount {
            found.append("第 \(index + 1) 关行数不是 \(GameConfig.gridCount)")
        }
        for (row, line) in level.rows.enumerated() where line.count != GameConfig.gridCount {
            found.append("第 \(index + 1) 关第 \(row) 行列数不是 \(GameConfig.gridCount)")
        }
        if level.enemyMix.total != level.totalEnemies {
            found.append("第 \(index + 1) 关 enemyMix 与 totalEnemies 不一致")
        }

        let map = GridMap(rows: level.rows)
        if map.basePosition != GameConfig.baseGridPoint {
            found.append("第 \(index + 1) 关基地不在 (6,12)")
        }
        if map.enemySpawns.count < 2 {
            found.append("第 \(index + 1) 关敌方出生点少于 2 个")
        }
        for spawn in map.enemySpawns {
            let path = GridPathfinder.shortestPath(from: spawn, to: map.basePosition, map: map)
            if path.isEmpty {
                found.append("第 \(index + 1) 关出生点 \(spawn.col),\(spawn.row) 到基地无通路")
            }
        }
        if let bossType = level.bossType {
            let tiles = bossType == .final
                ? GameConfig.finalBossFootprintTiles
                : GameConfig.miniBossFootprintTiles
            if map.firstOpenFootprint(tiles: tiles) == nil {
                found.append("第 \(index + 1) 关放不下 \(tiles)x\(tiles) Boss")
            }
        }
        return found
    }

    static func assertAllCampaignLevels() {
        for (index, level) in Levels.all.enumerated() {
            let problems = issues(in: level, index: index)
            assert(problems.isEmpty, problems.joined(separator: "; "))
        }
    }
}
