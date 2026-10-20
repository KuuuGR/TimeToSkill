import XCTest
@testable import Time4Skill

final class SessionDurationHistogramTests: XCTestCase {

    func testEmptySampleHasNoBinsAndNoCurve() {
        let histogram = SessionDurationHistogram(minutes: [], binWidth: 15)
        XCTAssertTrue(histogram.minutes.isEmpty)
        XCTAssertTrue(histogram.bins.isEmpty)
        XCTAssertNil(histogram.mean)
        XCTAssertNil(histogram.sampleStandardDeviation)
        XCTAssertFalse(histogram.showsReferenceCurve)
    }

    func testEmptySampleWithDetailHasNoBins() {
        let histogram = SessionDurationHistogram(minutes: [], detail: .narrow)
        XCTAssertTrue(histogram.bins.isEmpty)
        XCTAssertFalse(histogram.showsReferenceCurve)
    }

    func testUnknownSourceIsNotATimerSession() {
        XCTAssertEqual(TimerSessionSample.timerSourceRaw, TimeIntervalSource.timer.rawValue)
        XCTAssertEqual(TimerSessionSample.minutes(sourceRaw: TimeIntervalSource.timer.rawValue, durationMinutes: 10), 10)
        XCTAssertNil(TimerSessionSample.minutes(sourceRaw: TimeIntervalSource.manual.rawValue, durationMinutes: 10))
        XCTAssertNil(TimerSessionSample.minutes(sourceRaw: "bogus", durationMinutes: 10))
        XCTAssertNil(TimerSessionSample.minutes(sourceRaw: "", durationMinutes: 10))
    }

    func testHugeDurationStaysInTheOverflowBin() throws {
        let histogram = SessionDurationHistogram(minutes: [1e20], binWidth: 5)
        let overflow = try XCTUnwrap(histogram.bins.last)
        XCTAssertEqual(histogram.bins.reduce(0) { $0 + $1.count }, 1)
        XCTAssertEqual(histogram.bins.filter(\.isOverflow).count, 1)
        XCTAssertEqual(histogram.bins.filter { !$0.isOverflow }.count, SessionDurationHistogram.maximumRegularBinCount)
        XCTAssertTrue(overflow.isOverflow)
        XCTAssertNil(overflow.upperMinutes)
        XCTAssertEqual(overflow.lowerMinutes, 5 * Double(SessionDurationHistogram.maximumRegularBinCount))
        XCTAssertEqual(overflow.count, 1)
        XCTAssertTrue(overflow.lowerMinutes.isFinite)
        XCTAssertTrue(histogram.bins.filter { !$0.isOverflow }.allSatisfy { bin in
            guard let upper = bin.upperMinutes else { return false }
            return bin.lowerMinutes.isFinite && upper.isFinite && upper - bin.lowerMinutes == 5
        })
    }

    func testManualZeroAndNonFiniteDurationsAreExcluded() {
        let values: [(Bool, Double)] = [
            (true, 25),
            (false, 40),
            (true, 0),
            (true, -5),
            (true, .nan),
            (true, .infinity),
            (true, 10)
        ]
        let minutes = values.compactMap { TimerSessionSample.minutes(isTimer: $0.0, durationMinutes: $0.1) }
        XCTAssertEqual(minutes, [25, 10])
    }

    func testFewerThanTenSessionsHidesTheCurveButKeepsEveryBin() {
        let histogram = SessionDurationHistogram(minutes: [5, 20, 45], binWidth: 15)
        XCTAssertEqual(histogram.minutes.count, 3)
        XCTAssertFalse(histogram.showsReferenceCurve)
        XCTAssertTrue(histogram.bins.allSatisfy { $0.expectedCount == nil })
        XCTAssertEqual(histogram.bins.map(\.count), [1, 1, 0, 1])
        XCTAssertEqual(histogram.bins.reduce(0) { $0 + $1.count }, 3)
    }

