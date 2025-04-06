//
//  TimeToSkillApp.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//

import SwiftUI
import SwiftData

@main
struct TimeToSkillApp: App {
    var body: some Scene {
        WindowGroup {
            SplashView() // Your custom splash screen
        }
        .modelContainer(for: Skill.self) // Replace Item with Skill
    }
}
