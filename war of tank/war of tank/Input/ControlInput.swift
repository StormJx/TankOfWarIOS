//
//  ControlInput.swift
//  war of tank
//

import Foundation

/// 操控场景写、战场场景读。两个 SpriteView 必须共享同一实例，不能各自拷一份。
/// 摇杆优先于键盘，避免模拟器上两者抢方向。
final class ControlInput {
    private var analogDirection: Direction?
    private var keyboardHeld: [Direction] = []
    private var pendingFire = false

    var direction: Direction? {
        analogDirection ?? keyboardHeld.last
    }

    func setAnalog(_ direction: Direction?) {
        analogDirection = direction
    }

    func setKeyboard(_ direction: Direction, isDown: Bool) {
        keyboardHeld.removeAll { $0 == direction }
        if isDown {
            keyboardHeld.append(direction)
        }
    }

    func requestFire() {
        pendingFire = true
    }

    func consumeFire() -> Bool {
        defer { pendingFire = false }
        return pendingFire
    }

    func reset() {
        analogDirection = nil
        keyboardHeld.removeAll()
        pendingFire = false
    }
}
