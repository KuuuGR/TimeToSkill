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
    private let maxTotalHours = 100_000.0
    private let minTotalHours = -100_000.0

    init(skill: Skill, onDelete: @escaping () -> Void) {
        self._skill = .init(wrappedValue: skill)
        self._newName = State(initialValue: skill.name)
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Name")) {
                    TextField("Skill Name", text: $newName)
                        .onSubmit {
                            skill.name = newName
                        }
                }

                Section(header: Text("Adjust Time")) {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Hours to add/subtract", text: $adjustHours)
                            .keyboardType(.numbersAndPunctuation)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        TextField("Minutes to add/subtract", text: $adjustMinutes)
                            .keyboardType(.numbersAndPunctuation)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Text("Enter positive or negative values.\nExample: -30 minutes subtracts half an hour.")
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        if showSuccessMessage {
                            Text("Time updated successfully!")
                                .foregroundColor(.green)
                                .font(.footnote)
                        }

                        Button("Apply Time Change") {
                            applyTimeChange()
                        }
                        .disabled(!isValidInput)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValidInput ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                        .cornerRadius(12)
                    }
                }

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

    private var isValidInput: Bool {
        let hours = Double(adjustHours) ?? 0
        let minutes = Double(adjustMinutes) ?? 0
        let totalInput = abs(hours) + abs(minutes / 60.0)
        let newTotal = skill.hours + hours + (minutes / 60.0)

        // Debug info (remove or comment in production)
        #if DEBUG
        print("Hours input: \(hours)")
        print("Minutes input: \(minutes)")
        print("Total input: \(totalInput)")
        print("Resulting total skill.hours: \(newTotal)")
        #endif

        // Must input something
        guard totalInput > 0 else { return false }

        // Check limits
        return totalInput <= maxFieldHours && newTotal <= maxTotalHours && newTotal >= minTotalHours
    }

    private func applyTimeChange() {
        let hours = Double(adjustHours) ?? 0
        let minutes = Double(adjustMinutes) ?? 0
        let totalHours = hours + (minutes / 60.0)

        guard totalHours != 0 else { return }

        skill.hours += totalHours
        adjustHours = ""
        adjustMinutes = ""
        showSuccessMessage = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSuccessMessage = false
        }
    }
}