    func testConstantSampleHidesTheCurve() {
        let histogram = SessionDurationHistogram(minutes: Array(repeating: 30, count: 12), binWidth: 15)
        XCTAssertEqual(histogram.sampleStandardDeviation, 0)
        XCTAssertFalse(histogram.showsReferenceCurve)
        XCTAssertEqual(histogram.mean, 30)
        XCTAssertEqual(histogram.bins.map(\.count).reduce(0, +), 12)
        XCTAssertEqual(histogram.bins.last?.count, 12)
    }

    func testZeroVarianceWithDetailHidesTheCurve() {
        let histogram = SessionDurationHistogram(
            minutes: Array(repeating: 42, count: 20),
            detail: .medium
        )
        XCTAssertEqual(histogram.sampleStandardDeviation, 0)
        XCTAssertFalse(histogram.showsReferenceCurve)
        XCTAssertEqual(histogram.bins.reduce(0) { $0 + $1.count }, 20)
        XCTAssertTrue(histogram.bins.allSatisfy { $0.expectedCount == nil })
    }

    func testExactBoundaryFallsInTheNextFiniteBin() throws {
        let histogram = SessionDurationHistogram(minutes: [15], binWidth: 15)
        XCTAssertEqual(histogram.bins.map(\.count), [0, 1])
        let last = try XCTUnwrap(histogram.bins.last)
        XCTAssertEqual(last.lowerMinutes, 15)
        XCTAssertEqual(last.upperMinutes, 30)
        XCTAssertFalse(last.isOverflow)
    }

    func testLargeObservationStaysInTheOverflowBin() throws {
        let histogram = SessionDurationHistogram(minutes: [1_000_000], binWidth: 60)
        let last = try XCTUnwrap(histogram.bins.last)
        let cutoff = 60 * Double(SessionDurationHistogram.maximumRegularBinCount)
        XCTAssertEqual(histogram.bins.reduce(0) { $0 + $1.count }, 1)
        XCTAssertTrue(last.isOverflow)
        XCTAssertNil(last.upperMinutes)
        XCTAssertEqual(last.lowerMinutes, cutoff)
        XCTAssertEqual(last.count, 1)
        XCTAssertGreaterThanOrEqual(1_000_000, last.lowerMinutes)
    }

    func testOverflowTailIsNotARegularWidthBin() throws {
        let regular = Array(repeating: 30.0, count: 9)
        let histogram = SessionDurationHistogram(minutes: regular + [10_000], binWidth: 15)
        let overflow = try XCTUnwrap(histogram.bins.last)
        let cutoff = 15 * Double(SessionDurationHistogram.maximumRegularBinCount)
        XCTAssertTrue(histogram.showsReferenceCurve)
        XCTAssertTrue(overflow.isOverflow)
        XCTAssertEqual(overflow.lowerMinutes, cutoff)
        XCTAssertNil(overflow.upperMinutes)
        XCTAssertEqual(overflow.count, 1)
        XCTAssertEqual(histogram.bins.reduce(0) { $0 + $1.count }, 10)
        XCTAssertTrue(histogram.bins.filter { !$0.isOverflow }.allSatisfy { bin in
            bin.upperMinutes.map { $0 - bin.lowerMinutes } == 15
        })

        let mean = try XCTUnwrap(histogram.mean)
        let deviation = try XCTUnwrap(histogram.sampleStandardDeviation)
        let tail = SessionDurationHistogram.expectedTailFrequency(
            sampleCount: 10,
            mean: mean,
            sampleStandardDeviation: deviation,
            lower: cutoff
        )
        let finiteSlice = SessionDurationHistogram.expectedFrequency(
            sampleCount: 10,
            mean: mean,
            sampleStandardDeviation: deviation,
            lower: cutoff,
            upper: cutoff + 15
        )
        XCTAssertEqual(overflow.expectedCount ?? -1, tail, accuracy: 1e-9)
        XCTAssertTrue((overflow.expectedCount ?? -1).isFinite)
        XCTAssertGreaterThanOrEqual(tail + 1e-9, finiteSlice)
    }

