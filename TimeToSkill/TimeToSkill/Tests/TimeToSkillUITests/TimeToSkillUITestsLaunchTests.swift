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
}
