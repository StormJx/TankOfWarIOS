//
//  GridMap.swift
//  war of tank
//

import CoreGraphics

enum TileType {
    case empty
    case brick
    case steel
    case water
    case grass
    case ice
    case base
}

/// col 从左到右 0...12，row 从上到下 0...12
struct GridPoint: Hashable {
    let col: Int
    let row: Int

    func neighbor(in direction: Direction) -> GridPoint {
        switch direction {
        case .up: return GridPoint(col: col, row: row - 1)
        case .down: return GridPoint(col: col, row: row + 1)
        case .left: return GridPoint(col: col - 1, row: row)
        case .right: return GridPoint(col: col + 1, row: row)
        }
    }

    func manhattanDistance(to other: GridPoint) -> Int {
        abs(col - other.col) + abs(row - other.row)
    }

    func sharesAxis(with other: GridPoint) -> Bool {
        col == other.col || row == other.row
    }

    var adjacentEight: [GridPoint] {
        var points: [GridPoint] = []
        for rowOffset in -1...1 {
            for colOffset in -1...1 where rowOffset != 0 || colOffset != 0 {
                points.append(GridPoint(col: col + colOffset, row: row + rowOffset))
            }
        }
        return points
    }
}

/// 战场的网格数据源，同时是行列与场景坐标互转的唯一入口。
/// 其他文件一律调用 center(of:) / gridPoint(at:)，不许自己写 col * tileSize + tileSize / 2。
final class GridMap {

    private var tiles: [[TileType]]
    /// 还没被打掉的 8pt 砖块。bit0 左下、bit1 右下、bit2 左上、bit3 右上
    private var brickMasks: [GridPoint: UInt8] = [:]

    let playerSpawn: GridPoint
    let enemySpawns: [GridPoint]
    let basePosition: GridPoint

    init(rows: [String]) {
        var parsed: [[TileType]] = []
        var masks: [GridPoint: UInt8] = [:]
        var player: GridPoint?
        var enemies: [GridPoint] = []
        var base: GridPoint?

        if rows.count != GameConfig.gridCount {
            assertionFailure("地图必须是 \(GameConfig.gridCount) 行，实际 \(rows.count) 行")
        }

        for (row, line) in rows.enumerated() {
            let characters = Array(line)
            if characters.count != GameConfig.gridCount {
                assertionFailure("地图第 \(row) 行必须是 \(GameConfig.gridCount) 列，实际 \(characters.count) 列")
            }

            var rowTiles: [TileType] = []
            for (col, character) in characters.enumerated() {
                let point = GridPoint(col: col, row: row)
                switch character {
                case ".":
                    rowTiles.append(.empty)
                case "B":
                    rowTiles.append(.brick)
                    masks[point] = GameConfig.fullBrickMask
                case "S":
                    rowTiles.append(.steel)
                case "W":
                    rowTiles.append(.water)
                case "G":
                    rowTiles.append(.grass)
                case "I":
                    rowTiles.append(.ice)
                case "E":
                    rowTiles.append(.base)
                    base = point
                case "P":
                    // 出生点只是标记，地形本身是空地
                    rowTiles.append(.empty)
                    player = point
                case "1", "2", "3":
                    rowTiles.append(.empty)
                    enemies.append(point)
                default:
                    assertionFailure("地图出现未定义字符 \(character)，位置 (\(col), \(row))")
                    rowTiles.append(.empty)
                }
            }
            parsed.append(rowTiles)
        }

        // Release 构建里 assertionFailure 是空操作，尺寸不对时必须补齐成方阵，
        // 否则后面按行列下标访问会越界崩溃
        tiles = Self.squared(parsed)
        brickMasks = masks

        if base == nil {
            assertionFailure("地图缺少基地 E")
        }
        if player == nil {
            assertionFailure("地图缺少玩家出生点 P")
        }
        basePosition = base ?? GameConfig.baseGridPoint
        playerSpawn = player ?? GameConfig.defaultPlayerSpawn
        enemySpawns = enemies
    }

