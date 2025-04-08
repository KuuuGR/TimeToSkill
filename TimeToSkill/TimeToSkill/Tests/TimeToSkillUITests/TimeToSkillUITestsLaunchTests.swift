//
//  TimeToSkillUITestsLaunchTests.swift
//  TimeToSkillUITests
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//

import XCTest

final class TimeToSkillUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchAndNavigateToTheoryView() {
        let app = XCUIApplication()
        app.launch()

        // Wait for the app logo (splash) to disappear
        let appLogo = app.images["app_logo"]
        XCTAssertTrue(appLogo.waitForExistence(timeout: 5), "App logo not found")

        // Tap the Theory button using accessibility label
        let theoryButton = app.buttons["Learning Theory"]
        XCTAssertTrue(theoryButton.waitForExistence(timeout: 5), "Theory button not found")
        theoryButton.tap()

        // Use a predicate to match a localized title (based on theory_nav_title = "Learning Theory")
        let theoryTitlePredicate = NSPredicate(format: "label CONTAINS[c] %@", "Learning Theory")
        let theoryTitle = app.staticTexts.containing(theoryTitlePredicate).element(boundBy: 0)
        XCTAssertTrue(theoryTitle.waitForExistence(timeout: 5), "TheoryView title not found")

        // Optionally, take screenshot for verification
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "TheoryView Screenshot"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
