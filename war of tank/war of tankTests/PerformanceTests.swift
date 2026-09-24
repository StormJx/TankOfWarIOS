//
//  PerformanceTests.swift
//  war of tankTests
//

import SpriteKit
import Testing
import UIKit
@testable import war_of_tank

@Suite(.serialized)
@MainActor
struct PerformanceTests {

    @Test("战场离开对局后能释放，AI 和状态回调不把场景留住")
    func battlefieldReleasesWithoutRetainCycle() {
        weak var scene: GameScene?
        autoreleasepool {
            let flow = GameFlow()
            flow.startNewGame()
            let created = GameScene.battlefield(flow: flow)
            scene = created
            created.update(0)
            created.update(1.0 / 60.0)
        }
        #expect(scene == nil)
    }

    @Test("挂机几秒后节点数不再往上爬")
    func idleNodeCountStopsClimbing() {
        let flow = GameFlow()
        flow.startNewGame()
        let scene = GameScene.battlefield(flow: flow)
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 208, height: 208))
        let window = UIWindow(frame: view.frame)
        window.addSubview(view)
        window.makeKeyAndVisible()
        view.presentScene(scene)

        let early = nodeCount(after: 2, view: view, scene: scene)
        let late = nodeCount(after: 3, view: view, scene: scene)
        view.presentScene(nil)

        #expect(late <= early + 40, "early \(early) late \(late)")
    }

    private func nodeCount(after seconds: TimeInterval, view: SKView, scene: SKScene) -> Int {
        let until = Date().addingTimeInterval(seconds)
        while Date() < until {
            RunLoop.current.run(until: Date().addingTimeInterval(1.0 / 30.0))
        }
        _ = view
        return scene.children.count
    }
}
