//
//  TimeBalanceView.swift
//  TimeToSkill
//
//  Remaining time that can grow or shrink. Layout:
//  [ − Start ] [ glass balance bar ] [ + Start ]
//  Stopping a skill timer still only increases that skill's hours.
//

import SwiftUI
import SwiftData
#if os(macOS)
import AppKit
#else
import AudioToolbox
#endif

enum TimeBalanceSound {
    static let defaultsKey = "TimeBalanceZeroSoundEnabled"

    static var isEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: defaultsKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: defaultsKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: defaultsKey) }
    }

    static func playZeroIfEnabled() {
        guard isEnabled else { return }
        #if os(macOS)
        NSSound.beep()
        #else
        AudioServicesPlaySystemSound(1057)
        #endif
    }
}

struct TimeBalanceView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \TimeBudget.title) private var budgets: [TimeBudget]
    @State private var showingNew = false
    @State private var pendingDelete: TimeBudget?
    @State private var zeroSoundPlayed: Set<UUID> = []

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(LocalizedStringKey("time_balance_note"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if budgets.isEmpty {
                        ContentUnavailableView {
                            Label(LocalizedStringKey("time_balance_empty_title"), systemImage: "hourglass")
                        } description: {
                            Text(LocalizedStringKey("time_balance_empty_description"))
                        }
                    } else {
                        ForEach(budgets) { budget in
                            balanceCard(budget, now: timeline.date)
                        }
                    }
                }
                .padding()
                .macOSContentWidth(760)
            }
            .onChange(of: timeline.date) { _, now in
                settleBudgets(at: now)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNew = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(Text(LocalizedStringKey("time_balance_new")))
            }
        }
        .confirmationDialog(
            LocalizedStringKey("delete_confirm_title"),
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(LocalizedStringKey("delete_confirm_action"), role: .destructive) {
                if let pendingDelete {
                    context.delete(pendingDelete)
                    try? context.save()
                }
                pendingDelete = nil
            }
            Button(LocalizedStringKey("cancel"), role: .cancel) { pendingDelete = nil }
        } message: {
            Text(LocalizedStringKey("delete_confirm_message"))
        }
        .sheet(isPresented: $showingNew) {
            NewTimeBalanceSheet { title, symbol in
                context.insert(TimeBudget(title: title, symbol: symbol))
                try? context.save()
            }
        }
    }

    private func balanceCard(_ budget: TimeBudget, now: Date) -> some View {
        let seconds = budget.currentSeconds(at: now)
        let hours = Double(seconds) / 3600.0
        let fill = ProgressFill.fraction(value: hours)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                if !budget.symbol.isEmpty {
                    Text(budget.symbol)
                        .font(.title2)
                }
                Text(budget.title)
                    .font(.headline)
                Spacer()
                Text(Self.format(seconds: seconds))
                    .font(.title3.monospacedDigit())
                    .accessibilityLabel(Text(LocalizedStringKey("time_balance_remaining")))
            }

            HStack(spacing: 10) {
                directionButton(
                    titleKey: budget.direction == .decreasing
                        ? "time_balance_minus_stop"
                        : "time_balance_minus_start",
                    accessibilityKey: budget.direction == .decreasing
                        ? "time_balance_a11y_stop_decrease"
                        : "time_balance_a11y_decrease",
                    systemImage: budget.direction == .decreasing ? "pause.fill" : "minus",
                    isActive: budget.direction == .decreasing,
                    disabled: budget.direction != .decreasing && seconds == 0
                ) {
                    if budget.direction == .decreasing {
                        budget.stop(at: now)
                    } else {
                        zeroSoundPlayed.remove(budget.id)
                        budget.startDecreasing(at: now)
                    }
                    try? context.save()
                }

                VStack(spacing: 4) {
                    CrystalProgressBar(
                        progress: fill,
                        hours: hours,
                        height: 14,
                        animated: !reduceMotion
                    )
                    .accessibilityLabel(Text(LocalizedStringKey("time_balance_bar")))
                    .accessibilityValue(Text(Self.format(seconds: seconds)))
                }
                .frame(maxWidth: .infinity)

                directionButton(
                    titleKey: budget.direction == .increasing
                        ? "time_balance_plus_stop"
                        : "time_balance_plus_start",
                    accessibilityKey: budget.direction == .increasing
                        ? "time_balance_a11y_stop_increase"
                        : "time_balance_a11y_increase",
                    systemImage: budget.direction == .increasing ? "pause.fill" : "plus",
                    isActive: budget.direction == .increasing,
                    disabled: false
                ) {
                    if budget.direction == .increasing {
                        budget.stop(at: now)
                    } else {
                        budget.startIncreasing(at: now)
                    }
                    try? context.save()
                }
            }

            HStack {
                Button(LocalizedStringKey("time_balance_add_quarter")) {
                    budget.add(minutes: 15, at: now)
                    try? context.save()
                }
                .buttonStyle(.bordered)
                Spacer()
                Button(role: .destructive) {
                    pendingDelete = budget
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel(Text(LocalizedStringKey("time_balance_delete")))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func directionButton(
        titleKey: LocalizedStringKey,
        accessibilityKey: LocalizedStringKey,
        systemImage: String,
        isActive: Bool,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                Text(titleKey)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(minWidth: 72)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
        }
        .buttonStyle(.bordered)
        .tint(isActive ? AppColors.accent : nil)
        .opacity(isActive ? 1 : 0.92)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isActive ? AppColors.accent : Color.clear, lineWidth: 2)
        )
        .disabled(disabled)
        .accessibilityLabel(Text(accessibilityKey))
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    private func settleBudgets(at now: Date) {
        var didChange = false
        for budget in budgets {
            if budget.settle(at: now) {
                didChange = true
                if !zeroSoundPlayed.contains(budget.id) {
                    zeroSoundPlayed.insert(budget.id)
                    TimeBalanceSound.playZeroIfEnabled()
                }
            }
        }
        if didChange {
            try? context.save()
        }
    }

    static func format(seconds: Int) -> String {
        let safe = max(0, seconds)
        let hours = safe / 3600
        let minutes = (safe % 3600) / 60
        let secs = safe % 60
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        }
        return String(format: "%dm %02ds", minutes, secs)
    }
}

private struct NewTimeBalanceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var symbol = ""
    let onCreate: (String, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                SkillEmojiPickerButton(selection: $symbol)
                TextField(LocalizedStringKey("counter_title_placeholder"), text: $title)
            }
            .navigationTitle(LocalizedStringKey("time_balance_new"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("create")) {
                        onCreate(title, symbol)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
