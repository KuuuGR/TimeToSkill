import XCTest
@testable import Time4Skill

final class YearActivityCalendarTests: XCTestCase {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    func testScoreRanksSeveralSkillsAboveOneLongSession() {
        let longSession = YearActivityCalendar.score(distinctSkills: 1, minutes: 600)
        let twoSkills = YearActivityCalendar.score(distinctSkills: 2, minutes: 2)
        XCTAssertEqual(longSession, 1.99, accuracy: 0.0001)
        XCTAssertEqual(YearActivityCalendar.level(for: longSession), 2)
        XCTAssertEqual(YearActivityCalendar.level(for: twoSkills), 3)
        XCTAssertGreaterThan(twoSkills, longSession)
    }

    func testLevelBands() {
        XCTAssertEqual(YearActivityCalendar.level(for: 0), 0)
        XCTAssertEqual(YearActivityCalendar.level(for: 1.49), 1)
        XCTAssertEqual(YearActivityCalendar.level(for: 1.5), 2)
        XCTAssertEqual(YearActivityCalendar.level(for: 2), 3)
        XCTAssertEqual(YearActivityCalendar.level(for: 3), 4)
        XCTAssertEqual(YearActivityCalendar.level(for: 4), 5)
        XCTAssertEqual(YearActivityCalendar.level(for: .nan), 0)
    }

    func testManualAndInvalidDurationsAreExcluded() {
        let skill = UUID()
        XCTAssertNil(YearActivityCalendar.acceptedSession(sourceRaw: "manual", skillId: skill, minutes: 30, endedAt: date(2024, 1, 2)))
        XCTAssertNil(YearActivityCalendar.acceptedSession(sourceRaw: "bogus", skillId: skill, minutes: 30, endedAt: date(2024, 1, 2)))
        XCTAssertNil(YearActivityCalendar.acceptedSession(sourceRaw: "timer", skillId: skill, minutes: 0, endedAt: date(2024, 1, 2)))
        XCTAssertNil(YearActivityCalendar.acceptedSession(sourceRaw: "timer", skillId: skill, minutes: .nan, endedAt: date(2024, 1, 2)))
        XCTAssertNotNil(YearActivityCalendar.acceptedSession(sourceRaw: "timer", skillId: skill, minutes: 15, endedAt: date(2024, 1, 2)))
    }

    func testDuplicateSessionsCountAsOneSkillAndLeapYearHas366Days() {
        let skill = UUID()
        let other = UUID()
        let sessions = [
            TimerSessionActivity(skillId: skill, minutes: 20, endedAt: date(2024, 3, 1)),
            TimerSessionActivity(skillId: skill, minutes: 40, endedAt: date(2024, 3, 1, hour: 18)),
            TimerSessionActivity(skillId: other, minutes: 10, endedAt: date(2024, 3, 1, hour: 20))
        ]
        let year = YearActivityCalendar.year(2024, sessions: sessions, calendar: calendar)
        XCTAssertEqual(year.days.count, 366)
        XCTAssertEqual(year.activeDayCount, 1)
        XCTAssertEqual(year.distinctSkillCount, 2)
        let active = year.days.filter { $0.level > 0 }
        XCTAssertEqual(active.count, 1)
        XCTAssertEqual(active[0].level, 3)
    }

    func testNonLeapYearHas365NeutralDaysWhenEmpty() {
        let year = YearActivityCalendar.year(2025, sessions: [], calendar: calendar)
        XCTAssertEqual(year.days.count, 365)
        XCTAssertTrue(year.days.allSatisfy { $0.level == 0 })
        XCTAssertEqual(year.activeDayCount, 0)
        XCTAssertEqual(year.distinctSkillCount, 0)
    }

    func testNavigationStopsAtFirstEvidencedYearAndCurrentYear() {
        let now = date(2026, 6, 1)
        let sessions = [
            TimerSessionActivity(skillId: UUID(), minutes: 10, endedAt: date(2020, 5, 2)),
            TimerSessionActivity(skillId: UUID(), minutes: 10, endedAt: date(2024, 1, 3)),
            TimerSessionActivity(skillId: UUID(), minutes: 10, endedAt: date(2028, 1, 1))
        ]
        let bounds = YearActivityCalendar.bounds(sessions: sessions, now: now, calendar: calendar)
        XCTAssertEqual(bounds.earliestYear, 2020)
        XCTAssertEqual(bounds.currentYear, 2026)
        XCTAssertTrue(bounds.hasRecordedActivity)
        XCTAssertFalse(bounds.contains(2019))
        XCTAssertFalse(bounds.contains(2027))
        let empty = YearActivityCalendar.year(2022, sessions: sessions, calendar: calendar)
        XCTAssertEqual(empty.days.count, 365)
        XCTAssertEqual(empty.activeDayCount, 0)
    }

    func testMonthMarksPracticeAndObtainedSeparately() {
        let practice = Set([calendar.startOfDay(for: date(2026, 3, 2)), calendar.startOfDay(for: date(2026, 3, 5))])
        let obtained = Set([calendar.startOfDay(for: date(2026, 3, 5)), calendar.startOfDay(for: date(2026, 3, 9))])
        let month = MonthActivityCalendar.month(
            containing: date(2026, 3, 15),
            practiceDays: practice,
            obtainedDays: obtained,
            calendar: calendar
        )
        XCTAssertEqual(month.days.count, 31)
        XCTAssertEqual(month.practiceDayCount, 2)
        XCTAssertEqual(month.obtainedDayCount, 2)
        XCTAssertEqual(month.days[1].mark, .practice)
        XCTAssertEqual(month.days[4].mark, .both)
        XCTAssertEqual(month.days[8].mark, .obtained)
        XCTAssertEqual(month.days[0].mark, .none)
        XCTAssertEqual(MonthActivityCalendar.mark(practiced: false, obtained: false), .none)
    }

    func testCatalogMergeKeepsUntranslatedRows() {
        let base = [
            SeedSkill(id: "a", title: "Alpha", description: "A", imageName: "star", category: "One", difficulty: 2, oneStarDescription: "keep"),
            SeedSkill(id: "b", title: "Beta", description: "B", imageName: "leaf", category: "Two", difficulty: 1)
        ]
        let localized = [
            SeedSkill(id: "a", title: "Alfa", description: "Opis", imageName: "ignored", category: "Raz", difficulty: 9)
        ]
        let merged = SkillSeeder.mergedItems(base: base, localized: localized)
        XCTAssertEqual(merged.map(\.id), ["a", "b"])
        XCTAssertEqual(merged[0].title, "Alfa")
        XCTAssertEqual(merged[0].imageName, "star")
        XCTAssertEqual(merged[0].oneStarDescription, "keep")
        let translatedLevel = SkillSeeder.mergedItems(
            base: base,
            localized: [SeedSkill(id: "a", title: "Alfa", description: "Opis", imageName: "ignored", category: "Raz", difficulty: 9, oneStarDescription: "nowe")]
        )
        XCTAssertEqual(translatedLevel[0].oneStarDescription, "nowe")
        XCTAssertEqual(translatedLevel[1].title, "Beta")
        XCTAssertEqual(merged[0].difficulty, 2)
        XCTAssertEqual(merged[1].title, "Beta")
    }

    func testNoSessionsStayOnTheCurrentYear() {
        let bounds = YearActivityCalendar.bounds(sessions: [], now: date(2026, 2, 2), calendar: calendar)
        XCTAssertFalse(bounds.hasRecordedActivity)
        XCTAssertEqual(bounds.earliestYear, 2026)
        XCTAssertEqual(bounds.currentYear, 2026)
    }
}