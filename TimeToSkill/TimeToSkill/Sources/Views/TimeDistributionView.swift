//
//  TimeDistributionView.swift
//  TimeToSkill
//
//  How long the individual sessions of one skill last ("Zobacz rozkład" in the
//  skill options), drawn as a horizontal bar chart: one row per duration
//  bucket, the bar length is the bucket's share of the busiest bucket and the
//  trailing numbers are the session count plus its share of all sessions.
//

import SwiftUI
import SwiftData

struct TimeDistributionView: View {
    let skill: Skill

    /// Adds the in-content "Gotowe" button used when the chart is presented as
    /// its own macOS sheet (see `SkillOptionsSheet`). iOS presents this screen
    /// as a pushed page with the standard back button, so it stays off there.
    var showsDoneButton: Bool = false

    @Environment(\.dismiss) private var dismiss

    /// Sessions of this skill. A live query instead of a one-off fetch keeps the
    /// histogram current when a session ends while the screen is still open.
    @Query private var entries: [TimeIntervalEntry]

    /// Upper edges (in minutes) of the fixed buckets. Longer sessions land in a
    /// trailing open-ended bucket.
    private static let bucketEdges: [Double] = [0, 5, 10, 15, 30, 60, 120, 240, 480, 960]

    init(skill: Skill, showsDoneButton: Bool = false) {
        self.skill = skill
        self.showsDoneButton = showsDoneButton
        let skillId = skill.id
        _entries = Query(filter: #Predicate<TimeIntervalEntry> { $0.skillId == skillId })
    }

    var body: some View {
        #if os(macOS)
        // A macOS sheet resizes itself to its content, and a scroll view has no
        // intrinsic height: with one here the window shrank to a thin strip
        // around the title bar. Laying the rows out at their natural height
        // instead lets the sheet grow until the last bucket is visible.
        layout
            .navigationTitle(LocalizedStringKey("distribution_nav_title"))
        #else
        // On iOS the screen keeps scrolling so long histograms stay reachable on
        // short devices.
        ScrollView { layout }
            .navigationTitle(LocalizedStringKey("distribution_nav_title"))
        #endif
    }

    /// Header, summary tiles and histogram, inset by the sheet's standard 16pt on
    /// every side - the inset below the histogram therefore matches the gap
    /// between the skill name and the window's title bar.
    private var layout: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            summary
            histogram
            #if os(macOS)
            // Part of the content on purpose: the sheet is sized from the
            // content, so an in-content button can never be clipped or push the
            // histogram out of the window.
            if showsDoneButton {
                doneRow
            }
            #endif
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .macOSContentWidth(700)
    }

    #if os(macOS)
    private var doneRow: some View {
        HStack {
            Spacer()

            Button(LocalizedStringKey("button_done")) {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
        }
    }
    #endif

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                if !skill.icon.isEmpty {
                    Text(skill.icon)
                        .accessibilityHidden(true)
                }

                Text(skill.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(2)
            }

            Text(LocalizedStringKey("time_distribution_title"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Summary

    private var summary: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 165), spacing: 12)],
            alignment: .leading,
            spacing: 12
        ) {
            summaryTile(
                String(
                    format: NSLocalizedString("time_total_hours_format", comment: ""),
                    formatHours(totalMinutes / 60)
                ),
                systemImage: "clock"
            )
            summaryTile(
                String(
                    format: NSLocalizedString("time_mean_minutes_format", comment: ""),
                    formatMinutes(meanMinutes)
                ),
                systemImage: "chart.bar"
            )
            summaryTile(
                String(
                    format: NSLocalizedString("time_std_minutes_format", comment: ""),
                    formatMinutes(stdMinutes)
                ),
                systemImage: "waveform.path"
            )
        }
    }

    private func summaryTile(_ text: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.callout)
                .foregroundStyle(AppColors.primary)

            Text(text)
                .font(.callout)
                .monospacedDigit()
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.surface)
        )
        .shadow(radius: 2, y: 1)
    }

    // MARK: - Histogram

    private var histogram: some View {
        VStack(alignment: .leading, spacing: 10) {
            if buckets.isEmpty {
                emptyState
            } else {
                ForEach(buckets) { bucket in
                    barRow(bucket)
                }
            }
        }
    }

    private func barRow(_ bucket: Bucket) -> some View {
        HStack(spacing: 12) {
            Text(bucket.label)
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 74, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.primary.opacity(0.08))

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.info, .mdbPurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        // Keep the shortest bar visible instead of a sliver.
                        .frame(width: max(6, geometry.size.width * bucket.share))
                }
            }
            .frame(height: 16)

            Text("\(bucket.count)")
                .font(.caption)
                .fontWeight(.semibold)
                .monospacedDigit()
                .frame(width: 30, alignment: .trailing)

            Text(bucket.frequency.formatted(.percent.precision(.fractionLength(0))))
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
    }

    private var emptyState: some View {
        HStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .foregroundStyle(.secondary)

            Text(LocalizedStringKey("distribution_empty_message"))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.surface)
        )
        .shadow(radius: 2, y: 1)
    }

    // MARK: - Data

    /// One bar of the histogram.
    private struct Bucket: Identifiable {
        let id = UUID()
        let label: String
        let count: Int
        /// Bar length relative to the busiest bucket (0…1).
        let share: Double
        /// Sessions in this bucket relative to all sessions (0…1).
        let frequency: Double
    }

    private var sessionDurations: [Double] {
        entries.map { max(0, $0.durationMinutes) }
    }

    private var totalMinutes: Double {
        sessionDurations.reduce(0, +)
    }

    private var meanMinutes: Double {
        let durations = sessionDurations
        guard !durations.isEmpty else { return 0 }
        return durations.reduce(0, +) / Double(durations.count)
    }

    private var stdMinutes: Double {
        let durations = sessionDurations
        guard !durations.isEmpty else { return 0 }
        let mean = durations.reduce(0, +) / Double(durations.count)
        let variance = durations.reduce(0) { $0 + pow($1 - mean, 2) } / Double(durations.count)
        return sqrt(variance)
    }

    private var buckets: [Bucket] {
        let durations = sessionDurations
        guard !durations.isEmpty else { return [] }

        let edges = Self.bucketEdges
        var counts: [(label: String, count: Int)] = []

        for index in 0..<(edges.count - 1) {
            let lower = edges[index]
            let upper = edges[index + 1]
            let count = durations.filter { $0 >= lower && $0 < upper }.count
            counts.append(("\(Int(lower))–\(Int(upper))m", count))
        }

        if let lastEdge = edges.last {
            let overflow = durations.filter { $0 >= lastEdge }.count
            if overflow > 0 {
                counts.append(("≥ \(Int(lastEdge))m", overflow))
            }
        }

        let busiest = max(1, counts.map(\.count).max() ?? 1)
        let total = max(1, durations.count)

        // Buckets without sessions are hidden so the chart only shows data that
        // actually exists.
        return counts
            .filter { $0.count > 0 }
            .map { bucket in
                Bucket(
                    label: bucket.label,
                    count: bucket.count,
                    share: Double(bucket.count) / Double(busiest),
                    frequency: Double(bucket.count) / Double(total)
                )
            }
    }

    // MARK: - Formatting

    private func formatMinutes(_ m: Double) -> String {
        String(format: "%.1f", m)
    }

    private func formatHours(_ h: Double) -> String {
        String(format: "%.2f", h)
    }
}

