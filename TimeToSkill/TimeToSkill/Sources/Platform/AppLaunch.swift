//
//  AppLaunch.swift
//  TimeToSkill
//
//  Counts how many times the app has been launched and decides which launches
//  are special:
//
//   * the launch splash plays on the 1st, 32nd, 64th and 128th launch;
//   * an App Store rating is requested on the 16th and 256th launch.
//
//  The counter is stored in `UserDefaults`, so it survives relaunches. Apple
//  caps review prompts at three per 365-day period per app, so even on a
//  "review" launch the system may choose not to show the prompt - asking is
//  always safe and never shows anything twice against the user's will.
//

import Foundation

/// Persisted, launch-count based policy for the app's one-off moments.
enum AppLaunch {
    /// `UserDefaults` key holding the number of launches completed so far.
    static let countKey = "appLaunchCount"

    /// Launches that present the splash screen.
    static let splashLaunches: Set<Int> = [1, 32, 64, 128]

    /// Launches that ask the App Store for a rating, once the main UI is up.
    static let reviewLaunches: Set<Int> = [16, 256]

    /// Guards against counting the same process twice (SwiftUI may build the
    /// root view more than once, e.g. when reopening a window on macOS).
    private static var didRecordThisProcess = false

    /// Increments the stored counter and returns the new value. The very first
    /// launch returns `1`.
    @discardableResult
    static func incrementCount(defaults: UserDefaults = .standard) -> Int {
        let count = defaults.integer(forKey: countKey) + 1
        defaults.set(count, forKey: countKey)
        return count
    }

    /// Number of launches recorded so far in this installation.
    static func currentCount(defaults: UserDefaults = .standard) -> Int {
        defaults.integer(forKey: countKey)
    }

    /// Records this launch exactly once per process and returns the launch
    /// number for the current run. Later calls in the same process just read
    /// the stored value, so previews and extra windows cannot inflate it.
    @discardableResult
    static func recordLaunch(defaults: UserDefaults = .standard) -> Int {
        // Xcode Previews instantiate the app repeatedly; never count those.
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            return currentCount(defaults: defaults)
        }
        guard !didRecordThisProcess else { return currentCount(defaults: defaults) }
        didRecordThisProcess = true
        return incrementCount(defaults: defaults)
    }

    /// Whether the splash screen should be presented on a given launch.
    static func shouldShowSplash(onLaunch count: Int) -> Bool {
        splashLaunches.contains(count)
    }

    /// Whether an App Store rating should be requested on a given launch.
    static func shouldRequestReview(onLaunch count: Int) -> Bool {
        reviewLaunches.contains(count)
    }
}
