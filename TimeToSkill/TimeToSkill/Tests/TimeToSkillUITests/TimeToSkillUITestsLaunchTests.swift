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

        // Wait for splash screen
        let splash = app.images["app_logo"]
        XCTAssertTrue(splash.waitForExistence(timeout: 3))

        // Navigate to TheoryView
        let theoryButton = app.buttons["Learning Theory"]
        XCTAssertTrue(theoryButton.waitForExistence(timeout: 3))
        theoryButton.tap()

        let theoryTitle = app.staticTexts["Teorie czasu nauki"]
        XCTAssertTrue(theoryTitle.waitForExistence(timeout: 3))

        // Screenshot for QA or App Store previews
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "TheoryView Screenshot"
        add(screenshot)
    }
}
