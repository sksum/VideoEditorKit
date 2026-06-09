import Foundation

struct EditorDurationLimitCoordinator {

    // MARK: - Public Methods

    static func normalizedMaximumDuration(
        _ maximumDuration: Double?
    ) -> Double? {
        guard let maximumDuration else { return nil }
        guard maximumDuration.isFinite, maximumDuration > 0 else { return nil }

        return maximumDuration
    }

    static func clampedTrimRange(
        _ range: ClosedRange<Double>,
        originalDuration: Double,
        maximumDuration: Double?
    ) -> ClosedRange<Double> {
        let resolvedOriginalDuration = max(
            originalDuration.isFinite ? originalDuration : 0,
            0
        )

        guard resolvedOriginalDuration > 0 else {
            return 0...0
        }

        let resolvedLowerBound = range.lowerBound.clamped(
            to: 0...resolvedOriginalDuration
        )
        let resolvedUpperBound = range.upperBound.clamped(
            to: resolvedLowerBound...resolvedOriginalDuration
        )
        let resolvedMaximumDuration = normalizedMaximumDuration(
            maximumDuration
        )

        guard let resolvedMaximumDuration else {
            return resolvedLowerBound...resolvedUpperBound
        }

        let currentDuration = resolvedUpperBound - resolvedLowerBound
        guard currentDuration > resolvedMaximumDuration else {
            return resolvedLowerBound...resolvedUpperBound
        }

        let limitedUpperBound = min(
            resolvedLowerBound + resolvedMaximumDuration,
            resolvedOriginalDuration
        )

        return resolvedLowerBound...limitedUpperBound
    }

    static func resolvedMaximumTrimDuration(
        originalDuration: Double,
        maximumDuration: Double?
    ) -> Double? {
        guard
            let resolvedMaximumDuration = normalizedMaximumDuration(
                maximumDuration
            )
        else {
            return nil
        }

        return min(resolvedMaximumDuration, max(originalDuration, 0))
    }

    static func applyDurationLimit(
        to video: inout Video,
        maximumDuration: Double?
    ) {
        video.rangeDuration = clampedTrimRange(
            video.rangeDuration,
            originalDuration: video.originalDuration,
            maximumDuration: maximumDuration
        )
    }

    static func applyDurationLimit(
        to video: inout Video,
        minimumDuration: Double?,
        maximumDuration: Double?
    ) {
        let resolvedOriginalDuration = max(
            video.originalDuration.isFinite ? video.originalDuration : 0,
            0
        )

        guard resolvedOriginalDuration > 0 else {
            video.rangeDuration = 0...0
            return
        }

        let resolvedMinimumDuration = minimumDuration.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
        let resolvedMaximumDuration = normalizedMaximumDuration(maximumDuration)

        // When both minimum and maximum are the same, enforce exact duration
        if let minimum = resolvedMinimumDuration,
           let maximum = resolvedMaximumDuration,
           abs(minimum - maximum) < 0.001 {
            let fixedDuration = minimum
            let maxLowerBound = resolvedOriginalDuration - fixedDuration
            let lowerBound = min(video.rangeDuration.lowerBound, maxLowerBound)
            let clampedLowerBound = max(lowerBound, 0)
            let upperBound = min(clampedLowerBound + fixedDuration, resolvedOriginalDuration)
            video.rangeDuration = clampedLowerBound...upperBound
        } else {
            // Apply normal constraints
            video.rangeDuration = clampedTrimRange(
                video.rangeDuration,
                originalDuration: video.originalDuration,
                maximumDuration: maximumDuration
            )
        }
    }

}
