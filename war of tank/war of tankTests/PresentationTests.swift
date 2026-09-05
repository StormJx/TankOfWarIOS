//
//  PresentationTests.swift
//  war of tankTests
//

import Foundation
import SpriteKit
import Testing
@testable import war_of_tank

struct PresentationTests {

    @Test("地形贴图是 nearest，空地没有贴图")
    func tileTexturesStayNearest() {
        #expect(TileTextures.texture(for: .empty) == nil)
        let brick = TileTextures.texture(for: .brick)
        #expect(brick != nil)
        #expect(brick?.filteringMode == .nearest)
        let water0 = TileTextures.texture(for: .water, frame: 0)
        let water1 = TileTextures.texture(for: .water, frame: 1)
        #expect(water0 != nil)
        #expect(water1 != nil)
    }

    @Test("静音开关写在隔离存档里，重启语义保持")
    func mutePersistsInIsolatedStore() {
        let suite = "war.of.tank.tests.audio.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            Issue.record("无法创建隔离 UserDefaults")
            return
        }
        defaults.removePersistentDomain(forName: suite)
        let previous = AudioManager.store
        AudioManager.store = defaults
        defer {
            AudioManager.store = previous
            defaults.removePersistentDomain(forName: suite)
        }
        #expect(AudioManager.isMuted == false)
        AudioManager.isMuted = true
        #expect(AudioManager.isMuted)
        AudioManager.isMuted = false
        #expect(AudioManager.isMuted == false)
    }

    @Test("菜单和结算用菜单色，战场保持纯黑")
    func menuChromeDiffersFromBattlefield() {
        #expect(isBlack(GameConfig.battlefieldColor))
        #expect(!isBlack(GameConfig.menuBackgroundColor))
    }

    private func isBlack(_ color: SKColor) -> Bool {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return r < 0.01 && g < 0.01 && b < 0.01 && a > 0.99
    }

    @Test("战场边长按 sceneSide 整数倍吸附，过窄时退回可用边长")
    func battlefieldSideSnapsToIntegerScale() {
        let side = GameConfig.sceneSide
        #expect(GameConfig.integerScaledBattlefieldSide(available: side * 2 + 30) == side * 2)
        #expect(GameConfig.integerScaledBattlefieldSide(available: side * 1.2) == side)
        #expect(GameConfig.integerScaledBattlefieldSide(available: side * 0.8) == side * 0.8)
        #expect(GameConfig.integerScaledBattlefieldSide(available: 0) == 0)
    }

    @Test("坦克视觉缩进和抖动只是表现常量，碰撞仍按 tile")
    func tankPresentationConstantsStayVisualOnly() {
        #expect(GameConfig.tankVisualInset == 1)
        #expect(GameConfig.tankBobAmplitude == 0.5)
        #expect(GameConfig.tankBobPeriod == 0.1)
        #expect(GameConfig.tankTurnDuration == 0.05)
        #expect(GameConfig.tileNodeSize == CGSize(width: GameConfig.tileSize, height: GameConfig.tileSize))
    }

}
