import XCTest
@testable import TimeToSkill

final class StatsSessionActivityTests: XCTestCase {

    private let skillA = UUID()
    private let skillB = UUID()
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func entry(
        id: UUID = UUID(),
        skillId: UUID,
        minutes: Double,
        daysAgo: Int
    ) -> (UUID, UUID, Double, Date) {
        let created = Calendar.current.date(byAdding: .day, value: -daysAgo, to: now)!
        return (id, skillId, minutes, created)
    }

    func testNewSkillWithoutEntriesCreatesNoActivity() {
        let rows = StatsSessionActivity.recentSessions(
            entries: [],
            skillNames: [skillA: "Guitar"]
        )
        XCTAssertTrue(rows.isEmpty)
    }

    func testStoppedTimerCreatesOneActivityRow() {
        let id = UUID()
        let rows = StatsSessionActivity.recentSessions(
            entries: [entry(id: id, skillId: skillA, minutes: 45, daysAgo: 0)],
            skillNames: [skillA: "Guitar"]
        )
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].id, id)
        XCTAssertEqual(rows[0].skillName, "Guitar")
        XCTAssertEqual(rows[0].durationMinutes, 45, accuracy: 0.0001)
        XCTAssertEqual(
            StatsSessionActivity.formattedDuration(minutes: rows[0].durationMinutes),
            "0h 45m"
        )
    }

    func testManualAdjustmentAppearsLikeTimerEntry() {
        let rows = StatsSessionActivity.recentSessions(
            entries: [entry(skillId: skillA, minutes: 30, daysAgo: 0)],
            skillNames: [skillA: "Piano"]
        )
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].skillName, "Piano")
        XCTAssertEqual(rows[0].durationMinutes, 30, accuracy: 0.0001)
    }

    func testSortedByCreatedAtDescending() {
        let older = entry(skillId: skillA, minutes: 10, daysAgo: 5)
        let newer = entry(skillId: skillB, minutes: 20, daysAgo: 1)
        let rows = StatsSessionActivity.recentSessions(
            entries: [older, newer],
            skillNames: [skillA: "A", skillB: "B"]
        )
        XCTAssertEqual(rows.map(\.skillName), ["B", "A"])
    }

    func testFirstSessionNilWhenNoEntries() {
        XCTAssertNil(StatsSessionActivity.firstSessionDate(createdAtDates: []))
    }

    func testFirstSessionUsesEarliestCreatedAt() {
        let early = now.addingTimeInterval(-10_000)
        let late = now.addingTimeInterval(-100)
        let first = StatsSessionActivity.firstSessionDate(createdAtDates: [late, early])
        XCTAssertEqual(first, early)
    }

    func testLifetimeHoursUnrelatedHelperStillSkillBased() {
        // Guard: Phase 03A lifetime path unchanged and independent of activity sessions.
        let lifetime = TrackedTimeCalculation.lifetimeHours([12.5, 7.5])
        XCTAssertEqual(lifetime, 20.0, accuracy: 0.0001)
    }
}
