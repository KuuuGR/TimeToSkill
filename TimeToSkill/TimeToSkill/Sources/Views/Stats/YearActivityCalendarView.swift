//
//  YearActivityCalendarView.swift
//  TimeToSkill
//
//  One aggregate year of practice. Day tiles sit above and below the year
//  control so the year stays in the centre without a circular layout.

import SwiftUI
import SwiftData

struct YearActivityCalendarView: View {
    @Query(sort: \TimeIntervalEntry.createdAt) private var entries: [TimeIntervalEntry]
    @State private var displayedYear: Int

    private var calendar: Calendar { .current }

    init() {
        _displayedYear = State(initialValue: Calendar.current.component(.year, from: .now))
    }

    var body: some View {
        let sessions = acceptedSessions
        let bounds = YearActivityCalendar.bounds(sessions: sessions, now: .now, calendar: calendar)
        let year = min(max(displayedYear, bounds.earliestYear), bounds.currentYear)
        let model = YearActivityCalendar.year(year, sessions: sessions, calendar: calendar)
        let split = model.days.count / 2

        VStack(alignment: .leading, spacing: 14) {
            LText(key: "activity_calendar_title")
                .font(.title2)
                .fontWeight(.semibold)

            dayGrid(Array(model.days.prefix(split)))
            yearControl(year: year, bounds: bounds, model: model)
            dayGrid(Array(model.days.suffix(model.days.count - split)))
        }
        .onAppear { clamp(to: bounds) }
        .onChange(of: sessions.count) { clamp(to: bounds) }
    }

    private var acceptedSessions: [TimerSessionActivity] {
        entries.compactMap {
            YearActivityCalendar.acceptedSession(
                sourceRaw: $0.sourceRaw,
                skillId: $0.skillId,
                minutes: $0.durationMinutes,
                endedAt: $0.createdAt
            )
        }
    }

    private func dayGrid(_ days: [YearActivityCalendar.Day]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let first = days.first, let last = days.last {
                Text(monthSpan(from: first.start, to: last.start))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(minimum: 8, maximum: 14), spacing: 3), count: 19),
                spacing: 3
            ) {
                ForEach(days) { day in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(tileColor(day.level))
                        .aspectRatio(1, contentMode: .fit)
                        .accessibilityLabel(Text(dayLabel(day)))
                }
            }
        }
    }

    private func yearControl(year: Int, bounds: YearActivityCalendar.Bounds, model: YearActivityCalendar.Year) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 16) {
                Button {
                    displayedYear = year - 1
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(!bounds.hasRecordedActivity || year <= bounds.earliestYear)
                .accessibilityLabel(Text(verbatim: L10n.string("activity_calendar_previous")))

                Text(verbatim: String(year))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .frame(minWidth: 108)

                Button {
                    displayedYear = year + 1
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(!bounds.hasRecordedActivity || year >= bounds.currentYear)
                .accessibilityLabel(Text(verbatim: L10n.string("activity_calendar_next")))
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderless)

            summary(bounds: bounds, model: model)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func summary(bounds: YearActivityCalendar.Bounds, model: YearActivityCalendar.Year) -> some View {
        if !bounds.hasRecordedActivity {
            LText(key: "activity_calendar_empty")
        } else if model.activeDayCount == 0 {
            LText(key: "activity_calendar_year_empty")
        } else {
            Text(String(
                format: L10n.string("activity_calendar_summary"),
                model.activeDayCount,
                model.distinctSkillCount
            ))
        }
    }

    private func tileColor(_ level: Int) -> Color {
        switch level {
        case 1: return AppColors.accent.opacity(0.28)
        case 2: return AppColors.accent.opacity(0.46)
        case 3: return AppColors.accent.opacity(0.64)
        case 4: return AppColors.accent.opacity(0.82)
        case 5: return AppColors.accent
        default: return Color.primary.opacity(0.08)
        }
    }

    private func dayLabel(_ day: YearActivityCalendar.Day) -> String {
        let level = min(max(day.level, 0), 5)
        return String(
            format: L10n.string("activity_calendar_day_accessibility"),
            L10n.mediumDate(day.start),
            L10n.string("activity_level_\(level)")
        )
    }

    private func monthSpan(from start: Date, to end: Date) -> String {
        "\(L10n.monthAbbreviation(start))–\(L10n.monthAbbreviation(end))"
    }

    private func clamp(to bounds: YearActivityCalendar.Bounds) {
        let clamped = min(max(displayedYear, bounds.earliestYear), bounds.currentYear)
        if clamped != displayedYear {
            displayedYear = clamped
        }
    }
}
