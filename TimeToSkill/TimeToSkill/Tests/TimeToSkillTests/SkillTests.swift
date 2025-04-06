//
//  TimeToSkillTests.swift
//  TimeToSkillTests
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//

import XCTest

@testable import TimeToSkill

final class SkillTests: XCTestCase {
    func testSkillProgressColors() {
        let skillLow = Skill(name: "Test", hours: 10)
        let skillHigh = Skill(name: "Test", hours: 500)
        
        // Create the view to test colors
        let viewLow = SkillProgressView(skill: skillLow, isActive: false, onToggleTimer: {})
        let viewHigh = SkillProgressView(skill: skillHigh, isActive: false, onToggleTimer: {})
        
        // Test the colors
        XCTAssertEqual(viewLow.progressColor, .green.opacity(0.7))
        XCTAssertEqual(viewHigh.progressColor, .red.opacity(0.7))
    }
}
