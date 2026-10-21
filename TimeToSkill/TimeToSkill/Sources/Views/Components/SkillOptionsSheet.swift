//
//  SkillOptionsSheet.swift
//  TimeToSkill
//
//  Created by ChatGPT on 08/04/2025.
//

import SwiftUI
import SwiftData

struct SkillOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var skill: Skill
    var onDelete: () -> Void

    @State private var newName: String
    @State private var skillIcon: String
    @State private var showResetConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var adjustHours: String = ""
    @State private var adjustMinutes: String = ""
    @State private var showSuccessMessage = false

    #if os(macOS)
    /// Whether the distribution chart sheet is open.
    @State private var showingDistribution = false
    #endif

    private let maxFieldHours = 10_000.0
    private let maxTotalHours = 876_000.0
    private let minTotalHours = -876_000.0

    init(skill: Skill, onDelete: @escaping () -> Void) {
        self._skill = .init(wrappedValue: skill)
        self._newName = State(initialValue: skill.name)
        self._skillIcon = State(initialValue: skill.icon)
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: LText(key: "skill_name_section")) {
                    LText(key: "skill_icon_label")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    SkillEmojiPickerButton(selection: $skillIcon)

                    LText(key: "skill_name_label")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextEditor(text: $newName)
                        .frame(minHeight: 40, maxHeight: 300)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3))
                        )
                        .onChange(of: newName) {
                            if newName.count > 255 {
                                newName = String(newName.prefix(255))
                            }
                        }

                    HStack {
                        Spacer()
                        Text("\(newName.count)/255")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: LText(key: "adjust_time_section")) {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("", text: $adjustHours, prompt: Text(verbatim: L10n.string("adjust_hours_placeholder")))
                            .numbersAndPunctuationKeyboard()
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        TextField("", text: $adjustMinutes, prompt: Text(verbatim: L10n.string("adjust_minutes_placeholder")))
                            .numbersAndPunctuationKeyboard()
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        LText(key: "adjust_time_hint")
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        if showSuccessMessage {
                            LText(key: "adjust_time_success")
                                .foregroundColor(.green)
                                .font(.footnote)
                        }

                        Button {
                            guard isValidInput else { return }
                            applyTimeChange()
                        } label: {
                            Text(verbatim: L10n.string("adjust_time_apply"))
                        }
                        .disabled(!isValidInput)
                        .keyboardShortcut(.defaultAction)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValidInput ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                        .cornerRadius(12)
                    }
                }

                Section(header: LText(key: "time_distribution_title")) {
                    #if os(macOS)
                    // A macOS sheet is sized from the top of its navigation stack,
                    // and a *pushed* screen reserves a navigation bar the sheet
                    // does not account for: the bottom of the histogram (the last
                    // bucket) ended up below the sheet's bottom edge. Presenting
                    // the chart as its own sheet keeps the whole histogram, last
                    // bar and its inset included, inside the window.
                    Button {
                        showingDistribution = true
                    } label: {
                        Text(verbatim: L10n.string("view_distribution"))
                    }
                    #else
                    NavigationLink {
                        TimeDistributionView(skill: skill)
                    } label: {
                        Text(verbatim: L10n.string("view_distribution"))
                    }
                    #endif
                }

                Section(header: LText(key: "reset_section")) {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Text(verbatim: L10n.string("reset_progress"))
                    }
                    .confirmationDialog(
                        Text(verbatim: L10n.string("reset_confirm_title")),
                        isPresented: $showResetConfirmation
                    ) {
                        Button(role: .destructive) {
                            resetProgress()
                        } label: {
                            Text(verbatim: L10n.string("reset_confirm_action"))
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label { Text(verbatim: L10n.string("delete_skill")) } icon: { Image(systemName: "trash") }
                    }
                    .alert(
                        Text(verbatim: L10n.string("delete_confirm_title")),
                        isPresented: $showDeleteConfirmation
                    ) {
                        Button(role: .destructive) {
                            onDelete()
                            dismiss()
                        } label: {
                            Text(verbatim: L10n.string("delete_confirm_action"))
                        }
                        Button(role: .cancel) {} label: {
                            Text(verbatim: L10n.string("cancel"))
                        }
                    } message: {
                        LText(key: "delete_confirm_message")
                    }
                }
            }
            .navigationTitle(Text(verbatim: L10n.string("skill_options_title")))
            .inlineNavigationBarTitle()
            #if os(macOS)
            // The chart is a sheet of its own (see the section above), so no
            // pushed screen is involved.
            .sheet(isPresented: $showingDistribution) {
                NavigationStack {
                    TimeDistributionView(skill: skill, showsDoneButton: true)
                }
            }
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        if !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                            let nameChanged = trimmed != skill.name
                            let iconChanged = skillIcon != skill.icon
                            skill.name = trimmed
                            skill.icon = skillIcon
                            if nameChanged || iconChanged {
                                skill.touchLastUpdated()
                            }
                            dismiss()
                        }
                    } label: {
                        Text(verbatim: L10n.string("done"))
                    }
                    // Return applies the time change instead of closing the whole
                    // sheet; the sheet itself is closed with Shift-Return.
                    .keyboardShortcut(KeyboardShortcut(.return, modifiers: .shift))
                }
            }
        }
    }

    private var isValidInput: Bool {
        let hours = Double(adjustHours) ?? 0
        let minutes = Double(adjustMinutes) ?? 0
        let totalInput = abs(hours) + abs(minutes / 60.0)
        let newTotal = skill.hours + hours + (minutes / 60.0)
        guard totalInput > 0 else { return false }
        return totalInput <= maxFieldHours && newTotal <= maxTotalHours && newTotal >= minTotalHours
    }

    private func applyTimeChange() {
        let hours = Double(adjustHours) ?? 0
        let minutes = Double(adjustMinutes) ?? 0
        let totalHours = hours + (minutes / 60.0)
        
        // Guard against NaN, infinite values, and zero change
        guard totalHours != 0 && totalHours.isFinite && !totalHours.isNaN else { return }

        skill.hours += totalHours
        skill.touchLastUpdated()
        // Persist interval entry as absolute minutes for distribution
        let entry = TimeIntervalEntry(skillId: skill.id, durationMinutes: abs(totalHours) * 60.0, source: .manual)
        context.insert(entry)
        try? context.save()

        adjustHours = ""
        adjustMinutes = ""
        showSuccessMessage = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSuccessMessage = false
        }
    }

    /// Clears tracked hours and matching interval history so stats / PDF /
    /// calendars stay consistent with a zeroed skill.
    private func resetProgress() {
        skill.hours = 0
        skill.activeStart = nil
        skill.touchLastUpdated()
        do {
            _ = try SkillIntervalCleanup.deleteEntries(for: skill.id, in: context)
            try context.save()
        } catch {
            try? context.save()
        }
    }
}
