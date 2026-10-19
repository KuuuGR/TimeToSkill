//
//  TimeBalanceView.swift
//  TimeToSkill
//
//  Remaining time that can be added or counted down.
//  Stopping a skill timer still only increases that skill's hours.
//

import SwiftUI
import SwiftData

struct TimeBalanceView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TimeBudget.title) private var budgets: [TimeBudget]
    @State private var showingNew = false
    @State private var pendingDelete: TimeBudget?

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
        let remaining = budget.remaining(at: now)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                if !budget.symbol.isEmpty {
                    Text(budget.symbol)
                        .font(.title2)
                }
                Text(budget.title)
                    .font(.headline)
                Spacer()
                Text(Self.format(seconds: remaining))
                    .font(.title3.monospacedDigit())
                    .accessibilityLabel(Text(LocalizedStringKey("time_balance_remaining")))
            }
            HStack {
                Button(LocalizedStringKey("time_balance_add_quarter")) {
                    budget.add(minutes: 15)
                    try? context.save()
                }
                .buttonStyle(.bordered)
                Button(budget.activeStart == nil ? LocalizedStringKey("time_balance_start") : LocalizedStringKey("time_balance_stop")) {
                    budget.toggle(at: now)
                    try? context.save()
                }
                .buttonStyle(.borderedProminent)
                .disabled(budget.activeStart == nil && remaining == 0)
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
