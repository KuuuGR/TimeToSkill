//
//  SessionDurationHistogram.swift
//  TimeToSkill
//
//  Pure binning and normal-reference math for the per-skill timer-session
//  chart (T4S-001). Nothing here is persisted, and nothing here reads
//  SwiftData. Global distribution and PDF binning stay in their own views.

import Foundation

/// Selects completed timer sessions for the per-skill duration chart.
enum TimerSessionSample {
    /// Stored `sourceRaw` value that counts as a completed timer session.
    /// Kept equal to `TimeIntervalSource.timer.rawValue`; the unit test locks that.
    static let timerSourceRaw = "timer"

    /// Returns the duration when `sourceRaw` is exactly `timer`.
    /// Manual adjustments, unknown source strings, zeroes, and non-finite
    /// values are not sessions. This does not use `TimeIntervalEntry.source`,
    /// which treats an unrecognized stored value as `.timer`.
    static func minutes(sourceRaw: String, durationMinutes: Double) -> Double? {
        minutes(isTimer: sourceRaw == timerSourceRaw, durationMinutes: durationMinutes)
    }

    /// Returns the duration when it is a completed timer session.
    /// Manual adjustments, zeroes, and non-finite values are not sessions.
    static func minutes(isTimer: Bool, durationMinutes: Double) -> Double? {
        guard isTimer, durationMinutes.isFinite, durationMinutes > 0 else { return nil }
        return durationMinutes
    }
}

/// Equal-width histogram of session durations, plus an optional normal
/// reference expressed in the same frequency units as the bins.
struct SessionDurationHistogram: Equatable {
    struct Bin: Equatable {
        /// Inclusive lower edge, in minutes.
        let lowerMinutes: Double
        /// Exclusive upper edge, in minutes. Nil for the open overflow bin
        /// [lower, +∞). That bin is not a regular-width bin.
        let upperMinutes: Double?
        /// True when this bin collects every session at or above `lowerMinutes`.
        let isOverflow: Bool
        let count: Int
        /// Expected count under the fitted normal, integrated across this bin.
        /// For the overflow bin that is the probability from its lower edge to
        /// +∞. Nil for every bin when the reference curve is hidden.
        let expectedCount: Double?
    }

    static let availableWidths: [Double] = [5, 15, 30, 60]
    /// The previous per-skill chart resolved only the first 15 minutes into
    /// 5-minute bins, then widened. 15 minutes is the default step.
    static let defaultWidth: Double = 15
    static let minimumCurveSampleCount = 10
    /// Regular equal-width bins drawn before one explicit overflow bin.
    static let maximumRegularBinCount = 512

    let minutes: [Double]
    let binWidth: Double
    let mean: Double?
    /// Sample standard deviation (divisor n − 1). Nil when n < 2.
    let sampleStandardDeviation: Double?
    let showsReferenceCurve: Bool
    let bins: [Bin]

    init(minutes: [Double], binWidth: Double) {
        let clean = minutes.filter { $0.isFinite && $0 > 0 }
        let width = Self.usableWidth(binWidth)
        let mean = Self.arithmeticMean(clean)
        let deviation = mean.flatMap { Self.sampleStandardDeviation(clean, mean: $0) }
        let showsCurve = Self.shouldShowCurve(count: clean.count, deviation: deviation)

        self.minutes = clean
        self.binWidth = width
        self.mean = mean
        self.sampleStandardDeviation = deviation
        self.showsReferenceCurve = showsCurve
        self.bins = Self.makeBins(
            values: clean,
            width: width,
            mean: mean,
            deviation: deviation,
            showsCurve: showsCurve
        )
    }

    /// Expected frequency of a normal sample in [lower, upper).
    ///
    /// Density: f(x) = exp(-0.5 * ((x - μ) / s)^2) / (s * sqrt(2π)).
    /// Integrating n * f(x) across the bin gives n * (Φ(zUpper) - Φ(zLower)),
    /// which is the count a bin of this actual width would hold. A density
    /// value is not used as if it were already a count.
    static func expectedFrequency(
        sampleCount: Int,
        mean: Double,
        sampleStandardDeviation s: Double,
        lower: Double,
        upper: Double
    ) -> Double {
        let width = upper - lower
        guard sampleCount > 0,
              width.isFinite, width > 0,
              mean.isFinite,
              s.isFinite, s > 0
        else { return 0 }

        let zLower = (lower - mean) / s
        let zUpper = (upper - mean) / s
        guard zLower.isFinite, zUpper.isFinite else { return 0 }

        let probability = normalCDF(zUpper) - normalCDF(zLower)
        guard probability.isFinite else { return 0 }
        let expected = Double(sampleCount) * max(0, probability)
        return expected.isFinite ? expected : 0
    }

