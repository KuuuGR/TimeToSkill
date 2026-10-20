import XCTest
@testable import Time4Skill

/// Validates Localizable / TimePerspective tables for every bundled UI language.
final class LocalizationCompletenessTests: XCTestCase {

    func testEveryLocalizableTableMatchesEnglishKeySet() throws {
        let english = try Self.loadBundledStrings(table: "Localizable", locale: "en")
        XCTAssertFalse(english.isEmpty, "English Localizable.strings is empty in the app bundle")

        let locales = Self.bundledLocales(containing: "Localizable")
        XCTAssertGreaterThanOrEqual(locales.count, 40, "Expected a full set of UI languages")

        var report: [String] = []
        for code in locales.sorted() {
            let table = try Self.loadBundledStrings(table: "Localizable", locale: code)
            let missing = Set(english.keys).subtracting(table.keys).sorted()
            let empty = table
                .filter { $0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .map(\.key)
                .sorted()
            if !missing.isEmpty || !empty.isEmpty {
                report.append("\(code): missing=\(missing.count) empty=\(empty.count)")
                if !missing.isEmpty {
                    report.append("  missing sample: \(missing.prefix(8).joined(separator: ", "))")
                }
            }
        }
        XCTAssertTrue(report.isEmpty, report.joined(separator: "\n"))
    }

    func testRequiredNavigationAndConverterKeysExistInEveryLanguage() throws {
        let required = [
            "time_converter_nav_title",
            "Time_Converter_Section_Header",
            "Time_Converter_Calculate_Button",
            "stats_recent_tracking",
            "stats_this_week",
            "stats_this_month",
            "sidebar_overview",
            "options_title",
            "language_device",
            "language_name_interslavic",
            "language_script_latin",
            "language_script_cyrillic",
            "language_script_glagolitic",
            "export_pdf_generated_on_format",
            "main_manage_trackers",
            "main_manage_counters",
            "tracking_nav_title",
            "tracking_title",
            "exemplary_skills_title",
            "stats_nav_title",
            "theory_nav_title",
            "ab_navigation_title",
            "button_done",
            "session_chart_detail_wide",
            "session_chart_detail_medium",
            "session_chart_detail_narrow",
            "session_chart_bin_width",
            "session_chart_metric"
        ]
        for code in Self.bundledLocales(containing: "Localizable").sorted() {
            let table = try Self.loadBundledStrings(table: "Localizable", locale: code)
            for key in required {
                let value = table[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                XCTAssertFalse(value.isEmpty, "\(code) missing/empty \(key)")
                XCTAssertNotEqual(value, key, "\(code) uses key as text for \(key)")
            }
        }

        let isv = try Self.loadBundledStrings(table: "Localizable", locale: "isv")
        for key in ["session_chart_detail_wide", "session_chart_detail_medium", "session_chart_detail_narrow", "session_chart_bin_width"] {
            let value = isv[key] ?? ""
            XCTAssertFalse(["Wide", "Medium", "Narrow", "Bar width"].contains(value), "isv still English for \(key)")
        }
    }

    func testTimePerspectiveCatalogCoversLibraryIDs() throws {
        let library = try TimePerspectiveLoader.loadLibrary()
        XCTAssertEqual(library.count, 63)
        let ids = Set(library.map(\.id))

        let english = try Self.loadBundledStrings(table: "TimePerspective", locale: "en")
        for id in ids.sorted() {
            for suffix in ["title", "description"] {
                let key = "perspective.\(id).\(suffix)"
                let value = english[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                XCTAssertFalse(value.isEmpty, "Missing/empty English \(key)")
            }
        }
        for cardKey in [
            "time_perspective.card.title",
            "time_perspective.card.empty_tagline",
            "time_perspective.card.empty_prompt"
        ] {
            XCTAssertFalse(
                (english[cardKey] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                cardKey
            )
        }
    }

    func testTimePerspectiveLocalesAreCompleteExceptDocumentedGaps() throws {
        let english = try Self.loadBundledStrings(table: "TimePerspective", locale: "en")
        let keys = english.keys.sorted()
        XCTAssertEqual(keys.count, 129)

        let expectedFull = Self.bundledLocales(containing: "TimePerspective")
        XCTAssertTrue(expectedFull.contains("eo"), "Esperanto Time Perspective column missing from bundle")
        XCTAssertTrue(expectedFull.contains("isv"), "Interslavic Time Perspective Latinica column missing")

        var incomplete: [String] = []
        for locale in expectedFull.sorted() {
            let table = try Self.loadBundledStrings(table: "TimePerspective", locale: locale)
            let missing = keys.filter { key in
                (table[key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            if !missing.isEmpty {
                incomplete.append(
                    "\(locale): \(missing.count) missing (e.g. \(missing.prefix(3).joined(separator: ", ")))"
                )
            }
        }
        XCTAssertTrue(incomplete.isEmpty, incomplete.joined(separator: "\n"))
    }

    func testInterslavicScriptLookupDoesNotTransliterateEnglishFallback() throws {
        let english = try Self.loadBundledStrings(table: "TimePerspective", locale: "en")
        XCTAssertFalse(english.isEmpty)

        // When an Interslavic key is absent, English is returned without Cyrillic/Glagolitic mapping.
        let fallback = LanguageCatalog.lookup(
            key: "perspective.coffee_break.title",
            bundleCode: "isv",
            script: .cyrillic,
            tables: ["isv": [:], "en": english]
        )
        XCTAssertEqual(fallback, english["perspective.coffee_break.title"])
        XCTAssertEqual(fallback, "Coffee Break")
    }

    func testInterslavicUIAndPerspectivesAreTranslatedInLatinica() throws {
        let localizable = try Self.loadBundledStrings(table: "Localizable", locale: "isv")
        let english = try Self.loadBundledStrings(table: "Localizable", locale: "en")
        XCTAssertEqual(Set(localizable.keys), Set(english.keys))

        let mustDiffer = [
            "time_balance_bar",
            "time_balance_zero_sound",
            "time_converter_nav_title",
            "options_title",
            "language_device"
        ]
        for key in mustDiffer {
            XCTAssertNotEqual(localizable[key], english[key], key)
            XCTAssertFalse((localizable[key] ?? "").isEmpty, key)
        }

        let perspectives = try Self.loadBundledStrings(table: "TimePerspective", locale: "isv")
        XCTAssertEqual(perspectives.count, 129)
        XCTAssertEqual(perspectives["perspective.coffee_break.title"], "Pauza na kavu")
        // Source of truth is Latinica — no Cyrillic/Glagolitic stored in resources.
        for (key, value) in perspectives {
            XCTAssertFalse(
                value.unicodeScalars.contains { (0x0400...0x04FF).contains($0.value) },
                "Cyrillic stored in isv resource for \(key)"
            )
            XCTAssertFalse(
                value.unicodeScalars.contains { (0x2C00...0x2C5F).contains($0.value) },
                "Glagolitic stored in isv resource for \(key)"
            )
        }
    }

    func testSidebarExposesTimeConverterOutsideOptions() {
        XCTAssertTrue(MacSidebarSection.primary.contains(.timeConverter))
        XCTAssertFalse(MacSidebarSection.secondary.contains(.timeConverter))
        XCTAssertEqual(MacSidebarSection.timeConverter.systemImage, "arrow.left.arrow.right")
        XCTAssertEqual(MacSidebarSection.timeConverter.rawValue, "timeConverter")
#if !os(macOS)
        XCTAssertEqual(HomeSection.timeConverter.rawValue, "timeConverter")
        XCTAssertEqual(HomeSection.timeConverter.systemImage, "arrow.left.arrow.right")
#endif
    }

    func testTheoryCompendiumKeysDifferFromEnglishWhereRequired() throws {
        let english = try Self.loadBundledStrings(table: "Localizable", locale: "en")
        let mustDiffer = TheoryCatalog.chapters.flatMap { chapter in
            [
                chapter.titleKey, chapter.leadKey, chapter.mechanismTitleKey, chapter.mechanismKey,
                chapter.exampleKey, chapter.caveatKey, chapter.takeawayKey
            ]
        } + [
            "theory_compendium_intro",
            "theory_callout_example",
            "theory_callout_caveat",
            "theory_callout_takeaway",
            "theory_hour_unit",
            "theory_detail_links",
            "time_converter_nav_title",
            "Time_Converter_Section_Header",
            "tracking_nav_title",
            "tracking_title"
        ]

        let englishVariants: Set<String> = ["en", "en-GB", "en-AU", "en-CA", "en-IN"]
        var leftovers: [String] = []
        for code in Self.bundledLocales(containing: "Localizable").sorted() where !englishVariants.contains(code) {
            let table = try Self.loadBundledStrings(table: "Localizable", locale: code)
            for key in mustDiffer {
                let value = (table[key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let englishValue = (english[key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                if value.isEmpty || value == key {
                    leftovers.append("\(code): empty/raw \(key)")
                } else if value == englishValue {
                    leftovers.append("\(code): still English \(key)")
                }
            }
        }
        XCTAssertTrue(leftovers.isEmpty, leftovers.prefix(40).joined(separator: "\n"))
    }

    func testTimePerspectiveCardChromeIsNotPolishFallbackElsewhere() throws {
        let polish = try Self.loadBundledStrings(table: "TimePerspective", locale: "pl")
        let english = try Self.loadBundledStrings(table: "TimePerspective", locale: "en")
        let chrome = [
            "time_perspective.card.title",
            "time_perspective.card.empty_tagline",
            "time_perspective.card.empty_prompt"
        ]
        for code in ["de", "fr", "isv", "eo", "es", "ja"].sorted() {
            let table = try Self.loadBundledStrings(table: "TimePerspective", locale: code)
            for key in chrome {
                let value = table[key] ?? ""
                XCTAssertFalse(value.isEmpty, "\(code) \(key)")
                XCTAssertNotEqual(value, key, "\(code) \(key)")
                // Non-Polish locales must not silently reuse Polish chrome.
                if code != "pl" {
                    XCTAssertNotEqual(value, polish[key], "\(code) reused Polish for \(key)")
                }
                if code == "isv" {
                    XCTAssertNotEqual(value, english[key], "isv still English for \(key)")
                }
            }
        }
    }

    func testTheoryTopicBodiesPresentForPrimaryLocales() throws {
        let english = try Self.loadBundledStrings(table: "Localizable", locale: "en")
        let topicKeys = TheoryCatalog.topics.flatMap { topic in
            [topic.titleKey, topic.summaryKey, topic.takeawayKey, topic.contextKey, topic.limitationKey]
        }
        for code in ["pl", "isv", "eo", "es", "de", "fr", "it", "ru", "uk", "ja", "zh-Hans"].sorted() {
            let table = try Self.loadBundledStrings(table: "Localizable", locale: code)
            for key in topicKeys {
                let value = (table[key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                XCTAssertFalse(value.isEmpty || value == key, "\(code) missing \(key)")
                if code != "en" {
                    XCTAssertNotEqual(value, english[key], "\(code) still English \(key)")
                }
            }
        }
    }

    // MARK: - Helpers

    private static func bundledLocales(containing table: String) -> Set<String> {
        var codes = Set<String>()
        for localization in Bundle.main.localizations {
            let code = localization == "Base" ? "en" : localization
            if Bundle.main.path(
                forResource: table,
                ofType: "strings",
                inDirectory: nil,
                forLocalization: code
            ) != nil {
                codes.insert(code)
            }
        }
        return codes
    }

    private static func loadBundledStrings(table: String, locale: String) throws -> [String: String] {
        let loaded = LanguageCatalog.loadStringsTable(named: table, locale: locale)
        if loaded.isEmpty {
            throw XCTSkip("Missing \(table).strings for \(locale) in app bundle")
        }
        return loaded
    }
}
