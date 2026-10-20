import SwiftUI
import SwiftData

/// Month grid for the overview. Days are marked only from saved sessions and
/// from dates a catalog skill was marked obtained.
struct MonthActivitySummary: View {
    @Query(sort: \TimeIntervalEntry.createdAt) private var entries: [TimeIntervalEntry]
    @Query private var catalog: [ExemplarySkill]
    @State private var displayedMonth: Date

    init() {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: .now)) ?? .now
        _displayedMonth = State(initialValue: start)
    }

    var body: some View {
        let calendar = Calendar.current
        let month = MonthActivityCalendar.month(
            containing: displayedMonth,
            practiceDays: practiceDays(calendar: calendar),
            obtainedDays: obtainedDays(calendar: calendar),
            calendar: calendar
        )
        let canGoForward = !calendar.isDate(displayedMonth, equalTo: .now, toGranularity: .month)

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(LocalizedStringKey("month_activity_title"))
                    .font(.title3.weight(.semibold))
                Spacer()
                Button {
                    shift(by: -1, calendar: calendar)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(Text(LocalizedStringKey("month_activity_previous")))

                Text(displayedMonth, format: .dateTime.month(.wide).year())
                    .font(.subheadline.weight(.medium))
                    .frame(minWidth: 140)

                Button {
                    shift(by: 1, calendar: calendar)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.borderless)
                .disabled(!canGoForward)
                .accessibilityLabel(Text(LocalizedStringKey("month_activity_next")))
            }

            weekdayHeader(calendar: calendar)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0..<month.leadingBlanks, id: \.self) { _ in
                    Color.clear.frame(height: 28)
                }
                ForEach(month.days) { day in
                    dayCell(day)
                }
            }
            .accessibilityIdentifier("MonthActivityGrid")

            VStack(alignment: .leading, spacing: 4) {
                legendRow(color: Color.brandAccent, text: "month_activity_practice")
                legendRow(color: Color.secondary.opacity(0.7), text: "month_activity_obtained")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if month.practiceDayCount == 0 && month.obtainedDayCount == 0 {
                Text(LocalizedStringKey("month_activity_empty"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func practiceDays(calendar: Calendar) -> Set<Date> {
        Set(entries.compactMap { entry in
            guard YearActivityCalendar.acceptedSession(
                sourceRaw: entry.sourceRaw,
                skillId: entry.skillId,
                minutes: entry.durationMinutes,
                endedAt: entry.createdAt
            ) != nil else { return nil }
            return calendar.startOfDay(for: entry.createdAt)
        })
    }

    private func obtainedDays(calendar: Calendar) -> Set<Date> {
        Set(catalog.compactMap { skill in
            guard let obtainedAt = skill.obtainedAt, skill.isObtained else { return nil }
            return calendar.startOfDay(for: obtainedAt)
        })
    }

    private func shift(by months: Int, calendar: Calendar) {
        guard let next = calendar.date(byAdding: .month, value: months, to: displayedMonth) else { return }
        if months > 0 && next > Date() { return }
        displayedMonth = next
    }

    private func weekdayHeader(calendar: Calendar) -> some View {
        let symbols = calendar.veryShortWeekdaySymbols
        let ordered = (0..<7).map { symbols[($0 + calendar.firstWeekday - 1) % 7] }
        return HStack(spacing: 6) {
            ForEach(ordered, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func dayCell(_ day: MonthActivityCalendar.Day) -> some View {
        Text("\(day.number)")
            .font(.caption.monospacedDigit())
            .frame(maxWidth: .infinity, minHeight: 28)
            .background(fill(day.mark), in: RoundedRectangle(cornerRadius: 6))
            .overlay {
                if day.mark == .both {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.secondary.opacity(0.8), lineWidth: 1.5)
                }
            }
            .foregroundStyle(day.mark == .practice || day.mark == .both ? Color.white : Color.primary)
    }

    private func fill(_ mark: MonthActivityCalendar.Mark) -> Color {
        switch mark {
        case .none: return Color.primary.opacity(0.06)
        case .practice, .both: return Color.brandAccent
        case .obtained: return Color.secondary.opacity(0.28)
        }
    }

    private func legendRow(color: Color, text: LocalizedStringKey) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(text)
        }
    }
}
