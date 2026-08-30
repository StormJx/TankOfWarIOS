//
//  ControlScene.swift
//  war of tank
//

import SpriteKit

/// 独立场景承载摇杆和射击键：战场必须维持 208x208 逻辑坐标，
/// 把 44pt 摇杆塞进 GameScene 会被 aspectFit 缩到几乎没法按。
final class ControlScene: SKScene {

    private let joystick: VirtualJoystick
    private let fireButton: FireButton

    init(input: ControlInput) {
        joystick = VirtualJoystick(input: input)
        fireButton = FireButton(input: input)
        super.init(size: CGSize(width: 1, height: 1))
        scaleMode = .resizeFill
        backgroundColor = GameConfig.controlAreaPlaceholderColor
        isUserInteractionEnabled = true
        anchorPoint = .zero
        addChild(joystick)
        addChild(fireButton)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("ControlScene 不支持从归档初始化")
    }

    override func didMove(to view: SKView) {
        layoutControls()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        layoutControls()
    }

    override func update(_ currentTime: TimeInterval) {
        fireButton.update(currentTime: currentTime)
    }

    private func layoutControls() {
        guard size.width > 0, size.height > 0 else { return }

        let padding = GameConfig.controlSidePadding
        let midY = size.height / 2
        joystick.position = CGPoint(
            x: padding + GameConfig.joystickTouchRadius,
            y: midY
        )
        fireButton.position = CGPoint(
            x: size.width - padding - GameConfig.fireButtonRadius,
            y: midY
        )
    }
}
