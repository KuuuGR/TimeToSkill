//
//  TimeToSkillTests.swift
//  TimeToSkillTests
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//

import XCTest
@testable import TimeToSkill

final class SkillTests: XCTestCase {

    func testSkillInitialization() {
        let skill = Skill(name: "Guitar", hours: 12.5)

        XCTAssertEqual(skill.name, "Guitar")
        XCTAssertEqual(skill.hours, 12.5, accuracy: 0.01)
    }

    func testSkillProgressColorLow() {
        let skill = Skill(name: "Test", hours: 10)
        let view = SkillProgressView(skill: skill, isActive: false, onToggleTimer: {})
        XCTAssertEqual(view.progressColor, .green.opacity(0.7))
    }

    func testSkillProgressColorMedium() {
        let skill = Skill(name: "Test", hours: 50)
        let view = SkillProgressView(skill: skill, isActive: false, onToggleTimer: {})
        XCTAssertEqual(view.progressColor, .orange.opacity(0.7))
    }

    func testSkillProgressColorHigh() {
        let skill = Skill(name: "Test", hours: 500)
        let view = SkillProgressView(skill: skill, isActive: false, onToggleTimer: {})
        XCTAssertEqual(view.progressColor, .red.opacity(0.7))
    }
}
