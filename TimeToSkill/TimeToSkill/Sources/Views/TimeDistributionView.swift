//
//  TimeDistributionView.swift
//  TimeToSkill
//
//  Per-skill chart of completed timer-session durations (T4S-001).
//  Manual adjustments are not part of this sample. The global distribution
//  and the PDF keep their own bins and continue to include manual entries.

import SwiftUI
import SwiftData

struct TimeDistributionView: View {
    let skill: Skill

    /// In-content Done button for when this screen is its own sheet. A pushed
    /// iOS page leaves it off and uses the system back button.
    var showsDoneButton: Bool = false

    @Environment(\.dismiss) private var dismiss
    @State private var binWidth = SessionDurationHistogram.defaultWidth

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
        #if os(macOS)
        // A macOS sheet resizes itself to its content, and a scroll view with
        // no height collapses to the title bar. The histogram scroll below has
        // an explicit height, so the sheet stays large enough to reach the
        // last bin. The minimum size uses the wider Mac layout.
        layout
            .navigationTitle(LocalizedStringKey("session_chart_nav_title"))
            .macOSSheetMinSize(width: 640, height: 560)
        #else
        // One sheet from the skill row. Done stays in the navigation bar so a
        // long histogram does not push dismissal off the first screen.
        ScrollView { layout }
            .navigationTitle(LocalizedStringKey("session_chart_nav_title"))
            .toolbar {
                if showsDoneButton {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(LocalizedStringKey("button_done")) {
                            dismiss()
                        }
                    }
                }
            }
        #endif
    }

    private var layout: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            summary
            binWidthPicker
            chartSection
            #if os(macOS)
            // In the content on purpose: the sheet is sized from its content,
            // so this button stays on screen with the histogram.
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

            Text(LocalizedStringKey("session_chart_metric"))
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
                    format: NSLocalizedString("session_chart_count_format", comment: ""),
                    distribution.minutes.count
                ),
                systemImage: "number"
            )
            summaryTile(
                String(
                    format: NSLocalizedString("session_chart_mean_format", comment: ""),
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

    private var binWidthPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey("session_chart_bin_width"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker(selection: $binWidth) {
                ForEach(SessionDurationHistogram.availableWidths, id: \.self) { width in
                    Text(binWidthTitle(width)).tag(width)
                }
            } label: {
                Text(LocalizedStringKey("session_chart_bin_width"))
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(Text(LocalizedStringKey("session_chart_bin_width")))
            .accessibilityValue(Text(binWidthTitle(binWidth)))
        }
    }

    // MARK: - Chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if distribution.bins.isEmpty {
                emptyState
            } else {
                boundedChart
                curveCaption
            }
        }
    }

    /// macOS gives the chart a real height so the sheet cannot collapse and
    /// hide the last bin. iOS already scrolls the whole page.
    @ViewBuilder
    private var boundedChart: some View {
        let chart = SessionDurationChart(histogram: distribution)
        #if os(macOS)
        let contentHeight = SessionDurationChart.contentHeight(binCount: distribution.bins.count)
        ScrollView {
            chart
        }
        .frame(height: min(max(contentHeight, 44), 480))
        #else
        chart
        #endif
    }

    private var curveCaption: some View {
        Text(LocalizedStringKey(
            distribution.showsReferenceCurve
                ? "session_chart_curve_caption"
                : "session_chart_curve_hidden"
        ))
        .font(.footnote)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var emptyState: some View {
        Text(LocalizedStringKey("session_chart_empty"))
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

    private var timerMinutes: [Double] {
        entries.compactMap { entry in
            TimerSessionSample.minutes(
                sourceRaw: entry.sourceRaw,
                durationMinutes: entry.durationMinutes
            )
        }
    }

    private var distribution: SessionDurationHistogram {
        SessionDurationHistogram(minutes: timerMinutes, binWidth: binWidth)
    }

    private func formatMinutes(_ minutes: Double?) -> String {
        guard let minutes, minutes.isFinite else {
            return NSLocalizedString("session_chart_mean_unavailable", comment: "")
        }
        return String(format: "%.1f", minutes)
    }

    private func binWidthTitle(_ width: Double) -> String {
        String(
            format: NSLocalizedString("session_chart_bin_minutes", comment: ""),
            Int(width.rounded())
        )
    }
}

/// Horizontal histogram: duration runs down the rows, frequency runs along
/// each bar. The normal reference is a translucent curve in those same
/// frequency units.
private struct SessionDurationChart: View {
    let histogram: SessionDurationHistogram

    private static let rowHeight: CGFloat = 22
    private static let rowSpacing: CGFloat = 8
    private static let labelWidth: CGFloat = 108
    private static let countWidth: CGFloat = 36

    static func contentHeight(binCount: Int) -> CGFloat {
        guard binCount > 0 else { return 0 }
        return CGFloat(binCount) * (rowHeight + rowSpacing) - rowSpacing
    }

    var body: some View {
        let bins = histogram.bins
        let peak = peakFrequency(bins)
        GeometryReader { geometry in
            let plotWidth = max(0, geometry.size.width - Self.labelWidth - Self.countWidth - 16)
            ZStack(alignment: .topLeading) {
                if histogram.showsReferenceCurve {
                    referenceShape(bins: bins, peak: peak, plotWidth: plotWidth, stroked: false)
                        .accessibilityHidden(true)
                }
                LazyVStack(alignment: .leading, spacing: Self.rowSpacing) {
                    ForEach(Array(bins.enumerated()), id: \.offset) { _, bin in
                        barRow(bin, peak: peak, plotWidth: plotWidth)
                    }
                }
                if histogram.showsReferenceCurve {
                    referenceShape(bins: bins, peak: peak, plotWidth: plotWidth, stroked: true)
                        .accessibilityHidden(true)
                }
            }
        }
        .frame(height: Self.contentHeight(binCount: histogram.bins.count))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(LocalizedStringKey("session_chart_accessibility")))
    }

    private func barRow(_ bin: SessionDurationHistogram.Bin, peak: Double, plotWidth: CGFloat) -> some View {
        let range = binRangeTitle(bin)
        return HStack(spacing: 8) {
            Text(range)
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(width: Self.labelWidth, alignment: .leading)

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
                    .frame(width: barWidth(count: bin.count, peak: peak, plotWidth: plotWidth), height: Self.rowHeight)
            }
            .frame(width: plotWidth, height: Self.rowHeight, alignment: .leading)

            Text("\(bin.count)")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: Self.countWidth, alignment: .trailing)
        }
        .frame(height: Self.rowHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(String(
            format: NSLocalizedString("session_chart_row_accessibility", comment: ""),
            range,
            bin.count
        )))
    }

    @ViewBuilder
    private func referenceShape(
        bins: [SessionDurationHistogram.Bin],
        peak: Double,
        plotWidth: CGFloat,
        stroked: Bool
    ) -> some View {
        let originX = Self.labelWidth + 8
        let points = curvePoints(bins: bins, peak: peak, plotWidth: plotWidth, originX: originX)
        if stroked {
            Path { path in
                guard let first = points.first else { return }
                path.move(to: CGPoint(x: originX, y: first.y))
                for point in points {
                    path.addLine(to: point)
                }
            }
            .stroke(Color.orange.opacity(0.9), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        } else {
            Path { path in
                guard let first = points.first, let last = points.last else { return }
                path.move(to: CGPoint(x: originX, y: first.y))
                for point in points {
                    path.addLine(to: point)
                }
                path.addLine(to: CGPoint(x: originX, y: last.y))
                path.closeSubpath()
            }
            .fill(Color.orange.opacity(0.22))
        }
    }

    private func curvePoints(
        bins: [SessionDurationHistogram.Bin],
        peak: Double,
        plotWidth: CGFloat,
        originX: CGFloat
    ) -> [CGPoint] {
        let stride = Self.rowHeight + Self.rowSpacing
        return bins.enumerated().compactMap { index, bin in
            guard let expected = bin.expectedCount, expected.isFinite else { return nil }
            let fraction = frequencyFraction(expected, peak: peak)
            let x = originX + plotWidth * fraction
            let y = CGFloat(index) * stride + Self.rowHeight / 2
            guard x.isFinite, y.isFinite else { return nil }
            return CGPoint(x: x, y: y)
        }
    }

    private func barWidth(count: Int, peak: Double, plotWidth: CGFloat) -> CGFloat {
        guard count > 0 else { return 0 }
        let width = plotWidth * frequencyFraction(Double(count), peak: peak)
        guard width.isFinite else { return 2 }
        return min(plotWidth, max(width, 2))
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

    private func binRangeTitle(_ bin: SessionDurationHistogram.Bin) -> String {
        if bin.isOverflow {
            return String(
                format: NSLocalizedString("session_chart_bin_overflow", comment: ""),
                wholeMinutes(bin.lowerMinutes)
            )
        }
        return String(
            format: NSLocalizedString("session_chart_bin_range", comment: ""),
            wholeMinutes(bin.lowerMinutes),
            wholeMinutes(bin.upperMinutes ?? .nan)
        )
    }

    /// Whole minutes for a bin edge. `Int(_:)` traps when the value does not
    /// fit, which a single covering bin can do for an extreme duration.
    private func wholeMinutes(_ value: Double) -> String {
        guard value.isFinite else {
            return NSLocalizedString("session_chart_mean_unavailable", comment: "")
        }
        let rounded = value.rounded()
        if let exact = Int(exactly: rounded) {
            return String(exact)
        }
        return String(format: "%.0f", value)
    }
}
