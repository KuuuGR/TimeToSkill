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
            "export_pdf_generated_on_format"
        ]
        for code in Self.bundledLocales(containing: "Localizable").sorted() {
            let table = try Self.loadBundledStrings(table: "Localizable", locale: code)
            for key in required {
                let value = table[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                XCTAssertFalse(value.isEmpty, "\(code) missing/empty \(key)")
            }
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
