//
//  CatalogQueryTests.swift
//

import XCTest
@testable import Time4Skill

final class CatalogQueryTests: XCTestCase {
    private let polish = Locale(identifier: "pl")

    private func entry(
        _ title: String,
        description: String = "",
        levels: [String] = [],
        obtained: Bool = false,
        at: Date? = nil,
        favorite: Bool = false
    ) -> CatalogEntry {
        CatalogEntry(
            id: title,
            title: title,
            description: description,
            category: "Test",
            levelTexts: levels,
            isObtained: obtained,
            obtainedAt: at,
            isFavorite: favorite,
            rating: obtained ? 2 : 0,
            difficulty: 1
        )
    }

    func testFullNameAndFragment() {
        let items = [entry("Fold scrambled eggs off the heat")]
        let query = CatalogQuery(text: "Fold scrambled eggs off the heat")
        XCTAssertEqual(query.apply(items, locale: polish).map(\.title), ["Fold scrambled eggs off the heat"])
        let fragment = CatalogQuery(text: "scram")
        XCTAssertEqual(fragment.apply(items, locale: polish).count, 1)
    }

    func testDescriptionAndLevelCriterion() {
        let item = entry(
            "Leaf",
            description: "Cover a small leaf with diagonal stitches.",
            levels: ["Continue alternating edges until the leaf is covered."]
        )
        XCTAssertEqual(CatalogQuery(text: "diagonal").apply([item], locale: polish).count, 1)
        XCTAssertEqual(CatalogQuery(text: "alternating edges").apply([item], locale: polish).count, 1)
    }

    func testPolishFoldingAndCase() {
        let item = entry("Złóż serwetkę")
        XCTAssertEqual(CatalogQuery(text: "zloz").apply([item], locale: polish).count, 1)
        XCTAssertEqual(CatalogQuery(text: "SERWETKĘ").apply([item], locale: polish).count, 1)
        XCTAssertEqual(CatalogQuery(text: "ząb").apply([item], locale: polish).count, 0)
    }

    func testEmptyTextAndNoResults() {
        let items = [entry("Alpha"), entry("Beta")]
        XCTAssertEqual(CatalogQuery(text: "   ").apply(items, locale: polish).count, 2)
        XCTAssertTrue(CatalogQuery(text: "brak takiej rzeczy").apply(items, locale: polish).isEmpty)
    }

    func testCombinedFiltersAndNameOrder() {
        let early = Date(timeIntervalSince1970: 10)
        let later = Date(timeIntervalSince1970: 50)
        let items = [
            entry("Łuk", obtained: true, at: later, favorite: true),
            entry("Lampa", obtained: false, favorite: true),
            entry("Mama", obtained: true, at: early, favorite: false),
            entry("Ak", obtained: true, favorite: true)
        ]
        let query = CatalogQuery(text: "", completion: .notDone, favorites: .favorites, sort: .name)
        XCTAssertEqual(query.apply(items, locale: polish).map(\.title), ["Lampa"])

        let names = CatalogQuery(sort: .name).apply(items, locale: polish).map(\.title)
        XCTAssertEqual(names, ["Ak", "Lampa", "Łuk", "Mama"])
    }

    func testCompletionDatesKeepMissingDatesLast() {
        let early = Date(timeIntervalSince1970: 10)
        let later = Date(timeIntervalSince1970: 50)
        let items = [
            entry("Bez daty", obtained: true, at: nil),
            entry("Starsze", obtained: true, at: early),
            entry("Nowsze", obtained: true, at: later)
        ]
        let newest = CatalogQuery(sort: .obtainedNewest).apply(items, locale: polish).map(\.title)
        XCTAssertEqual(newest, ["Nowsze", "Starsze", "Bez daty"])
        let oldest = CatalogQuery(sort: .obtainedOldest).apply(items, locale: polish).map(\.title)
        XCTAssertEqual(oldest, ["Starsze", "Nowsze", "Bez daty"])
    }

