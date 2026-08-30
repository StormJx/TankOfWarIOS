//
//  StatusEffectManager.swift
//  war of tank
//

import Foundation

enum StatusEffectID: Hashable {
    case playerShield
    case playerStun
    case playerFreeze
    case playerInvincible
    case enemyInvincible(ObjectIdentifier)
    case enemyFreeze(ObjectIdentifier)
    case bossSlow(ObjectIdentifier)
    case bossWindup(ObjectIdentifier)
    case bossStun(ObjectIdentifier)
    case shovel
}

/// 所有有时限状态的唯一计时入口。用场景 dt 累加，场景暂停时不会继续走。
final class StatusEffectManager {

    private struct Entry {
        var remaining: TimeInterval
    }

    private var entries: [StatusEffectID: Entry] = [:]
    var onExpired: ((StatusEffectID) -> Void)?

    func apply(_ id: StatusEffectID, duration: TimeInterval) {
        entries[id] = Entry(remaining: duration)
    }

    func remaining(_ id: StatusEffectID) -> TimeInterval {
        entries[id]?.remaining ?? 0
    }

    func has(_ id: StatusEffectID) -> Bool {
        remaining(id) > 0
    }

    func clear(_ id: StatusEffectID) {
        entries[id] = nil
    }

    func clearPlayerBoundEffects() {
        clear(.playerShield)
        clear(.playerStun)
        clear(.playerFreeze)
        clear(.playerInvincible)
    }

    func clear(enemy id: ObjectIdentifier) {
        clear(.enemyInvincible(id))
        clear(.enemyFreeze(id))
        clear(.bossSlow(id))
        clear(.bossWindup(id))
        clear(.bossStun(id))
    }

    func activePlayerHUDTags() -> [String] {
        var tags: [String] = []
        if has(.playerShield) { tags.append(L10n.hudShield) }
        if has(.playerInvincible) { tags.append(L10n.hudInvincible) }
        if has(.playerFreeze) { tags.append(L10n.hudFreeze) }
        if has(.playerStun) { tags.append(L10n.hudStun) }
        if has(.shovel) { tags.append(L10n.hudShovel) }
        return tags
    }

    func update(dt: TimeInterval) {
        let keys = Array(entries.keys)
        for key in keys {
            guard var entry = entries[key] else { continue }
            entry.remaining -= dt
            if entry.remaining <= 0 {
                entries[key] = nil
                onExpired?(key)
            } else {
                entries[key] = entry
            }
        }
    }
}
