//
//  FireButton.swift
//  war of tank
//

import SpriteKit

final class FireButton: SKNode {

    private let input: ControlInput
    private let plate: SKShapeNode
    private var activeTouch: UITouch?
    private var lastFireTime: TimeInterval?
    private var isHeld = false

    init(input: ControlInput) {
        self.input = input
        plate = SKShapeNode(circleOfRadius: GameConfig.fireButtonRadius)
        plate.fillColor = GameConfig.fireButtonColor
        plate.strokeColor = GameConfig.fireButtonStrokeColor
        plate.lineWidth = GameConfig.fireButtonLineWidth

        super.init()
        isUserInteractionEnabled = true
        zPosition = GameConfig.Layer.ui
        addChild(plate)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("FireButton 不支持从归档初始化")
    }

    override func contains(_ p: CGPoint) -> Bool {
        hypot(p.x, p.y) <= GameConfig.fireButtonRadius
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTouch == nil, let touch = touches.first else { return }
        activeTouch = touch
        isHeld = true
        plate.fillColor = GameConfig.fireButtonPressedColor
        input.requestFire()
        lastFireTime = nil
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        reset()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        reset()
    }

    /// 用场景时间累加间隔，避免 Timer 在暂停后继续走
    func update(currentTime: TimeInterval) {
        guard isHeld else { return }
        if let lastFireTime {
            if currentTime - lastFireTime >= GameConfig.fireButtonRepeatInterval {
                input.requestFire()
                self.lastFireTime = currentTime
            }
        } else {
            lastFireTime = currentTime
        }
    }

    private func reset() {
        activeTouch = nil
        isHeld = false
        lastFireTime = nil
        plate.fillColor = GameConfig.fireButtonColor
    }
}
