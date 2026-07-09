import Foundation

/// Deterministic RNG (SplitMix64) so the same seed always produces the same timeline.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func nextInt(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        return Int(next() % UInt64(upperBound))
    }
}

func seededShuffle<T>(_ array: inout [T], rng: inout SplitMix64) {
    guard array.count > 1 else { return }
    for i in stride(from: array.count - 1, to: 0, by: -1) {
        let j = rng.nextInt(upperBound: i + 1)
        array.swapAt(i, j)
    }
}

func seededShuffle<T>(_ array: inout [T], seed: UInt64) {
    var rng = SplitMix64(seed: seed)
    seededShuffle(&array, rng: &rng)
}
