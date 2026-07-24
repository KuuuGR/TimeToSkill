import Foundation

/// Selects the best Time Perspective for a duration using binary search.
///
/// Expects `sortedLibrary` to be ordered ascending by `thresholdMinutes`.
enum TimePerspectiveMatcher {
    /// Returns the perspective whose threshold is the largest value ≤ `targetMinutes`.
    ///
    /// When several entries share that threshold, one is chosen at random.
    /// Returns `nil` only when `sortedLibrary` is empty.
    static func findBestPerspective(
        for targetMinutes: Int,
        in sortedLibrary: [TimePerspective]
    ) -> TimePerspective? {
        guard !sortedLibrary.isEmpty else {
            return nil
        }

        let index = sortedLibrary.partitioningIndex {
            $0.thresholdMinutes > targetMinutes
        }
        let matchedIndex = index > 0 ? index - 1 : 0
        let threshold = sortedLibrary[matchedIndex].thresholdMinutes
        let candidates = sortedLibrary.filter {
            $0.thresholdMinutes == threshold
        }
        return candidates.randomElement() ?? sortedLibrary[matchedIndex]
    }
}

// MARK: - Binary search helper

private extension RandomAccessCollection {
    /// First index where `belongsInSecondPartition` is true, assuming a single partition boundary.
    /// Matches the semantics used by Swift Algorithms' `partitioningIndex(where:)`.
    func partitioningIndex(
        where belongsInSecondPartition: (Element) throws -> Bool
    ) rethrows -> Index {
        var count = self.count
        var index = startIndex

        while count > 0 {
            let step = count / 2
            let mid = self.index(index, offsetBy: step)
            if try belongsInSecondPartition(self[mid]) {
                count = step
            } else {
                index = self.index(after: mid)
                count -= step + 1
            }
        }

        return index
    }
}
