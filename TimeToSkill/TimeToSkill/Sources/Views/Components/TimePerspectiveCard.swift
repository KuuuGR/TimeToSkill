import SwiftUI

/// Premium-style comparison card shown below Time Converter controls.
/// Always visible: placeholder before the first calculation, matched perspective after.
struct TimePerspectiveCard: View {
    let perspective: TimePerspective?

    /// Observes script / language so Cyrillic & Glagolitic refresh immediately.
    @ObservedObject private var language = AppLanguage.shared

    var body: some View {
        let _ = language.resolved.presentationIdentity
        VStack(alignment: .leading, spacing: 12) {
            LText(key: "time_perspective.card.title", table: "TimePerspective")
                .font(.headline)
                .foregroundStyle(.primary)

            if let perspective {
                HStack(alignment: .top, spacing: 12) {
                    Text(perspective.icon)
                        .font(.largeTitle)
                        .accessibilityHidden(true)
                        .frame(width: 44, alignment: .center)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: perspective.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        Text(verbatim: perspective.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: L10n.string("time_perspective.card.empty_tagline", table: "TimePerspective"))
                        .font(.subheadline)
                        .italic()
                        .foregroundStyle(.secondary)

                    Text(verbatim: L10n.string("time_perspective.card.empty_prompt", table: "TimePerspective"))
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(minHeight: 64, alignment: .topLeading)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColors.primary.opacity(0.35), lineWidth: 1.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: accessibilityLabelText))
    }

    private var accessibilityLabelText: String {
        let title = L10n.string("time_perspective.card.title", table: "TimePerspective")
        if let perspective {
            return "\(title), \(perspective.title). \(perspective.description)"
        }
        let tagline = L10n.string("time_perspective.card.empty_tagline", table: "TimePerspective")
        let prompt = L10n.string("time_perspective.card.empty_prompt", table: "TimePerspective")
        return "\(title). \(tagline) \(prompt)"
    }
}
