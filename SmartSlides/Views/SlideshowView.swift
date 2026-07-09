import SwiftUI
import AppKit

struct SlideshowView: View {
    @ObservedObject var player: SlideshowPlayerViewModel
    @State private var overlayVisible: Bool = true
    @State private var overlayHideWorkItem: DispatchWorkItem?
    var onExit: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let scene = player.currentScene {
                SceneView(scene: scene)
                    .id(scene.id)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: player.transitionDuration), value: scene.id)
            }

            VStack {
                Spacer()
                if overlayVisible {
                    SlideshowOverlayView(player: player)
                        .padding(.bottom, 24)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: overlayVisible)
        }
        .contentShape(Rectangle())
        .onContinuousHover { _ in
            showOverlayTemporarily()
        }
        .onAppear {
            showOverlayTemporarily()
        }
        .background(KeyEventCatcher(
            onSpace: { player.togglePause(); showOverlayTemporarily() },
            onRight: { player.next(); showOverlayTemporarily() },
            onLeft: { player.previous(); showOverlayTemporarily() },
            onEscape: onExit
        ))
    }

    private func showOverlayTemporarily() {
        overlayVisible = true
        overlayHideWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            overlayVisible = false
        }
        overlayHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
    }
}

private struct SceneView: View {
    let scene: SlideScene

    var body: some View {
        switch scene.layout {
        case .onePortrait, .oneLandscape:
            SingleImageView(url: scene.imageURLs.first)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .twoPortraitsSideBySide, .twoLandscapesSideBySide:
            PairedImageView(
                leftURL: scene.imageURLs.first,
                rightURL: scene.imageURLs.count > 1 ? scene.imageURLs[1] : nil
            )
        }
    }
}

/// Sizes two images to a shared height (derived from their real aspect ratios) so they sit
/// flush against each other with no gap, rather than each being fit independently into a
/// fixed half-width column (which produces mismatched heights and a black gap between them).
private struct PairedImageView: View {
    let leftURL: URL?
    let rightURL: URL?

    var body: some View {
        GeometryReader { geo in
            let leftImage = leftURL.flatMap { NSImage(contentsOf: $0) }
            let rightImage = rightURL.flatMap { NSImage(contentsOf: $0) }
            let leftAspect = aspectRatio(of: leftImage)
            let rightAspect = aspectRatio(of: rightImage)
            let combinedHeight = min(geo.size.height, geo.size.width / (leftAspect + rightAspect))

            HStack(spacing: 0) {
                imageView(leftImage)
                    .frame(width: leftAspect * combinedHeight, height: combinedHeight)
                imageView(rightImage)
                    .frame(width: rightAspect * combinedHeight, height: combinedHeight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func aspectRatio(of image: NSImage?) -> CGFloat {
        guard let image, image.size.height > 0 else { return 1 }
        return image.size.width / image.size.height
    }

    @ViewBuilder
    private func imageView(_ image: NSImage?) -> some View {
        if let image {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Color.black
        }
    }
}

private struct SingleImageView: View {
    let url: URL?

    var body: some View {
        Group {
            if let url, let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Color.black
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

/// Bridges AppKit key events (space/arrows/escape) into SwiftUI.
private struct KeyEventCatcher: NSViewRepresentable {
    let onSpace: () -> Void
    let onRight: () -> Void
    let onLeft: () -> Void
    let onEscape: () -> Void

    func makeNSView(context: Context) -> KeyCatcherView {
        let view = KeyCatcherView()
        view.onSpace = onSpace
        view.onRight = onRight
        view.onLeft = onLeft
        view.onEscape = onEscape
        return view
    }

    func updateNSView(_ nsView: KeyCatcherView, context: Context) {
        nsView.onSpace = onSpace
        nsView.onRight = onRight
        nsView.onLeft = onLeft
        nsView.onEscape = onEscape
    }

    final class KeyCatcherView: NSView {
        var onSpace: (() -> Void)?
        var onRight: (() -> Void)?
        var onLeft: (() -> Void)?
        var onEscape: (() -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            window?.makeFirstResponder(self)
        }

        override func keyDown(with event: NSEvent) {
            switch event.keyCode {
            case 49: onSpace?() // space
            case 124: onRight?() // right arrow
            case 123: onLeft?() // left arrow
            case 53: onEscape?() // escape
            default: super.keyDown(with: event)
            }
        }
    }
}
