//
//  MapRenderer.swift
//  war of tank
//

import SpriteKit

/// 把 GridMap 渲染成节点树。草丛单独一层压在坦克之上形成遮蔽，其余地形在底层。
final class MapRenderer {

    private let map: GridMap
    private let terrainLayer = SKNode()
    private let grassLayer = SKNode()
    private var tileNodes: [GridPoint: SKSpriteNode] = [:]
    private var waterNodes: [SKSpriteNode] = []
    private var waterAge: TimeInterval = 0
    private var waterFrame = 0

    init(map: GridMap) {
        self.map = map
        terrainLayer.zPosition = GameConfig.Layer.terrain
        grassLayer.zPosition = GameConfig.Layer.grass
    }

    func attach(to parent: SKNode) {
        parent.addChild(terrainLayer)
        parent.addChild(grassLayer)
        renderAll()
    }

    func renderAll() {
        tileNodes.values.forEach { $0.removeFromParent() }
        tileNodes.removeAll()
        waterNodes.removeAll()

        for row in 0..<GameConfig.gridCount {
            for col in 0..<GameConfig.gridCount {
                addNode(at: GridPoint(col: col, row: row))
            }
        }
    }

    func tickWater(dt: TimeInterval) {
        guard !waterNodes.isEmpty else { return }
        waterAge += dt
        let frame = Int(waterAge / GameConfig.waterFrameDuration) % 2
        guard frame != waterFrame else { return }
        waterFrame = frame
        guard let texture = TileTextures.texture(for: .water, frame: frame) else { return }
        for node in waterNodes {
            node.texture = texture
        }
    }

    /// 子弹破墙后只重画这一个 tile，整图重建会在 60fps 下明显掉帧
    func refreshTile(at point: GridPoint) {
        if let old = tileNodes[point] {
            waterNodes.removeAll { $0 === old }
            old.removeFromParent()
        }
        tileNodes[point] = nil
        addNode(at: point)
    }

    private func addNode(at point: GridPoint) {
        let type = map.tile(at: point)
        guard let texture = TileTextures.texture(for: type) else { return }

        let node = SKSpriteNode(texture: texture, size: GameConfig.tileNodeSize)
        node.position = map.center(of: point)

        let layer = type == .grass ? grassLayer : terrainLayer
        layer.addChild(node)
        tileNodes[point] = node
        if type == .water {
            waterNodes.append(node)
        }
    }
}
