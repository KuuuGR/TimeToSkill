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

    func testStartButton() {
        app.buttons["Start"].tap()
        XCTAssertTrue(app.buttons["Stop"].exists)
    }

    func testSkillProgressUpdates() {
        app.buttons["Start"].tap()
        sleep(2) // simulate practice
        app.buttons["Stop"].tap()

        // Make sure this label has `.accessibilityIdentifier("SkillProgressLabel")` in SkillProgressView
        let label = app.staticTexts["SkillProgressLabel"]
        XCTAssertTrue(label.label.contains("hours"))
    }
}

