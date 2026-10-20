import XCTest
@testable import Time4Skill

final class InterslavicScriptTests: XCTestCase {

    func testCyrillicConvertsDigraphsDiacriticsAndNasalE() {
        XCTAssertEqual(InterslavicTransliterator.latinToCyrillic("medžuslovjansky"), "меџусловјанскы")
        XCTAssertEqual(InterslavicTransliterator.latinToCyrillic("Prěgled"), "Прєглед")
        XCTAssertEqual(InterslavicTransliterator.latinToCyrillic("język"), "язык")
        XCTAssertEqual(InterslavicTransliterator.latinToCyrillic("ljudi"), "људи")
        XCTAssertEqual(InterslavicTransliterator.latinToCyrillic("njuh"), "њух")
        XCTAssertEqual(InterslavicTransliterator.latinToCyrillic("ćudo"), "ћудо")
    }

    func testGlagoliticConvertsLettersAndUsesNotoCompatibleCodepoints() {
        XCTAssertEqual(InterslavicTransliterator.latinToGlagolitic("Prěgled"), "Ⰿⱀⱑⰳⰻⰵⰴ")
        XCTAssertEqual(InterslavicTransliterator.latinToGlagolitic("język"), "ⱔⰷⱑⰺ")
        let converted = InterslavicTransliterator.latinToGlagolitic("čas 12")
        XCTAssertTrue(converted.unicodeScalars.filter(\.properties.isAlphabetic).allSatisfy {
            (0x2C00...0x2C5F).contains($0.value)
        })
        XCTAssertTrue(converted.contains("12"))
    }

    func testPlaceholdersNumbersAndPunctuationSurviveConversion() {
        let sample = "Saldo: %d / %@ (%1$@–%2$@) · 12!"
        XCTAssertEqual(InterslavicTransliterator.latinToCyrillic(sample), "Салдо: %d / %@ (%1$@–%2$@) · 12!")
        XCTAssertTrue(InterslavicTransliterator.latinToGlagolitic(sample).contains("%d"))
        XCTAssertTrue(InterslavicTransliterator.latinToGlagolitic(sample).contains("%1$@"))
        XCTAssertTrue(InterslavicTransliterator.latinToGlagolitic(sample).contains("12"))
        XCTAssertEqual(InterslavicTransliterator.latinToCyrillic(""), "")
        XCTAssertEqual(InterslavicTransliterator.latinToGlagolitic(""), "")
    }

    func testDoubleConversionIsAvoided() {
        let once = InterslavicTransliterator.latinToCyrillic("Prěgled")
        XCTAssertTrue(InterslavicTransliterator.appearsConverted(to: .cyrillic, text: once))
        let lookedUp = LanguageCatalog.lookup(
            key: "k",
            bundleCode: "isv",
            script: .cyrillic,
            tables: ["isv": ["k": once], "en": [:]]
        )
        XCTAssertEqual(lookedUp, once)

        let glag = InterslavicTransliterator.latinToGlagolitic("čas")
        XCTAssertTrue(InterslavicTransliterator.appearsConverted(to: .glagolitic, text: glag))
        XCTAssertEqual(
            LanguageCatalog.lookup(
                key: "k",
                bundleCode: "isv",
                script: .glagolitic,
                tables: ["isv": ["k": glag], "en": [:]]
            ),
            glag
        )
    }

    func testScriptChoiceDoesNotChangeLatinSourceBundle() {
        let latin = LanguageCatalog.resolve(
            preferenceKey: "isv-Latn",
            deviceLanguages: ["en"],
            available: ["en", "isv"]
        )
        let cyrillic = LanguageCatalog.resolve(
            preferenceKey: "isv-Cyrl",
            deviceLanguages: ["en"],
            available: ["en", "isv"]
        )
        let glagolitic = LanguageCatalog.resolve(
            preferenceKey: "isv-Glag",
            deviceLanguages: ["en"],
            available: ["en", "isv"]
        )
        XCTAssertEqual(latin.bundleCode, "isv")
        XCTAssertEqual(cyrillic.bundleCode, "isv")
        XCTAssertEqual(glagolitic.bundleCode, "isv")
        XCTAssertEqual(latin.script, .latin)
        XCTAssertEqual(cyrillic.script, .cyrillic)
        XCTAssertEqual(glagolitic.script, .glagolitic)
    }

