//
//  KeyboardCatcher.swift
//  war of tank
//

import SwiftUI
import UIKit

/// SpriteView 在模拟器里通常拿不到键盘焦点。这个透明 UIView 抢 first responder，
/// 把方向键 / WASD / 空格转进共享的 ControlInput。
struct KeyboardCatcher: UIViewRepresentable {
    let input: ControlInput

    func makeUIView(context: Context) -> CatcherView {
        let view = CatcherView()
        view.input = input
        return view
    }

    func updateUIView(_ uiView: CatcherView, context: Context) {
        uiView.input = input
    }

    final class CatcherView: UIView {
        weak var input: ControlInput?

        override var canBecomeFirstResponder: Bool { true }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window != nil {
                becomeFirstResponder()
            }
        }

        override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            guard apply(presses, isDown: true) else {
                super.pressesBegan(presses, with: event)
                return
            }
        }

        override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            guard apply(presses, isDown: false) else {
                super.pressesEnded(presses, with: event)
                return
            }
        }

        override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            _ = apply(presses, isDown: false)
        }

        private func apply(_ presses: Set<UIPress>, isDown: Bool) -> Bool {
            var handled = false
            for press in presses {
                guard let key = press.key else { continue }
                if handle(key, isDown: isDown) {
                    handled = true
                }
            }
            return handled
        }

        private func handle(_ key: UIKey, isDown: Bool) -> Bool {
            if let direction = Self.direction(for: key) {
                input?.setKeyboard(direction, isDown: isDown)
                return true
            }
            if Self.isFire(key) {
                if isDown {
                    input?.requestFire()
                }
                return true
            }
            return false
        }

        private static func direction(for key: UIKey) -> Direction? {
            switch key.keyCode {
            case .keyboardUpArrow, .keyboardW: return .up
            case .keyboardDownArrow, .keyboardS: return .down
            case .keyboardLeftArrow, .keyboardA: return .left
            case .keyboardRightArrow, .keyboardD: return .right
            default:
                break
            }
            switch key.charactersIgnoringModifiers.lowercased() {
            case "w": return .up
            case "s": return .down
            case "a": return .left
            case "d": return .right
            default: return nil
            }
        }

        private static func isFire(_ key: UIKey) -> Bool {
            if key.keyCode == .keyboardSpacebar || key.keyCode == .keyboardJ {
                return true
            }
            return key.charactersIgnoringModifiers == " " || key.charactersIgnoringModifiers.lowercased() == "j"
        }
    }
}
