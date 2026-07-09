import Foundation

enum TimelineGenerator {
    struct Result {
        var scenes: [SlideScene]
        var skippedCount: Int
    }

    static func generate(assets: [ImageAsset], enabledLayouts: Set<SlideLayout>, seed: UInt64) -> Result {
        guard !enabledLayouts.isEmpty else {
            return Result(scenes: [], skippedCount: assets.count)
        }

        var rng = SplitMix64(seed: seed)

        var portraitPool = assets.filter { $0.orientation == .portrait }
        var landscapePool = assets.filter { $0.orientation == .landscape }
        seededShuffle(&portraitPool, rng: &rng)
        seededShuffle(&landscapePool, rng: &rng)

        var skipped = 0

        let portraitScenes = buildScenes(
            from: &portraitPool,
            pairLayout: .twoPortraitsSideBySide,
            singleLayout: .onePortrait,
            enabledLayouts: enabledLayouts,
            rng: &rng,
            skipped: &skipped
        )

        let landscapeScenes = buildScenes(
            from: &landscapePool,
            pairLayout: .twoLandscapesSideBySide,
            singleLayout: .oneLandscape,
            enabledLayouts: enabledLayouts,
            rng: &rng,
            skipped: &skipped
        )

        var scenes = portraitScenes + landscapeScenes
        seededShuffle(&scenes, rng: &rng)

        return Result(scenes: scenes, skippedCount: skipped)
    }

    private static func buildScenes(
        from pool: inout [ImageAsset],
        pairLayout: SlideLayout,
        singleLayout: SlideLayout,
        enabledLayouts: Set<SlideLayout>,
        rng: inout SplitMix64,
        skipped: inout Int
    ) -> [SlideScene] {
        var scenes: [SlideScene] = []
        let pairEnabled = enabledLayouts.contains(pairLayout)
        let singleEnabled = enabledLayouts.contains(singleLayout)

        guard pairEnabled || singleEnabled else {
            skipped += pool.count
            pool.removeAll()
            return scenes
        }

        var index = 0
        while index < pool.count {
            let canPair = pairEnabled && index + 1 < pool.count
            let canSingle = singleEnabled

            // When both layouts are available, flip a coin each time so pairs and
            // singles both show up throughout the timeline, not just as a leftover.
            let usePair: Bool
            if canPair && canSingle {
                usePair = rng.nextInt(upperBound: 2) == 0
            } else {
                usePair = canPair
            }

            if usePair {
                let pair = [pool[index].url, pool[index + 1].url]
                scenes.append(SlideScene(layout: pairLayout, imageURLs: pair))
                index += 2
            } else if canSingle {
                scenes.append(SlideScene(layout: singleLayout, imageURLs: [pool[index].url]))
                index += 1
            } else {
                // Odd leftover with no single-layout fallback available.
                skipped += 1
                index += 1
            }
        }

        return scenes
    }
}
