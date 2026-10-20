//
//  TheoryCard.swift
//  TimeToSkill
//
//  Summary card for one bundled theory topic. Research detail stays behind
//  the footer button.

import SwiftUI

struct TheoryCard: View {
    let topic: TheoryTopic
    var onShowDetails: () -> Void

    @ObservedObject private var language = AppLanguage.shared

    var body: some View {
        let _ = language.resolved.presentationIdentity
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                thresholdCrystal(hours: topic.hourMark)
                Text(verbatim: L10n.string(topic.titleKey))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(verbatim: L10n.string(topic.summaryKey))
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                LText(key: "theory_takeaway_label")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(verbatim: L10n.string(topic.takeawayKey))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: onShowDetails) {
                LText(key: "theory_sources_button")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: L10n.string("theory_sources_accessibility")))
            .accessibilityIdentifier("TheorySources_\(topic.id)")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

struct TheoryDetailView: View {
    let topic: TheoryTopic
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var language = AppLanguage.shared

    var body: some View {
        let _ = language.resolved.presentationIdentity
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    thresholdCrystal(hours: topic.hourMark)
                    Text(verbatim: L10n.string(topic.titleKey))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .fixedSize(horizontal: false, vertical: true)
                }

                detailBlock("theory_detail_citation", textKey: topic.citationKey)
                detailBlock("theory_detail_source_type", textKey: topic.sourceKind.labelKey)
                detailBlock("theory_detail_context", textKey: topic.contextKey)

                if let intro = topic.findingsIntroKey, !topic.findings.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(verbatim: L10n.string(intro))
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                        ForEach(topic.findings) { finding in
                            HStack(alignment: .firstTextBaseline) {
                                Text(verbatim: L10n.string(finding.labelKey))
                                Spacer(minLength: 12)
                                Text(verbatim: L10n.string(finding.valueKey))
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                            .accessibilityElement(children: .combine)
                        }
                    }
                }

                detailBlock("theory_detail_limitation", textKey: topic.limitationKey)

                VStack(alignment: .leading, spacing: 8) {
                    LText(key: "theory_detail_links")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(topic.links) { link in
                        Link(destination: link.url) {
                            Label {
                                Text(verbatim: L10n.string(link.labelKey))
                            } icon: {
                                Image(systemName: "arrow.up.right")
                            }
                                .font(.subheadline)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(Text(verbatim: L10n.string("theory_detail_title")))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    dismiss()
                } label: {
                    LText(key: "button_done")
                }
            }
        }
        .macOSSheetMinSize(width: 560, height: 520)
    }

    private func detailBlock(_ labelKey: String, textKey: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: L10n.string(labelKey))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(verbatim: L10n.string(textKey))
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Small crystal for an app hour threshold. Topics without a threshold get nothing.
@ViewBuilder
func thresholdCrystal(hours: Int?) -> some View {
    if let hours, let palette = CrystalPalette.forHours(Double(hours)) {
        SkillCrystalBadge(
            compact: true,
            palette: palette,
            accessibilityKey: "theory_threshold_crystal"
        )
    }
}
