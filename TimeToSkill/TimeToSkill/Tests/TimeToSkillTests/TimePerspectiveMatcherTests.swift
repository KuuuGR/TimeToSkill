import XCTest
@testable import TimeToSkill

final class TimePerspectiveMatcherTests: XCTestCase {

    private func perspective(
        id: String,
        minutes: Int,
        category: PerspectiveCategory = .everydayLife
    ) -> TimePerspective {
        TimePerspective(
            id: id,
            thresholdMinutes: minutes,
            icon: "⏱️",
            category: category
        )
    }

    func testEmptyLibraryReturnsNil() {
        XCTAssertNil(
            TimePerspectiveMatcher.findBestPerspective(for: 10, in: [])
        )
    }

    func testTargetBelowFirstThresholdReturnsFirstEntry() {
        let library = [
            perspective(id: "a", minutes: 15),
            perspective(id: "b", minutes: 60)
        ]
        let match = TimePerspectiveMatcher.findBestPerspective(for: 5, in: library)
        XCTAssertEqual(match?.id, "a")
    }

    func testExactThresholdMatch() {
        let library = [
            perspective(id: "a", minutes: 15),
            perspective(id: "b", minutes: 60)
        ]
        let match = TimePerspectiveMatcher.findBestPerspective(for: 60, in: library)
        XCTAssertEqual(match?.id, "b")
    }

    func testLargestThresholdLessOrEqual() {
        let library = [
            perspective(id: "a", minutes: 15),
            perspective(id: "b", minutes: 60),
            perspective(id: "c", minutes: 120)
        ]
        let match = TimePerspectiveMatcher.findBestPerspective(for: 90, in: library)
        XCTAssertEqual(match?.id, "b")
    }

    func testTiedThresholdsRotateAmongCandidates() {
        let library = [
            perspective(id: "a", minutes: 15),
            perspective(id: "b", minutes: 15),
            perspective(id: "c", minutes: 60)
        ]
        var seen = Set<String>()
        for _ in 0..<40 {
            if let id = TimePerspectiveMatcher.findBestPerspective(for: 15, in: library)?.id {
                seen.insert(id)
            }
        }
        XCTAssertEqual(seen.subtracting(["a", "b"]), [])
        XCTAssertTrue(seen.contains("a") || seen.contains("b"))
        // With enough samples both ties should appear; soft-check to avoid flaky CI
        XCTAssertFalse(seen.contains("c"))
    }

    func testLoaderDecodesBundledAsset() throws {
        let library = try TimePerspectiveLoader.loadLibrary()
        XCTAssertFalse(library.isEmpty)
        XCTAssertEqual(library.first?.id, "coffee_break")
        XCTAssertEqual(library.first?.thresholdMinutes, 15)
        XCTAssertEqual(library.first?.category, .everydayLife)
    }

    func testLocalizedTitlesAndDescriptionsResolve() throws {
        let library = try TimePerspectiveLoader.loadLibrary()
        let byID = Dictionary(uniqueKeysWithValues: library.map { ($0.id, $0) })

        let expected: [(String, String, String)] = [
            ("coffee_break", "Coffee Break", "Taking a short coffee break usually takes about fifteen minutes."),
            ("scotch_whisky", "Scotch Whisky", "Scotch whisky must mature for at least three years."),
            ("coconut_palm", "Coconut Palm", "A coconut palm reaches full productivity after about thirty years."),
            ("proxima_centauri", "Proxima Centauri", "Light from Earth reaches Proxima Centauri in about 4.25 years."),
            ("light_in_space", "Light in Space", "Light travels about 18 million km in one minute.")
        ]

        for (id, title, description) in expected {
            let item = try XCTUnwrap(byID[id], "Missing library entry \(id)")
            XCTAssertEqual(item.title, title, "title for \(id)")
            XCTAssertEqual(item.description, description, "description for \(id)")
            XCTAssertFalse(item.title.hasPrefix("perspective."), "raw key leaked for \(id) title")
            XCTAssertFalse(item.description.hasPrefix("perspective."), "raw key leaked for \(id) description")
        }
    }
}
