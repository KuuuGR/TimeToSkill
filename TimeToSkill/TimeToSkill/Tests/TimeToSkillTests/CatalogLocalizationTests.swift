import XCTest
@testable import Time4Skill

final class CatalogLocalizationTests: XCTestCase {
    private var resourceBundle: Bundle { .main }

    func testBaseCatalogHasExpectedSkillCount() throws {
        let catalog = try XCTUnwrap(SkillSeeder.loadCatalog(named: "ExemplarySkills", bundle: resourceBundle))
        XCTAssertEqual(catalog.items.count, 2146)
        XCTAssertFalse(catalog.items.contains(where: { $0.id.isEmpty || $0.title.isEmpty || $0.description.isEmpty }))
    }

    func testCompleteOverlaysCoverEveryBaseId() throws {
        let base = try XCTUnwrap(SkillSeeder.loadCatalog(named: "ExemplarySkills", bundle: resourceBundle))
        let baseIDs = Set(base.items.map(\.id))
        // pl/es/eo are fully translated human/assembled overlays.
        for code in ["pl", "es", "eo"] {
            let overlay = try XCTUnwrap(
                SkillSeeder.loadCatalog(named: "ExemplarySkills_\(code)", bundle: resourceBundle),
                "missing overlay \(code)"
            )
            let overlayIDs = Set(overlay.items.map(\.id))
            XCTAssertEqual(overlayIDs, baseIDs, "\(code) must cover every base id")
            for item in overlay.items {
                XCTAssertFalse(item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(code) \(item.id) title")
                XCTAssertFalse(item.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(code) \(item.id) description")
                XCTAssertFalse(item.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(code) \(item.id) category")
            }
        }
    }

    func testInterslavicOverlayCoversEveryBaseIdWhenPresent() throws {
        guard let overlay = SkillSeeder.loadCatalog(named: "ExemplarySkills_isv", bundle: resourceBundle) else {
            throw XCTSkip("ExemplarySkills_isv.json not bundled yet")
        }
        let base = try XCTUnwrap(SkillSeeder.loadCatalog(named: "ExemplarySkills", bundle: resourceBundle))
        XCTAssertEqual(Set(overlay.items.map(\.id)), Set(base.items.map(\.id)))
    }

    func testCatalogOverlayResolvesRegionalChineseAndPortuguese() {
        XCTAssertEqual(SkillSeeder.catalogOverlayCode(for: "zh-Hans-CN"), "zh-Hans")
        XCTAssertEqual(SkillSeeder.catalogOverlayCode(for: "zh-Hant-TW"), "zh-Hant")
        XCTAssertEqual(SkillSeeder.catalogOverlayCode(for: "pt-BR"), "pt-BR")
        XCTAssertEqual(SkillSeeder.catalogOverlayCode(for: "pt-PT"), "pt-PT")
        XCTAssertEqual(SkillSeeder.catalogOverlayCode(for: "isv-Latn"), "isv")
        XCTAssertNil(SkillSeeder.catalogOverlayCode(for: "en-AU"))
    }

    func testMergedItemsPreferLocalizedTextButKeepBaseIds() throws {
        let base = try XCTUnwrap(SkillSeeder.loadCatalog(named: "ExemplarySkills", bundle: resourceBundle))
        let pl = try XCTUnwrap(SkillSeeder.loadCatalog(named: "ExemplarySkills_pl", bundle: resourceBundle))
        let merged = SkillSeeder.mergedItems(base: base.items, localized: pl.items)
        XCTAssertEqual(merged.count, base.items.count)
        let sample = try XCTUnwrap(merged.first)
        let localized = try XCTUnwrap(pl.items.first(where: { $0.id == sample.id }))
        XCTAssertEqual(sample.title, localized.title)
        XCTAssertEqual(sample.id, localized.id)
    }
}
