//
//  PlayerControlTests.swift
//  war of tankTests
//

import CoreGraphics
import SpriteKit
import Testing
@testable import war_of_tank

struct PlayerControlTests {

    @Test("摇杆方向优先于键盘，松开摇杆后键盘还能接着控")
    func analogOverridesKeyboard() {
        let input = ControlInput()
        input.setKeyboard(.up, isDown: true)
        #expect(input.direction == .up)
        input.setAnalog(.left)
        #expect(input.direction == .left)
        input.setAnalog(nil)
        #expect(input.direction == .up)
        input.setKeyboard(.up, isDown: false)
        #expect(input.direction == nil)
    }

    @Test("摇杆取绝对值较大的轴，死区内没有方向")
    func joystickPicksDominantAxisAndDeadZone() {
        let dead = GameConfig.joystickDeadZone

        #expect(Direction.fromVector(CGPoint(x: dead / 2, y: 0), deadZone: dead) == nil)
        #expect(Direction.fromVector(CGPoint(x: 20, y: 8), deadZone: dead) == .right)
        #expect(Direction.fromVector(CGPoint(x: -20, y: 8), deadZone: dead) == .left)
        #expect(Direction.fromVector(CGPoint(x: 8, y: 20), deadZone: dead) == .up)
        #expect(Direction.fromVector(CGPoint(x: 8, y: -20), deadZone: dead) == .down)
    }

    @Test("转向时垂直轴吸附到最近的 8pt 倍数")
    func turningSnapsPerpendicularAxis() {
        let map = GridMap(rows: Levels.level1.rows)
        let tank = PlayerTank(at: CGPoint(x: 20, y: 24))
        tank.direction = .right
        tank.commandedDirection = .up

        let delta = tank.move(dt: 0, in: map)
        let grain = GameConfig.alignmentGranularity

        #expect(tank.direction == .up)
        #expect(delta.x == (20 / grain).rounded() * grain - 20)
        #expect(delta.y == 0)
    }

    @Test("冻结或僵直时不能移动也不能开火")
    func frozenOrStunnedBlocksActions() {
        let map = GridMap(rows: Levels.level1.rows)
        let tank = PlayerTank(at: map.center(of: map.playerSpawn))
        tank.commandedDirection = .up

        tank.isFrozen = true
        #expect(tank.move(dt: 1, in: map) == .zero)
        #expect(tank.fire() == nil)

        tank.isFrozen = false
        tank.isStunned = true
        #expect(tank.move(dt: 1, in: map) == .zero)
        #expect(tank.fire() == nil)
    }

    @Test("火力等级决定同屏子弹数、速度和破钢墙")
    func firepowerMapsToBulletRules() {
        let tank = PlayerTank(at: .zero)

        #expect(tank.firepower == 0)
        #expect(tank.maxSimultaneousBullets == GameConfig.playerMaxBulletsLow)
        #expect(tank.bulletSpeed == GameConfig.playerBulletSpeedLevel0)
        #expect(tank.canBreakSteel == false)

        tank.firepower = 1
        #expect(tank.maxSimultaneousBullets == GameConfig.playerMaxBulletsLow)
        #expect(tank.bulletSpeed == GameConfig.playerBulletSpeedUpgraded)
        #expect(tank.canBreakSteel == false)

        tank.firepower = 2
        #expect(tank.maxSimultaneousBullets == GameConfig.playerMaxBulletsHigh)
        #expect(tank.canBreakSteel == false)

        tank.firepower = 3
        #expect(tank.maxSimultaneousBullets == GameConfig.playerMaxBulletsHigh)
        #expect(tank.canBreakSteel)

        tank.firepower = 9
        #expect(tank.firepower == GameConfig.playerFirepowerMax)
    }

    @Test("resetPowerUps 清掉火力和全部临时状态")
    func resetPowerUpsClearsTemporaryState() {
        let tank = PlayerTank(at: .zero)
        tank.firepower = 3
        tank.hasShield = true
        tank.isFrozen = true
        tank.isStunned = true

        tank.resetPowerUps()

        #expect(tank.firepower == 0)
        #expect(tank.hasShield == false)
        #expect(tank.isFrozen == false)
        #expect(tank.isStunned == false)
        #expect(tank.canBreakSteel == false)
        #expect(tank.maxSimultaneousBullets == GameConfig.playerMaxBulletsLow)
    }

    @Test("护盾期间不受伤")
    func shieldBlocksDamage() {
        let tank = PlayerTank(at: .zero)
        tank.hasShield = true
        let hp = tank.hp
        tank.takeDamage()
        #expect(tank.hp == hp)
    }

