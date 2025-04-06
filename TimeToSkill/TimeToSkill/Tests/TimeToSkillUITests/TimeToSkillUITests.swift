//
//  TimeToSkillUITests.swift
//  TimeToSkillUITests
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//

import XCTest

final class TimeToSkillUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUp() {
        app.launch()
    }
    
    func testStartButton() {
        app.buttons["Start"].tap()
        XCTAssertTrue(app.buttons["Stop"].exists)
    }
    
    func testSkillProgressUpdates() {
        app.buttons["Start"].tap()
        sleep(2) // Simulate 2s practice
        app.buttons["Stop"].tap()
        XCTAssertTrue(app.staticTexts["0.1 hours"].exists)
    }
}
