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
    var name: String
    var hours: Double  // Total hours invested
    var lastUpdated: Date
    
    init(name: String, hours: Double = 0) {
        self.name = name
        self.hours = hours
        self.lastUpdated = Date()
    }
}
