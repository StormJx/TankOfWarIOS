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

            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
                CGRect(x: x * px, y: y * px, width: w * px, height: h * px)
            }

            func fill(_ r: CGRect, _ color: SKColor) {
                cg.setFillColor(color.cgColor)
                cg.fill(r)
            }

            // 履带
            fill(rect(1, 5, 3, 10), track)
            fill(rect(12, 5, 3, 10), track)
            // 车体
            fill(rect(4, 6, 8, 8), body)
            fill(rect(5, 5, 6, 1), body)
            // 炮塔
            fill(rect(5, 8, 6, 4), track)
            // 舱盖
            fill(rect(7, 9, 2, 2), .black)
            // 炮管
            fill(rect(5, 0, 1, 6), .black)
            fill(rect(10, 0, 1, 6), .black)
            fill(rect(6, 0, 4, 6), barrel)
            fill(rect(6, 0, 4, 1), .white)
            // 外轮廓
            cg.setStrokeColor(SKColor.black.cgColor)
            cg.setLineWidth(px)
            cg.stroke(rect(1, 0, 14, 15).insetBy(dx: px / 2, dy: px / 2))
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }
}
