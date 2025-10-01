import SwiftUI

struct CustomExemplarySkillSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var category: String = ""
    @State private var difficulty: Int = 1
    @State private var oneStarDesc: String = ""
    @State private var twoStarDesc: String = ""
    @State private var threeStarDesc: String = ""
    let onCreate: (String, String, String, Int, String, String, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(LocalizedStringKey("skill_details_title"))) {
                    TextField(LocalizedStringKey("enter_skill_name"), text: $title)
                    TextField(LocalizedStringKey("description"), text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Category", text: $category)
                    Stepper(value: $difficulty, in: 1...10) {
                        Text(LocalizedStringKey("difficulty_label")) + Text(": \(difficulty)")
                    }
                }
                Section(header: Text(LocalizedStringKey("star_descriptions_title"))) {
                    TextField(LocalizedStringKey("one_star_description"), text: $oneStarDesc, axis: .vertical)
                        .lineLimit(2...4)
                    TextField(LocalizedStringKey("two_star_description"), text: $twoStarDesc, axis: .vertical)
                        .lineLimit(2...4)
                    TextField(LocalizedStringKey("three_star_description"), text: $threeStarDesc, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(LocalizedStringKey("add_skill"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(LocalizedStringKey("cancel")) { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button(LocalizedStringKey("create")) {
                        onCreate(
                            title.trimmingCharacters(in: .whitespaces),
                            description.trimmingCharacters(in: .whitespacesAndNewlines),
                            category.trimmingCharacters(in: .whitespaces),
                            difficulty,
                            oneStarDesc.trimmingCharacters(in: .whitespacesAndNewlines),
                            twoStarDesc.trimmingCharacters(in: .whitespacesAndNewlines),
                            threeStarDesc.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}


