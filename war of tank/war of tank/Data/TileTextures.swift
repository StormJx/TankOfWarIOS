//
//  TileTextures.swift
//  war of tank
//

import SpriteKit
import UIKit

/// 阶段 1-6 的地形占位贴图，由代码生成。阶段 7 换成 texture atlas 时
/// 只替换内部实现，对外始终只有 texture(for:) 这一个入口。
enum TileTextures {

    private static var cache: [TileType: SKTexture] = [:]

    /// 空地不生成节点，直接透出场景底色，所以返回 nil
    static func texture(for type: TileType) -> SKTexture? {
        guard type != .empty else { return nil }
        if let cached = cache[type] {
            return cached
        }
        let texture = make(for: type)
        cache[type] = texture
        return texture
    }

    private static func make(for type: TileType) -> SKTexture {
        let side = GameConfig.tileSize
        let format = UIGraphicsImageRendererFormat.default()
        // 贴图必须正好是 16x16 像素，放大交给 SpriteKit 的 nearest 采样，
        // 用 Retina 倍率生成会先被平滑一次，像素边缘就糊了
        format.scale = 1

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
        let image = renderer.image { context in
            draw(type, in: context.cgContext, side: side)
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }

    private static func draw(_ type: TileType, in context: CGContext, side: CGFloat) {
        let base = baseColor(for: type)
        fill(CGRect(x: 0, y: 0, width: side, height: side), with: base, in: context)

        let light = base.adjustingBrightness(by: GameConfig.tileDetailLightenFactor)
        let dark = base.adjustingBrightness(by: GameConfig.tileDetailDarkenFactor)
        let thickness = GameConfig.tileDetailThickness
        let half = side / 2
        let quarter = side / 4
        let dot = side / 8

        switch type {
        case .empty:
            break

        case .brick:
            fill(CGRect(x: 0, y: half - thickness / 2, width: side, height: thickness), with: dark, in: context)
            fill(CGRect(x: quarter, y: 0, width: thickness, height: half), with: dark, in: context)
            fill(CGRect(x: side - quarter, y: half, width: thickness, height: half), with: dark, in: context)

        case .steel:
            fill(CGRect(x: half - thickness / 2, y: 0, width: thickness, height: side), with: dark, in: context)
            fill(CGRect(x: 0, y: half - thickness / 2, width: side, height: thickness), with: dark, in: context)
            fill(CGRect(x: thickness, y: thickness, width: quarter, height: quarter), with: light, in: context)

        case .water:
            fill(CGRect(x: dot, y: quarter, width: half, height: thickness), with: light, in: context)
            fill(CGRect(x: half - dot, y: side - quarter, width: half, height: thickness), with: light, in: context)

        case .grass:
            for spot in [CGPoint(x: dot, y: dot),
                         CGPoint(x: half + dot, y: dot * 2),
                         CGPoint(x: dot * 2, y: half + dot),
                         CGPoint(x: half + dot * 2, y: half + dot * 2)] {
                fill(CGRect(x: spot.x, y: spot.y, width: dot, height: dot), with: light, in: context)
            }

        case .ice:
            for step in 0..<3 {
                let offset = CGFloat(step) * quarter
                fill(CGRect(x: offset, y: side - quarter - offset, width: quarter, height: thickness),
                     with: light, in: context)
            }

        case .base:
            context.setStrokeColor(dark.cgColor)
            context.setLineWidth(thickness)
            context.stroke(CGRect(x: 0, y: 0, width: side, height: side)
                .insetBy(dx: thickness / 2, dy: thickness / 2))

            // 老鹰的占位轮廓，只求能一眼认出这格是基地
            let eagle = CGMutablePath()
            eagle.move(to: CGPoint(x: half, y: quarter))
            eagle.addLine(to: CGPoint(x: side - quarter, y: side - quarter))
            eagle.addLine(to: CGPoint(x: quarter, y: side - quarter))
            eagle.closeSubpath()
            context.setFillColor(dark.cgColor)
            context.addPath(eagle)
            context.fillPath()
        }
    }

    private static func fill(_ rect: CGRect, with color: SKColor, in context: CGContext) {
        context.setFillColor(color.cgColor)
        context.fill(rect)
    }

    private static func baseColor(for type: TileType) -> SKColor {
        switch type {
        case .empty: return GameConfig.battlefieldColor
        case .brick: return GameConfig.brickColor
        case .steel: return GameConfig.steelColor
        case .water: return GameConfig.waterColor
        case .grass: return GameConfig.grassColor
        case .ice: return GameConfig.iceColor
        case .base: return GameConfig.baseColor
        }
    }
}

private extension SKColor {
    /// 明暗细节一律从底色推导，省掉为每种地形再定义一组高光与阴影常量
    func adjustingBrightness(by factor: CGFloat) -> SKColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        guard getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return self
        }
        return SKColor(hue: hue, saturation: saturation, brightness: min(brightness * factor, 1), alpha: alpha)
    }
}
