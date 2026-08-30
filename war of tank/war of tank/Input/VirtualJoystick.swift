//
//  VirtualJoystick.swift
//  war of tank
//

import SpriteKit

final class VirtualJoystick: SKNode {

    private let input: ControlInput
    private let base: SKShapeNode
    private let knob: SKShapeNode
    private var activeTouch: UITouch?

    init(input: ControlInput) {
        self.input = input

        let baseRadius = GameConfig.joystickBaseRadius
        base = SKShapeNode(circleOfRadius: baseRadius)
        base.fillColor = GameConfig.joystickBaseColor
        base.strokeColor = GameConfig.joystickBaseStrokeColor
        base.lineWidth = GameConfig.joystickLineWidth

        knob = SKShapeNode(circleOfRadius: GameConfig.joystickKnobRadius)
        knob.fillColor = GameConfig.joystickKnobColor
        knob.strokeColor = .clear

        super.init()
        isUserInteractionEnabled = true
        zPosition = GameConfig.Layer.ui
        addChild(base)
        addChild(knob)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("VirtualJoystick 不支持从归档初始化")
    }

    override func contains(_ p: CGPoint) -> Bool {
        hypot(p.x, p.y) <= GameConfig.joystickTouchRadius
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTouch == nil, let touch = touches.first else { return }
        activeTouch = touch
        apply(touch)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        apply(touch)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        reset()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        reset()
    }

    private func apply(_ touch: UITouch) {
        let local = touch.location(in: self)
        let length = hypot(local.x, local.y)
        let limit = GameConfig.joystickBaseRadius
        if length > limit, length > 0 {
            knob.position = CGPoint(x: local.x / length * limit, y: local.y / length * limit)
        } else {
            knob.position = local
        }
        input.setAnalog(Direction.fromVector(local, deadZone: GameConfig.joystickDeadZone))
    }

    private func reset() {
        activeTouch = nil
        knob.position = .zero
        input.setAnalog(nil)
    }
}
