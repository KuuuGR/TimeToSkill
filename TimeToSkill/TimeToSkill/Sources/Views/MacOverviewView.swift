//
//  MacOverviewView.swift
//  TimeToSkill
//
//  Calm, native landing surface for macOS: brand, one primary action and two
//  secondary shortcuts. Deliberately avoids the mobile "full-width gradient
//  button" pattern so the wide window reads as a desktop app.
//

#if os(macOS)

import SwiftUI
import SwiftData

struct MacOverviewView: View {
    @Binding var selection: MacSidebarSection?

    @Query private var skills: [Skill]

    private var totalTrackedHours: Double {
        skills.reduce(0) { $0 + $1.effectiveHours(at: Date()) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Hero: app name and a one-line introduction.
                VStack(alignment: .leading, spacing: 12) {
                    Text("ab_app_name")
                        .font(.system(.largeTitle, weight: .bold))
                        .foregroundColor(AppColors.onSurface)

                    Text(LocalizedStringKey("home_hero_intro"))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(String(
                            format: NSLocalizedString("time_total_hours_format", comment: "Total tracked time"),
                            formatHours(totalTrackedHours)
                        ))
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()
                        .foregroundColor(AppColors.onSurface)
                        .accessibilityIdentifier("MacTotalTrackedLabel")

                        Button(LocalizedStringKey("main_manage_trackers")) {
                            selection = .trackers
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Button(LocalizedStringKey("main_manage_counters")) {
                            selection = .counters
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 2)
                } label: {
                    Label(LocalizedStringKey("overview_tracking_tools"), systemImage: "hourglass")
                }

                MonthActivitySummary()

                Spacer(minLength: 8)
            }
            .padding(28)
            .frame(maxWidth: 660, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle(LocalizedStringKey("ab_app_name"))
        // Same shared control as Options — top-trailing of the detail panel.
        .languageSelectorCorner()
    }

    private func formatHours(_ hours: Double) -> String {
        let safeHours = hours.isFinite && !hours.isNaN ? hours : 0
        return String(format: "%.1f", safeHours)
    }
}

#endif
