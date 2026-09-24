//
//  TankPlaceholderTextures.swift
//  war of tank
//

import SpriteKit
import UIKit

/// atlas 缺失时的代码占位：结构对齐像素坦克（描边 / 履带 / 炮塔 / 炮管），避免退回纯色方块。
enum TankPlaceholderTextures {

    static func make(
        body: SKColor,
        track: SKColor,
        barrel: SKColor,
        side: CGFloat = GameConfig.tileSize
    ) -> SKTexture {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
        let image = renderer.image { context in
            let cg = context.cgContext
            let px = side / 16
            let inset = GameConfig.tankVisualInset

            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
                CGRect(x: x * px, y: y * px, width: w * px, height: h * px)
            }

            func fill(_ r: CGRect, _ color: SKColor) {
                cg.setFillColor(color.cgColor)
                cg.fill(r)
            }

            // 履带：2px 条纹、四边留 1 单位，和 atlas 第 0 帧对齐
            for y in stride(from: CGFloat(6), to: 15, by: 1) {
                let stripe = (Int(y) / 2) % 2 == 0
                let color = stripe ? track : body
                fill(rect(2, y, 3, 1), color)
                fill(rect(11, y, 3, 1), color)
            }
            // 车体
            fill(rect(5, 7, 6, 7), body)
            fill(rect(6, 6, 4, 1), body)
            // 炮塔
            fill(rect(6, 9, 4, 3), track)
            // 舱盖
            fill(rect(7, 10, 2, 2), .black)
            // 炮管：通体 barrel，顶端缩进，不再刷白炮口
            fill(rect(5, 1, 1, 6), .black)
            fill(rect(10, 1, 1, 6), .black)
            fill(rect(6, 1, 4, 6), barrel)
            // 外轮廓停在 inset 内侧，避免和墙顶边
            cg.setStrokeColor(SKColor.black.cgColor)
            cg.setLineWidth(px)
            let outline = rect(inset, inset, 16 - inset * 2, 16 - inset * 2)
            cg.stroke(outline.insetBy(dx: px / 2, dy: px / 2))
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }
}
