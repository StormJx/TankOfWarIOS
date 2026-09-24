//
//  Tank.swift
//  war of tank
//

import SpriteKit

class Tank: SKSpriteNode {

    var direction: Direction = .up {
        didSet {
            if oldValue != direction {
                // 未入场时直接对齐，避免出生/单测里空转 0.05s
                presentFacing(direction, animated: parent != nil)
            }
        }
    }

    var moveSpeed: CGFloat
    var hp: Int
    var isFrozen = false
    var isStunned = false
    var fireCooldown: TimeInterval
    var fireCooldownRemaining: TimeInterval = 0
    var faction: Faction
    var bulletSpeed: CGFloat
    var canBreakSteel = false
    var canPierceBrick = false
    var commandedDirection: Direction?
    var isInvincible = false
    var trackFrames: [SKTexture] = []
    var trackCacheKey = ""
    private var isPresentingMotion = false
    /// 贴图和抖动挂在这里，父节点 position 只服务碰撞
    private let visualNode = SKSpriteNode(color: .clear, size: .zero)

    var isShowingMotion: Bool { isPresentingMotion }

    init(
        texture: SKTexture?,
        size: CGSize,
        moveSpeed: CGFloat,
        hp: Int,
        fireCooldown: TimeInterval,
        faction: Faction,
        bulletSpeed: CGFloat
    ) {
        self.moveSpeed = moveSpeed
        self.hp = hp
        self.fireCooldown = fireCooldown
        self.faction = faction
        self.bulletSpeed = bulletSpeed
        super.init(texture: nil, color: .clear, size: size)
        zPosition = GameConfig.Layer.tank
        zRotation = direction.zRotation
        configureVisual(texture)
        attachGroundShadow()
    }

    private func configureVisual(_ texture: SKTexture?) {
        visualNode.name = GameConfig.tankVisualNodeName
        visualNode.size = size
        visualNode.zPosition = 0
        displayTexture(texture)
        addChild(visualNode)
    }

    func displayTexture(_ texture: SKTexture?) {
        visualNode.texture = texture
        visualNode.texture?.filteringMode = .nearest
    }

    /// 插值只改显示角；commandedDirection / 子弹仍读离散 Direction
    func presentFacing(_ facing: Direction, animated: Bool) {
        removeAction(forKey: GameConfig.tankTurnActionKey)
        if !animated {
            zRotation = facing.zRotation
            return
        }
        run(
            SpriteProvider.turnAction(to: facing).copy() as! SKAction,
            withKey: GameConfig.tankTurnActionKey
        )
    }

    /// 椭圆软阴影挂在脚下；随车身旋转，只负责贴地感，不进碰撞盒
    private func attachGroundShadow() {
        let shadow = SKShapeNode(ellipseOf: CGSize(
            width: size.width * GameConfig.tankShadowScaleX,
            height: size.height * GameConfig.tankShadowScaleY
        ))
        shadow.fillColor = GameConfig.tankShadowColor
        shadow.strokeColor = .clear
        shadow.alpha = GameConfig.tankShadowAlpha
        shadow.zPosition = -1
        shadow.position = CGPoint(x: 0, y: GameConfig.tankShadowOffsetY)
        // 阴影不吃点击，避免偶发挡住子弹判定以外的交互
        shadow.isUserInteractionEnabled = false
        addChild(shadow)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Tank 不支持从归档初始化")
    }

    var canMove: Bool {
        !isFrozen && !isStunned && hp > 0
    }

    var canFire: Bool {
        !isFrozen && !isStunned && hp > 0 && fireCooldownRemaining <= 0
    }

    var maxSimultaneousBullets: Int { 1 }

    /// 炮口闪颜色跟当前炮管：基础暗部 / 火力热红，由子类覆盖
    var muzzleFlashColor: SKColor { GameConfig.playerShadeColor }

    var footprintTiles: Int {
        max(1, Int((size.width / GameConfig.tileSize).rounded()))
    }

