//
//  GridPathfinder.swift
//  war of tank
//

enum GridPathfinder {

    /// 网格 BFS。砖墙算可走（AI 会停下来轰开），钢墙/河流不可走。
    static func shortestPath(from start: GridPoint, to goal: GridPoint, map: GridMap) -> [GridPoint] {
        if start == goal { return [start] }
        guard map.isInside(start), map.isInside(goal) else { return [] }

        var cameFrom: [GridPoint: GridPoint] = [:]
        var queue: [GridPoint] = [start]
        var head = 0
        var visited: Set<GridPoint> = [start]

        while head < queue.count {
            let current = queue[head]
            head += 1
            if current == goal {
                return reconstruct(cameFrom: cameFrom, start: start, goal: goal)
            }
            for direction in Direction.allCases {
                let next = current.neighbor(in: direction)
                guard !visited.contains(next), isPathable(next, goal: goal, map: map) else { continue }
                visited.insert(next)
                cameFrom[next] = current
                queue.append(next)
            }
        }
        return []
    }

    static func isPathable(_ point: GridPoint, goal: GridPoint, map: GridMap) -> Bool {
        guard map.isInside(point) else { return false }
        if point == goal { return true }
        switch map.tile(at: point) {
        case .empty, .grass, .ice, .brick:
            return true
        case .steel, .water, .base:
            return false
        }
    }

    private static func reconstruct(cameFrom: [GridPoint: GridPoint], start: GridPoint, goal: GridPoint) -> [GridPoint] {
        var path = [goal]
        var current = goal
        while current != start {
            guard let previous = cameFrom[current] else { return [] }
            path.append(previous)
            current = previous
        }
        return path.reversed()
    }
}
