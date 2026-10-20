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
                    LText(key: "ab_app_name")
                        .font(.system(.largeTitle, weight: .bold))
                        .foregroundColor(AppColors.onSurface)

                    LText(key: "home_hero_intro")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(verbatim: L10n.format(
                            "time_total_hours_format",
                            formatHours(totalTrackedHours)
                        ))
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()
                        .foregroundColor(AppColors.onSurface)
                        .accessibilityIdentifier("MacTotalTrackedLabel")

                        Button {
                            selection = .trackers
                        } label: {
                            LText(key: "main_manage_trackers")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Button {
                            selection = .counters
                        } label: {
                            LText(key: "main_manage_counters")
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 2)
                } label: {
                    Label {
                        LText(key: "overview_tracking_tools")
                    } icon: {
                        Image(systemName: "hourglass")
                    }
                }

                MonthActivitySummary()

                Spacer(minLength: 8)
            }
            .padding(28)
            .frame(maxWidth: 660, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationTitle(Text(verbatim: L10n.string("ab_app_name")))
        // Same shared control as Options — top-trailing of the detail panel.
        .languageSelectorCorner()
    }

    private func formatHours(_ hours: Double) -> String {
        let safeHours = hours.isFinite && !hours.isNaN ? hours : 0
        return String(format: "%.1f", safeHours)
    }
}

#endif
