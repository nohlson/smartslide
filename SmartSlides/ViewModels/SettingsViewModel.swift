import Foundation
import AppKit
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings
    @Published var folderURL: URL?
    @Published var folderDisplayName: String = "No folder selected"
    @Published var assets: [ImageAsset] = []
    @Published var skippedCount: Int = 0
    @Published var needsFolderReselect: Bool = false
    @Published var isSlideshowActive: Bool = false
    let thumbnailStore = ThumbnailStore()

    var totalCount: Int { assets.count }
    var portraitCount: Int { assets.filter { $0.orientation == .portrait }.count }
    var landscapeCount: Int { assets.filter { $0.orientation == .landscape }.count }

    var canStartSlideshow: Bool {
        !settings.enabledLayouts.isEmpty && !settings.timeline.isEmpty
    }

    /// The full navigable sequence — the just-replaced generation (if Rehash on Replay has
    /// kicked in) followed by the current one. Both the main-view strip and the fullscreen
    /// scrubber render this same concatenated sequence.
    var displayTimeline: [SlideScene] {
        settings.previousTimeline + settings.timeline
    }

    init() {
        let loaded = AppSettingsStore.load()
        self.settings = loaded
        restoreFolderIfPossible()
    }

    private func restoreFolderIfPossible() {
        guard let bookmark = settings.folderBookmark else { return }
        guard let url = AppSettingsStore.resolveBookmark(bookmark) else {
            needsFolderReselect = true
            return
        }
        folderURL = url
        folderDisplayName = url.lastPathComponent
        rescan(persistExistingTimelineIfEmpty: true)
        refreshThumbnails()
    }

    func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Folder"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        folderURL = url
        folderDisplayName = url.lastPathComponent
        needsFolderReselect = false
        settings.folderBookmark = AppSettingsStore.makeBookmark(for: url)
        rescan(persistExistingTimelineIfEmpty: false)
        regenerateTimelineWithNewSeed()
        persist()
    }

    func toggleIncludeSubfolders(_ value: Bool) {
        settings.includeSubfolders = value
        rescan(persistExistingTimelineIfEmpty: false)
        regenerateTimelineWithNewSeed()
        persist()
    }

    func toggleLayout(_ layout: SlideLayout, enabled: Bool) {
        if enabled {
            settings.enabledLayouts.insert(layout)
        } else {
            settings.enabledLayouts.remove(layout)
        }
        // The enabled layout set changes which scene compositions are valid, so a fresh
        // hash produces a timeline that actually reflects the new constraints rather than
        // replaying the old seed's pairing decisions against a different layout set.
        regenerateTimelineWithNewSeed()
        persist()
    }

    func updateDisplayDuration(_ value: Double) {
        settings.displayDuration = value
        persist()
    }

    func updateTransitionDuration(_ value: Double) {
        settings.transitionDuration = value
        persist()
    }

    func updateCrossfadeEnabled(_ value: Bool) {
        settings.crossfadeEnabled = value
        persist()
    }

    func generateNewHash() {
        regenerateTimelineWithNewSeed()
        persist()
    }

    func toggleRehashOnReplay(_ enabled: Bool) {
        settings.rehashOnReplay = enabled
        persist()
    }

    /// Discards the kept-around previous generation, collapsing the navigable sequence back
    /// down to just the current timeline — the "reset to current hash, forget the rest" button.
    func resetToCurrentHash() {
        let dropCount = settings.previousTimeline.count
        guard dropCount > 0 else { return }
        settings.previousTimeline = []
        settings.currentTimelineIndex = max(settings.currentTimelineIndex - dropCount, 0)
        persist()
    }

    /// Called by the slideshow player (via a callback) when it's a few frames from running out
    /// of material and Rehash on Replay is on. Generates a fresh timeline with a new seed,
    /// keeping only the generation it replaces (discarding anything further back), and returns
    /// the new scenes so the player can seamlessly extend its own local timeline array.
    func performRehash() -> [SlideScene] {
        guard !assets.isEmpty else { return [] }
        let newSeed = UInt64.random(in: UInt64.min...UInt64.max)
        let result = TimelineGenerator.generate(
            assets: assets,
            enabledLayouts: settings.enabledLayouts,
            seed: newSeed
        )
        settings.previousTimeline = settings.timeline
        settings.timeline = result.scenes
        settings.seed = newSeed
        skippedCount = result.skippedCount
        refreshThumbnails()
        persist()
        return result.scenes
    }

    private func regenerateTimelineWithNewSeed() {
        settings.seed = UInt64.random(in: UInt64.min...UInt64.max)
        regenerateTimeline()
    }

    private func rescan(persistExistingTimelineIfEmpty: Bool) {
        guard let folderURL else { return }
        let result = ImageScanner.scan(folder: folderURL, includeSubfolders: settings.includeSubfolders)
        assets = result.assets
        if persistExistingTimelineIfEmpty && !settings.timeline.isEmpty {
            // Keep the previously generated/persisted timeline as-is on resume.
            return
        }
    }

    func regenerateTimeline() {
        let result = TimelineGenerator.generate(
            assets: assets,
            enabledLayouts: settings.enabledLayouts,
            seed: settings.seed
        )
        settings.timeline = result.scenes
        // A deliberate regeneration (new hash, layout change, folder change) is a clean
        // break, not a Rehash on Replay continuation — nothing to scrub back into.
        settings.previousTimeline = []
        settings.currentTimelineIndex = 0
        skippedCount = result.skippedCount
        refreshThumbnails()
    }

    private func refreshThumbnails() {
        let urls = displayTimeline.flatMap { $0.imageURLs }
        thumbnailStore.generate(for: urls)
    }

    func persist() {
        AppSettingsStore.save(settings)
    }

    func updateCurrentIndex(_ index: Int) {
        settings.currentTimelineIndex = index
        persist()
    }
}
