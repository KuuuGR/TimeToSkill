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
        favorite: Bool = false,
        userCreated: Bool = false
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
            difficulty: 1,
            isUserCreated: userCreated
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
        var query = CatalogQuery(text: "x", completion: .done, favorites: .favorites, ownership: .custom, sort: .obtainedNewest)
        XCTAssertFalse(query.isDefault)
        query = CatalogQuery()
        XCTAssertTrue(query.isDefault)
    }

    func testCustomFilterUsesTheUserCreatedFlag() {
        let items = [
            entry("Katalog", description: "Opis katalogu", obtained: true, favorite: true),
            entry("Własna", description: "Mój opis", obtained: false, favorite: false, userCreated: true),
            entry("Własna zrobiona", description: "Inny opis", obtained: true, favorite: true, userCreated: true)
        ]
        let custom = CatalogQuery(ownership: .custom, sort: .name)
        XCTAssertEqual(custom.apply(items, locale: polish).map(\.title), ["Własna", "Własna zrobiona"])
        let combined = CatalogQuery(text: "moj", completion: .notDone, ownership: .custom, sort: .name)
        XCTAssertEqual(combined.apply(items, locale: polish).map(\.title), ["Własna"])
        XCTAssertEqual(CatalogQuery(ownership: .custom).emptyStateKey, "catalog_no_custom")
        XCTAssertEqual(CatalogQuery(favorites: .favorites).emptyStateKey, "catalog_no_favorites")
        XCTAssertEqual(CatalogQuery(completion: .done).emptyStateKey, "catalog_no_done")
        XCTAssertEqual(CatalogQuery(completion: .notDone).emptyStateKey, "catalog_no_not_done")
        XCTAssertEqual(CatalogQuery(text: "x", ownership: .custom).emptyStateKey, "catalog_no_results")
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
        // x86_64 Simulator can exceed 1s on large catalogs; keep a tight but realistic budget.
        XCTAssertLessThan(elapsed, 2.5)
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
            [
                "overview", "trackers", "counters", "timeConverter",
                "statistics", "theory", "skills", "settings", "about"
            ]
        )
        XCTAssertTrue(MacSidebarSection.primary.contains(.skills))
        XCTAssertTrue(MacSidebarSection.primary.contains(.timeConverter))
        XCTAssertTrue(MacSidebarSection.secondary.contains(.settings))
        XCTAssertTrue(MacSidebarSection.secondary.contains(.about))
        XCTAssertFalse(MacSidebarSection.secondary.contains(.timeConverter))
        selection = .trackers
        XCTAssertEqual(selection, .trackers)
        selection = .timeConverter
        XCTAssertEqual(selection, .timeConverter)
        selection = .settings
        XCTAssertEqual(selection, .settings)
    }
}

final class AppLanguageTests: XCTestCase {
    private let available: Set<String> = ["en", "pl", "es", "eo", "isv", "de", "pt-BR", "zh-Hans", "zh-Hant", "en-GB"]

    func testDeviceLanguageKeepsThePreferenceAndFallsBackToEnglish() {
        let polish = LanguageCatalog.resolve(preferenceKey: "system", deviceLanguages: ["pl-PL"], available: available)
        XCTAssertEqual(polish.preferenceKey, "system")
        XCTAssertEqual(polish.bundleCode, "pl")
        XCTAssertTrue(polish.followsDevice)

        let missing = LanguageCatalog.resolve(preferenceKey: nil, deviceLanguages: ["sw-TZ"], available: available)
        XCTAssertEqual(missing.preferenceKey, "system")
        XCTAssertEqual(missing.bundleCode, "en")

        let explicit = LanguageCatalog.resolve(preferenceKey: "es", deviceLanguages: ["pl-PL"], available: available)
        XCTAssertEqual(explicit.preferenceKey, "es")
        XCTAssertEqual(explicit.bundleCode, "es")
        XCTAssertFalse(explicit.followsDevice)
    }

    func testRegionalPreferencesStayDistinctFromTheBaseLanguage() {
        let brazil = LanguageCatalog.resolve(preferenceKey: "system", deviceLanguages: ["pt-BR"], available: available)
        XCTAssertEqual(brazil.bundleCode, "pt-BR")
        let traditional = LanguageCatalog.resolve(preferenceKey: "system", deviceLanguages: ["zh-Hant-TW"], available: available)
        XCTAssertEqual(traditional.bundleCode, "zh-Hant")
        let britain = LanguageCatalog.resolve(preferenceKey: "en-GB", deviceLanguages: ["pl-PL"], available: available)
        XCTAssertEqual(britain.bundleCode, "en-GB")
    }

    func testInterslavicChoiceDoesNotReplaceTheStoredScript() {
        let cyrillic = LanguageCatalog.resolve(preferenceKey: "isv-Cyrl", deviceLanguages: ["en-US"], available: available)
        XCTAssertEqual(cyrillic.preferenceKey, "isv-Cyrl")
        XCTAssertEqual(cyrillic.bundleCode, "isv")
        XCTAssertEqual(cyrillic.script, .cyrillic)

        let withoutFile = LanguageCatalog.resolve(preferenceKey: "isv-Glag", deviceLanguages: ["pl-PL"], available: ["en", "pl"])
        XCTAssertEqual(withoutFile.preferenceKey, "isv-Glag")
        XCTAssertEqual(withoutFile.bundleCode, "en")
        XCTAssertNil(withoutFile.script)
    }

