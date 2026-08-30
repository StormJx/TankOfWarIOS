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

        for row in 0..<GameConfig.gridCount {
            for col in 0..<GameConfig.gridCount {
                addNode(at: GridPoint(col: col, row: row))
            }
        }
    }

    /// 子弹破墙后只重画这一个 tile，整图重建会在 60fps 下明显掉帧
    func refreshTile(at point: GridPoint) {
        tileNodes[point]?.removeFromParent()
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
    }
}
