//
//  TheoryView.swift
//  TimeToSkill
//
//  Hour-threshold compendium. Each tab is an existing Time4Skill mark.
//  The crystal on a tab is the same palette entry the progress bar uses
//  for that number of hours.

import SwiftUI

struct TheoryView: View {
    @State private var selectedHour: Int = TheoryCatalog.chapters[0].hourMark

    private var chapter: TheoryChapter {
        TheoryCatalog.chapter(hourMark: selectedHour) ?? TheoryCatalog.chapters[0]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey("theory_title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 8)

                Text(LocalizedStringKey("theory_compendium_intro"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                tabIndex
                chapterPage
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
            .macOSContentWidth(740)
        }
        .navigationTitle(LocalizedStringKey("theory_nav_title"))
    }

    private var tabIndex: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(TheoryCatalog.chapters) { item in
                    tab(item)
                }
            }
            .padding(.horizontal, 2)
        }
        .accessibilityIdentifier("TheoryTabs")
    }

    private func tab(_ item: TheoryChapter) -> some View {
        let selected = item.hourMark == chapter.hourMark
        let palette = CrystalPalette.forHours(Double(item.hourMark))
        return Button {
            selectedHour = item.hourMark
        } label: {
            VStack(spacing: 6) {
                thresholdCrystal(hours: item.hourMark)
                Text(item.hourMark, format: .number.grouping(.automatic))
                    .font(.subheadline.weight(selected ? .semibold : .regular))
                    .monospacedDigit()
                Text(LocalizedStringKey("theory_hour_unit"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 88)
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, selected ? 14 : 10)
            .background(
                UnevenRoundedRectangle(topLeadingRadius: 14, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 14)
                    .fill(selected ? Color.primary.opacity(0.08) : Color.primary.opacity(0.03))
            )
            .overlay(alignment: .top) {
                UnevenRoundedRectangle(topLeadingRadius: 14, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 14)
                    .stroke(selected ? (palette?.gemColors.dropFirst().first ?? Color.secondary) : Color.primary.opacity(0.12), lineWidth: selected ? 1.4 : 0.6)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("TheoryTab_\(item.hourMark)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var chapterPage: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                thresholdCrystal(hours: chapter.hourMark)
                Text(LocalizedStringKey(chapter.titleKey))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityIdentifier("TheoryChapter_\(chapter.hourMark)")

            Text(LocalizedStringKey(chapter.leadKey))
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            section(titleKey: chapter.mechanismTitleKey, bodyKey: chapter.mechanismKey)

            callout(labelKey: "theory_callout_example", bodyKey: chapter.exampleKey, systemImage: "text.alignleft")
            callout(labelKey: "theory_callout_caveat", bodyKey: chapter.caveatKey, systemImage: "exclamationmark.circle")
            callout(labelKey: "theory_callout_takeaway", bodyKey: chapter.takeawayKey, systemImage: "arrow.turn.down.right")

            sources
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.6)
        )
    }

    private func section(titleKey: String, bodyKey: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(titleKey))
                .font(.headline)
            Text(LocalizedStringKey(bodyKey))
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func callout(labelKey: String, bodyKey: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(LocalizedStringKey(labelKey), systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(LocalizedStringKey(bodyKey))
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.6)
        )
        .accessibilityIdentifier("TheoryCallout_\(chapter.hourMark)_\(labelKey)")
    }

    private var sources: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey("theory_detail_links"))
                .font(.headline)
            ForEach(chapter.sourceTopicIDs, id: \.self) { topicID in
                if let topic = TheoryCatalog.topic(id: topicID) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(LocalizedStringKey(topic.citationKey))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        if !topic.findings.isEmpty {
                            if let intro = topic.findingsIntroKey {
                                Text(LocalizedStringKey(intro))
                                    .font(.caption)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            ForEach(topic.findings) { finding in
                                HStack(alignment: .firstTextBaseline) {
                                    Text(LocalizedStringKey(finding.labelKey))
                                    Spacer(minLength: 12)
                                    Text(LocalizedStringKey(finding.valueKey))
                                        .foregroundStyle(.secondary)
                                }
                                .font(.caption)
                            }
                        }
                        ForEach(topic.links) { link in
                            Link(destination: link.url) {
                                Label(LocalizedStringKey(link.labelKey), systemImage: "arrow.up.right")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
    }
}
