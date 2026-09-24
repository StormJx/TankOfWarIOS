//
//  GameScene.swift
//  war of tank
//

import SpriteKit

/// 战场逻辑尺寸固定 208x208。主循环：dt → 出生 → 输入/AI → 移动 → 子弹 → 碰撞 → 清理。
final class GameScene: SKScene {

    private let input: ControlInput
    private let hud: GameHUDState
    private weak var flow: GameFlow?
    private var map: GridMap?
    private var mapRenderer: MapRenderer?
    private var player: PlayerTank?
    private var enemies: [EnemyTank] = []
    private var bullets: [Bullet] = []
    private var lastUpdateTime: TimeInterval = 0

    private var spawnSystem: SpawnSystem?
    private var powerUps = PowerUpSystem()
    private let status = StatusEffectManager()
    private let ai = AIController()
    private var lives = GameConfig.playerLives
    private var respawnRemaining: TimeInterval?
    private var isGameOver = false
    private let bossHealthBar = BossHealthBar()
    private var hitStopRemaining: TimeInterval = 0

    static func battlefield(flow: GameFlow) -> GameScene {
        GameScene(size: GameConfig.sceneSize, flow: flow)
    }

    init(size: CGSize, flow: GameFlow) {
        self.input = flow.input
        self.hud = flow.hud
        self.flow = flow
        super.init(size: size)

        // 原点固定在左下角：GridMap 的 y = sceneSide - (row * tileSize + tileSize/2)
        // 换成 .center 会让全部行列换算失效
        anchorPoint = .zero
        scaleMode = .aspectFit
        backgroundColor = GameConfig.battlefieldColor

        load(GameConfig.debugTerrainShowcase ? Levels.terrainShowcase : flow.levels.currentLevel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("GameScene 不支持从归档初始化")
    }

    override func update(_ currentTime: TimeInterval) {
        guard let map else { return }

        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }

        let dt = min(currentTime - lastUpdateTime, GameConfig.maxFrameDelta)
        lastUpdateTime = currentTime

        if isGameOver { return }
        if hitStopRemaining > 0 {
            hitStopRemaining = max(0, hitStopRemaining - dt)
            return
        }

        status.update(dt: dt)
        tickRespawn(dt: dt, map: map)
        spawnEnemies(dt: dt, map: map)
        mapRenderer?.tickWater(dt: dt)
        updatePowerUps(dt: dt, map: map)
        updatePlayer(dt: dt, map: map)
        updateEnemies(dt: dt, map: map)

        for bullet in bullets where !bullet.isDestroyed {
            advance(bullet, dt: dt, map: map)
        }
        bullets.removeAll { $0.isDestroyed }

        enemies.removeAll { enemy in
            guard enemy.hp <= 0 else { return false }
            if let boss = enemy as? BossTank {
                EffectFactory.bossDeath(at: boss.position, footprint: boss.size, in: self)
            }
            flow?.score.addKill(score: enemy.score)
            EffectFactory.scorePopup(enemy.score, at: enemy.position, in: self)
            ai.forget(enemy)
            status.clear(enemy: ObjectIdentifier(enemy))
            spawnSystem?.released(enemy)
            enemy.removeFromParent()
            return true
        }

        refreshHUD()
        checkLevelCleared()
    }

    func prepareForResume() {
        lastUpdateTime = 0
    }

    private func load(_ level: LevelData) {
        let map = GridMap(rows: level.rows)
        let renderer = MapRenderer(map: map)
        renderer.attach(to: self)

        self.map = map
        self.mapRenderer = renderer
        #if DEBUG
        if !GameConfig.debugTerrainShowcase {
            let problems = LevelValidator.issues(in: level, index: flow?.levels.currentIndex ?? 0)
            assert(problems.isEmpty, problems.joined(separator: "; "))
        }
        #endif

        spawnSystem = SpawnSystem(mix: level.enemyMix)
        powerUps = PowerUpSystem(isBossLevel: level.bossType != nil)
        lives = GameConfig.playerLives
        bindStatusCallbacks()

        let player = PlayerTank(at: map.center(of: map.playerSpawn))
        addChild(player)
        self.player = player
        spawnBossIfNeeded(level, map: map)
        bossHealthBar.position = CGPoint(
            x: GameConfig.sceneSide / 2,
            y: GameConfig.sceneSide - GameConfig.bossHealthBarTopInset
        )
        addChild(bossHealthBar)
        refreshHUD()
        PresentationCues.stageStarted(
            number: flow?.levels.stageNumber ?? 1,
            in: self,
            isBoss: level.bossType != nil
        )

        if GameConfig.debugShowGrid {
            addChild(makeGridOverlay(for: map))
        }
        if GameConfig.debugTerrainShowcase {
            addGrassOcclusionProbe(in: map)
        }
    }