    /// Expected count in [lower, +∞). Used only for the overflow bin, whose
    /// width is not the selected regular width.
    static func expectedTailFrequency(
        sampleCount: Int,
        mean: Double,
        sampleStandardDeviation s: Double,
        lower: Double
    ) -> Double {
        guard sampleCount > 0,
              lower.isFinite,
              mean.isFinite,
              s.isFinite, s > 0
        else { return 0 }

        let zLower = (lower - mean) / s
        let probability: Double
        if zLower.isFinite {
            probability = 1 - normalCDF(zLower)
        } else {
            probability = zLower > 0 ? 0 : 1
        }
        guard probability.isFinite else { return 0 }
        let expected = Double(sampleCount) * min(1, max(0, probability))
        return expected.isFinite ? expected : 0
    }

    // MARK: - Private

    private static func usableWidth(_ width: Double) -> Double {
        guard width.isFinite, width > 0 else { return defaultWidth }
        return width
    }

    private static func arithmeticMean(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let total = values.reduce(0, +)
        guard total.isFinite else { return nil }
        let mean = total / Double(values.count)
        return mean.isFinite ? mean : nil
    }

    /// s = sqrt(Σ (x − μ)² / (n − 1)). Returns nil when n < 2 or the result
    /// is non-finite. A zero result is returned as zero so the caller can
    /// hide the curve.
    private static func sampleStandardDeviation(_ values: [Double], mean: Double) -> Double? {
        guard values.count >= 2, mean.isFinite else { return nil }
        var sumOfSquares = 0.0
        for value in values {
            let delta = value - mean
            sumOfSquares += delta * delta
        }
        guard sumOfSquares.isFinite else { return nil }
        let variance = sumOfSquares / Double(values.count - 1)
        guard variance.isFinite, variance >= 0 else { return nil }
        let deviation = sqrt(variance)
        return deviation.isFinite ? deviation : nil
    }

    private static func shouldShowCurve(count: Int, deviation: Double?) -> Bool {
        guard count >= minimumCurveSampleCount, let deviation else { return false }
        return deviation.isFinite && deviation > 0
    }

    private static func makeBins(
        values: [Double],
        width: Double,
        mean: Double?,
        deviation: Double?,
        showsCurve: Bool
    ) -> [Bin] {
        guard let maximum = values.max(), maximum.isFinite, maximum > 0 else { return [] }
        let cutoff = Double(maximumRegularBinCount) * width
        if !cutoff.isFinite || cutoff <= 0 || maximum >= cutoff {
            return binsWithOverflow(
                values: values,
                width: width,
                cutoff: cutoff,
                mean: mean,
                deviation: deviation,
                showsCurve: showsCurve
            )
        }

        guard let end = coveredEnd(maximum: maximum, width: width) else {
            return binsWithOverflow(
                values: values,
                width: width,
                cutoff: cutoff,
                mean: mean,
                deviation: deviation,
                showsCurve: showsCurve
            )
        }

        let rawCount = end / width
        guard rawCount.isFinite, rawCount >= 1, rawCount <= Double(maximumRegularBinCount) else {
            return binsWithOverflow(
                values: values,
                width: width,
                cutoff: cutoff,
                mean: mean,
                deviation: deviation,
                showsCurve: showsCurve
            )
        }

        let binCount = Int(rawCount.rounded())
        var counts = Array(repeating: 0, count: binCount)
        var overflow = 0
        for value in values {
            if let index = regularIndex(value: value, width: width, limit: binCount) {
                counts[index] += 1
            } else {
                overflow += 1
            }
        }
        if overflow > 0 {
            return binsWithOverflow(
                values: values,
                width: width,
                cutoff: cutoff,
                mean: mean,
                deviation: deviation,
                showsCurve: showsCurve
            )
        }

        return counts.enumerated().map { index, count in
            let lower = Double(index) * width
            return regularBin(
                lower: lower,
                upper: lower + width,
                count: count,
                mean: mean,
                deviation: deviation,
                sampleCount: values.count,
                showsCurve: showsCurve
            )
        }
    }

