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
    @State private var showResetConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var adjustHours: String = ""
    @State private var adjustMinutes: String = ""
    @State private var showSuccessMessage = false

    private let maxFieldHours = 10_000.0
    private let maxTotalHours = 876_000.0
    private let minTotalHours = -876_000.0

    init(skill: Skill, onDelete: @escaping () -> Void) {
        self._skill = .init(wrappedValue: skill)
        self._newName = State(initialValue: skill.name)
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(LocalizedStringKey("skill_name_section"))) {
                    Text(LocalizedStringKey("skill_name_label"))
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

                Section(header: Text(LocalizedStringKey("adjust_time_section"))) {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField(LocalizedStringKey("adjust_hours_placeholder"), text: $adjustHours)
                            .keyboardType(.numbersAndPunctuation)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        TextField(LocalizedStringKey("adjust_minutes_placeholder"), text: $adjustMinutes)
                            .keyboardType(.numbersAndPunctuation)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Text(LocalizedStringKey("adjust_time_hint"))
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        if showSuccessMessage {
                            Text(LocalizedStringKey("adjust_time_success"))
                                .foregroundColor(.green)
                                .font(.footnote)
                        }

                        Button(LocalizedStringKey("adjust_time_apply")) {
                            applyTimeChange()
                        }
                        .disabled(!isValidInput)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValidInput ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                        .cornerRadius(12)
                    }
                }

                Section(header: Text("Time Distribution")) {
                    NavigationLink("View Distribution") { TimeDistributionView(skill: skill) }
                }

                Section(header: Text(LocalizedStringKey("reset_section"))) {
                    Button(LocalizedStringKey("reset_progress"), role: .destructive) {
                        showResetConfirmation = true
                    }
                    .confirmationDialog(LocalizedStringKey("reset_confirm_title"), isPresented: $showResetConfirmation) {
                        Button(LocalizedStringKey("reset_confirm_action"), role: .destructive) {
                            skill.hours = 0
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label(LocalizedStringKey("delete_skill"), systemImage: "trash")
                    }
                    .alert(LocalizedStringKey("delete_confirm_title"), isPresented: $showDeleteConfirmation) {
                        Button(LocalizedStringKey("delete_confirm_action"), role: .destructive) {
                            onDelete()
                            dismiss()
                        }
                        Button(LocalizedStringKey("cancel"), role: .cancel) { }
                    } message: {
                        Text(LocalizedStringKey("delete_confirm_message"))
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("skill_options_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedStringKey("done")) {
                        if !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            skill.name = newName
                            dismiss()
                        }
                    }
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
        // Persist interval entry as absolute minutes for distribution
        let entry = TimeIntervalEntry(skillId: skill.id, durationMinutes: abs(totalHours) * 60.0, source: .manual)
        context.insert(entry)
        
        adjustHours = ""
        adjustMinutes = ""
        showSuccessMessage = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSuccessMessage = false
        }
    }
}
