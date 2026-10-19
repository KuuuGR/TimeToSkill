//
//  CatalogScreenUITests.swift
//
//  Drives the skills screen on the simulator and writes screenshots to /tmp.
//

import XCTest

final class CatalogScreenUITests: XCTestCase {
    private let shotDirectory = URL(fileURLWithPath: "/tmp/t4s-034-ui", isDirectory: true)

    override func setUpWithError() throws {
        continueAfterFailure = false
        try FileManager.default.createDirectory(at: shotDirectory, withIntermediateDirectories: true)
    }

    func testPolishCatalogFiltersAndProgressBar() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(pl)", "-AppleLocale", "pl_PL"]
        app.launch()

        let skills = app.buttons["Umiejętności"]
        XCTAssertTrue(skills.waitForExistence(timeout: 20))
        skills.tap()

        let search = app.textFields["CatalogSearchField"]
        XCTAssertTrue(search.waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Wszystkie"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["Wykonane"].exists)
        XCTAssertTrue(app.buttons["Niewykonane"].exists)
        XCTAssertTrue(app.buttons["Ulubione"].exists)
        saveShot(named: "01-skills-pl")

        search.tap()
        search.typeText("zzzz-brak")
        XCTAssertTrue(app.staticTexts["CatalogNoResults"].waitForExistence(timeout: 4))
        saveShot(named: "02-no-results")

        let reset = app.buttons["CatalogResetFilters"]
        XCTAssertTrue(reset.waitForExistence(timeout: 4))
        reset.tap()
        XCTAssertFalse(app.staticTexts["CatalogNoResults"].waitForExistence(timeout: 2))
        saveShot(named: "03-reset")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        let trackers = app.buttons["Zarządzaj trackerami"]
        XCTAssertTrue(trackers.waitForExistence(timeout: 6))
        trackers.tap()
        XCTAssertTrue(app.staticTexts["StartViewTitle"].waitForExistence(timeout: 6))

        app.buttons["Dodaj nową umiejętność"].tap()
        let name = app.textFields["AddSkillNameField"]
        XCTAssertTrue(name.waitForExistence(timeout: 4))
        name.tap()
        name.typeText("Bardzo długa nazwa z żółcią i łódką")
        app.buttons["AddSkillConfirmButton"].tap()

        let progress = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "SkillProgressLabel_")).firstMatch
        XCTAssertTrue(progress.waitForExistence(timeout: 6))
        saveShot(named: "04-progress-zero")
    }

    func testFavoriteFilterSurvivesRelaunchAndSearchDoesNot() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(pl)", "-AppleLocale", "pl_PL"]
        app.launch()

        let skills = app.buttons["Umiejętności"]
        XCTAssertTrue(skills.waitForExistence(timeout: 20))
        skills.tap()

        let search = app.textFields["CatalogSearchField"]
        XCTAssertTrue(search.waitForExistence(timeout: 8))
        search.tap()
        search.typeText("serwet")
        app.buttons["Ulubione"].tap()
        XCTAssertTrue(app.buttons["Ulubione"].isSelected)
        app.terminate()

        app.launch()
        let skillsAgain = app.buttons["Umiejętności"]
        XCTAssertTrue(skillsAgain.waitForExistence(timeout: 20))
        skillsAgain.tap()
        let searchAgain = app.textFields["CatalogSearchField"]
        XCTAssertTrue(searchAgain.waitForExistence(timeout: 8))
        saveShot(named: "07-relaunch-favorites")
        XCTAssertTrue(app.buttons["Ulubione"].isSelected)
        let value = (searchAgain.value as? String) ?? ""
        XCTAssertFalse(value.localizedCaseInsensitiveContains("serwet"))
        XCTAssertTrue(app.buttons["CatalogResetFilters"].waitForExistence(timeout: 4))
        app.buttons["CatalogResetFilters"].tap()
        let favorites = app.buttons["Ulubione"]
        XCTAssertTrue(favorites.waitForExistence(timeout: 4))
        XCTAssertFalse(favorites.isSelected)
        saveShot(named: "08-reset-after-relaunch")
    }

    func testPreviewGlassBarAndCrystal() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(pl)",
            "-AppleLocale", "pl_PL",
            "-T4SPreviewProgress"
        ]
        app.launch()

        let skills = app.buttons["Umiejętności"]
        XCTAssertTrue(skills.waitForExistence(timeout: 20))
        skills.tap()
        XCTAssertTrue(app.staticTexts["Brzuszki – kamień milowy"].waitForExistence(timeout: 8))
        saveShot(named: "05-crystal-favorite")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        let trackers = app.buttons["Zarządzaj trackerami"]
        XCTAssertTrue(trackers.waitForExistence(timeout: 6))
        trackers.tap()
        XCTAssertTrue(app.staticTexts["Szklany pasek szmaragdowy"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Szklany pasek szafirowy"].waitForExistence(timeout: 4))
        saveShot(named: "06-glass-bars")
    }

    private func saveShot(named name: String) {
        let data = XCUIScreen.main.screenshot().pngRepresentation
        let url = shotDirectory.appendingPathComponent("\(name).png")
        try? data.write(to: url)
    }
}
