import SwiftUI

struct AddSkillView: View {
    @Environment(\.dismiss) var dismiss

    @State private var skillName: String = ""
    var onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("Enter skill name", text: $skillName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: {
                    guard !skillName.isEmpty else { return }
                    onSave(skillName)
                    dismiss()
                }) {
                    Text("Add Skill")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("New Skill")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
