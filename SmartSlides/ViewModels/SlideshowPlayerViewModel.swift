import Foundation
import Combine

@MainActor
final class SlideshowPlayerViewModel: ObservableObject {
    @Published private(set) var timeline: [SlideScene]
    @Published private(set) var currentIndex: Int
    @Published var isPaused: Bool = false
    @Published var displayDuration: Double
    @Published var transitionDuration: Double
    @Published var isTransitioning: Bool = false

    /// How long the current slide has been showing — ticks live while playing so the overlay
    /// can show an elapsed/remaining time like a video scrubber.
    @Published private(set) var elapsedInCurrentSlide: TimeInterval = 0

    /// Called whenever the current index changes, so the owner can persist it.
    var onIndexChange: ((Int) -> Void)?

    /// Rehash on Replay: when set, called as playback nears the end of `timeline` to generate
    /// a fresh continuation. Returns the new scenes to append, or empty to skip (e.g. folder
    /// unavailable).
    var onNeedsRehash: (() -> [SlideScene])?
    var rehashOnReplayEnabled: Bool

    private var timer: Timer?
    private var tickTimer: Timer?
    private var slideStartDate = Date()
    private var pausedElapsed: TimeInterval = 0

    /// Index within `timeline` where the *current* generation begins — everything before this
    /// is the kept-around previous generation. When a rehash appends a new generation, this
    /// generation's scenes become the new previous, and anything before this index is dropped.
    @Published private(set) var currentSegmentStart: Int

    /// Bumped every time a Rehash on Replay continuation is spliced in — a one-shot signal the
    /// view can observe (via `onChange`) to show a brief "fresh shuffle" toast, independent of
    /// whatever state the main controls overlay happens to be in.
    @Published private(set) var rehashEventID = 0

    var currentScene: SlideScene? {
        guard timeline.indices.contains(currentIndex) else { return nil }
        return timeline[currentIndex]
    }

    var totalCount: Int { timeline.count }

    /// Total time elapsed across the whole timeline, assuming every slide takes the current
    /// display duration (approximate if the duration was changed mid-playback).
    var totalElapsed: TimeInterval {
        Double(currentIndex) * displayDuration + elapsedInCurrentSlide
    }

    var totalDuration: TimeInterval {
        Double(totalCount) * displayDuration
    }

    init(
        timeline: [SlideScene],
        startIndex: Int,
        currentSegmentStart: Int,
        displayDuration: Double,
        transitionDuration: Double,
        rehashOnReplayEnabled: Bool
    ) {
        self.timeline = timeline
        self.currentIndex = timeline.indices.contains(startIndex) ? startIndex : 0
        self.currentSegmentStart = min(max(currentSegmentStart, 0), timeline.count)
        self.displayDuration = displayDuration
        self.transitionDuration = transitionDuration
        self.rehashOnReplayEnabled = rehashOnReplayEnabled
    }

    func start() {
        isPaused = false
        slideStartDate = Date()
        pausedElapsed = 0
        elapsedInCurrentSlide = 0
        scheduleTimer()
        scheduleTick()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        tickTimer?.invalidate()
        tickTimer = nil
    }

    func togglePause() {
        isPaused.toggle()
        if isPaused {
            timer?.invalidate()
            timer = nil
            tickTimer?.invalidate()
            tickTimer = nil
            pausedElapsed = elapsedInCurrentSlide
        } else {
            slideStartDate = Date().addingTimeInterval(-pausedElapsed)
            scheduleTimer()
            scheduleTick()
        }
    }

    func next() {
        guard !timeline.isEmpty else { return }
        advance(to: (currentIndex + 1) % timeline.count)
        restartTimerIfPlaying()
    }

    func previous() {
        guard !timeline.isEmpty else { return }
        advance(to: (currentIndex - 1 + timeline.count) % timeline.count)
        restartTimerIfPlaying()
    }

    /// Suspends the auto-advance timer without flipping `isPaused`, so the play/pause icon
    /// doesn't flicker while the user is actively dragging the scrub bar.
    func beginScrub() {
        timer?.invalidate()
        timer = nil
    }

    /// Jumps directly to `index` (used by the scrub bar) and restarts the timer if playback
    /// wasn't paused, same as a manual next/previous.
    func scrub(to index: Int) {
        guard timeline.indices.contains(index), index != currentIndex else {
            restartTimerIfPlaying()
            return
        }
        advance(to: index)
        restartTimerIfPlaying()
    }

    func setDisplayDuration(_ value: Double) {
        displayDuration = value
        restartTimerIfPlaying()
    }

    func setTransitionDuration(_ value: Double) {
        transitionDuration = value
    }

    private func advance(to index: Int) {
        isTransitioning = true
        currentIndex = index
        slideStartDate = Date()
        pausedElapsed = 0
        elapsedInCurrentSlide = 0
        onIndexChange?(currentIndex)
        maybeTriggerRehash()
        DispatchQueue.main.asyncAfter(deadline: .now() + transitionDuration) { [weak self] in
            self?.isTransitioning = false
        }
    }

    /// A few scenes before running out of timeline, ask for a fresh continuation and splice it
    /// on — dropping anything older than the generation currently playing, since we only keep
    /// one generation of scrub-back history.
    private func maybeTriggerRehash() {
        guard rehashOnReplayEnabled, !timeline.isEmpty else { return }
        let remaining = timeline.count - 1 - currentIndex
        guard remaining <= TimelineConstants.rehashLookaheadCount else { return }
        guard let newScenes = onNeedsRehash?(), !newScenes.isEmpty else { return }

        let dropCount = currentSegmentStart
        let keptCurrentGeneration = Array(timeline[dropCount...])
        currentIndex -= dropCount
        timeline = keptCurrentGeneration + newScenes
        currentSegmentStart = keptCurrentGeneration.count
        onIndexChange?(currentIndex)
        rehashEventID += 1
    }

    private func scheduleTimer() {
        timer?.invalidate()
        guard !timeline.isEmpty else { return }
        timer = Timer.scheduledTimer(withTimeInterval: displayDuration, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.next()
            }
        }
    }

    private func scheduleTick() {
        tickTimer?.invalidate()
        guard !timeline.isEmpty else { return }
        tickTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, !self.isPaused else { return }
                self.elapsedInCurrentSlide = Date().timeIntervalSince(self.slideStartDate)
            }
        }
    }

    private func restartTimerIfPlaying() {
        guard !isPaused else { return }
        scheduleTimer()
    }
}
