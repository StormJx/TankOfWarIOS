//
//  GameScene.swift
//  war of tank
//

import SpriteKit

/// 阶段 1 的场景：确立 208x208 的逻辑坐标系与左下角原点，加载并渲染关卡地形。
/// 移动、输入与碰撞从阶段 2 起接入。
final class GameScene: SKScene {

    private var map: GridMap?
    private var mapRenderer: MapRenderer?

    /// 场景尺寸只允许从 GameConfig 推导，避免调用方各自构造 CGSize
    static func battlefield() -> GameScene {
        GameScene(size: GameConfig.sceneSize)
    }

    override init(size: CGSize) {
        super.init(size: size)

        // 原点固定在左下角：GridMap 的 y = sceneSide - (row * tileSize + tileSize/2)
        // 换算公式以此为前提，改成 .center 会让全部行列换算失效
        anchorPoint = .zero
        scaleMode = .aspectFit
        backgroundColor = GameConfig.battlefieldColor

        load(GameConfig.debugTerrainShowcase ? Levels.terrainShowcase : Levels.level1)
    }

    required init?(coder aDecoder: NSCoder) {
        // 场景全部由代码构建，工程里不保留任何 .sks，因此没有反序列化路径
        fatalError("GameScene 不支持从归档初始化")
    }

    private func load(_ level: LevelData) {
        let map = GridMap(rows: level.rows)
        let renderer = MapRenderer(map: map)
        renderer.attach(to: self)

        self.map = map
        self.mapRenderer = renderer

        if GameConfig.debugShowGrid {
            addChild(makeGridOverlay(for: map))
        }
        if GameConfig.debugTerrainShowcase {
            addGrassOcclusionProbe(in: map)
        }
    }

    private func makeGridOverlay(for map: GridMap) -> SKNode {
        let overlay = SKNode()
        overlay.zPosition = GameConfig.Layer.ui

        let path = CGMutablePath()
        for index in 0...GameConfig.gridCount {
            let offset = CGFloat(index) * GameConfig.tileSize
            path.move(to: CGPoint(x: offset, y: 0))
            path.addLine(to: CGPoint(x: offset, y: GameConfig.sceneSide))
            path.move(to: CGPoint(x: 0, y: offset))
            path.addLine(to: CGPoint(x: GameConfig.sceneSide, y: offset))
        }

        let lines = SKShapeNode(path: path)
        lines.strokeColor = GameConfig.debugGridLineColor
        lines.lineWidth = GameConfig.debugGridLineWidth
        overlay.addChild(lines)

        for row in 0..<GameConfig.gridCount {
            for col in 0..<GameConfig.gridCount {
                let point = GridPoint(col: col, row: row)
                let label = SKLabelNode(text: "\(col),\(row)")
                label.fontName = GameConfig.debugGridLabelFontName
                label.fontSize = GameConfig.debugGridLabelFontSize
                label.fontColor = GameConfig.debugGridLabelColor
                label.horizontalAlignmentMode = .center
                label.verticalAlignmentMode = .center
                label.position = map.center(of: point)
                overlay.addChild(label)
            }
        }

        return overlay
    }

    /// 在第一块草丛下面放个坦克层的方块，用来验证草丛确实盖在坦克之上
    private func addGrassOcclusionProbe(in map: GridMap) {
        guard let grassPoint = map.firstPoint(of: .grass) else { return }

        let probe = SKSpriteNode(color: GameConfig.playerColor, size: GameConfig.tileNodeSize)
        probe.position = map.center(of: grassPoint)
        probe.zPosition = GameConfig.Layer.tank
        addChild(probe)
    }
}
