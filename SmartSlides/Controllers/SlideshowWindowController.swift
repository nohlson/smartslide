import AppKit
import SwiftUI

/// Borderless windows can't become key by default, which would silently swallow all keyboard input.
private final class KeyableBorderlessWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class SlideshowWindowController: NSWindowController {
    private var player: SlideshowPlayerViewModel?
    var onExit: (() -> Void)?

    convenience init(settingsViewModel: SettingsViewModel) {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)

        let window = KeyableBorderlessWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .mainMenu + 1
        window.backgroundColor = .black
        window.isOpaque = true
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        self.init(window: window)

        let player = SlideshowPlayerViewModel(
            timeline: settingsViewModel.settings.timeline,
            startIndex: settingsViewModel.settings.currentTimelineIndex,
            displayDuration: settingsViewModel.settings.displayDuration,
            transitionDuration: settingsViewModel.settings.transitionDuration
        )
        player.onIndexChange = { [weak settingsViewModel] index in
            settingsViewModel?.updateCurrentIndex(index)
        }
        self.player = player

        let rootView = SlideshowView(player: player, onExit: { [weak self] in
            self?.exitSlideshow()
        })
        window.contentView = NSHostingView(rootView: rootView)
        window.setFrame(screenFrame, display: true)
        window.makeKeyAndOrderFront(nil)

        player.start()
    }

    func exitSlideshow() {
        player?.stop()
        NSCursor.unhide()
        window?.close()
        onExit?()
    }
}
