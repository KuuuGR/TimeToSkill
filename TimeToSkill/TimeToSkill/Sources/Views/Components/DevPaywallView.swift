import SwiftUI

struct DevPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    var onUnlock: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(LocalizedStringKey("unlock_custom_skills_title"))
                    .font(.title2).bold()
                Text(LocalizedStringKey("unlock_custom_skills_subtitle"))
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 8) {
                    Label(LocalizedStringKey("unlock_benefit_create"), systemImage: "star.fill")
                    Label(LocalizedStringKey("unlock_benefit_delete"), systemImage: "trash")
                    Label(LocalizedStringKey("unlock_benefit_support"), systemImage: "heart")
                    Label(LocalizedStringKey("unlock_benefit_reset_limit"), systemImage: "arrow.counterclockwise")
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.08)))

                Spacer()

                HStack(spacing: 12) {
                    Button(LocalizedStringKey("restore_purchases")) {
                        // Dev mode: just dismiss
                        dismiss()
                    }
                    .buttonStyle(.bordered)

                    Button(LocalizedStringKey("buy_unlock")) {
                        onUnlock()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle(LocalizedStringKey("unlock_title_short"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(LocalizedStringKey("cancel")) { dismiss() } } }
        }
    }
}


