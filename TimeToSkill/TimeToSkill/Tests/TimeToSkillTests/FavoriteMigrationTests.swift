//
//  FavoriteMigrationTests.swift
//
//  Isolated store only. This does not open the user's database.
//

import XCTest
import SwiftData
@testable import Time4Skill

final class FavoriteMigrationTests: XCTestCase {
    func testNewRecordDefaultsFavoriteToFalseAndReopenKeepsProgress() throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("t4s-migration-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let storeURL = folder.appendingPathComponent("isolated.store")
        let obtained = Date(timeIntervalSince1970: 1_700_000_000)
        let schema = Schema([Skill.self, ExemplarySkill.self])

        let first = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)]
        )
        let writing = ModelContext(first)
        let tracked = Skill(name: "Gitara", hours: 12.5)
        let exemplary = ExemplarySkill(
            catalogID: "seed-zloz",
            title: "Złóż serwetkę",
            skillDescription: "Złóż płótno na trzy.",
            imageName: "star.fill",
            category: "Dom",
            difficultyLevel: 3,
            oneStarDescription: "Złóż raz.",
            twoStarDescription: "Wyrównaj krawędź.",
            threeStarDescription: "Zostaw płaskie zgięcie.",
            userRating: 2,
            obtainedAt: obtained,
            isObtained: true
        )
        writing.insert(tracked)
        writing.insert(exemplary)
        try writing.save()
        let trackedID = tracked.id
        let exemplaryID = exemplary.id

        let second = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)]
        )
        let reading = ModelContext(second)
        let skills = try reading.fetch(FetchDescriptor<Skill>())
        let catalog = try reading.fetch(FetchDescriptor<ExemplarySkill>())
        let reloadedSkill = try XCTUnwrap(skills.first { $0.id == trackedID })
        let reloaded = try XCTUnwrap(catalog.first { $0.id == exemplaryID })

        XCTAssertEqual(reloadedSkill.hours, 12.5, accuracy: 0.001)
        XCTAssertEqual(reloadedSkill.name, "Gitara")
        XCTAssertFalse(reloaded.isFavorite)
        XCTAssertTrue(reloaded.isObtained)
        XCTAssertEqual(reloaded.userRating, 2)
        XCTAssertEqual(reloaded.obtainedAt, obtained)
        XCTAssertEqual(reloaded.oneStarDescription, "Złóż raz.")

        reloaded.isFavorite = true
        try reading.save()

        let third = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)]
        )
        let again = ModelContext(third)
        let afterFavorite = try XCTUnwrap(try again.fetch(FetchDescriptor<ExemplarySkill>()).first { $0.id == exemplaryID })
        let hoursStill = try XCTUnwrap(try again.fetch(FetchDescriptor<Skill>()).first { $0.id == trackedID })
        XCTAssertTrue(afterFavorite.isFavorite)
        XCTAssertEqual(afterFavorite.obtainedAt, obtained)
        XCTAssertEqual(afterFavorite.userRating, 2)
        XCTAssertEqual(hoursStill.hours, 12.5, accuracy: 0.001)
    }

    /// Opens a store written before `isFavorite` existed. The fixture is a copy of a
    /// simulator database whose `ZEXEMPLARYSKILL` table has no favorite column.
    func testPreFavoriteStoreKeepsSeededRowsAndDefaultsFavoriteToFalse() throws {
        let fixture = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/pre-favorite.store")
        XCTAssertTrue(FileManager.default.fileExists(atPath: fixture.path))
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("t4s-old-store-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let storeURL = folder.appendingPathComponent("copied.store")
        try FileManager.default.copyItem(at: fixture, to: storeURL)

        let schema = Schema([Skill.self, ExemplarySkill.self, Counter.self, TimeIntervalEntry.self, TimeBudget.self])
        let container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)]
        )
        let reading = ModelContext(container)
        let catalog = try reading.fetch(FetchDescriptor<ExemplarySkill>())
        XCTAssertEqual(catalog.count, 38)
        XCTAssertTrue(catalog.allSatisfy { $0.isFavorite == false })
        XCTAssertTrue(catalog.allSatisfy { $0.isObtained == false })
        XCTAssertTrue(catalog.contains { $0.title == "Speed Listener" })

        let sample = try XCTUnwrap(catalog.first { $0.title == "Speed Listener" })
        let originalDescription = sample.skillDescription
        sample.isFavorite = true
        try reading.save()

        let reopened = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)]
        )
        let again = ModelContext(reopened)
        let kept = try again.fetch(FetchDescriptor<ExemplarySkill>())
        XCTAssertEqual(kept.count, 38)
        let favorite = try XCTUnwrap(kept.first { $0.title == "Speed Listener" })
        XCTAssertTrue(favorite.isFavorite)
        XCTAssertEqual(favorite.skillDescription, originalDescription)
        XCTAssertFalse(favorite.isObtained)
        XCTAssertEqual(try again.fetch(FetchDescriptor<Skill>()).count, 0)
        XCTAssertEqual(try again.fetch(FetchDescriptor<TimeBudget>()).count, 0)
    }

    func testCounterSymbolAndTimeBalanceDoNotChangeSkillHours() throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("t4s-balance-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let storeURL = folder.appendingPathComponent("isolated.store")
        let schema = Schema([Skill.self, ExemplarySkill.self, Counter.self, TimeIntervalEntry.self, TimeBudget.self])
        let container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)]
        )
        let context = ModelContext(container)
        let skill = Skill(name: "Gitara", hours: 12.5)
        let counter = Counter(title: "Powtórzenia", symbol: "🎯", value: 4, step: 1)
        let budget = TimeBudget(title: "Gra", symbol: "🎮", remainingSeconds: 600)
        context.insert(skill)
        context.insert(counter)
        context.insert(budget)
        try context.save()

        counter.symbol = "🎲"
        budget.add(minutes: 15)
        budget.toggle(at: Date(timeIntervalSince1970: 1_700_000_000))
        let later = Date(timeIntervalSince1970: 1_700_000_120)
        XCTAssertEqual(budget.remaining(at: later), 600 + 15 * 60 - 120)
        try context.save()

        let reopened = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)]
        )
        let reading = ModelContext(reopened)
        let keptSkill = try XCTUnwrap(try reading.fetch(FetchDescriptor<Skill>()).first)
        let keptCounter = try XCTUnwrap(try reading.fetch(FetchDescriptor<Counter>()).first)
        let keptBudget = try XCTUnwrap(try reading.fetch(FetchDescriptor<TimeBudget>()).first)
        XCTAssertEqual(keptSkill.hours, 12.5, accuracy: 0.001)
        XCTAssertEqual(keptCounter.value, 4)
        XCTAssertEqual(keptCounter.symbol, "🎲")
        XCTAssertEqual(keptBudget.remainingSeconds, 600 + 15 * 60)
        XCTAssertNotNil(keptBudget.activeStart)
    }

    func testTimeBalanceStopsAtZeroAndTheoryMarksUseTheProgressPalette() throws {
        let start = Date(timeIntervalSince1970: 1_000)
        XCTAssertEqual(TimeBalance.remaining(storedSeconds: 30, activeStart: start, now: start.addingTimeInterval(10)), 20)
        XCTAssertEqual(TimeBalance.remaining(storedSeconds: 30, activeStart: start, now: start.addingTimeInterval(90)), 0)
        XCTAssertEqual(TimeBalance.remaining(storedSeconds: 30, activeStart: nil, now: start), 30)

        XCTAssertEqual(TheoryCatalog.topic(id: "theory.tenthousand.popular")?.hourMark, 10_000)
        XCTAssertNil(TheoryCatalog.topic(id: "theory.kaufman.first20")?.hourMark)
        XCTAssertNil(TheoryCatalog.topic(id: "theory.lally.habit")?.hourMark)
        XCTAssertEqual(TheoryCatalog.milestones.map(\.hourMark), [21, 100, 1_000, 10_000])
        XCTAssertEqual(CrystalPalette.forHours(21), .sapphire)
        XCTAssertEqual(CrystalPalette.forHours(100), .amber)
        XCTAssertEqual(CrystalPalette.forHours(1_000), .arcane)
        XCTAssertEqual(CrystalPalette.forHours(10_000), .crimson)
        XCTAssertEqual(TheoryCatalog.chapters.map(\.hourMark), [21, 100, 1_000, 10_000])
        XCTAssertEqual(TheoryCatalog.chapters.map { CrystalPalette.forHours(Double($0.hourMark)) }, [.sapphire, .amber, .arcane, .crimson])
        for chapter in TheoryCatalog.chapters {
            XCTAssertFalse(chapter.leadKey.isEmpty)
            XCTAssertFalse(chapter.exampleKey.isEmpty)
            XCTAssertFalse(chapter.caveatKey.isEmpty)
            for topicID in chapter.sourceTopicIDs {
                let topic = try XCTUnwrap(TheoryCatalog.topic(id: topicID))
                XCTAssertFalse(topic.links.isEmpty)
                XCTAssertFalse(topic.citationKey.isEmpty)
            }
        }
        let below = ProgressFill.fraction(value: 20.9)
        let boundary = ProgressFill.fraction(value: 21)
        let above = ProgressFill.fraction(value: 22)
        XCTAssertEqual(ProgressFill.fraction(value: 0), 0, accuracy: 0.0001)
        XCTAssertEqual(ProgressFill.fraction(value: 100_000), 1, accuracy: 0.0001)
        XCTAssertLessThan(below, boundary)
        XCTAssertLessThan(boundary, above)
        XCTAssertLessThan(above - boundary, 0.05, "crossing 21 hours must not refill the track")
    }

    func testCounterRefreshUsesTheDateAndLeavesSkillHistoryAlone() throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("t4s-counter-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let storeURL = folder.appendingPathComponent("isolated.store")
        let schema = Schema([Skill.self, ExemplarySkill.self, Counter.self])
        let container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)]
        )
        let context = ModelContext(container)
        let obtained = Date(timeIntervalSince1970: 1_600_000_000)
        let skill = Skill(name: "Gitara", hours: 12.5)
        let exemplary = ExemplarySkill(
            catalogID: "seed-keep",
            title: "Zostaw",
            skillDescription: "Opis.",
            imageName: "star",
            category: "Dom",
            difficultyLevel: 2,
            isObtained: true
        )
        exemplary.obtainedAt = obtained
        exemplary.userRating = 3
        exemplary.isFavorite = true
        let manual = Counter(title: "Powtórzenia", value: 7, thresholds: [10, 20])
        let dated = Counter(title: "Dni", value: 99, thresholds: [10, 30])
        dated.kind = .elapsedDays
        context.insert(skill)
        context.insert(exemplary)
        context.insert(manual)
        context.insert(dated)
        try context.save()

        XCTAssertFalse(manual.refreshFromAnchor())
        XCTAssertEqual(manual.value, 7)
        XCTAssertFalse(dated.refreshFromAnchor())
        XCTAssertEqual(dated.value, 99)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let anchor = Date(timeIntervalSince1970: 1_700_000_000)
        dated.anchorDay = anchor
        let later = calendar.date(byAdding: .day, value: 4, to: calendar.startOfDay(for: anchor))!
        XCTAssertTrue(dated.refreshFromAnchor(now: later, calendar: calendar))
        XCTAssertEqual(dated.value, 4)
        XCTAssertTrue(dated.refreshFromAnchor(now: later, calendar: calendar))
        XCTAssertEqual(dated.value, 4)
        let earlier = calendar.date(byAdding: .day, value: -2, to: calendar.startOfDay(for: anchor))!
        XCTAssertTrue(dated.refreshFromAnchor(now: earlier, calendar: calendar))
        XCTAssertEqual(dated.value, -2)
        XCTAssertEqual(dated.barFraction, 0, accuracy: 0.0001)

        dated.value = 15
        let fuller = dated.barFraction
        dated.value = 5
        XCTAssertLessThan(dated.barFraction, fuller)

        XCTAssertEqual(skill.hours, 12.5, accuracy: 0.001)
        XCTAssertEqual(exemplary.obtainedAt, obtained)
        XCTAssertEqual(exemplary.userRating, 3)
        XCTAssertTrue(exemplary.isFavorite)
        XCTAssertTrue(exemplary.isObtained)
    }

    func testCatalogReconcileAddsRowsWithoutTouchingUserProgress() throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("t4s-seed-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let storeURL = folder.appendingPathComponent("isolated.store")
        let schema = Schema([ExemplarySkill.self, Skill.self])
        let container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)]
        )
        let context = ModelContext(container)
        let obtained = Date(timeIntervalSince1970: 1_650_000_000)
        let existing = ExemplarySkill(
            catalogID: "seed-a",
            title: "Stara nazwa",
            skillDescription: "Stary opis.",
            imageName: "a",
            category: "Dom",
            difficultyLevel: 2,
            userRating: 2,
            obtainedAt: obtained,
            isObtained: true,
            isFavorite: true
        )
        let custom = ExemplarySkill(
            isUserCreated: true,
            title: "Moja umiejętność",
            skillDescription: "Własny opis.",
            imageName: "b",
            category: "Inne",
            difficultyLevel: 4,
            isObtained: true
        )
        context.insert(existing)
        context.insert(custom)
        try context.save()

        let first = [
            SeedSkill(id: "seed-a", title: "Nowa nazwa", description: "Nowy opis.", imageName: "a2", category: "Dom", difficulty: 3)
        ]
        SkillSeeder.reconcile(first, in: context)
        let afterFirst = try context.fetch(FetchDescriptor<ExemplarySkill>())
        XCTAssertEqual(afterFirst.count, 2)
        let updated = try XCTUnwrap(afterFirst.first { $0.catalogID == "seed-a" })
        XCTAssertEqual(updated.title, "Nowa nazwa")
        XCTAssertEqual(updated.skillDescription, "Nowy opis.")
        XCTAssertTrue(updated.isObtained)
        XCTAssertTrue(updated.isFavorite)
        XCTAssertEqual(updated.userRating, 2)
        XCTAssertEqual(updated.obtainedAt, obtained)

        let second = first + [
            SeedSkill(id: "seed-b", title: "Dodana", description: "Nowa.", imageName: "c", category: "Ruch", difficulty: 1),
            SeedSkill(id: "seed-c", title: "Moja umiejętność", description: "Nie przejmuj.", imageName: "d", category: "Inne", difficulty: 1)
        ]
        SkillSeeder.reconcile(second, in: context)
        let afterSecond = try context.fetch(FetchDescriptor<ExemplarySkill>())
        XCTAssertEqual(afterSecond.filter { $0.catalogID == "seed-a" }.count, 1)
        XCTAssertEqual(afterSecond.filter { $0.catalogID == "seed-b" }.count, 1)
        let owned = try XCTUnwrap(afterSecond.first { $0.isUserCreated })
        XCTAssertNil(owned.catalogID)
        XCTAssertEqual(owned.skillDescription, "Własny opis.")
        XCTAssertTrue(owned.isObtained)
        let catalogCopy = try XCTUnwrap(afterSecond.first { $0.catalogID == "seed-c" })
        XCTAssertFalse(catalogCopy.isUserCreated)
        XCTAssertEqual(catalogCopy.skillDescription, "Nie przejmuj.")
        XCTAssertEqual(afterSecond.count, 4)
    }
}
