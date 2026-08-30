//
//  Direction.swift
//  war of tank
//

import CoreGraphics

enum Direction: CaseIterable {
    case up
    case down
    case left
    case right

    var vector: CGVector {
        switch self {
        case .up: return CGVector(dx: 0, dy: 1)
        case .down: return CGVector(dx: 0, dy: -1)
        case .left: return CGVector(dx: -1, dy: 0)
        case .right: return CGVector(dx: 1, dy: 0)
        }
    }

    var isHorizontal: Bool {
        self == .left || self == .right
    }

    var opposite: Direction {
        switch self {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    }

    var perpendicular: [Direction] {
        isHorizontal ? [.up, .down] : [.left, .right]
    }

    static func toward(from start: GridPoint, to end: GridPoint) -> Direction? {
        let dc = end.col - start.col
        let dr = end.row - start.row
        if dc == 0 && dr == 0 { return nil }
        if abs(dc) > abs(dr) {
            return dc > 0 ? .right : .left
        }
        return dr > 0 ? .down : .up
    }

    /// SpriteKit 正旋转为逆时针；贴图默认朝上
    var zRotation: CGFloat {
        switch self {
        case .up: return 0
        case .right: return -.pi / 2
        case .down: return .pi
        case .left: return .pi / 2
        }
    }

    /// 取绝对值较大的轴，避免对角输入在两向之间抖动
    static func fromVector(_ vector: CGPoint, deadZone: CGFloat) -> Direction? {
        let dx = vector.x
        let dy = vector.y
        guard hypot(dx, dy) >= deadZone else { return nil }
        if abs(dx) > abs(dy) {
            return dx > 0 ? .right : .left
        }
        return dy > 0 ? .up : .down
    }
}