    private static func squared(_ parsed: [[TileType]]) -> [[TileType]] {
        let side = GameConfig.gridCount
        let emptyRow = [TileType](repeating: .empty, count: side)
        return (0..<side).map { row in
            guard row < parsed.count else { return emptyRow }
            var rowTiles = parsed[row]
            if rowTiles.count > side {
                rowTiles.removeLast(rowTiles.count - side)
            } else if rowTiles.count < side {
                rowTiles.append(contentsOf: [TileType](repeating: .empty, count: side - rowTiles.count))
            }
            return rowTiles
        }
    }

    // MARK: - 查询

    func isInside(_ point: GridPoint) -> Bool {
        point.col >= 0 && point.col < GameConfig.gridCount
            && point.row >= 0 && point.row < GameConfig.gridCount
    }

    /// 越界一律当作阻挡，省掉每个调用点都先判边界
    func tile(at point: GridPoint) -> TileType {
        guard isInside(point) else { return .steel }
        return tiles[point.row][point.col]
    }

    func isOpenFootprint(origin: GridPoint, tiles: Int) -> Bool {
        for rowOffset in 0..<tiles {
            for colOffset in 0..<tiles {
                if blocksTank(at: GridPoint(col: origin.col + colOffset, row: origin.row + rowOffset)) {
                    return false
                }
            }
        }
        return true
    }

    func firstOpenFootprint(tiles: Int) -> GridPoint? {
        var candidates: [GridPoint] = []
        if let spawn = enemySpawns.dropFirst().first {
            candidates.append(
                GridPoint(col: max(0, spawn.col - tiles / 2), row: spawn.row)
            )
        }
        for row in 0...(GameConfig.gridCount - tiles) {
            for col in 0...(GameConfig.gridCount - tiles) {
                let origin = GridPoint(col: col, row: row)
                if !candidates.contains(origin) {
                    candidates.append(origin)
                }
            }
        }
        return candidates.first { isOpenFootprint(origin: $0, tiles: tiles) }
    }

    func centerOfFootprint(origin: GridPoint, tiles: Int) -> CGPoint {
        let minCenter = center(of: origin)
        let maxCenter = center(of: GridPoint(col: origin.col + tiles - 1, row: origin.row + tiles - 1))
        return CGPoint(
            x: (minCenter.x + maxCenter.x) / 2,
            y: (minCenter.y + maxCenter.y) / 2
        )
    }

    func firstPoint(of type: TileType) -> GridPoint? {
        for row in 0..<GameConfig.gridCount {
            for col in 0..<GameConfig.gridCount where tiles[row][col] == type {
                return GridPoint(col: col, row: row)
            }
        }
        return nil
    }

    // MARK: - 坐标互转

    /// 场景原点在左下角，而 row 自上而下增长，所以 y 要用场景边长减回去
    func center(of point: GridPoint) -> CGPoint {
        let half = GameConfig.tileSize / 2
        return CGPoint(
            x: CGFloat(point.col) * GameConfig.tileSize + half,
            y: GameConfig.sceneSide - (CGFloat(point.row) * GameConfig.tileSize + half)
        )
    }

    func gridPoint(at position: CGPoint) -> GridPoint {
        let col = Int((position.x / GameConfig.tileSize).rounded(.down))
        let row = Int(((GameConfig.sceneSide - position.y) / GameConfig.tileSize).rounded(.down))
        let bounds = 0...(GameConfig.gridCount - 1)
        return GridPoint(col: col.clamped(to: bounds), row: row.clamped(to: bounds))
    }

    // MARK: - 通行规则（见 GAME_DESIGN 第 2 节）

    func blocksTank(at point: GridPoint) -> Bool {
        switch tile(at: point) {
        case .brick, .steel, .water, .base:
            return true
        case .empty, .grass, .ice:
            return false
        }
    }

