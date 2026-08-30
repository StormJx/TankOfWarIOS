//
//  GameContainerView.swift
//  war of tank
//

import SpriteKit
import SwiftUI

struct GameContainerView: View {

    @StateObject private var flow = GameFlow()
    @State private var overlayScene: SKScene = SKScene(size: GameConfig.sceneSize)
    @State private var gameScene: GameScene?
    @State private var controlScene: ControlScene?
    @State private var hudScene: HUDScene?

    var body: some View {
        Group {
            if flow.screen == .playing {
                playLayout
            } else {
                SpriteView(scene: overlayScene, preferredFramesPerSecond: GameConfig.preferredFramesPerSecond)
            }
        }
        .background(Color(chromeColor).ignoresSafeArea())
        .onAppear(perform: startAtMenu)
        .onChange(of: flow.screen) { screen in
            syncOverlay(screen)
        }
        .onChange(of: flow.playGeneration) { _ in
            rebuildGame()
        }
        .onChange(of: flow.isPaused) { paused in
            applyPause(paused)
        }
    }

    /// 菜单/结算跟菜单色，进对局后回到战场黑，避免战场外一圈和菜单色打架
    private var chromeColor: SKColor {
        flow.screen == .playing ? GameConfig.battlefieldColor : GameConfig.menuBackgroundColor
    }

    private var playLayout: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    hudBand
                    battlefield(side: battlefieldSide(in: geometry.size))
                    controlPad
                }
                KeyboardCatcher(input: flow.input)
                    .frame(width: 0, height: 0)
                    .allowsHitTesting(false)
                if flow.isPaused {
                    PauseOverlay(
                        onResume: { flow.resume() },
                        onRestart: { flow.restartCurrentLevel() },
                        onMenu: { flow.backToMenu() }
                    )
                }
            }
        }
    }

    private func battlefieldSide(in size: CGSize) -> CGFloat {
        let heightForBattlefield = size.height - GameConfig.hudHeight - GameConfig.controlAreaMinHeight
        return max(0, min(size.width, heightForBattlefield))
    }

    private func battlefield(side: CGFloat) -> some View {
        Group {
            if let gameScene {
                SpriteView(
                    scene: gameScene,
                    preferredFramesPerSecond: GameConfig.preferredFramesPerSecond,
                    options: [.shouldCullNonVisibleNodes],
                    debugOptions: debugOptions
                )
            } else {
                Color.black
            }
        }
        .frame(width: side, height: side)
    }

    private var controlPad: some View {
        Group {
            if let controlScene {
                SpriteView(
                    scene: controlScene,
                    preferredFramesPerSecond: GameConfig.preferredFramesPerSecond,
                    options: [.shouldCullNonVisibleNodes]
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var hudBand: some View {
        ZStack(alignment: .trailing) {
            if let hudScene {
                SpriteView(scene: hudScene, preferredFramesPerSecond: GameConfig.preferredFramesPerSecond)
            }
            Button("II") { flow.togglePause() }
                .font(.system(size: GameConfig.hudIconFontSize, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(GameConfig.hudTextColor))
                .padding(.trailing, GameConfig.hudPauseButtonTrailing)
        }
        .frame(height: GameConfig.hudHeight)
    }

    private var debugOptions: SpriteView.DebugOptions {
        GameConfig.debugShowStats ? [.showsFPS, .showsNodeCount, .showsDrawCount] : []
    }

    private func startAtMenu() {
        AudioManager.prepare()
        PresentationCues.menu()
        if controlScene == nil {
            controlScene = ControlScene(input: flow.input)
        }
        if hudScene == nil {
            hudScene = HUDScene(hud: flow.hud)
        }
        overlayScene = MenuScene(flow: flow)
    }

    private func syncOverlay(_ screen: AppScreen) {
        if screen != .playing {
            gameScene = nil
        }
        switch screen {
        case .menu:
            PresentationCues.menu()
            overlayScene = MenuScene(flow: flow)
        case .levelClear:
            overlayScene = LevelClearScene(flow: flow)
        case .gameOver:
            overlayScene = GameOverScene(flow: flow)
        case .victory:
            PresentationCues.menu()
            overlayScene = VictoryScene(flow: flow)
        case .playing:
            break
        }
    }

    private func rebuildGame() {
        let scene = GameScene.battlefield(flow: flow)
        gameScene = scene
        applyPause(flow.isPaused)
    }

    private func applyPause(_ paused: Bool) {
        gameScene?.isPaused = paused
        controlScene?.isPaused = paused
        controlScene?.isUserInteractionEnabled = !paused
        if paused {
            flow.input.reset()
        } else {
            gameScene?.prepareForResume()
        }
    }
}
