//
//  TimeDistributionView.swift
//  TimeToSkill
//
//  Per-skill chart of session durations (T4S-001): completed timer sessions
//  and positive manual hour additions. The global distribution and the PDF
//  keep their own bins.

import SwiftUI
import SwiftData

struct TimeDistributionView: View {
    let skill: Skill

    /// In-content / toolbar Done for when this screen is its own sheet. A pushed
    /// iOS page leaves it off and uses the system back button.
    var showsDoneButton: Bool = false

    @Environment(\.dismiss) private var dismiss
    @State private var detail: SessionChartDetail = SessionDurationHistogram.defaultDetail

    /// Sessions of this skill. A live query keeps the chart current if a
    /// session ends while the screen is open. The timer-only sample is
    /// applied below; this query itself does not change stored rows.
    @Query private var entries: [TimeIntervalEntry]

    init(skill: Skill, showsDoneButton: Bool = false) {
        self.skill = skill
        self.showsDoneButton = showsDoneButton
        let skillId = skill.id
        _entries = Query(filter: #Predicate<TimeIntervalEntry> { $0.skillId == skillId })
    }

    var body: some View {
        Group {
            #if os(macOS)
            // A macOS sheet resizes itself to its content. The plot has a fixed
            // height, so the sheet stays large enough without a page scroll
            // that collapses the title bar.
            layout
                .macOSSheetMinSize(width: 640, height: 560)
            #else
            ScrollView { layout }
            #endif
        }
        .navigationTitle(Text(verbatim: L10n.string("session_chart_nav_title")))
    }

    private var layout: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            summary
            detailPicker
            chartSection
            // Single dismiss control at the bottom of the chart content —
            // not also in the toolbar / header (that duplicated “Gotowe”).
            if showsDoneButton {
                doneRow
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .macOSContentWidth(700)
    }

    private var doneRow: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Text(verbatim: L10n.string("button_done"))
            }
            .keyboardShortcut(.cancelAction)
        }
    }

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

            LText(key: "session_chart_metric")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
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
                    format: L10n.string("session_chart_count_format"),
                    distribution.minutes.count
                ),
                systemImage: "number"
            )
            summaryTile(
                String(
                    format: L10n.string("session_chart_mean_format"),
                    formatMinutes(distribution.mean)
                ),
                systemImage: "chart.bar"
            )
        }
    }

    private func summaryTile(_ text: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
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

    private var detailPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            LText(key: "session_chart_bin_width")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker(selection: $detail) {
                ForEach(SessionChartDetail.allCases) { level in
                    Text(verbatim: L10n.string(level.titleKey)).tag(level)
                }
            } label: {
                LText(key: "session_chart_bin_width")
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(Text(verbatim: L10n.string("session_chart_bin_width")))
            .accessibilityValue(Text(verbatim: L10n.string(detail.titleKey)))
        }
    }

    // MARK: - Chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if distribution.bins.isEmpty {
                emptyState
            } else {
                SessionDurationChart(histogram: distribution)
                    // Force a fresh plot when the detail level or view window
                    // changes (avoids stale geometry from a prior pick).
                    .id("\(detail.rawValue)-\(distribution.binWidth)-\(distribution.presentationWindow.lower)-\(distribution.presentationWindow.upper)")
                if distribution.presentationWindow.outsideCount > 0 {
                    outsideRangeCaption
                }
                curveCaption
            }
        }
    }

    private var outsideRangeCaption: some View {
        Text(verbatim: L10n.format(
            "session_chart_outside_range_format",
            distribution.presentationWindow.outsideCount
        ))
        .font(.footnote)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var curveCaption: some View {
        Text(verbatim: L10n.string(
            distribution.showsReferenceCurve
                ? "session_chart_curve_caption"
                : "session_chart_curve_hidden"
        ))
        .font(.footnote)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var emptyState: some View {
        LText(key: "session_chart_empty")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.surface)
            )
    }

    // MARK: - Data

    /// Live sample for this skill: timer sessions and manual hour additions.
    /// Recomputed whenever `@Query` sees new `TimeIntervalEntry` rows.
    private var observationMinutes: [Double] {
        SkillDurationSample.minutes(
            forSkillId: skill.id,
            entries: entries.map { ($0.skillId, $0.sourceRaw, $0.durationMinutes) }
        )
    }

    private var distribution: SessionDurationHistogram {
        SessionDurationHistogram(minutes: observationMinutes, detail: detail)
    }

    private func formatMinutes(_ minutes: Double?) -> String {
        guard let minutes, minutes.isFinite else {
            return L10n.string("session_chart_mean_unavailable")
        }
        return String(format: "%.1f", minutes)
    }
}

