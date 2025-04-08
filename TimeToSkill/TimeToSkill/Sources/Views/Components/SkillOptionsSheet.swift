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
}