    var collisionRect: CGRect {
        CGRect(
            x: position.x - size.width / 2,
            y: position.y - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    /// 转向时把垂直轴并进位移，交给 CollisionSystem 裁剪，避免吸附直接嵌进墙里
    func move(dt: TimeInterval, in _: GridMap) -> CGPoint {
        guard canMove, let command = commandedDirection else { return .zero }

        let travel = moveSpeed * CGFloat(dt)
        var delta = CGPoint(
            x: command.vector.dx * travel,
            y: command.vector.dy * travel
        )

        // 每帧都吸附一次：转向当帧若被墙裁掉，下一帧还能继续对进走廊
        let snapped = alignedPosition(for: command)
        delta.x += snapped.x - position.x
        delta.y += snapped.y - position.y
        direction = command

        return delta
    }

    func fire() -> Bullet? {
        fireVolley().first
    }

    func fireVolley() -> [Bullet] {
        guard canFire else { return [] }
        fireCooldownRemaining = fireCooldown
        return [makeBullet()]
    }

    func takeDamage(_ amount: Int = 1) {
        if isInvincible { return }
        hp -= amount
    }

    func updateTiming(dt: TimeInterval) {
        if fireCooldownRemaining > 0 {
            fireCooldownRemaining = max(0, fireCooldownRemaining - dt)
        }
    }

    func makeBullet() -> Bullet {
        let bullet = Bullet(
            direction: direction,
            moveSpeed: bulletSpeed,
            canBreakSteel: canBreakSteel,
            owner: faction,
            canPierceBrick: canPierceBrick
        )
        bullet.position = muzzlePoint(along: direction.vector)
        return bullet
    }

    func muzzlePoint(along travel: CGVector) -> CGPoint {
        let offset = size.width / 2
        return CGPoint(
            x: position.x + travel.dx * offset,
            y: position.y + travel.dy * offset
        )
    }

    private func alignedPosition(for newDirection: Direction) -> CGPoint {
        let tiles = footprintTiles
        let half = size.width / 2
        let minCenter = half
        let maxCenter = GameConfig.sceneSide - half
        let grain = tiles == 1 ? GameConfig.alignmentGranularity : GameConfig.tileSize
        let offset = tiles % 2 == 0 ? 0 : GameConfig.tileSize / 2

        func snap(_ value: CGFloat) -> CGFloat {
            ((value - offset) / grain).rounded() * grain + offset
        }

        var snapped = position
        if newDirection.isHorizontal {
            snapped.y = snap(position.y)
        } else {
            snapped.x = snap(position.x)
        }
        snapped.x = min(max(snapped.x, minCenter), maxCenter)
        snapped.y = min(max(snapped.y, minCenter), maxCenter)
        return snapped
    }

    func applyTrackFrames(_ frames: [SKTexture], cacheKey: String) {
        trackFrames = frames
        trackCacheKey = cacheKey
        if let first = frames.first {
            displayTexture(first)
        }
    }

    /// 换装贴图时若正在履带动画，先停再按新帧重启，避免旧 SKAction 继续刷旧纹理
    func replaceTrackFrames(_ frames: [SKTexture], cacheKey: String) {
        let moving = isPresentingMotion
        presentMotion(false)
        applyTrackFrames(frames, cacheKey: cacheKey)
        if moving {
            presentMotion(true)
        }
    }

    func presentMotion(_ moving: Bool) {
        guard moving != isPresentingMotion else { return }
        isPresentingMotion = moving
        if moving {
            if trackFrames.count >= 2 {
                visualNode.run(
                    SpriteProvider.trackAction(for: trackFrames, cacheKey: trackCacheKey).copy() as! SKAction,
                    withKey: GameConfig.trackActionKey
                )
            }
            visualNode.run(
                SpriteProvider.motionBobAction().copy() as! SKAction,
                withKey: GameConfig.tankBobActionKey
            )
        } else {
            visualNode.removeAction(forKey: GameConfig.trackActionKey)
            visualNode.removeAction(forKey: GameConfig.tankBobActionKey)
            visualNode.position = .zero
            if let first = trackFrames.first {
                displayTexture(first)
            }
        }
    }
}
