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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey(topic.titleKey))
                .font(.title3)
                .fontWeight(.semibold)
                .fixedSize(horizontal: false, vertical: true)

            Text(LocalizedStringKey(topic.summaryKey))
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey("theory_takeaway_label"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(LocalizedStringKey(topic.takeawayKey))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: onShowDetails) {
                Text(LocalizedStringKey("theory_sources_button"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(LocalizedStringKey("theory_sources_accessibility")))
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(LocalizedStringKey(topic.titleKey))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .fixedSize(horizontal: false, vertical: true)

                detailBlock("theory_detail_citation", textKey: topic.citationKey)
                detailBlock("theory_detail_source_type", textKey: topic.sourceKind.labelKey)
                detailBlock("theory_detail_context", textKey: topic.contextKey)

                if let intro = topic.findingsIntroKey, !topic.findings.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey(intro))
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                        ForEach(topic.findings) { finding in
                            HStack(alignment: .firstTextBaseline) {
                                Text(LocalizedStringKey(finding.labelKey))
                                Spacer(minLength: 12)
                                Text(LocalizedStringKey(finding.valueKey))
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                            .accessibilityElement(children: .combine)
                        }
                    }
                }

                detailBlock("theory_detail_limitation", textKey: topic.limitationKey)

                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey("theory_detail_links"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(topic.links) { link in
                        Link(destination: link.url) {
                            Label(LocalizedStringKey(link.labelKey), systemImage: "arrow.up.right")
                                .font(.subheadline)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(LocalizedStringKey("theory_detail_title"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(LocalizedStringKey("button_done")) {
                    dismiss()
                }
            }
        }
        .macOSSheetMinSize(width: 560, height: 520)
    }

    private func detailBlock(_ labelKey: String, textKey: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LocalizedStringKey(labelKey))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(LocalizedStringKey(textKey))
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
