import Foundation

enum TimelineConstants {
    /// How many scenes before the end of the timeline a Rehash on Replay continuation is
    /// prepared — also how many placeholder cells are shown at the tail to signal it's coming.
    static let rehashLookaheadCount = 3
}
