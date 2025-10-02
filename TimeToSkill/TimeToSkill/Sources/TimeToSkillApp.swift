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
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var iap = IAPManager.shared
    
    var body: some Scene {
        WindowGroup {
            SplashView()
                .preferredColorScheme(.dark) // Force dark
                .environment(\.colorScheme, .dark) // Override all views
                .environmentObject(iap)
        }
        .modelContainer(for: [Skill.self, ExemplarySkill.self, Counter.self, TimeIntervalEntry.self])
    }
}
