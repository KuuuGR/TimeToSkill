//
//  TimeToSkillUITests.swift
//  TimeToSkillUITests
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//

import XCTest

final class StartViewUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testStartButtonNavigatesToStartView() {
        let startTrackingButton = app.buttons["Start Tracking"]
        XCTAssertTrue(startTrackingButton.waitForExistence(timeout: 3), "Start Tracking button not found")
        startTrackingButton.tap()

        let title = app.staticTexts["StartViewTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 3), "StartView title not found")
    }

//    func testSkillProgressUpdatesAfterStartStop() {
//        let startTrackingButton = app.buttons["Start Tracking"]
//        XCTAssertTrue(startTrackingButton.waitForExistence(timeout: 5), "Start Tracking button not found")
//        startTrackingButton.tap()
//
//        let title = app.staticTexts["StartViewTitle"]
//        XCTAssertTrue(title.waitForExistence(timeout: 5), "StartView title not found")
//
//        // Find and tap the first button that starts with "StartButton_"
//        let startPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "StartButton_")
//        let startButton = app.buttons.matching(startPredicate).element(boundBy: 0)
//        XCTAssertTrue(startButton.waitForExistence(timeout: 5), "Start button not found")
//        startButton.tap()
//
//        sleep(2) // Simulate elapsed time
//
//        // Find and tap the first button that starts with "StopButton_"
//        let stopPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "StopButton_")
//        let stopButton = app.buttons.matching(stopPredicate).element(boundBy: 0)
//        XCTAssertTrue(stopButton.waitForExistence(timeout: 5), "Stop button not found")
//        stopButton.tap()
//
//        // Find a label that starts with "SkillProgressLabel_"
//        let labelPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "SkillProgressLabel_")
//        let progressLabel = app.staticTexts.matching(labelPredicate).element(boundBy: 0)
//        XCTAssertTrue(progressLabel.waitForExistence(timeout: 5), "Skill progress label not found")
//        XCTAssertTrue(progressLabel.label.contains("hours"), "Label doesn't contain 'hours'")
//    }
}
