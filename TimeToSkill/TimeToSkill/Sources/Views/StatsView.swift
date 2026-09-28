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

    /// iOS presents this view as a sheet (with a Done button); macOS hosts it as
    /// a sidebar section in the detail column, where "Done" makes no sense.
    var showsDoneButton: Bool = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    Text(LocalizedStringKey("stats_title_overview"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)

                    StatsSummaryView(skills: skills)
                    TopSkillsView(skills: skills)
                    TrackedTimeView(skills: skills)
                    ActivityLogView(skills: skills)
                    GlobalTimeDistributionView()
                }
                .padding()
                .macOSContentWidth(820)
            }
            .navigationTitle(LocalizedStringKey("stats_nav_title"))
            .inlineNavigationBarTitle()
            .toolbar {
                if showsDoneButton {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(LocalizedStringKey("button_done")) {
                            dismiss()
                        }
                    }
                }
            }
            .macOSSheetMinSize(width: 640, height: 660)
        }
    }
}
