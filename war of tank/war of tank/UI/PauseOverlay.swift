//
//  PauseOverlay.swift
//  war of tank
//

import SwiftUI

struct PauseOverlay: View {
    let onResume: () -> Void
    let onRestart: () -> Void
    let onMenu: () -> Void
    @State private var muted = AudioManager.isMuted

    var body: some View {
        ZStack {
            Color(GameConfig.overlayScrimColor)
            VStack(spacing: GameConfig.pauseOverlaySpacing) {
                Text(L10n.paused)
                    .font(.system(.title3, design: .monospaced).weight(.bold))
                Button(L10n.continueGame, action: onResume)
                Button(L10n.restart, action: onRestart)
                Button(L10n.pauseSound(isMuted: muted)) {
                    AudioManager.isMuted.toggle()
                    muted = AudioManager.isMuted
                }
                Button(L10n.menu, action: onMenu)
            }
            .font(.system(.caption, design: .monospaced).weight(.bold))
            .foregroundStyle(Color(GameConfig.hudTextColor))
        }
    }
}
