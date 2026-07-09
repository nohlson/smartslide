import Foundation

struct AppSettings: Codable {
    var folderBookmark: Data?
    var includeSubfolders: Bool = false
    var enabledLayouts: Set<SlideLayout> = Set(SlideLayout.allCases)
    var seed: UInt64 = UInt64.random(in: UInt64.min...UInt64.max)
    var displayDuration: Double = 7.0
    var transitionDuration: Double = 1.0
    /// When true, slides dissolve into each other over `transitionDuration`. When false, each
    /// slide switches instantly with no fade.
    var crossfadeEnabled: Bool = true
    /// Index into `previousTimeline + timeline` (the concatenated, navigable sequence) —
    /// not just `timeline` alone. When `previousTimeline` is empty (the normal case) this is
    /// simply an index into `timeline`, same as before.
    var currentTimelineIndex: Int = 0
    var timeline: [SlideScene] = []

    /// When Rehash on Replay generates a new timeline mid-playback, the timeline it replaces
    /// is kept here (one generation back only) so the user can still scrub into it. A manual
    /// hash regeneration, layout change, or folder change clears this.
    var previousTimeline: [SlideScene] = []
    var rehashOnReplay: Bool = false
}
