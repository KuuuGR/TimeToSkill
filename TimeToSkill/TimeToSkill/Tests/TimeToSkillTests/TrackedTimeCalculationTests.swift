import XCTest
@testable import TimeToSkill

final class TrackedTimeCalculationTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_700_000_000) // fixed anchor

    private func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: now)!
    }

    func testLast7DaysIncludesRecentSessionOnly() {
        let cutoff = TrackedTimeCalculation.cutoffDate(daysAgo: 7, from: now)!
        let sessions: [(Date, Double)] = [
            (daysAgo(2), 60),   // 1h recent
            (daysAgo(10), 600), // 10h old — excluded from window
        ]
        let hours = TrackedTimeCalculation.committedHours(sessions: sessions, since: cutoff)
        XCTAssertEqual(hours, 1.0, accuracy: 0.0001)
    }

    func testManualAdjustmentAppearsInLast7Days() {
        let cutoff = TrackedTimeCalculation.cutoffDate(daysAgo: 7, from: now)!
        // Manual adjust of +30 minutes → durationMinutes 30
        let sessions: [(Date, Double)] = [
            (daysAgo(1), 30),
        ]
        let hours = TrackedTimeCalculation.committedHours(sessions: sessions, since: cutoff)
        XCTAssertEqual(hours, 0.5, accuracy: 0.0001)
    }

    func testOldSkillNewSessionDoesNotRecountLifetime() {
        let cutoff = TrackedTimeCalculation.cutoffDate(daysAgo: 7, from: now)!
        // Skill may have 500h lifetime; only the new 2h session entry counts for the window
        let lifetime = TrackedTimeCalculation.lifetimeHours([500])
        let sessions: [(Date, Double)] = [
            (daysAgo(1), 120), // 2h new session
        ]
        let last7 = TrackedTimeCalculation.committedHours(sessions: sessions, since: cutoff)
        XCTAssertEqual(last7, 2.0, accuracy: 0.0001)
        XCTAssertEqual(lifetime, 500, accuracy: 0.0001)
        XCTAssertNotEqual(last7, lifetime)
    }

    func testActiveTimerExcludedUntilCommittedEntryExists() {
        let cutoff = TrackedTimeCalculation.cutoffDate(daysAgo: 7, from: now)!
        // No TimeIntervalEntry while timer runs → 0
        let hours = TrackedTimeCalculation.committedHours(sessions: [], since: cutoff)
        XCTAssertEqual(hours, 0, accuracy: 0.0001)
    }

    func testAllTimeUsesSkillHoursOnly() {
        let lifetime = TrackedTimeCalculation.lifetimeHours([10, 20.5, -1])
        XCTAssertEqual(lifetime, 29.5, accuracy: 0.0001)
    }

    func testAllTimeZeroWhenEmpty() {
        XCTAssertEqual(TrackedTimeCalculation.lifetimeHours([]), 0, accuracy: 0.0001)
    }

    func testPercentageDivideByZero() {
        XCTAssertEqual(
            TrackedTimeCalculation.percentageLabel(periodHours: 5, lifetimeHours: 0),
            "0%"
        )
    }

    func testPercentageNormal() {
        XCTAssertEqual(
            TrackedTimeCalculation.percentageLabel(periodHours: 25, lifetimeHours: 100),
            "25%"
        )
    }

    func testLast30DaysIncludesOlderThan7() {
        let cutoff7 = TrackedTimeCalculation.cutoffDate(daysAgo: 7, from: now)!
        let cutoff30 = TrackedTimeCalculation.cutoffDate(daysAgo: 30, from: now)!
        let sessions: [(Date, Double)] = [
            (daysAgo(10), 60), // in 30d, not in 7d
        ]
        XCTAssertEqual(
            TrackedTimeCalculation.committedHours(sessions: sessions, since: cutoff7),
            0,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            TrackedTimeCalculation.committedHours(sessions: sessions, since: cutoff30),
            1.0,
            accuracy: 0.0001
        )
    }
}