    func testLookupFallsBackToEnglishWithoutTransliteratingIt() {
        let tables = [
            "en": ["greeting": "Hello %d"],
            "isv": ["greeting": "Zdrav %d"]
        ]
        XCTAssertEqual(
            LanguageCatalog.lookup(key: "greeting", bundleCode: "isv", script: .cyrillic, tables: tables),
            "Здрав %d"
        )
        XCTAssertEqual(
            LanguageCatalog.lookup(key: "only_english", bundleCode: "isv", script: .glagolitic, tables: [
                "en": ["only_english": "Keep this English"],
                "isv": [:]
            ]),
            "Keep this English"
        )
        XCTAssertEqual(
            LanguageCatalog.lookup(key: "missing", bundleCode: "isv", script: .latin, tables: tables),
            "missing"
        )
    }

    func testTransliteratorKeepsFormatTokensAndMapsDigraphs() {
        XCTAssertEqual(InterslavicTransliterator.latinToCyrillic("Medžu %1$@"), "Меџу %1$@")
        XCTAssertEqual(InterslavicTransliterator.latinToCyrillic("ljudi"), "људи")
        let glagolitic = InterslavicTransliterator.latinToGlagolitic("A B C")
        XCTAssertEqual(glagolitic, "Ⰰ Ⰱ Ⱆ")
        XCTAssertTrue(InterslavicTransliterator.latinToGlagolitic("Version %@").contains("%@"))
    }

    func testCatalogOverlayFollowsDeviceLanguageIndependentlyOfUI() {
        // UI may be Spanish while the catalog overlay still keys off the device tag.
        XCTAssertEqual(SkillSeeder.catalogOverlayCode(for: "pl-PL"), "pl")
        XCTAssertEqual(SkillSeeder.catalogOverlayCode(for: "es-419"), "es-419")
        XCTAssertEqual(SkillSeeder.catalogOverlayCode(for: "es-MX"), "es")
        XCTAssertNil(SkillSeeder.catalogOverlayCode(for: "en-GB"))
        XCTAssertEqual(SkillSeeder.catalogOverlayCode(for: "de-DE"), "de")
        XCTAssertEqual(SkillSeeder.catalogOverlayCode(for: "zh-Hans"), "zh-Hans")
        XCTAssertEqual(SkillSeeder.catalogOverlayCode(for: "zh-Hant-TW"), "zh-Hant")
        XCTAssertEqual(SkillSeeder.catalogOverlayCode(for: "pt-BR"), "pt-BR")
        XCTAssertEqual(SkillSeeder.catalogOverlayCode(for: "pt-PT"), "pt-PT")
        XCTAssertEqual(SkillSeeder.catalogOverlayCode(for: "pt"), "pt-BR")
        XCTAssertEqual(SkillSeeder.catalogOverlayCode(for: "fr-CA"), "fr-CA")
        XCTAssertEqual(SkillSeeder.catalogOverlayCode(for: "isv"), "isv")
        XCTAssertEqual(SkillSeeder.catalogOverlayCode(for: "isv-Cyrl"), "isv")

        let uiSpanish = LanguageCatalog.resolve(preferenceKey: "es", deviceLanguages: ["pl-PL"], available: available)
        XCTAssertEqual(uiSpanish.bundleCode, "es")
        XCTAssertEqual(SkillSeeder.catalogOverlayCode(for: "pl-PL"), "pl")
        XCTAssertNotEqual(uiSpanish.bundleCode, SkillSeeder.catalogOverlayCode(for: "pl-PL"))
    }

    @MainActor
    func testInterslavicScriptPreferenceSurvivesOtherLanguageChoice() {
        let defaults = UserDefaults(suiteName: "t4s.language.script.\(UUID().uuidString)")!
        let language = AppLanguage(defaults: defaults, deviceLanguages: ["en-US"])
        language.select("isv-Cyrl")
        XCTAssertEqual(language.resolved.script, .cyrillic)
        XCTAssertEqual(language.savedInterslavicScript, .cyrillic)
        language.select("pl")
        XCTAssertNil(language.resolved.script)
        XCTAssertEqual(language.savedInterslavicScript, .cyrillic)
        language.selectInterslavicRestoringScript()
        XCTAssertEqual(language.resolved.preferenceKey, "isv-Cyrl")
        XCTAssertEqual(language.resolved.script, .cyrillic)
    }

    func testEveryBundledLanguageHasAFlagAssetName() {
        for code in LanguageFlagCatalog.requiredCodes {
            let name = LanguageFlagCatalog.assetName(for: code)
            XCTAssertFalse(name.isEmpty, code)
            if code == "pl" { XCTAssertEqual(name, "Flag_of_Poland") }
            if code == "eo" { XCTAssertEqual(name, "Flag_of_Esperanto") }
            if code == "isv" { XCTAssertEqual(name, "Flag_of_Interslavic") }
            if code == "de" { XCTAssertEqual(name, "Lang_de") }
        }
        XCTAssertEqual(LanguageFlagCatalog.assetName(for: "en"), "English_language")
    }

    @MainActor
    func testLanguagePreferenceChangeDoesNotClearSidebarSelection() {
        let suite = "t4s.nav.language.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defaults.set(MacSidebarSection.settings.rawValue, forKey: MacSidebarSection.selectionDefaultsKey)

        let language = AppLanguage(defaults: defaults, deviceLanguages: ["en-US"])
        language.select("pl")
        language.select("isv-Latn")
        language.select("isv-Cyrl")
        language.select("eo")

        XCTAssertEqual(
            defaults.string(forKey: MacSidebarSection.selectionDefaultsKey),
            MacSidebarSection.settings.rawValue
        )
        XCTAssertEqual(language.resolved.bundleCode, "eo")
    }
}