/// Vertical histogram: duration bins along X, frequency along Y. The normal
/// reference is drawn in the same frequency units as the bar heights.
private struct SessionDurationChart: View {
    let histogram: SessionDurationHistogram

    private static let plotHeight: CGFloat = 260
    private static let yAxisWidth: CGFloat = 36
    private static let labelHeight: CGFloat = 44
    private static let minBarSlot: CGFloat = 28
    private static let barInset: CGFloat = 4

    var body: some View {
        let bins = histogram.bins
        let peak = peakFrequency(bins)
        GeometryReader { geometry in
            let plotWidth = max(0, geometry.size.width - Self.yAxisWidth - 8)
            let slot = max(Self.minBarSlot, plotWidth / CGFloat(max(bins.count, 1)))
            let contentWidth = slot * CGFloat(bins.count)

            HStack(alignment: .top, spacing: 8) {
                yAxis(peak: peak)
                    .frame(width: Self.yAxisWidth, height: Self.plotHeight, alignment: .trailing)

                ScrollView(.horizontal, showsIndicators: contentWidth > plotWidth + 0.5) {
                    VStack(alignment: .leading, spacing: 6) {
                        ZStack(alignment: .bottomLeading) {
                            gridLines(width: contentWidth)

                            if histogram.showsReferenceCurve {
                                referenceShape(
                                    bins: bins,
                                    peak: peak,
                                    slot: slot,
                                    stroked: false
                                )
                                .accessibilityHidden(true)
                            }

                            HStack(alignment: .bottom, spacing: 0) {
                                ForEach(Array(bins.enumerated()), id: \.offset) { _, bin in
                                    barColumn(bin, peak: peak, slot: slot)
                                }
                            }

                            if histogram.showsReferenceCurve {
                                referenceShape(
                                    bins: bins,
                                    peak: peak,
                                    slot: slot,
                                    stroked: true
                                )
                                .accessibilityHidden(true)
                            }
                        }
                        .frame(width: contentWidth, height: Self.plotHeight, alignment: .bottomLeading)

                        HStack(alignment: .top, spacing: 0) {
                            ForEach(Array(bins.enumerated()), id: \.offset) { _, bin in
                                Text(binRangeTitle(bin))
                                    .font(.caption2)
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.6)
                                    .multilineTextAlignment(.center)
                                    .frame(width: slot, alignment: .top)
                                    .accessibilityHidden(true)
                            }
                        }
                        .frame(width: contentWidth, height: Self.labelHeight, alignment: .topLeading)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: Self.plotHeight + Self.labelHeight + 6)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(verbatim: L10n.string("session_chart_accessibility")))
    }

    private func yAxis(peak: Double) -> some View {
        let top = axisLabel(peak)
        let mid = axisLabel(peak / 2)
        return VStack {
            Text(top)
            Spacer(minLength: 0)
            Text(mid)
            Spacer(minLength: 0)
            Text("0")
        }
        .font(.caption2)
        .monospacedDigit()
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)
    }

