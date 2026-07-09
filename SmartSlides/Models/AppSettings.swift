import Foundation

struct AppSettings: Codable {
    var folderBookmark: Data?
    var includeSubfolders: Bool = false
    var enabledLayouts: Set<SlideLayout> = Set(SlideLayout.allCases)
    var seed: UInt64 = UInt64.random(in: UInt64.min...UInt64.max)
    var displayDuration: Double = 8.0
    var transitionDuration: Double = 1.0
    var currentTimelineIndex: Int = 0
    var timeline: [SlideScene] = []
}
