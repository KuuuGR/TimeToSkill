import SwiftUI
import SwiftData

struct AddSkillView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var context

    @State private var skillName: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField(LocalizedStringKey("enter_skill_name"), text: $skillName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: {
                    guard !skillName.isEmpty else { return }
                    let newSkill = Skill(name: skillName)
                    context.insert(newSkill)
                    dismiss()
                }) {
                    Text(LocalizedStringKey("add_skill"))
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
            .navigationTitle(LocalizedStringKey("new_skill"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }
}