    private func tickRespawn(dt: TimeInterval, map: GridMap) {
        guard var remaining = respawnRemaining else { return }
        remaining -= dt
        if remaining > 0 {
            respawnRemaining = remaining
            return
        }
        respawnRemaining = nil
        guard let player else { return }
        player.restoreAfterRespawn(at: map.center(of: map.playerSpawn))
        applyInvincible(to: player, duration: GameConfig.playerRespawnInvincibility)
        if player.parent == nil {
            addChild(player)
        }
    }

    private func spawnEnemies(dt: TimeInterval, map: GridMap) {
        guard let spawnSystem else { return }
        let blockers = allLivingTanks()
        let born = spawnSystem.update(
            dt: dt,
            map: map,
            parent: self,
            liveEnemies: enemies,
            blockingTanks: blockers
        )
        for enemy in born {
            addChild(enemy)
            enemies.append(enemy)
        }
    }

    private func updatePlayer(dt: TimeInterval, map: GridMap) {
        guard let player, player.hp > 0 else { return }
        player.updateTiming(dt: dt)
        player.commandedDirection = input.direction
        applyMove(player, dt: dt, map: map)
        if input.consumeFire() {
            tryFire(from: player, maxBullets: player.maxSimultaneousBullets)
        }
    }

    private func updateEnemies(dt: TimeInterval, map: GridMap) {
        ai.beginFrame()
        let livingPlayer = player.flatMap { $0.hp > 0 ? $0 : nil }
        for enemy in enemies where enemy.hp > 0 {
            enemy.updateTiming(dt: dt)
            let command = ai.command(
                for: enemy,
                dt: dt,
                map: map,
                player: livingPlayer,
                bullets: bullets,
                powerUp: powerUps.current
            )
            if let final = enemy as? FinalBoss, command.isCharging {
                applyCharge(final, direction: command.direction ?? final.direction, dt: dt, map: map)
            } else {
                enemy.commandedDirection = command.direction
                applyMove(enemy, dt: dt, map: map)
            }
            if let direction = command.startWindup, let final = enemy as? FinalBoss {
                beginWindup(final, direction: direction)
            }
            for _ in 0..<command.summonCount {
                spawnSummonedFast()
            }
            if command.shouldFire {
                tryFire(from: enemy, maxBullets: enemy.maxSimultaneousBullets)
            }
        }
    }

    private func applyMove(_ tank: Tank, dt: TimeInterval, map: GridMap) {
        let desired = tank.move(dt: dt, in: map)
        let clipped = CollisionSystem.resolveTankMove(
            tank: tank,
            desiredDelta: desired,
            map: map,
            others: allLivingTanks()
        )
        tank.position = CGPoint(
            x: tank.position.x + clipped.x,
            y: tank.position.y + clipped.y
        )
        tank.presentMotion(clipped.x != 0 || clipped.y != 0)
    }

    private func updatePowerUps(dt: TimeInterval, map: GridMap) {
        guard let renderer = mapRenderer else { return }
        powerUps.update(dt: dt, map: map, parent: self, tanks: allLivingTanks())
        let shovelLeft = status.remaining(.shovel)
        if shovelLeft > 0 {
            powerUps.blinkShovelIfNeeded(remaining: shovelLeft, map: map, renderer: renderer)
        }
        guard let (type, tank) = powerUps.collectIfNeeded(tanks: allLivingTanks(), map: map) else { return }
        PresentationCues.powerUpPicked(byPlayer: tank === player)
        if let player, tank === player {
            applyToPlayer(type)
        } else if let enemy = tank as? EnemyTank {
            applyToEnemy(type, enemy: enemy)
        }
    }

    private func tryFire(from tank: Tank, maxBullets: Int) {
        let live = bullets.filter { $0.owner == tank.faction && !$0.isDestroyed }.count
        guard live < maxBullets else { return }
        var added = live
        for bullet in tank.fireVolley() {
            guard added < maxBullets else { break }
            addChild(bullet)
            bullets.append(bullet)
            added += 1
        }
        if added > live {
            PresentationCues.fired()
            EffectFactory.muzzleFlash(
                at: tank.muzzlePoint(along: tank.direction.vector),
                color: tank.muzzleFlashColor,
                in: self
            )
        }
    }

