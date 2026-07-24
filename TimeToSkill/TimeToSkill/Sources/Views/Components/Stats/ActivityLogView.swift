//
//  ActivityLogView.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 10/04/2025.
//

import SwiftUI
import SwiftData

/// Recent committed sessions from `TimeIntervalEntry` (timer + manual).
struct ActivityLogView: View {
    let skills: [Skill]
    @Query private var entries: [TimeIntervalEntry]

    private var recentSessions: [StatsSessionActivity.SessionRow] {
        let names = Dictionary(uniqueKeysWithValues: skills.map { ($0.id, $0.name) })
        let mapped = entries.map { ($0.id, $0.skillId, $0.durationMinutes, $0.createdAt) }
        return StatsSessionActivity.recentSessions(
            entries: mapped,
            skillNames: names,
            limit: 5
        )
    }

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStringKey("activity_log_title"))
                .font(.title2)
                .fontWeight(.semibold)

            if recentSessions.isEmpty {
                Text(LocalizedStringKey("activity_log_empty_message"))
                    .foregroundColor(.secondary)
                    .font(.footnote)
                    .padding(.top, 8)
            } else {
                ForEach(recentSessions, id: \.id) { session in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.skillName)
                                .font(.headline)

                            Text(dateFormatter.string(from: session.createdAt))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(StatsSessionActivity.formattedDuration(minutes: session.durationMinutes))
                            .font(.subheadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .padding(12)
                    .background(AppColors.surface)
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                }
            }
        }
    }
}
