import XCTest
import SwiftData
@testable import Time4Skill

@MainActor
final class SkillDataIntegrityTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Skill.self, TimeIntervalEntry.self, ExemplarySkill.self, Counter.self, TimeBudget.self,
            configurations: config
        )
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    func testTouchLastUpdatedAdvancesTimestamp() {
        let skill = Skill(name: "Guitar", hours: 1)
        let earlier = Date(timeIntervalSince1970: 1_700_000_000)
        skill.lastUpdated = earlier
        let later = earlier.addingTimeInterval(120)
        skill.touchLastUpdated(at: later)
        XCTAssertEqual(skill.lastUpdated, later)
    }

    func testDeleteEntriesRemovesOnlyMatchingSkill() throws {
        let keep = Skill(name: "Keep", hours: 2)
        let remove = Skill(name: "Remove", hours: 3)
        context.insert(keep)
        context.insert(remove)
        context.insert(TimeIntervalEntry(skillId: keep.id, durationMinutes: 10, source: .timer))
        context.insert(TimeIntervalEntry(skillId: remove.id, durationMinutes: 20, source: .timer))
        context.insert(TimeIntervalEntry(skillId: remove.id, durationMinutes: 5, source: .manual))
        try context.save()

        let deleted = try SkillIntervalCleanup.deleteEntries(for: remove.id, in: context)
        try context.save()
        XCTAssertEqual(deleted, 2)

        let remaining = try context.fetch(FetchDescriptor<TimeIntervalEntry>())
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.skillId, keep.id)
    }

    func testDeleteSkillPathLeavesNoOrphans() throws {
        let skill = Skill(name: "Solo", hours: 4)
        context.insert(skill)
        context.insert(TimeIntervalEntry(skillId: skill.id, durationMinutes: 30, source: .timer))
        try context.save()

        let skillId = skill.id
        _ = try SkillIntervalCleanup.deleteEntries(for: skillId, in: context)
        context.delete(skill)
        try context.save()

        let entries = try context.fetch(FetchDescriptor<TimeIntervalEntry>())
        let skills = try context.fetch(FetchDescriptor<Skill>())
        XCTAssertTrue(entries.isEmpty)
        XCTAssertTrue(skills.isEmpty)
    }
}
