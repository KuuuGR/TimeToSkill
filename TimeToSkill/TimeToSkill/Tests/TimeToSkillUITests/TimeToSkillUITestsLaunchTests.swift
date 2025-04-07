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

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for splash screen to pass
        let splash = app.images["app_logo"]
        XCTAssertTrue(splash.waitForExistence(timeout: 3))
        
        // Take screenshot of main screen
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Main Screen"
        add(attachment)
    }
    
    func testNavigationToTheoryView() {
        let app = XCUIApplication()
        app.launch()

        // Tap the "Learning Theory" button
        let theoryButton = app.buttons["Learning Theory"]
        XCTAssertTrue(theoryButton.waitForExistence(timeout: 3))
        theoryButton.tap()

        // Verify navigation occurred
        let theoryTitle = app.staticTexts["Teorie czasu nauki"]
        XCTAssertTrue(theoryTitle.waitForExistence(timeout: 3))
    }
}