    /// 高速子弹一步跨过薄墙，所以按不超过 bulletMaxStep 的步长推进
    private func advance(_ bullet: Bullet, dt: TimeInterval, map: GridMap) {
        let distance = bullet.moveSpeed * CGFloat(dt)
        let steps = max(1, Int(ceil(distance / GameConfig.bulletMaxStep)))
        let stepLength = distance / CGFloat(steps)
        let step = CGPoint(
            x: bullet.travel.dx * stepLength,
            y: bullet.travel.dy * stepLength
        )

        for _ in 0..<steps {
            bullet.position = CGPoint(
                x: bullet.position.x + step.x,
                y: bullet.position.y + step.y
            )
            let hit = CollisionSystem.bulletHitTest(
                bullet: bullet,
                map: map,
                tanks: allLivingTanks(),
                bullets: bullets
            )
            if handle(hit, for: bullet, map: map) {
                return
            }
        }
    }

    private func allLivingTanks() -> [Tank] {
        var tanks: [Tank] = enemies.filter { $0.hp > 0 }
        if let player, player.hp > 0 {
            tanks.append(player)
        }
        return tanks
    }

    @discardableResult
    private func handle(_ hit: HitResult, for bullet: Bullet, map: GridMap) -> Bool {
        switch hit {
        case .none:
            return false

        case .outOfBounds:
            bullet.markDestroyed()
            return true

        case .terrain(let point):
            let tile = map.tile(at: point)
            if tile == .base {
                EffectFactory.bigExplosion(at: map.center(of: point), in: self)
                PresentationCues.hitTerrain(.base)
                bullet.markDestroyed()
                finishGame()
                return true
            }
            let destroyed = map.destroyTile(at: point, byLevel3Bullet: bullet.canBreakSteel)
            if destroyed {
                mapRenderer?.refreshTile(at: point)
            }
            PresentationCues.hitTerrain(tile)
            EffectFactory.smallExplosion(at: map.center(of: point), in: self)
            bullet.markDestroyed()
            return true

        case .tank(let tank):
            let hpBefore = tank.hp
            let shieldWasUp = (tank as? PlayerTank)?.hasShield == true
            tank.takeDamage()
            if tank.hp <= 0 {
                if !(tank is BossTank) {
                    EffectFactory.bigExplosion(at: tank.position, in: self)
                    EffectFactory.shake(scene: self)
                    PresentationCues.bigExplosion()
                }
                hitStopRemaining = GameConfig.killHitStop
                handleTankDestroyed(tank)
            } else {
                EffectFactory.hitSpark(at: bullet.position, in: self)
                PresentationCues.smallExplosion()
                EffectFactory.hitFlash(on: tank, shielded: shieldWasUp && tank.hp == hpBefore)
            }
            bullet.markDestroyed()
            return true

        case .bullet(let other):
            PresentationCues.smallExplosion()
            EffectFactory.smallExplosion(at: bullet.position, in: self)
            other.markDestroyed()
            bullet.markDestroyed()
            return true
        }
    }

    private func handleTankDestroyed(_ tank: Tank) {
        if tank === player {
            playerDied()
        }
    }

    private func playerDied() {
        guard let player else { return }
        status.clearPlayerBoundEffects()
        player.resetPowerUps()
        player.isInvincible = false
        player.isHidden = true
        EffectFactory.stopFlicker(on: player)
        PresentationCues.playerHit()
        lives -= 1
        refreshHUD()
        if lives <= 0 {
            finishGame()
            return
        }
        respawnRemaining = GameConfig.playerRespawnDelay
    }

    private func bindStatusCallbacks() {
        status.onExpired = { [weak self] id in
            self?.handleExpired(id)
        }
    }

    private func handleExpired(_ id: StatusEffectID) {
        switch id {
        case .playerShield:
            player?.hasShield = false
        case .playerStun:
            player?.isStunned = false
        case .playerFreeze:
            player?.isFrozen = false
        case .playerInvincible:
            player?.isInvincible = false
            if let player { EffectFactory.stopFlicker(on: player) }
        case .bossSlow(let token):
            if let mini = enemy(for: token) as? MiniBoss {
                mini.isSlowed = false
                mini.refreshSpeed()
            }
        case .bossWindup(let token):
            if let final = enemy(for: token) as? FinalBoss {
                final.isWindingUp = false
                final.isCharging = true
                EffectFactory.stopChargeWarning(on: final)
            }
        case .bossStun(let token):
            enemy(for: token)?.isStunned = false
        case .enemyInvincible(let token):
            enemy(for: token)?.isInvincible = false
            if let enemy = enemy(for: token) { EffectFactory.stopFlicker(on: enemy) }
        case .enemyFreeze(let token):
            enemy(for: token)?.isFrozen = false
        case .shovel:
            if let map, let renderer = mapRenderer {
                powerUps.restoreShovel(map: map, renderer: renderer)
            }
        }
        refreshHUD()
    }

