//
//  SkillIntervalCleanup.swift
//  TimeToSkill
//
//  TimeIntervalEntry rows are keyed by skillId without a SwiftData
//  relationship, so deleting or resetting a Skill must remove matching
//  intervals explicitly. Otherwise histograms, PDFs and calendars keep
//  orphaned minutes.
//

import Foundation
import SwiftData

enum SkillIntervalCleanup {
    /// Deletes every `TimeIntervalEntry` whose `skillId` matches.
    /// Does not touch other skills' rows.
    @discardableResult
    static func deleteEntries(
        for skillId: UUID,
        in context: ModelContext
    ) throws -> Int {
        let target = skillId
        let descriptor = FetchDescriptor<TimeIntervalEntry>(
            predicate: #Predicate { $0.skillId == target }
        )
        let entries = try context.fetch(descriptor)
        for entry in entries {
            context.delete(entry)
        }
        return entries.count
    }
}