    /// 512 equal-width bins on [0, cutoff), then one open bin [cutoff, +∞).
    /// When cutoff itself is not a finite bound, every observation is counted
    /// in a single overflow bin starting at 0.
    private static func binsWithOverflow(
        values: [Double],
        width: Double,
        cutoff: Double,
        mean: Double?,
        deviation: Double?,
        showsCurve: Bool
    ) -> [Bin] {
        guard cutoff.isFinite, cutoff > 0 else {
            return [overflowBin(
                lower: 0,
                count: values.count,
                mean: mean,
                deviation: deviation,
                sampleCount: values.count,
                showsCurve: showsCurve
            )]
        }

        var counts = Array(repeating: 0, count: maximumRegularBinCount)
        var overflow = 0
        for value in values {
            if !value.isFinite || value >= cutoff {
                overflow += 1
            } else if let index = regularIndex(value: value, width: width, limit: maximumRegularBinCount) {
                counts[index] += 1
            } else {
                // Still below the overflow edge, so it belongs in the last
                // regular bin rather than the open tail.
                counts[maximumRegularBinCount - 1] += 1
            }
        }

        var bins = counts.enumerated().map { index, count in
            let lower = Double(index) * width
            return regularBin(
                lower: lower,
                upper: lower + width,
                count: count,
                mean: mean,
                deviation: deviation,
                sampleCount: values.count,
                showsCurve: showsCurve
            )
        }
        bins.append(overflowBin(
            lower: cutoff,
            count: overflow,
            mean: mean,
            deviation: deviation,
            sampleCount: values.count,
            showsCurve: showsCurve
        ))
        return bins
    }

    /// Index of a half-open regular bin, or nil when the value belongs in the
    /// overflow bin. Avoids converting a huge quotient to `Int`.
    private static func regularIndex(value: Double, width: Double, limit: Int) -> Int? {
        guard value.isFinite, width.isFinite, width > 0, limit > 0 else { return nil }
        let scaled = value / width
        guard scaled.isFinite, scaled < Double(limit) else { return nil }
        var index = Int(scaled.rounded(.down))
        if index >= limit { return nil }
        if index < 0 { index = 0 }
        return index
    }

    /// Smallest multiple of `width` that is strictly above `maximum`, so a
    /// session that lands exactly on a boundary still belongs to a real bin.
    /// If that multiple overflows, the next representable value is used so the
    /// observation is not dropped.
    private static func coveredEnd(maximum: Double, width: Double) -> Double? {
        guard maximum.isFinite, maximum > 0, width.isFinite, width > 0 else { return nil }
        var end = (maximum / width).rounded(.up) * width
        if !end.isFinite || end <= 0 {
            end = maximum.nextUp
        } else if maximum >= end - 1e-6 {
            let extended = end + width
            // Adding the width can be a no-op once the magnitude exceeds
            // what Double can distinguish. Use the next representable value
            // so the edge stays strictly above the longest session.
            if extended.isFinite, extended > maximum {
                end = extended
            } else {
                end = maximum.nextUp
            }
        }
        guard end.isFinite, end > maximum else { return nil }
        return end
    }

    private static func regularBin(
        lower: Double,
        upper: Double,
        count: Int,
        mean: Double?,
        deviation: Double?,
        sampleCount: Int,
        showsCurve: Bool
    ) -> Bin {
        let expected = curveExpected(
            showsCurve: showsCurve,
            mean: mean,
            deviation: deviation
        ) {
            expectedFrequency(
                sampleCount: sampleCount,
                mean: $0,
                sampleStandardDeviation: $1,
                lower: lower,
                upper: upper
            )
        }
        return Bin(
            lowerMinutes: lower,
            upperMinutes: upper,
            isOverflow: false,
            count: count,
            expectedCount: expected
        )
    }

    private static func overflowBin(
        lower: Double,
        count: Int,
        mean: Double?,
        deviation: Double?,
        sampleCount: Int,
        showsCurve: Bool
    ) -> Bin {
        let expected = curveExpected(
            showsCurve: showsCurve,
            mean: mean,
            deviation: deviation
        ) {
            expectedTailFrequency(
                sampleCount: sampleCount,
                mean: $0,
                sampleStandardDeviation: $1,
                lower: lower
            )
        }
        return Bin(
            lowerMinutes: lower,
            upperMinutes: nil,
            isOverflow: true,
            count: count,
            expectedCount: expected
        )
    }

    private static func curveExpected(
        showsCurve: Bool,
        mean: Double?,
        deviation: Double?,
        compute: (Double, Double) -> Double
    ) -> Double? {
        guard showsCurve, let mean, let deviation else { return nil }
        let expected = compute(mean, deviation)
        return expected.isFinite ? expected : 0
    }

    /// Φ(z) = 0.5 * (1 + erf(z / sqrt(2))).
    private static func normalCDF(_ z: Double) -> Double {
        guard z.isFinite else { return z > 0 ? 1 : 0 }
        let value = 0.5 * (1 + erf(z / sqrt(2)))
        guard value.isFinite else { return z > 0 ? 1 : 0 }
        return min(1, max(0, value))
    }
}