    func blocksBullet(at point: GridPoint) -> Bool {
        switch tile(at: point) {
        case .brick, .steel, .base:
            return true
        case .empty, .water, .grass, .ice:
            return false
        }
    }

    // MARK: - 破坏

    /// 返回是否真的被摧毁，调用方据此决定要不要重绘该 tile 与播放特效
    func destroyTile(at point: GridPoint, byLevel3Bullet: Bool) -> Bool {
        guard isInside(point) else { return false }
        switch tiles[point.row][point.col] {
        case .brick:
            tiles[point.row][point.col] = .empty
            brickMasks[point] = nil
            return true
        case .steel:
            guard byLevel3Bullet else { return false }
            tiles[point.row][point.col] = .empty
            return true
        case .empty, .water, .grass, .ice, .base:
            return false
        }
    }

    func setTile(_ type: TileType, at point: GridPoint) {
        guard isInside(point) else { return }
        tiles[point.row][point.col] = type
        if type == .brick {
            brickMasks[point] = GameConfig.fullBrickMask
        } else {
            brickMasks[point] = nil
        }
    }

    func brickMask(at point: GridPoint) -> UInt8 {
        guard tile(at: point) == .brick else { return 0 }
        return brickMasks[point] ?? GameConfig.fullBrickMask
    }

    /// 打掉子弹碰到的一块。满星再沿弹道打掉下一块。返回需要重绘的格子
    func damageBrick(hitBy rect: CGRect, travel: CGVector, doubleDepth: Bool) -> [GridPoint] {
        guard let hit = firstSolidQuadrant(intersecting: rect) else { return [] }
        var changed: [GridPoint] = []
        if clearQuadrant(hit.index, at: hit.tile) {
            changed.append(hit.tile)
        }
        if doubleDepth, let next = neighborQuadrant(hit.index, travel: travel, from: hit.tile) {
            if clearQuadrant(next.index, at: next.tile) {
                changed.append(next.tile)
            }
        }
        var unique: [GridPoint] = []
        for point in changed where !unique.contains(point) {
            unique.append(point)
        }
        return unique
    }

    /// 坦克会被挡住的矩形：残砖只挡还在的小块，钢墙河基地仍是整格
    func tankBlockers(at point: GridPoint) -> [CGRect] {
        switch tile(at: point) {
        case .brick:
            return solidQuadrantRects(at: point)
        case .steel, .water, .base:
            return [Self.tileRect(at: point)]
        case .empty, .grass, .ice:
            return []
        }
    }

    /// 子弹先撞钢墙和基地，砖墙可被穿透弹忽略
    func bulletBlockingTile(intersecting rect: CGRect, pierceBrick: Bool) -> GridPoint? {
        var brickHit: GridPoint?
        for point in pointsOverlapping(rect) {
            switch tile(at: point) {
            case .steel, .base:
                if rect.intersects(Self.tileRect(at: point)) {
                    return point
                }
            case .brick:
                if pierceBrick { continue }
                if solidQuadrantRects(at: point).contains(where: { rect.intersects($0) }) {
                    brickHit = brickHit ?? point
                }
            case .empty, .water, .grass, .ice:
                break
            }
        }
        return brickHit
    }

    private func solidQuadrantRects(at point: GridPoint) -> [CGRect] {
        let mask = brickMask(at: point)
        let origin = Self.tileRect(at: point).origin
        let half = GameConfig.tileSize / 2
        var rects: [CGRect] = []
        for index in 0..<4 where mask & (1 << index) != 0 {
            let x = origin.x + (index % 2 == 1 ? half : 0)
            let y = origin.y + (index >= 2 ? half : 0)
            rects.append(CGRect(x: x, y: y, width: half, height: half))
        }
        return rects
    }

