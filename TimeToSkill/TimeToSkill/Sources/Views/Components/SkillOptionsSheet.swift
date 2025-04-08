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
    @State private var timeAdjustment: String = ""
    @State private var adjustHours: String = ""
    @State private var adjustMinutes: String = ""

    init(skill: Skill, onDelete: @escaping () -> Void) {
        self._skill = .init(wrappedValue: skill)
        self._newName = State(initialValue: skill.name)
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                // Skill name editing
                Section(header: Text("Name")) {
                    TextField("Skill Name", text: $newName)
                        .onSubmit {
                            skill.name = newName
                        }
                }

                // Manual time adjustment
                Section(header: Text("Adjust Time")) {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Hours to add/subtract", text: $adjustHours)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        TextField("Minutes to add/subtract", text: $adjustMinutes)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Text("Enter positive or negative values.\nExample: -30 minutes subtracts half an hour.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }

                    Button("Apply Time Change") {
                        applyTimeChange()
                    }
                }

                // Reset progress with confirmation
                Section(header: Text("Progress")) {
                    Button("Reset Progress", role: .destructive) {
                        showResetConfirmation = true
                    }
                    .confirmationDialog("Are you sure you want to reset progress?", isPresented: $showResetConfirmation) {
                        Button("Reset", role: .destructive) {
                            skill.hours = 0
                        }
                    }
                }

                // Delete skill with double confirmation
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Skill", systemImage: "trash")
                    }
                    .alert("Are you sure?", isPresented: $showDeleteConfirmation) {
                        Button("Delete", role: .destructive) {
                            onDelete()
                            dismiss()
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("This action cannot be undone.")
                    }
                }
            }
            .navigationTitle("Skill Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        skill.name = newName
                        dismiss()
                    }
                }
            }
        }
    }

    /// Parses minutes input and adjusts the skill's total hours.
    private func applyTimeChange() {
        let hours = Double(adjustHours) ?? 0
        let minutes = Double(adjustMinutes) ?? 0
        let totalHours = hours + (minutes / 60)
        skill.hours += totalHours

        adjustHours = ""
        adjustMinutes = ""
    }
}