    @MainActor
    func testScriptPreferenceSurvivesRelaunchAndDoesNotClearSidebar() {
        let suite = "t4s.isv.script.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defaults.set(MacSidebarSection.settings.rawValue, forKey: MacSidebarSection.selectionDefaultsKey)

        let first = AppLanguage(defaults: defaults, deviceLanguages: ["en-US"])
        first.select("isv-Glag")
        XCTAssertEqual(first.resolved.script, .glagolitic)
        XCTAssertEqual(first.savedInterslavicScript, .glagolitic)

        let relaunched = AppLanguage(defaults: defaults, deviceLanguages: ["en-US"])
        XCTAssertEqual(relaunched.resolved.preferenceKey, "isv-Glag")
        XCTAssertEqual(relaunched.resolved.script, .glagolitic)
        XCTAssertEqual(
            defaults.string(forKey: MacSidebarSection.selectionDefaultsKey),
            MacSidebarSection.settings.rawValue
        )

        relaunched.select("pl")
        XCTAssertNil(relaunched.resolved.script)
        XCTAssertEqual(relaunched.savedInterslavicScript, .glagolitic)
        XCTAssertEqual(
            defaults.string(forKey: MacSidebarSection.selectionDefaultsKey),
            MacSidebarSection.settings.rawValue
        )
    }

    func testCatalogOverlayStaysIndependentOfInterslavicUI() {
        XCTAssertEqual(SkillSeeder.catalogOverlayCode(for: "pl-PL"), "pl")
        let ui = LanguageCatalog.resolve(
            preferenceKey: "isv-Cyrl",
            deviceLanguages: ["pl-PL"],
            available: ["en", "pl", "isv"]
        )
        XCTAssertEqual(ui.bundleCode, "isv")
        XCTAssertNotEqual(ui.bundleCode, SkillSeeder.catalogOverlayCode(for: "pl-PL"))
    }

    func testMenuKeysHaveInterslavicLatinSourceAndTransliterate() throws {
        let isv = try Self.loadLocalizable(locale: "isv")
        let menuKeys = [
            "sidebar_overview",
            "main_manage_trackers",
            "main_manage_counters",
            "time_converter_nav_title",
            "stats_nav_title",
            "theory_nav_title",
            "exemplary_skills_title",
            "options_title",
            "ab_navigation_title",
            "button_done",
            "session_chart_detail_wide",
            "session_chart_detail_medium",
            "session_chart_detail_narrow",
            "session_chart_bin_width"
        ]
        for key in menuKeys {
            let latin = try XCTUnwrap(isv[key]?.trimmingCharacters(in: .whitespacesAndNewlines))
            XCTAssertFalse(latin.isEmpty, key)
            XCTAssertNotEqual(latin, key, "Key leaked as label: \(key)")
            // Must not leave English control labels for chart density.
            if key.hasPrefix("session_chart_detail_") || key == "session_chart_bin_width" {
                XCTAssertFalse(["Wide", "Medium", "Narrow", "Bar width"].contains(latin), key)
            }

            let cyrillic = LanguageCatalog.lookup(
                key: key,
                bundleCode: "isv",
                script: .cyrillic,
                tables: ["isv": isv, "en": [:]]
            )
            let glagolitic = LanguageCatalog.lookup(
                key: key,
                bundleCode: "isv",
                script: .glagolitic,
                tables: ["isv": isv, "en": [:]]
            )
            XCTAssertTrue(
                InterslavicTransliterator.appearsConverted(to: .cyrillic, text: cyrillic)
                    || cyrillic == InterslavicTransliterator.latinToCyrillic(latin),
                "\(key) cyrillic"
            )
            XCTAssertEqual(cyrillic, InterslavicTransliterator.latinToCyrillic(latin))
            XCTAssertEqual(glagolitic, InterslavicTransliterator.latinToGlagolitic(latin))
            // No double conversion.
            XCTAssertEqual(
                LanguageCatalog.lookup(
                    key: key,
                    bundleCode: "isv",
                    script: .cyrillic,
                    tables: ["isv": [key: cyrillic], "en": [:]]
                ),
                cyrillic
            )
        }
    }

    @MainActor
    func testPresentationCacheInvalidatesWhenScriptChanges() {
        let suite = "t4s.isv.cache.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let language = AppLanguage(defaults: defaults, deviceLanguages: ["en-US"])
        language.select("isv-Latn")
        let latin = LanguageState.shared.string("sidebar_overview")
        language.select("isv-Cyrl")
        let cyrillic = LanguageState.shared.string("sidebar_overview")
        XCTAssertNotEqual(latin, cyrillic)
        XCTAssertEqual(cyrillic, InterslavicTransliterator.latinToCyrillic(latin))
        language.select("isv-Glag")
        let glagolitic = LanguageState.shared.string("sidebar_overview")
        XCTAssertEqual(glagolitic, InterslavicTransliterator.latinToGlagolitic(latin))
    }

    private static func loadLocalizable(locale: String) throws -> [String: String] {
        let table = LanguageCatalog.loadStringsTable(named: "Localizable", locale: locale)
        XCTAssertFalse(table.isEmpty, "Missing Localizable for \(locale)")
        return table
    }
}