    func testTailAtTheMeanIsHalfTheSample() {
        let tail = SessionDurationHistogram.expectedTailFrequency(
            sampleCount: 10,
            mean: 30,
            sampleStandardDeviation: 10,
            lower: 30
        )
        XCTAssertEqual(tail, 5, accuracy: 0.001)
        XCTAssertTrue(tail.isFinite)
    }

    func testSampleStandardDeviationUsesNMinusOne() {
        let histogram = SessionDurationHistogram(minutes: [10, 20], binWidth: 15)
        XCTAssertEqual(histogram.mean ?? 0, 15, accuracy: 1e-9)
        XCTAssertEqual(histogram.sampleStandardDeviation ?? 0, sqrt(50), accuracy: 1e-9)
        XCTAssertFalse(histogram.showsReferenceCurve)
    }

    func testIntegratedFrequencyMatchesTheNormalBinProbability() {
        let expected = SessionDurationHistogram.expectedFrequency(
            sampleCount: 10,
            mean: 30,
            sampleStandardDeviation: 10,
            lower: 30,
            upper: 45
        )
        XCTAssertEqual(expected, 4.331927987, accuracy: 0.001)
    }

    func testMixedSampleShowsAFiniteCurveOnTheSameScaleAsTheBins() throws {
        let minutes = [10, 15, 20, 25, 30, 35, 40, 50, 60, 80].map(Double.init)
        let histogram = SessionDurationHistogram(minutes: minutes, binWidth: 15)
        XCTAssertTrue(histogram.showsReferenceCurve)
        XCTAssertEqual(histogram.bins.reduce(0) { $0 + $1.count }, minutes.count)

        let expected = histogram.bins.compactMap(\.expectedCount)
        XCTAssertEqual(expected.count, histogram.bins.count)
        XCTAssertTrue(expected.allSatisfy { $0.isFinite && $0 >= 0 })
        let totalExpected = expected.reduce(0, +)
        XCTAssertGreaterThan(totalExpected, 0)
        XCTAssertLessThanOrEqual(totalExpected, Double(minutes.count) + 0.001)

        let mean = try XCTUnwrap(histogram.mean)
        let deviation = try XCTUnwrap(histogram.sampleStandardDeviation)
        let first = histogram.bins[0]
        let direct = SessionDurationHistogram.expectedFrequency(
            sampleCount: minutes.count,
            mean: mean,
            sampleStandardDeviation: deviation,
            lower: first.lowerMinutes,
            upper: try XCTUnwrap(first.upperMinutes)
        )
        XCTAssertEqual(first.expectedCount ?? -1, direct, accuracy: 1e-9)
    }

    func testNonFiniteInputDoesNotProduceNonFiniteGeometry() {
        let histogram = SessionDurationHistogram(
            minutes: [.nan, .infinity, -.infinity, 0, 12],
            binWidth: .nan
        )
        XCTAssertEqual(histogram.minutes, [12])
        XCTAssertEqual(histogram.binWidth, SessionDurationHistogram.defaultWidth)
        XCTAssertTrue(histogram.bins.allSatisfy { bin in
            bin.lowerMinutes.isFinite && (bin.upperMinutes?.isFinite ?? false) && !bin.isOverflow
        })
        XCTAssertFalse(histogram.showsReferenceCurve)
    }

    // MARK: - Freedman–Diaconis multipliers

    func testMediumWidthEqualsAutomaticBaseWidth() {
        let minutes = stride(from: 5.0, through: 120.0, by: 2.5).map { $0 }
        let medium = SessionDurationHistogram(minutes: minutes, detail: .medium)
        let base = SessionDurationHistogram.freedmanDiaconisBaseWidth(values: minutes)
        XCTAssertEqual(medium.baseBinWidth, base, accuracy: 1e-12)
        XCTAssertEqual(medium.binWidth, base, accuracy: 1e-12)
    }

