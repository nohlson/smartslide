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

    /// Called whenever the current index changes, so the owner can persist it.
    var onIndexChange: ((Int) -> Void)?

    private var timer: Timer?

    var currentScene: SlideScene? {
        guard timeline.indices.contains(currentIndex) else { return nil }
        return timeline[currentIndex]
    }

    var totalCount: Int { timeline.count }

    init(timeline: [SlideScene], startIndex: Int, displayDuration: Double, transitionDuration: Double) {
        self.timeline = timeline
        self.currentIndex = timeline.indices.contains(startIndex) ? startIndex : 0
        self.displayDuration = displayDuration
        self.transitionDuration = transitionDuration
    }

    func start() {
        isPaused = false
        scheduleTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func togglePause() {
        isPaused.toggle()
        if isPaused {
            timer?.invalidate()
            timer = nil
        } else {
            scheduleTimer()
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
        onIndexChange?(currentIndex)
        DispatchQueue.main.asyncAfter(deadline: .now() + transitionDuration) { [weak self] in
            self?.isTransitioning = false
        }
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

    private func restartTimerIfPlaying() {
        guard !isPaused else { return }
        scheduleTimer()
    }
}
