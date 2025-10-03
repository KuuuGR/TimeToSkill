import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var iap: IAPManager
    @Environment(\.dismiss) private var dismiss

    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey("unlock_custom_skills_title"))
                        .font(.title2).bold()
                    Text(LocalizedStringKey("unlock_custom_skills_subtitle"))
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label(LocalizedStringKey("unlock_benefit_create"), systemImage: "star.fill")
                    Label(LocalizedStringKey("unlock_benefit_delete"), systemImage: "trash")
                    Label(LocalizedStringKey("unlock_benefit_reset_limit"), systemImage: "arrow.counterclockwise")
                    Label(LocalizedStringKey("unlock_benefit_support"), systemImage: "heart")
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.08)))

                if let price = iap.displayPrice {
                    Text(String(format: NSLocalizedString("paywall_price_format", comment: ""), price))
                        .font(.headline)
                }

                if let msg = errorMessage {
                    Text(msg)
                        .foregroundColor(.red)
                        .font(.footnote)
                }

                Spacer()

                HStack(spacing: 12) {
                    Button(LocalizedStringKey("restore_purchases")) {
                        Task {
                            isRestoring = true
                            defer { isRestoring = false }
                            await iap.restorePurchases()
                            if iap.isPurchased { dismiss() }
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isPurchasing || isRestoring)

                    Button(LocalizedStringKey("buy_unlock")) {
                        Task {
                            isPurchasing = true
                            defer { isPurchasing = false }
                            await iap.purchase()
                            if iap.isPurchased { dismiss() }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isPurchasing || isRestoring || iap.product == nil)
                }

                HStack(spacing: 16) {
                    Link(LocalizedStringKey("privacy_policy_link"), destination: URL(string: "https://github.com/KuuuGR/TimeToSkill/wiki/Privacy-Policy")!)
                    Link(LocalizedStringKey("terms_of_use_link"), destination: URL(string: "https://github.com/KuuuGR/TimeToSkill/wiki/Terms-of-Use")!)
                }
                .font(.footnote)
                .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle(LocalizedStringKey("unlock_title_short"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(LocalizedStringKey("cancel")) { dismiss() } } }
        }
        .task {
            if iap.product == nil { await iap.loadProduct() }
        }
    }
}