    @Test("火力改炮口闪颜色，护盾不改炮管色")
    func firepowerChangesMuzzleFlashColor() {
        let tank = PlayerTank(at: .zero)
        #expect(colorsMatch(tank.muzzleFlashColor, GameConfig.playerShadeColor))
        tank.firepower = 1
        #expect(colorsMatch(tank.muzzleFlashColor, GameConfig.playerBarrelPoweredColor))
        tank.hasShield = true
        #expect(colorsMatch(tank.muzzleFlashColor, GameConfig.playerBarrelPoweredColor))
        tank.resetPowerUps()
        #expect(colorsMatch(tank.muzzleFlashColor, GameConfig.playerShadeColor))
    }

    @Test("火力改炮管贴图、护盾改外壳贴图，缓存键跟着变")
    func powerUpsSwapAppearanceKeys() {
        let tank = PlayerTank(at: .zero)
        let baseKey = tank.trackCacheKey

        tank.firepower = 1
        #expect(tank.trackCacheKey.contains("fp1"))
        #expect(tank.trackCacheKey != baseKey)

        tank.hasShield = true
        #expect(tank.trackCacheKey.contains("sh1"))
        #expect(tank.trackCacheKey.contains("fp1"))

        tank.resetPowerUps()
        #expect(tank.trackCacheKey.contains("fp0"))
        #expect(tank.trackCacheKey.contains("sh0"))
    }

    @Test("开火消耗冷却，冷却未转好时不能连发")
    func fireHonorsCooldown() {
        let tank = PlayerTank(at: .zero)
        tank.fireCooldown = 1
        #expect(tank.fire() != nil)
        #expect(tank.fire() == nil)
        tank.updateTiming(dt: 1)
        #expect(tank.fire() != nil)
    }

    @Test("视觉缩进不改碰撞盒、占地和炮口碰撞边")
    func visualInsetKeepsCollisionSemantics() {
        let tank = PlayerTank(at: CGPoint(x: 80, y: 64))
        #expect(tank.size == GameConfig.tileNodeSize)
        #expect(tank.collisionRect.size == GameConfig.tileNodeSize)
        #expect(tank.footprintTiles == 1)
        #expect(tank.collisionRect.origin.x == tank.position.x - tank.size.width / 2)
        #expect(tank.collisionRect.origin.y == tank.position.y - tank.size.height / 2)

        let muzzle = tank.muzzlePoint(along: Direction.up.vector)
        #expect(muzzle.x == tank.position.x)
        #expect(muzzle.y == tank.position.y + tank.size.height / 2)
    }

    @Test("转向插值只改显示角，子弹仍走离散四向")
    func turnInterpolationDoesNotSkewBullets() {
        let scene = SKScene(size: GameConfig.sceneSize)
        let tank = PlayerTank(at: CGPoint(x: 32, y: 32))
        scene.addChild(tank)

        tank.direction = .right
        #expect(tank.action(forKey: GameConfig.tankTurnActionKey) != nil)
        #expect(tank.direction == .right)

        tank.zRotation = -.pi / 4
        let bullet = tank.makeBullet()
        #expect(bullet.direction == .right)
        #expect(bullet.travel.dx == 1)
        #expect(bullet.travel.dy == 0)
        #expect(bullet.position.x == tank.position.x + tank.size.width / 2)
        #expect(bullet.position.y == tank.position.y)
    }

    @Test("停下立刻停履带和抖动，抖动不写进碰撞盒")
    func stoppingMotionHaltsBobWithoutMovingCollision() {
        let tank = PlayerTank(at: CGPoint(x: 48, y: 48))
        let origin = tank.position
        let box = tank.collisionRect

        tank.presentMotion(true)
        #expect(tank.isShowingMotion)
        let visual = tank.childNode(withName: GameConfig.tankVisualNodeName)
        #expect(visual?.action(forKey: GameConfig.tankBobActionKey) != nil)

        tank.presentMotion(false)
        #expect(tank.isShowingMotion == false)
        #expect(visual?.action(forKey: GameConfig.tankBobActionKey) == nil)
        #expect(visual?.position == .zero)
        #expect(tank.position == origin)
        #expect(tank.collisionRect == box)
    }

    private func colorsMatch(_ lhs: SKColor, _ rhs: SKColor) -> Bool {
        var lr: CGFloat = 0, lg: CGFloat = 0, lb: CGFloat = 0, la: CGFloat = 0
        var rr: CGFloat = 0, rg: CGFloat = 0, rb: CGFloat = 0, ra: CGFloat = 0
        lhs.getRed(&lr, green: &lg, blue: &lb, alpha: &la)
        rhs.getRed(&rr, green: &rg, blue: &rb, alpha: &ra)
        return abs(lr - rr) < 0.01 && abs(lg - rg) < 0.01 && abs(lb - rb) < 0.01 && abs(la - ra) < 0.01
    }
}
