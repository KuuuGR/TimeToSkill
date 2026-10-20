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

/// Three readable histogram densities. Medium uses an automatic base width;
/// wide and narrow are exact multipliers of that base.
enum SessionChartDetail: String, CaseIterable, Identifiable, Equatable {
    case wide
    case medium
    case narrow

    var id: String { rawValue }

    /// Localization key for the segmented control.
    var titleKey: String {
        switch self {
        case .wide: return "session_chart_detail_wide"
        case .medium: return "session_chart_detail_medium"
        case .narrow: return "session_chart_detail_narrow"
        }
    }

    /// Exact multiplier applied to the automatic medium (`base`) width.
    var widthMultiplier: Double {
        switch self {
        case .wide: return 3
        case .medium: return 1
        case .narrow: return 1.0 / 3.0
        }
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

    /// Default detail level for the segmented control.
    static let defaultDetail: SessionChartDetail = .medium
    static let minimumCurveSampleCount = 10

    /// Fallback when the sample is empty or has no usable spread.
    static let defaultWidth: Double = 15
    static let availableWidths: [Double] = [5, 15, 30, 60]

    /// Explicit bin-count limits so FD / multipliers never produce a single
    /// unreadable bar or hundreds of hairline slots.
    static let minimumRegularBinCount = 2
    static let maximumRegularBinCount = 48

    let minutes: [Double]
    let detail: SessionChartDetail
    /// Freedman–Diaconis (or fallback) width for the medium setting, before
    /// applying the detail multiplier and bin-count clamps.
    let baseBinWidth: Double
    /// Actual numeric bin width used for this histogram.
    let binWidth: Double
    let mean: Double?
    /// Sample standard deviation (divisor n − 1). Nil when n < 2.
    let sampleStandardDeviation: Double?
    let showsReferenceCurve: Bool
    let bins: [Bin]

    init(minutes: [Double], detail: SessionChartDetail = .medium) {
        let clean = minutes.filter { $0.isFinite && $0 > 0 }
        let mean = Self.arithmeticMean(clean)
        let deviation = mean.flatMap { Self.sampleStandardDeviation(clean, mean: $0) }
        let showsCurve = Self.shouldShowCurve(count: clean.count, deviation: deviation)
        let base = Self.freedmanDiaconisBaseWidth(values: clean)
        let width = Self.resolvedWidth(values: clean, detail: detail, base: base)

        self.minutes = clean
        self.detail = detail
        self.baseBinWidth = base
        self.binWidth = width
        self.mean = mean
        self.sampleStandardDeviation = deviation
        self.showsReferenceCurve = showsCurve
        self.bins = Self.makeBins(
            values: clean,
            width: width,
            originAlignedToData: true,
            maximumRegularBins: Self.maximumRegularBinCount,
            mean: mean,
            deviation: deviation,
            showsCurve: showsCurve
        )
    }

    /// Width-based initializer retained for unit tests that pin a minute step.
    /// Bins start at 0 so legacy half-open expectations stay stable.
    init(minutes: [Double], binWidth: Double) {
        let clean = minutes.filter { $0.isFinite && $0 > 0 }
        let width = Self.usableWidth(binWidth)
        let mean = Self.arithmeticMean(clean)
        let deviation = mean.flatMap { Self.sampleStandardDeviation(clean, mean: $0) }
        let showsCurve = Self.shouldShowCurve(count: clean.count, deviation: deviation)

        self.minutes = clean
        self.detail = .medium
        self.baseBinWidth = width
        self.binWidth = width
        self.mean = mean
        self.sampleStandardDeviation = deviation
        self.showsReferenceCurve = showsCurve
        self.bins = Self.makeBins(
            values: clean,
            width: width,
            originAlignedToData: false,
            maximumRegularBins: Self.maximumRegularBinCount,
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

    /// Automatic medium width: Freedman–Diaconis `2 · IQR · n^(−1/3)`, with
    /// Scott's rule when IQR is zero but sample SD is positive, then a range
    /// fallback. Result is clamped so the data range yields between
    /// `minimumRegularBinCount` and `maximumRegularBinCount` bins.
    static func freedmanDiaconisBaseWidth(values: [Double]) -> Double {
        guard values.count >= 2,
              let lo = values.min(), let hi = values.max(),
              lo.isFinite, hi.isFinite
        else { return defaultWidth }

        let range = hi - lo
        if !(range.isFinite && range > 0) {
            return defaultWidth
        }

        let n = Double(values.count)
        let iqr = interquartileRange(values)
        let raw: Double
        if iqr.isFinite, iqr > 0 {
            raw = 2.0 * iqr / pow(n, 1.0 / 3.0)
        } else if let mean = arithmeticMean(values),
                  let s = sampleStandardDeviation(values, mean: mean),
                  s.isFinite, s > 0 {
            // Scott: 3.5 · s · n^(−1/3) when IQR vanishes but variance remains.
            raw = 3.5 * s / pow(n, 1.0 / 3.0)
        } else {
            // All equal (or no usable spread): one “medium” slot spanning the
            // tiny numeric gap; clamps below still enforce at least 2 bins when
            // the caller later expands the range with nextUp edges.
            raw = max(range, defaultWidth)
        }

        guard raw.isFinite, raw > 0 else { return defaultWidth }
        return clampWidth(raw, range: range)
    }

    /// Medium → base; wide → `base × 3`; narrow → `base ÷ 3`.
    /// Multipliers stay exact so the three settings never collapse to one
    /// width; bin-count limits are enforced later when laying out bins
    /// (overflow after `maximumRegularBinCount`), not by rewriting the width.
    static func resolvedWidth(
        values: [Double],
        detail: SessionChartDetail,
        base: Double? = nil
    ) -> Double {
        let baseWidth = base ?? freedmanDiaconisBaseWidth(values: values)
        let scaled = baseWidth * detail.widthMultiplier
        guard scaled.isFinite, scaled > 0 else { return usableWidth(baseWidth) }
        return scaled
    }

    // MARK: - Private

    private static func usableWidth(_ width: Double) -> Double {
        guard width.isFinite, width > 0 else { return defaultWidth }
        return width
    }

    /// Keeps `range / width` inside `[minimumRegularBinCount, maximumRegularBinCount]`.
    private static func clampWidth(_ width: Double, range: Double) -> Double {
        guard width.isFinite, width > 0, range.isFinite, range > 0 else {
            return usableWidth(width)
        }
        let maxWidth = range / Double(minimumRegularBinCount)
        let minWidth = range / Double(maximumRegularBinCount)
        let clamped = min(max(width, minWidth), maxWidth)
        return clamped.isFinite && clamped > 0 ? clamped : usableWidth(width)
    }

    /// Tukey hinges: Q3 − Q1 on the sorted sample.
    private static func interquartileRange(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        guard sorted.count >= 2 else { return 0 }
        let q1 = quantile(sorted, probability: 0.25)
        let q3 = quantile(sorted, probability: 0.75)
        guard q1.isFinite, q3.isFinite else { return 0 }
        return max(0, q3 - q1)
    }

    private static func quantile(_ sorted: [Double], probability: Double) -> Double {
        guard !sorted.isEmpty else { return .nan }
        if sorted.count == 1 { return sorted[0] }
        let p = min(1, max(0, probability))
        let position = p * Double(sorted.count - 1)
        let lowerIndex = Int(position.rounded(.down))
        let upperIndex = min(sorted.count - 1, lowerIndex + 1)
        let fraction = position - Double(lowerIndex)
        let lower = sorted[lowerIndex]
        let upper = sorted[upperIndex]
        return lower + (upper - lower) * fraction
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
        originAlignedToData: Bool,
        maximumRegularBins: Int,
        mean: Double?,
        deviation: Double?,
        showsCurve: Bool
    ) -> [Bin] {
        guard let maximum = values.max(), maximum.isFinite, maximum > 0,
              let minimum = values.min(), minimum.isFinite
        else { return [] }

        let origin: Double
        if originAlignedToData {
            // Align the first edge to a multiple of `width` at or below min so
            // empty leading bins below the sample are not invented from zero.
            let rawOrigin = (minimum / width).rounded(.down) * width
            origin = rawOrigin.isFinite ? max(0, rawOrigin) : 0
        } else {
            origin = 0
        }

        let limit = max(1, maximumRegularBins)
        guard width.isFinite, width > 0, origin.isFinite else {
            return [overflowBin(
                lower: 0,
                count: values.count,
                mean: mean,
                deviation: deviation,
                sampleCount: values.count,
                showsCurve: showsCurve
            )]
        }

        // Half-open bins: value `v` lands in floor((v − origin) / width).
        // A session exactly on a multiple therefore needs the next bin, not
        // an exclusive end that drops it. Compare in Double first so a huge
        // duration never traps when converting the quotient to Int.
        let lastScaled = (maximum - origin) / width
        guard lastScaled.isFinite, lastScaled >= 0 else {
            return binsWithOverflow(
                values: values,
                width: width,
                origin: origin,
                cutoff: origin + Double(limit) * width,
                maximumRegularBins: limit,
                mean: mean,
                deviation: deviation,
                showsCurve: showsCurve
            )
        }
        if lastScaled >= Double(limit) {
            return binsWithOverflow(
                values: values,
                width: width,
                origin: origin,
                cutoff: origin + Double(limit) * width,
                maximumRegularBins: limit,
                mean: mean,
                deviation: deviation,
                showsCurve: showsCurve
            )
        }
        let lastIndex = Int(lastScaled.rounded(.down))
        let binCount = max(1, lastIndex + 1)
        var counts = Array(repeating: 0, count: binCount)
        var overflow = 0
        for value in values {
            if let index = regularIndex(value: value, origin: origin, width: width, limit: binCount) {
                counts[index] += 1
            } else {
                overflow += 1
            }
        }
        if overflow > 0 {
            return binsWithOverflow(
                values: values,
                width: width,
                origin: origin,
                cutoff: origin + Double(binCount) * width,
                maximumRegularBins: limit,
                mean: mean,
                deviation: deviation,
                showsCurve: showsCurve
            )
        }

        return counts.enumerated().map { index, count in
            let lower = origin + Double(index) * width
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

    private static func binsWithOverflow(
        values: [Double],
        width: Double,
        origin: Double,
        cutoff: Double,
        maximumRegularBins: Int,
        mean: Double?,
        deviation: Double?,
        showsCurve: Bool
    ) -> [Bin] {
        guard cutoff.isFinite, cutoff > origin else {
            return [overflowBin(
                lower: origin,
                count: values.count,
                mean: mean,
                deviation: deviation,
                sampleCount: values.count,
                showsCurve: showsCurve
            )]
        }

        let limit = max(1, maximumRegularBins)
        var counts = Array(repeating: 0, count: limit)
        var overflow = 0
        for value in values {
            if !value.isFinite || value >= cutoff {
                overflow += 1
            } else if let index = regularIndex(value: value, origin: origin, width: width, limit: limit) {
                counts[index] += 1
            } else {
                counts[limit - 1] += 1
            }
        }

        var bins = counts.enumerated().map { index, count in
            let lower = origin + Double(index) * width
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

    /// Index of a half-open regular bin relative to `origin`, or nil for overflow.
    private static func regularIndex(
        value: Double,
        origin: Double,
        width: Double,
        limit: Int
    ) -> Int? {
        guard value.isFinite, origin.isFinite, width.isFinite, width > 0, limit > 0 else { return nil }
        let scaled = (value - origin) / width
        guard scaled.isFinite, scaled >= 0, scaled < Double(limit) else { return nil }
        var index = Int(scaled.rounded(.down))
        if index >= limit { return nil }
        if index < 0 { index = 0 }
        return index
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
