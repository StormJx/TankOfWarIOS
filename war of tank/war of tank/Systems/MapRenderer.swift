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
    private var tileNodes: [GridPoint: SKNode] = [:]
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
            if let sprite = old as? SKSpriteNode {
                waterNodes.removeAll { $0 === sprite }
            }
            old.removeFromParent()
        }
        tileNodes[point] = nil
        addNode(at: point)
    }

    private func addNode(at point: GridPoint) {
        let type = map.tile(at: point)
        if type == .brick {
            addBrick(at: point)
            return
        }
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

    /// 四块 8pt 各自用砖贴图的一角，打掉的块不再画出来
    private func addBrick(at point: GridPoint) {
        let mask = map.brickMask(at: point)
        guard mask != 0 else { return }
        let container = SKNode()
        container.position = map.center(of: point)
        let half = GameConfig.tileSize / 4
        let piece = GameConfig.tileSize / 2
        for index in 0..<4 where mask & (1 << index) != 0 {
            let texture = TileTextures.brickQuadrant(index)
            let node = SKSpriteNode(
                texture: texture,
                color: texture == nil ? GameConfig.brickColor : .clear,
                size: CGSize(width: piece, height: piece)
            )
            node.texture?.filteringMode = .nearest
            let dx: CGFloat = index % 2 == 1 ? half : -half
            let dy: CGFloat = index >= 2 ? half : -half
            node.position = CGPoint(x: dx, y: dy)
            container.addChild(node)
        }
        terrainLayer.addChild(container)
        tileNodes[point] = container
    }
}