    func testWideIsThreeTimesBaseAndNarrowIsOneThird() {
        // Spread sample so clamps do not flatten the multipliers.
        var minutes: [Double] = []
        for i in 0..<80 {
            minutes.append(10 + Double(i) * 1.5 + Double(i % 7) * 0.3)
        }
        let base = SessionDurationHistogram.freedmanDiaconisBaseWidth(values: minutes)
        let wide = SessionDurationHistogram(minutes: minutes, detail: .wide)
        let medium = SessionDurationHistogram(minutes: minutes, detail: .medium)
        let narrow = SessionDurationHistogram(minutes: minutes, detail: .narrow)

        XCTAssertEqual(medium.binWidth, base, accuracy: 1e-9)
        XCTAssertEqual(wide.binWidth, base * 3, accuracy: 1e-9)
        XCTAssertEqual(narrow.binWidth, base / 3, accuracy: 1e-9)
        XCTAssertEqual(wide.baseBinWidth, base, accuracy: 1e-9)
        XCTAssertEqual(narrow.baseBinWidth, base, accuracy: 1e-9)
    }

    func testDifferentDistributionsYieldDifferentBaseWidths() {
        let tight = (0..<40).map { 50.0 + Double($0) * 0.2 }
        let wide = (0..<40).map { 10.0 + Double($0) * 4.0 }
        let tightBase = SessionDurationHistogram.freedmanDiaconisBaseWidth(values: tight)
        let wideBase = SessionDurationHistogram.freedmanDiaconisBaseWidth(values: wide)
        XCTAssertNotEqual(tightBase, wideBase, accuracy: 1e-6)
        XCTAssertLessThan(tightBase, wideBase)
    }

    func testDetailChangeAltersBinEdgesAndCounts() {
        var minutes: [Double] = []
        for i in 0..<60 {
            minutes.append(8 + Double(i) * 1.7)
        }
        let wide = SessionDurationHistogram(minutes: minutes, detail: .wide)
        let medium = SessionDurationHistogram(minutes: minutes, detail: .medium)
        let narrow = SessionDurationHistogram(minutes: minutes, detail: .narrow)

        XCTAssertNotEqual(wide.binWidth, medium.binWidth)
        XCTAssertNotEqual(medium.binWidth, narrow.binWidth)
        XCTAssertNotEqual(wide.bins.map(\.lowerMinutes), narrow.bins.map(\.lowerMinutes))
        XCTAssertGreaterThan(narrow.bins.filter { !$0.isOverflow }.count, wide.bins.filter { !$0.isOverflow }.count)

        XCTAssertEqual(wide.bins.reduce(0) { $0 + $1.count }, minutes.count)
        XCTAssertEqual(medium.bins.reduce(0) { $0 + $1.count }, minutes.count)
        XCTAssertEqual(narrow.bins.reduce(0) { $0 + $1.count }, minutes.count)
    }

    func testDetailLevelsNeverDropOrDoubleCountObservations() {
        let minutes: [Double] = [
            3, 7, 12, 12, 18, 22, 29, 31, 40, 55, 70, 95, 120, 180
        ]
        for detail in SessionChartDetail.allCases {
            let histogram = SessionDurationHistogram(minutes: minutes, detail: detail)
            XCTAssertEqual(
                histogram.bins.reduce(0) { $0 + $1.count },
                minutes.count,
                "Detail \(detail) lost or double-counted observations"
            )
            XCTAssertEqual(histogram.minutes.count, minutes.count)
            XCTAssertEqual(histogram.mean, SessionDurationHistogram(minutes: minutes, detail: .medium).mean)
            XCTAssertEqual(
                histogram.sampleStandardDeviation,
                SessionDurationHistogram(minutes: minutes, detail: .medium).sampleStandardDeviation
            )
        }
    }