    private func enemy(for id: ObjectIdentifier) -> EnemyTank? {
        enemies.first { ObjectIdentifier($0) == id }
    }

    private func applyInvincible(to tank: Tank, duration: TimeInterval) {
        tank.isInvincible = true
        EffectFactory.applyInvincibleFlicker(to: tank)
        if tank === player {
            status.apply(.playerInvincible, duration: duration)
        } else {
            status.apply(.enemyInvincible(ObjectIdentifier(tank)), duration: duration)
        }
    }

    private func applyToPlayer(_ type: PowerUpType) {
        guard let player, let map, let renderer = mapRenderer else { return }
        switch type {
        case .star:
            player.firepower += 1
        case .helmet:
            player.hasShield = true
            status.apply(.playerShield, duration: GameConfig.helmetPlayerDuration)
        case .tank:
            lives += 1
        case .grenade:
            detonateGrenade()
        case .timer:
            for enemy in enemies where enemy.hp > 0 {
                if let mini = enemy as? MiniBoss {
                    mini.isSlowed = true
                    mini.refreshSpeed()
                    status.apply(.bossSlow(ObjectIdentifier(mini)), duration: GameConfig.timerEnemyFreezeDuration)
                } else if enemy is FinalBoss {
                    continue
                } else if !enemy.isBoss {
                    enemy.isFrozen = true
                    status.apply(.enemyFreeze(ObjectIdentifier(enemy)), duration: GameConfig.timerEnemyFreezeDuration)
                }
            }
        case .shovel:
            powerUps.applyShovel(asPlayer: true, map: map, renderer: renderer)
            status.apply(.shovel, duration: GameConfig.shovelDuration)
        }
        refreshHUD()
    }

    private func applyToEnemy(_ type: PowerUpType, enemy: EnemyTank) {
        guard let player, let map, let renderer = mapRenderer else { return }
        switch type {
        case .star:
            enemy.bulletSpeed = GameConfig.enemyBulletSpeed * GameConfig.enemyStarBulletSpeedMultiplier
            enemy.canPierceBrick = true
        case .helmet:
            applyInvincible(to: enemy, duration: GameConfig.helmetEnemyDuration)
        case .tank:
            if let extra = spawnSystem?.spawnReinforcement(map: map, liveEnemies: enemies, blockingTanks: allLivingTanks()) {
                addChild(extra)
                enemies.append(extra)
            }
        case .grenade:
            player.isStunned = true
            status.apply(.playerStun, duration: GameConfig.grenadePlayerStunDuration)
        case .timer:
            player.isFrozen = true
            status.apply(.playerFreeze, duration: GameConfig.timerPlayerFreezeDuration)
        case .shovel:
            powerUps.applyShovel(asPlayer: false, map: map, renderer: renderer)
            status.apply(.shovel, duration: GameConfig.shovelDuration)
        }
        refreshHUD()
    }

    private func detonateGrenade() {
        for enemy in enemies where enemy.hp > 0 {
            let hpBefore = enemy.hp
            if enemy.isBoss {
                enemy.takeDamage(GameConfig.grenadeBossDamage)
            } else if !enemy.isInvincible {
                enemy.takeDamage(max(enemy.hp, 1))
            }
            if enemy.hp <= 0 {
                EffectFactory.bigExplosion(at: enemy.position, in: self)
            } else {
                EffectFactory.hitSpark(at: enemy.position, in: self)
                if enemy.hp < hpBefore {
                    EffectFactory.hitFlash(on: enemy, shielded: false)
                }
            }
        }
    }

    private func refreshHUD() {
        hud.lives = lives
        hud.firepower = player?.firepower ?? 0
        hud.effects = status.activePlayerHUDTags()
        hud.stage = flow?.levels.stageNumber ?? 1
        hud.score = flow?.score.score ?? 0
        let remaining = (spawnSystem?.remainingInQueue ?? 0)
            + (spawnSystem?.pendingCount ?? 0)
            + enemies.filter { $0.hp > 0 && !$0.isBoss }.count
        hud.remainingEnemies = remaining
        if let boss = enemies.compactMap({ $0 as? BossTank }).first, boss.hp > 0 {
            hud.bossHP = boss.hp
            hud.bossMaxHP = boss is FinalBoss ? GameConfig.finalBossHitPoints : GameConfig.miniBossHitPoints
            hud.bossPhase = boss.phase
        } else {
            hud.bossHP = 0
            hud.bossMaxHP = 0
            hud.bossPhase = 0
        }
        bossHealthBar.render(hp: hud.bossHP, maxHP: hud.bossMaxHP, phase: hud.bossPhase)
    }