    private func firstSolidQuadrant(intersecting rect: CGRect) -> (tile: GridPoint, index: Int)? {
        for point in pointsOverlapping(rect) where tile(at: point) == .brick {
            let mask = brickMask(at: point)
            let origin = Self.tileRect(at: point).origin
            let half = GameConfig.tileSize / 2
            for index in 0..<4 where mask & (1 << index) != 0 {
                let piece = CGRect(
                    x: origin.x + (index % 2 == 1 ? half : 0),
                    y: origin.y + (index >= 2 ? half : 0),
                    width: half,
                    height: half
                )
                if rect.intersects(piece) {
                    return (point, index)
                }
            }
        }
        return nil
    }

    private func clearQuadrant(_ index: Int, at point: GridPoint) -> Bool {
        guard isInside(point), tile(at: point) == .brick else { return false }
        var mask = brickMask(at: point)
        let bit: UInt8 = 1 << index
        guard mask & bit != 0 else { return false }
        mask &= ~bit
        if mask == 0 {
            tiles[point.row][point.col] = .empty
            brickMasks[point] = nil
        } else {
            brickMasks[point] = mask
        }
        return true
    }

    private func neighborQuadrant(_ index: Int, travel: CGVector, from point: GridPoint) -> (tile: GridPoint, index: Int)? {
        let horizontal = abs(travel.dx) >= abs(travel.dy)
        if horizontal {
            let goingRight = travel.dx >= 0
            if goingRight {
                switch index {
                case 0: return (point, 1)
                case 2: return (point, 3)
                case 1: return (GridPoint(col: point.col + 1, row: point.row), 0)
                default: return (GridPoint(col: point.col + 1, row: point.row), 2)
                }
            }
            switch index {
            case 1: return (point, 0)
            case 3: return (point, 2)
            case 0: return (GridPoint(col: point.col - 1, row: point.row), 1)
            default: return (GridPoint(col: point.col - 1, row: point.row), 3)
            }
        }
        let goingUp = travel.dy >= 0
        if goingUp {
            switch index {
            case 0: return (point, 2)
            case 1: return (point, 3)
            case 2: return (GridPoint(col: point.col, row: point.row - 1), 0)
            default: return (GridPoint(col: point.col, row: point.row - 1), 1)
            }
        }
        switch index {
        case 2: return (point, 0)
        case 3: return (point, 1)
        case 0: return (GridPoint(col: point.col, row: point.row + 1), 2)
        default: return (GridPoint(col: point.col, row: point.row + 1), 3)
        }
    }

    private func pointsOverlapping(_ rect: CGRect) -> [GridPoint] {
        let inset = GameConfig.collisionEpsilon
        guard rect.width > inset * 2, rect.height > inset * 2 else { return [] }
        let a = gridPoint(at: CGPoint(x: rect.minX + inset, y: rect.minY + inset))
        let b = gridPoint(at: CGPoint(x: rect.maxX - inset, y: rect.maxY - inset))
        let cols = min(a.col, b.col)...max(a.col, b.col)
        let rows = min(a.row, b.row)...max(a.row, b.row)
        var points: [GridPoint] = []
        for row in rows {
            for col in cols {
                points.append(GridPoint(col: col, row: row))
            }
        }
        return points
    }

    private static func tileRect(at point: GridPoint) -> CGRect {
        let half = GameConfig.tileSize / 2
        let centerX = CGFloat(point.col) * GameConfig.tileSize + half
        let centerY = GameConfig.sceneSide - (CGFloat(point.row) * GameConfig.tileSize + half)
        return CGRect(x: centerX - half, y: centerY - half, width: GameConfig.tileSize, height: GameConfig.tileSize)
    }

    /// 基地周围 8 格里当前是砖/钢的才算围墙，空地不纳入快照
    func baseWallPoints() -> [GridPoint] {
        basePosition.adjacentEight.filter { point in
            isInside(point) && (tile(at: point) == .brick || tile(at: point) == .steel)
        }
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
