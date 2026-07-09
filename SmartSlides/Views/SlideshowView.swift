import SwiftUI
import AppKit

struct SlideshowView: View {
    @ObservedObject var player: SlideshowPlayerViewModel
    @ObservedObject var thumbnailStore: ThumbnailStore
    let crossfadeEnabled: Bool
    @State private var overlayVisible: Bool = true
    @State private var overlayHideWorkItem: DispatchWorkItem?
    @State private var rehashToastVisible: Bool = false
    @State private var rehashToastHideWorkItem: DispatchWorkItem?
    var onExit: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CrossfadeSceneView(
                scene: player.currentScene,
                thumbnails: thumbnailStore.thumbnails,
                transitionDuration: player.transitionDuration,
                crossfadeEnabled: crossfadeEnabled
            )

            VStack {
                Spacer()
                if overlayVisible {
                    SlideshowOverlayView(
                        player: player,
                        thumbnailStore: thumbnailStore,
                        onDragBegin: {
                            player.beginScrub()
                            showOverlayTemporarily()
                        }
                    )
                    .padding(.bottom, 24)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: overlayVisible)

            // Shown regardless of whether the controls overlay is visible or the user is
            // interacting — a brief, unobtrusive heads-up that a fresh shuffle is coming.
            VStack {
                if rehashToastVisible {
                    RehashToastView()
                        .padding(.top, 28)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                Spacer()
            }
            .animation(.easeInOut(duration: 0.3), value: rehashToastVisible)
            .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onContinuousHover { _ in
            showOverlayTemporarily()
        }
        .onAppear {
            showOverlayTemporarily()
        }
        .task(id: player.currentIndex) {
            await prefetchNeighbors()
        }
        .onChange(of: player.rehashEventID) { _, _ in
            showRehashToastBriefly()
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

    private func showRehashToastBriefly() {
        rehashToastVisible = true
        rehashToastHideWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            rehashToastVisible = false
        }
        rehashToastHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: workItem)
    }

    /// Warms the display cache for the current slide and the next several ahead (plus one
    /// behind, for quick back-nav), so switching feels instant. This is the thing that matters
    /// most — a plain slideshow just playing forward is the normal, primary use case, and
    /// everything here is ordered so the most imminent slides are ready first.
    private func prefetchNeighbors() async {
        let timeline = player.timeline
        let count = timeline.count
        guard count > 0 else { return }

        let rawOffsets = [0, 1, 2, 3, -1]
        var urls: [URL] = []
        for offset in rawOffsets {
            let wrapped = ((player.currentIndex + offset) % count + count) % count
            urls.append(contentsOf: timeline[wrapped].imageURLs)
        }
        await DisplayImageCache.shared.prefetch(urls)
    }
}

/// The canonical SwiftUI cross-dissolve (what Photos/Keynote-style dissolves reduce to):
/// the scene view is identity-keyed with `.id(scene.id)` and given an `.opacity` transition,
/// and the *container* carries the `.animation(value:)`. On a scene change SwiftUI keeps both
/// the outgoing and incoming views alive for the duration, fading one out 1→0 while the other
/// fades in 0→1 in the same transaction — no hand-managed layer state to get stale (which is
/// what previously caused repeated frames and placeholder flashes mid-fade).
///
/// The crucial detail vs. the naive version: the animation must be attached to the container,
/// not the id'd view itself, or the removal never animates and the switch looks instant.
private struct CrossfadeSceneView: View {
    let scene: SlideScene?
    let thumbnails: [URL: NSImage]
    let transitionDuration: Double
    let crossfadeEnabled: Bool

    var body: some View {
        ZStack {
            if let scene {
                SceneView(scene: scene, thumbnails: thumbnails)
                    .id(scene.id)
                    .transition(.opacity)
            }
        }
        .animation(
            crossfadeEnabled ? .easeInOut(duration: transitionDuration) : nil,
            value: scene?.id
        )
    }
}

private struct SceneView: View {
    let scene: SlideScene
    let thumbnails: [URL: NSImage]

    var body: some View {
        switch scene.layout {
        case .onePortrait, .oneLandscape:
            CachedDisplayImage(url: scene.imageURLs.first)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
        case .twoPortraitsSideBySide, .twoLandscapesSideBySide:
            PairedImageView(
                leftURL: scene.imageURLs.first,
                rightURL: scene.imageURLs.count > 1 ? scene.imageURLs[1] : nil,
                thumbnails: thumbnails
            )
        }
    }
}

/// Sizes two images to a shared height (derived from their real aspect ratios) so they sit
/// flush against each other with no gap, rather than each being fit independently into a
/// fixed half-width column (which produces mismatched heights and a black gap between them).
/// Aspect ratios come from the already-cached small thumbnails (same aspect ratio, effectively
/// free) rather than decoding the full-resolution images just to measure them.
private struct PairedImageView: View {
    let leftURL: URL?
    let rightURL: URL?
    let thumbnails: [URL: NSImage]

    var body: some View {
        GeometryReader { geo in
            let leftAspect = aspectRatio(for: leftURL)
            let rightAspect = aspectRatio(for: rightURL)
            let combinedHeight = min(geo.size.height, geo.size.width / (leftAspect + rightAspect))

            HStack(spacing: 0) {
                CachedDisplayImage(url: leftURL)
                    .frame(width: leftAspect * combinedHeight, height: combinedHeight)
                CachedDisplayImage(url: rightURL)
                    .frame(width: rightAspect * combinedHeight, height: combinedHeight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func aspectRatio(for url: URL?) -> CGFloat {
        guard let url, let thumb = thumbnails[url], thumb.size.height > 0 else { return 1 }
        return thumb.size.width / thumb.size.height
    }
}

/// Displays a full-resolution (screen-capped) image via `DisplayImageCache`. Loading is keyed
/// to the URL via `.task(id:)`, so it only re-runs when the URL actually changes — not on every
/// unrelated re-render of a parent view (e.g. the overlay's live-ticking clock) — which is what
/// keeps this from repeatedly re-decoding the same image from disk.
///
/// `image` is seeded synchronously from the cache at init — since this view is `.id()`-keyed
/// per scene (so the crossfade transition works), it's fully recreated on every slide change,
/// and if `@State` started at `nil` every time, even an already-prefetched image would flash to
/// black for a frame while `.task` spun up. Seeding synchronously means a cache hit (the normal
/// case, thanks to prefetching) renders correctly on the very first frame.
private struct CachedDisplayImage: View {
    let url: URL?
    @State private var image: NSImage?

    init(url: URL?) {
        self.url = url
        _image = State(initialValue: url.flatMap { DisplayImageCache.shared.cachedImage(for: $0) })
    }

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Color.black
            }
        }
        .task(id: url) {
            guard image == nil, let url else { return }
            image = await DisplayImageCache.shared.load(url)
        }
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
