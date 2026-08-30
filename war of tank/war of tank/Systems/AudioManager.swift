//
//  AudioManager.swift
//  war of tank
//

import AVFoundation
import UIKit

enum AudioCue: String {
    case fire
    case hitBrick = "hit_brick"
    case hitSteel = "hit_steel"
    case explosionSmall = "explosion_small"
    case explosionBig = "explosion_big"
    case powerUpPickup = "powerup_pickup"
    case powerUpAppear = "powerup_appear"
    case playerDeath = "player_death"
    case bossPhase = "boss_phase"
    case stageStart = "stage_start"
    case gameOver = "game_over"
}

enum MusicTrack: String {
    case menu = "bgm_menu"
    case battle = "bgm_battle"
    case boss = "bgm_boss"
}

/// 预加载到内存，播放走已打开的 AVAudioPlayer，避免每次从磁盘读。
enum AudioManager {

    static var store = UserDefaults.standard

    static var isMuted: Bool {
        get { store.bool(forKey: GameConfig.saveMutedKey) }
        set {
            store.set(newValue, forKey: GameConfig.saveMutedKey)
            if newValue {
                musicPlayer?.pause()
            } else {
                musicPlayer?.play()
            }
        }
    }

    private static var sfx: [AudioCue: AVAudioPlayer] = [:]
    private static var firePool: [AVAudioPlayer] = []
    private static var hitPool: [AVAudioPlayer] = []
    private static var musicPlayer: AVAudioPlayer?
    private static var currentTrack: MusicTrack?
    private static var didPrepare = false
    private static let heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)
    private static let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private static let rigidHaptic = UIImpactFeedbackGenerator(style: .rigid)

    static func prepare() {
        guard !didPrepare else { return }
        didPrepare = true
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        for cue in [AudioCue.fire, .hitBrick, .hitSteel, .explosionSmall, .explosionBig,
                    .powerUpPickup, .powerUpAppear, .playerDeath, .bossPhase, .stageStart, .gameOver] {
            if let player = makePlayer(named: cue.rawValue) {
                sfx[cue] = player
            }
        }
        firePool = (0..<GameConfig.sfxFireVoiceLimit).compactMap { _ in makePlayer(named: AudioCue.fire.rawValue) }
        hitPool = (0..<GameConfig.sfxHitVoiceLimit).compactMap { _ in makePlayer(named: AudioCue.hitBrick.rawValue) }
        heavyHaptic.prepare()
        lightHaptic.prepare()
        rigidHaptic.prepare()
    }

    static func play(_ cue: AudioCue) {
        prepare()
        guard !isMuted else { return }
        switch cue {
        case .fire:
            playFromPool(firePool, fallback: sfx[.fire])
        case .hitBrick, .hitSteel:
            playFromPool(hitPool, fallback: sfx[cue])
        default:
            guard let player = sfx[cue] else { return }
            player.currentTime = 0
            player.play()
        }
    }

    static func playMusic(_ track: MusicTrack) {
        prepare()
        if currentTrack == track, musicPlayer?.isPlaying == true { return }
        currentTrack = track
        musicPlayer?.stop()
        musicPlayer = makePlayer(named: track.rawValue)
        musicPlayer?.numberOfLoops = -1
        musicPlayer?.volume = 0.45
        if !isMuted {
            musicPlayer?.play()
        }
    }

    static func stopMusic() {
        musicPlayer?.stop()
        currentTrack = nil
    }

    static func hapticHeavy() {
        guard !isMuted else { return }
        heavyHaptic.impactOccurred()
    }

    static func hapticLight() {
        guard !isMuted else { return }
        lightHaptic.impactOccurred()
    }

    static func hapticRigid() {
        guard !isMuted else { return }
        rigidHaptic.impactOccurred()
    }

    private static func playFromPool(_ pool: [AVAudioPlayer], fallback: AVAudioPlayer?) {
        if let idle = pool.first(where: { !$0.isPlaying }) {
            idle.currentTime = 0
            idle.play()
            return
        }
        fallback?.currentTime = 0
        fallback?.play()
    }

    private static func makePlayer(named file: String) -> AVAudioPlayer? {
        let url = Bundle.main.url(forResource: file, withExtension: "wav")
            ?? Bundle.main.url(forResource: file, withExtension: "wav", subdirectory: "Audio")
            ?? Bundle.main.url(forResource: file, withExtension: "wav", subdirectory: "Resources/Audio")
        guard let url, let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.prepareToPlay()
        return player
    }
}
