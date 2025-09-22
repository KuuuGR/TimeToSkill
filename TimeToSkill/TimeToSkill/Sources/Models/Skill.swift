//
//  Skill.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//

import Foundation  // ← Add this import
import SwiftData

/// Represents a skill to track (e.g., "Guitar", "Spanish")
@Model
final class Skill {
    @Attribute(.unique) var id: UUID
    var name: String
    var hours: Double
    var lastUpdated: Date
    var activeStart: Date?

    init(id: UUID = UUID(), name: String, hours: Double = 0) {
        self.id = id
        self.name = name
        // Guard against NaN and infinite values
        self.hours = hours.isFinite && !hours.isNaN ? hours : 0
        self.lastUpdated = Date()
    }
}
