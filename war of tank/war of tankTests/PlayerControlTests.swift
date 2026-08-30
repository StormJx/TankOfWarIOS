//
//  PlayerControlTests.swift
//  war of tankTests
//

import CoreGraphics
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

    @Test("开火消耗冷却，冷却未转好时不能连发")
    func fireHonorsCooldown() {
        let tank = PlayerTank(at: .zero)
        tank.fireCooldown = 1
        #expect(tank.fire() != nil)
        #expect(tank.fire() == nil)
        tank.updateTiming(dt: 1)
        #expect(tank.fire() != nil)
    }
}