    func testObservationsAreAssignedToHalfOpenBinsWithoutOverlap() throws {
        let minutes: [Double] = [0.5, 14.9, 15, 29.9, 30, 44.9]
        let histogram = SessionDurationHistogram(minutes: minutes, binWidth: 15)
        XCTAssertEqual(histogram.bins.map(\.count), [2, 2, 2])
        XCTAssertEqual(histogram.bins.reduce(0) { $0 + $1.count }, minutes.count)

        for bin in histogram.bins where !bin.isOverflow {
            let upper = try XCTUnwrap(bin.upperMinutes)
            let assigned = minutes.filter { $0 >= bin.lowerMinutes && $0 < upper }
            XCTAssertEqual(assigned.count, bin.count)
        }
    }

    func testCurveScaleMatchesBinWidthForEachDetail() throws {
        let minutes = [10, 15, 20, 25, 30, 35, 40, 50, 60, 80].map(Double.init)
        for detail in SessionChartDetail.allCases {
            let histogram = SessionDurationHistogram(minutes: minutes, detail: detail)
            XCTAssertTrue(histogram.showsReferenceCurve)
            let mean = try XCTUnwrap(histogram.mean)
            let deviation = try XCTUnwrap(histogram.sampleStandardDeviation)
            let first = try XCTUnwrap(histogram.bins.first { !$0.isOverflow })
            let upper = try XCTUnwrap(first.upperMinutes)
            XCTAssertEqual(upper - first.lowerMinutes, histogram.binWidth, accuracy: 1e-12)

            let direct = SessionDurationHistogram.expectedFrequency(
                sampleCount: minutes.count,
                mean: mean,
                sampleStandardDeviation: deviation,
                lower: first.lowerMinutes,
                upper: upper
            )
            XCTAssertEqual(first.expectedCount ?? -1, direct, accuracy: 1e-9)

            let totalExpected = histogram.bins.compactMap(\.expectedCount).reduce(0, +)
            XCTAssertGreaterThan(totalExpected, 0)
            XCTAssertLessThanOrEqual(totalExpected, Double(minutes.count) + 0.001)
        }
    }

    func testDefaultDetailIsMedium() {
        XCTAssertEqual(SessionDurationHistogram.defaultDetail, .medium)
        let histogram = SessionDurationHistogram(minutes: [10, 20, 30])
        XCTAssertEqual(histogram.detail, .medium)
    }

    func testZeroVarianceAndEmptyDoNotProduceNaNWidths() {
        let empty = SessionDurationHistogram.freedmanDiaconisBaseWidth(values: [])
        XCTAssertTrue(empty.isFinite && empty > 0)
        let constant = SessionDurationHistogram.freedmanDiaconisBaseWidth(values: Array(repeating: 12, count: 8))
        XCTAssertTrue(constant.isFinite && constant > 0)
        let hist = SessionDurationHistogram(minutes: Array(repeating: 12, count: 8), detail: .narrow)
        XCTAssertTrue(hist.binWidth.isFinite && hist.binWidth > 0)
        XCTAssertTrue(hist.bins.allSatisfy { $0.lowerMinutes.isFinite })
    }
}

final class TrackerToolKindTests: XCTestCase {
    func testProgressShowsNewSkillAndBalanceDoesNot() {
        XCTAssertTrue(TrackerToolKind.progress.showsNewSkillAction)
        XCTAssertFalse(TrackerToolKind.progress.showsNewBalanceAction)
        XCTAssertFalse(TrackerToolKind.balance.showsNewSkillAction)
        XCTAssertTrue(TrackerToolKind.balance.showsNewBalanceAction)
    }

    func testResolveFallsBackToProgress() {
        XCTAssertEqual(TrackerToolKind.resolve("progress"), .progress)
        XCTAssertEqual(TrackerToolKind.resolve("balance"), .balance)
        XCTAssertEqual(TrackerToolKind.resolve("unknown"), .progress)
    }
}
