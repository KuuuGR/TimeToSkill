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

    /// Launch number captured before any view is built, so `RootView` can decide
    /// whether to show the splash and/or ask for an App Store review.
    private let launchCount: Int

    init() {
        launchCount = AppLaunch.recordLaunch()
    }

    var body: some Scene {
        WindowGroup {
            RootView(launchCount: launchCount)
                .preferredColorScheme(.dark) // Force dark
                .environment(\.colorScheme, .dark) // Override all views
        }
        .modelContainer(for: [Skill.self, ExemplarySkill.self, Counter.self, TimeIntervalEntry.self])
        .macOSDefaultWindowSize(width: 1000, height: 760)
    }
}
