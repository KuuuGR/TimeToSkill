//
//  TrackerToolKind.swift
//  TimeToSkill
//
//  Which tool the tracker management screen is showing. Visibility of the
//  "new skill" vs "new balance" actions follows this value, not button titles.
//

import Foundation

enum TrackerToolKind: String, CaseIterable, Equatable {
    case progress
    case balance

    static let storageKey = "TrackerTool"
    static let `default`: TrackerToolKind = .progress

    /// Creates a skill from the tracker toolbar / FAB.
    var showsNewSkillAction: Bool { self == .progress }

    /// Creates a time balance from the balance screen's own toolbar.
    var showsNewBalanceAction: Bool { self == .balance }

    static func resolve(_ raw: String) -> TrackerToolKind {
        TrackerToolKind(rawValue: raw) ?? .default
    }
}