    private func spawnBossIfNeeded(_ level: LevelData, map: GridMap) {
        guard let bossType = level.bossType else { return }
        let tiles = bossType == .final
            ? GameConfig.finalBossFootprintTiles
            : GameConfig.miniBossFootprintTiles
        guard let origin = map.firstOpenFootprint(tiles: tiles) else { return }
        let position = map.centerOfFootprint(origin: origin, tiles: tiles)
        let boss: BossTank
        switch bossType {
        case .mini:
            let stage = flow?.levels.stageNumber ?? 1
            let trait: MiniBossTrait
            if stage == GameConfig.miniBossSummonStage {
                trait = .summoner
            } else if stage == GameConfig.miniBossSwiftStage {
                trait = .swift
            } else {
                trait = .none
            }
            boss = MiniBoss(at: position, trait: trait)
        case .final:
            boss = FinalBoss(at: position)
        }
        boss.onPhaseChange = { [weak self] _ in
            guard let self else { return }
            EffectFactory.phaseShake(scene: self)
            if boss is MiniBoss {
                EffectFactory.flashWhite(in: self)
            }
            PresentationCues.bossPhaseChanged()
            self.refreshHUD()
        }
        addChild(boss)
        enemies.append(boss)
        PresentationCues.bossIntro(on: boss, in: self)
    }

    private func beginWindup(_ boss: FinalBoss, direction: Direction) {
        guard !boss.isWindingUp, !boss.isCharging, !boss.isStunned else { return }
        boss.isWindingUp = true
        boss.chargeDirection = direction
        boss.direction = direction
        boss.commandedDirection = nil
        status.apply(.bossWindup(ObjectIdentifier(boss)), duration: GameConfig.finalBossChargeWindup)
        EffectFactory.applyChargeWarning(to: boss)
    }

    private func applyCharge(_ boss: FinalBoss, direction: Direction, dt: TimeInterval, map: GridMap) {
        let travel = GameConfig.finalBossChargeSpeed * CGFloat(dt)
        let desired = CGPoint(
            x: direction.vector.dx * travel,
            y: direction.vector.dy * travel
        )
        let result = CollisionSystem.resolveChargeMove(
            tank: boss,
            desiredDelta: desired,
            map: map,
            others: allLivingTanks()
        )
        boss.position = CGPoint(
            x: boss.position.x + result.delta.x,
            y: boss.position.y + result.delta.y
        )
        boss.direction = direction
        boss.presentMotion(result.delta.x != 0 || result.delta.y != 0)
        for point in result.crushed {
            if map.destroyTile(at: point, byLevel3Bullet: false) {
                mapRenderer?.refreshTile(at: point)
                EffectFactory.smallExplosion(at: map.center(of: point), in: self)
            }
        }
        if let hit = result.hitPlayer {
            let hpBefore = hit.hp
            let shieldWasUp = (hit as? PlayerTank)?.hasShield == true
            hit.takeDamage(max(hit.hp, 1))
            if hit.hp <= 0 {
                EffectFactory.bigExplosion(at: hit.position, in: self)
                EffectFactory.shake(scene: self)
                handleTankDestroyed(hit)
            } else {
                EffectFactory.hitFlash(on: hit, shielded: shieldWasUp && hit.hp == hpBefore)
            }
        }
        if result.hitSolid {
            boss.isCharging = false
            boss.isStunned = true
            status.apply(.bossStun(ObjectIdentifier(boss)), duration: GameConfig.finalBossChargeStun)
            EffectFactory.stopChargeWarning(on: boss)
        }
    }

    private func spawnSummonedFast() {
        guard let map, let spawnSystem else { return }
        if let extra = spawnSystem.spawnReinforcement(
            type: .fast,
            map: map,
            liveEnemies: enemies,
            blockingTanks: allLivingTanks()
        ) {
            addChild(extra)
            enemies.append(extra)
        }
    }

    private func checkLevelCleared() {
        guard !isGameOver, let spawnSystem, let flow else { return }
        if flow.levels.isCleared(
            remainingQueue: spawnSystem.remainingInQueue,
            pending: spawnSystem.pendingCount,
            liveEnemies: enemies.filter { $0.hp > 0 }.count
        ) {
            isGameOver = true
            flow.handleLevelCleared()
        }
    }

    private func finishGame() {
        guard !isGameOver else { return }
        isGameOver = true
        PresentationCues.gameOver()
        flow?.handleDefeat()
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
