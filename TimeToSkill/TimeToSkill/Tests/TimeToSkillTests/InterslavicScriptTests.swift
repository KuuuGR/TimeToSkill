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
        // Foreign leftovers that used to survive as Latin glyphs
        XCTAssertEqual(InterslavicTransliterator.latinToCyrillic("Gladwell"), "Гладвелл")
        XCTAssertEqual(InterslavicTransliterator.latinToCyrillic("Eksel"), "Ексел")
        XCTAssertEqual(InterslavicTransliterator.latinToCyrillic("Wixted"), "Викстед")
        XCTAssertEqual(InterslavicTransliterator.latinToCyrillic("Römer"), "Ромер")
        XCTAssertEqual(InterslavicTransliterator.latinToCyrillic("prazdnotu"), "праздноту")
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
        // Locale id must stay `isv` (logical code); strings load from Interslavic/, not isv.lproj.
        XCTAssertEqual(latin.localeIdentifier, "isv")
        XCTAssertEqual(cyrillic.localeIdentifier, "isv")
        XCTAssertEqual(glagolitic.localeIdentifier, "isv")
        XCTAssertNotEqual(latin.presentationIdentity, glagolitic.presentationIdentity)
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
            "tracking_nav_title",
            "tracking_title",
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

    func testAllInterslavicUIKeysTransliterateToGlagolitic() throws {
        try assertAllInterslavicUIKeysTransliterate(to: .glagolitic)
    }

    func testAllInterslavicUIKeysTransliterateToCyrillic() throws {
        try assertAllInterslavicUIKeysTransliterate(to: .cyrillic)
    }

    func testTimePerspectiveChromeAndFactsTransliterateToCyrillic() throws {
        let isv = LanguageCatalog.loadStringsTable(named: "TimePerspective", locale: "isv")
        XCTAssertFalse(isv.isEmpty)
        let sampleKeys = [
            "time_perspective.card.title",
            "time_perspective.card.empty_tagline",
            "time_perspective.card.empty_prompt",
            "perspective.coffee_break.title",
            "perspective.coffee_break.description"
        ]
        for key in sampleKeys {
            let latin = try XCTUnwrap(isv[key])
            let cyrillic = LanguageCatalog.lookup(
                key: key,
                bundleCode: "isv",
                script: .cyrillic,
                tables: ["isv": isv, "en": [:]]
            )
            XCTAssertEqual(cyrillic, InterslavicTransliterator.latinToCyrillic(latin), key)
            XCTAssertTrue(
                InterslavicTransliterator.appearsConverted(to: .cyrillic, text: cyrillic)
                    || cyrillic == InterslavicTransliterator.latinToCyrillic(latin),
                key
            )
            // Must not accidentally stay on Glagolitic when Cyrilica is selected.
            XCTAssertFalse(
                InterslavicTransliterator.appearsConverted(to: .glagolitic, text: cyrillic),
                "Mixed Glagolitic into Cyrilica for \(key)"
            )
        }
    }

    func testScriptSwitchDoesNotMixAlphabets() {
        let latin = "Prěgled vremene"
        let cyrillic = InterslavicTransliterator.latinToCyrillic(latin)
        let glagolitic = InterslavicTransliterator.latinToGlagolitic(latin)
        XCTAssertTrue(InterslavicTransliterator.appearsConverted(to: .cyrillic, text: cyrillic))
        XCTAssertTrue(InterslavicTransliterator.appearsConverted(to: .glagolitic, text: glagolitic))
        XCTAssertFalse(InterslavicTransliterator.appearsConverted(to: .glagolitic, text: cyrillic))
        XCTAssertFalse(InterslavicTransliterator.appearsConverted(to: .cyrillic, text: glagolitic))
        XCTAssertEqual(InterslavicTransliterator.latinToCyrillic(cyrillic), cyrillic)
        XCTAssertEqual(InterslavicTransliterator.latinToGlagolitic(glagolitic), glagolitic)
    }

    private func assertAllInterslavicUIKeysTransliterate(to script: InterslavicScript) throws {
        let isv = try Self.loadLocalizable(locale: "isv")
        var converted = 0
        var skippedBrandOrSymbol = 0
        for (key, latin) in isv {
            let trimmed = latin.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                XCTFail("Empty isv value for \(key)")
                continue
            }
            let convertedText = LanguageCatalog.lookup(
                key: key,
                bundleCode: "isv",
                script: script,
                tables: ["isv": isv, "en": [:]]
            )
            if latin.contains("%") {
                let tokens = ["%d", "%@", "%1$@", "%2$@", "%lld"]
                for token in tokens where latin.contains(token) {
                    XCTAssertTrue(convertedText.contains(token), "\(key) lost \(token) under \(script)")
                }
            }
            let latinLetters = trimmed.unicodeScalars.filter { CharacterSet.letters.contains($0) }
            guard !latinLetters.isEmpty else {
                skippedBrandOrSymbol += 1
                continue
            }
            let allowLatinPassthrough = key.hasPrefix("ab_") || key.contains("email") || key == "theory_link_pubmed"
            if allowLatinPassthrough {
                skippedBrandOrSymbol += 1
                continue
            }
            let expected: String
            switch script {
            case .latin: expected = latin
            case .cyrillic: expected = InterslavicTransliterator.latinToCyrillic(latin)
            case .glagolitic: expected = InterslavicTransliterator.latinToGlagolitic(latin)
            }
            XCTAssertTrue(
                InterslavicTransliterator.appearsConverted(to: script, text: convertedText)
                    || convertedText == expected,
                "UI key \(key) not \(script) after conversion: \(convertedText)"
            )
            XCTAssertEqual(convertedText, expected, key)
            converted += 1
        }
        XCTAssertGreaterThan(converted, 100, "Expected a broad UI key set to convert to \(script)")
        _ = skippedBrandOrSymbol
    }

    private static func loadLocalizable(locale: String) throws -> [String: String] {
        let table = LanguageCatalog.loadStringsTable(named: "Localizable", locale: locale)
        XCTAssertFalse(table.isEmpty, "Missing Localizable for \(locale)")
        return table
    }
}
