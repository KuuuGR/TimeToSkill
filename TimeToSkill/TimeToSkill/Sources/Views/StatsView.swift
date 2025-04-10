//
//  .
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 10/04/2025.
//

import SwiftUI
import SwiftData

/// Displays full statistics summary of user's tracked skills
struct StatsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var skills: [Skill]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    Text("📊 Skill Progress Overview")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)

                    StatsSummaryView(skills: skills)
                    TopSkillsView(skills: skills)
                    TrackedTimeView(skills: skills)
                    ActivityLogView(skills: skills)
                }
                .padding()
            }
            .navigationTitle("Your Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
