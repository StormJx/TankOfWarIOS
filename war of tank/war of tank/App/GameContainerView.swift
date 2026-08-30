//
//  GameContainerView.swift
//  war of tank
//

import SpriteKit
import SwiftUI

/// 竖屏三段布局：顶部 HUD、中间正方形战场、底部控制区。
/// HUD 与控制区在阶段 5 / 阶段 2 才有真实内容，这里只占位。
struct GameContainerView: View {

    @State private var scene = GameScene.battlefield()

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                hudPlaceholder
                battlefield(side: battlefieldSide(in: geometry.size))
                controlAreaPlaceholder
            }
        }
        // 战场底色延伸到刘海与 home indicator 区域，避免出现白边
        .background(Color(GameConfig.battlefieldColor).ignoresSafeArea())
    }

    /// 战场是正方形，边长取「可用宽度」与「扣掉 HUD 和控制区下限后的剩余高度」的较小值，
    /// 这样在 iPhone SE 到 Pro Max 上都完整可见且不会被拉伸
    private func battlefieldSide(in size: CGSize) -> CGFloat {
        let heightForBattlefield = size.height - GameConfig.hudHeight - GameConfig.controlAreaMinHeight
        return max(0, min(size.width, heightForBattlefield))
    }

    private func battlefield(side: CGFloat) -> some View {
        SpriteView(
            scene: scene,
            preferredFramesPerSecond: GameConfig.preferredFramesPerSecond,
            options: [.shouldCullNonVisibleNodes],
            debugOptions: debugOptions
        )
        .frame(width: side, height: side)
    }

    private var debugOptions: SpriteView.DebugOptions {
        GameConfig.debugShowStats ? [.showsFPS, .showsNodeCount, .showsDrawCount] : []
    }

    private var hudPlaceholder: some View {
        placeholderBand(title: "HUD", fill: GameConfig.hudPlaceholderColor)
            .frame(height: GameConfig.hudHeight)
    }

    private var controlAreaPlaceholder: some View {
        placeholderBand(title: "CONTROLS", fill: GameConfig.controlAreaPlaceholderColor)
            .frame(maxHeight: .infinity)
    }

    private func placeholderBand(title: String, fill: SKColor) -> some View {
        ZStack {
            Color(fill)
            Text(title)
                .font(.system(.caption, design: .monospaced).weight(.bold))
                .foregroundStyle(Color(GameConfig.placeholderLabelColor))
        }
    }
}