    private func gridLines(width: CGFloat) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: width, y: 0))
            path.move(to: CGPoint(x: 0, y: Self.plotHeight / 2))
            path.addLine(to: CGPoint(x: width, y: Self.plotHeight / 2))
            path.move(to: CGPoint(x: 0, y: Self.plotHeight))
            path.addLine(to: CGPoint(x: width, y: Self.plotHeight))
        }
        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        .frame(width: width, height: Self.plotHeight, alignment: .bottom)
        .accessibilityHidden(true)
    }

    private func barColumn(
        _ bin: SessionDurationHistogram.Bin,
        peak: Double,
        slot: CGFloat
    ) -> some View {
        let range = binRangeTitle(bin)
        let height = barHeight(count: bin.count, peak: peak)
        return VStack(spacing: 0) {
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.info, .mdbPurple],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: max(4, slot - Self.barInset * 2), height: height)
        }
        .frame(width: slot, height: Self.plotHeight, alignment: .bottom)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(String(
            format: L10n.string("session_chart_row_accessibility"),
            range,
            bin.count
        )))
    }

    @ViewBuilder
    private func referenceShape(
        bins: [SessionDurationHistogram.Bin],
        peak: Double,
        slot: CGFloat,
        stroked: Bool
    ) -> some View {
        let points = curvePoints(bins: bins, peak: peak, slot: slot)
        if stroked {
            Path { path in
                guard let first = points.first else { return }
                path.move(to: first)
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
            .stroke(Color.orange.opacity(0.9), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        } else {
            Path { path in
                guard let first = points.first, let last = points.last else { return }
                path.move(to: CGPoint(x: first.x, y: Self.plotHeight))
                path.addLine(to: first)
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
                path.addLine(to: CGPoint(x: last.x, y: Self.plotHeight))
                path.closeSubpath()
            }
            .fill(Color.orange.opacity(0.22))
        }
    }

    private func curvePoints(
        bins: [SessionDurationHistogram.Bin],
        peak: Double,
        slot: CGFloat
    ) -> [CGPoint] {
        bins.enumerated().compactMap { index, bin in
            guard let expected = bin.expectedCount, expected.isFinite else { return nil }
            let fraction = frequencyFraction(expected, peak: peak)
            let x = CGFloat(index) * slot + slot / 2
            let y = Self.plotHeight * (1 - fraction)
            guard x.isFinite, y.isFinite else { return nil }
            return CGPoint(x: x, y: y)
        }
    }

    private func barHeight(count: Int, peak: Double) -> CGFloat {
        guard count > 0 else { return 0 }
        let height = Self.plotHeight * frequencyFraction(Double(count), peak: peak)
        guard height.isFinite else { return 2 }
        return min(Self.plotHeight, max(height, 2))
    }

    private func frequencyFraction(_ value: Double, peak: Double) -> CGFloat {
        guard value.isFinite, peak.isFinite, peak > 0 else { return 0 }
        let fraction = value / peak
        guard fraction.isFinite else { return 0 }
        return CGFloat(min(1, max(0, fraction)))
    }

    private func peakFrequency(_ bins: [SessionDurationHistogram.Bin]) -> Double {
        let peak = bins.map { max(Double($0.count), $0.expectedCount ?? 0) }.max() ?? 0
        guard peak.isFinite, peak > 0 else { return 1 }
        return peak
    }

    private func axisLabel(_ value: Double) -> String {
        guard value.isFinite else {
            return L10n.string("session_chart_mean_unavailable")
        }
        if value >= 10 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    private func binRangeTitle(_ bin: SessionDurationHistogram.Bin) -> String {
        if bin.isOverflow {
            return String(
                format: L10n.string("session_chart_bin_overflow"),
                wholeMinutes(bin.lowerMinutes)
            )
        }
        return String(
            format: L10n.string("session_chart_bin_range"),
            wholeMinutes(bin.lowerMinutes),
            wholeMinutes(bin.upperMinutes ?? .nan)
        )
    }

    /// Whole minutes for a bin edge. `Int(_:)` traps when the value does not
    /// fit, which a single covering bin can do for an extreme duration.
    private func wholeMinutes(_ value: Double) -> String {
        guard value.isFinite else {
            return L10n.string("session_chart_mean_unavailable")
        }
        let rounded = value.rounded()
        if let exact = Int(exactly: rounded) {
            return String(exact)
        }
        return String(format: "%.0f", value)
    }
}