    func testResetMeansDefaultQuery() {
        var query = CatalogQuery(text: "x", completion: .done, favorites: .favorites, sort: .obtainedNewest)
        XCTAssertFalse(query.isDefault)
        query = CatalogQuery()
        XCTAssertTrue(query.isDefault)
    }

    func testSearchFavoritesAndCompletionTogether() {
        let items = [
            entry("Złóż mapę", description: "Złóż arkusz wzdłuż zgięcia.", levels: ["Wygładź zgięcie."], obtained: true, favorite: true),
            entry("Złóż list", description: "Złóż kartkę na trzy.", obtained: false, favorite: true),
            entry("Inna", description: "Złóż arkusz.", obtained: true, favorite: false)
        ]
        let query = CatalogQuery(text: "zgiecia", completion: .done, favorites: .favorites, sort: .name)
        XCTAssertEqual(query.apply(items, locale: polish).map(\.title), ["Złóż mapę"])
    }

    func testFavoriteFlagDoesNotChangeCompletion() {
        var item = entry("Gitara", obtained: true, at: Date(timeIntervalSince1970: 20), favorite: false)
        let before = item.obtainedAt
        item.isFavorite = true
        XCTAssertEqual(item.obtainedAt, before)
        XCTAssertTrue(item.isObtained)
        XCTAssertEqual(item.rating, 2)
    }

    func testSeveralThousandEntriesStayResponsive() {
        let items = (0..<4000).map { index in
            entry("Umiejętność \(index)", description: "Opis poziomu \(index)", levels: ["Kryterium \(index)"])
        }
        let start = Date()
        let found = CatalogQuery(text: "umiejetnosc 3999").apply(items, locale: polish)
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertEqual(found.count, 1)
        XCTAssertLessThan(elapsed, 1.0)
    }

    func testCrystalPaletteFollowsHourStageNotAReward() {
        XCTAssertEqual(CrystalPalette.forHours(10), .emerald)
        XCTAssertEqual(CrystalPalette.forHours(50), .sapphire)
        XCTAssertEqual(CrystalPalette.forHours(500), .amber)
        XCTAssertEqual(CrystalPalette.forHours(5000), .arcane)
        XCTAssertEqual(CrystalPalette.forHours(20000), .crimson)
        XCTAssertNil(CrystalPalette.forHours(-1))
        XCTAssertNotEqual(CrystalPalette.forHours(10), .crimson)
    }

    func testAppPurposeDescribesTheLearningCollection() {
        let lines = [
            "ab_purpose_major_system",
            "ab_purpose_large_numbers",
            "ab_purpose_dates",
            "ab_purpose_words"
        ].map { NSLocalizedString($0, comment: "") }
        let text = lines.joined(separator: "\n")
        XCTAssertFalse(lines.contains(where: { $0.isEmpty || $0.hasPrefix("ab_purpose_") }))
        XCTAssertFalse(text.contains("20h"))
        XCTAssertFalse(text.contains("1000h"))
        XCTAssertFalse(text.localizedCaseInsensitiveContains("memory"))
        XCTAssertFalse(text.contains("pamięć"))
        let folded = text.folding(options: .diacriticInsensitive, locale: polish).lowercased()
        XCTAssertTrue(
            folded.contains("skill") || folded.contains("umiejetnosc") || folded.contains("umiejetnos")
        )
    }

    func testSidebarSelectionSurvivesOpeningTheSkillsSection() {
        var selection: MacSidebarSection? = .trackers
        selection = .skills
        XCTAssertEqual(selection, .skills)
        XCTAssertEqual(
            MacSidebarSection.allCases.map(\.rawValue),
            ["overview", "trackers", "counters", "statistics", "theory", "skills", "settings", "about"]
        )
        XCTAssertTrue(MacSidebarSection.primary.contains(.skills))
        XCTAssertTrue(MacSidebarSection.secondary.contains(.settings))
        XCTAssertTrue(MacSidebarSection.secondary.contains(.about))
        selection = .trackers
        XCTAssertEqual(selection, .trackers)
        selection = .settings
        XCTAssertEqual(selection, .settings)
    }
}
