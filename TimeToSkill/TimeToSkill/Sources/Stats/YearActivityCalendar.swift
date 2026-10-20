//
//  YearActivityCalendar.swift
//  TimeToSkill
//
//  Aggregate yearly practice calendar (T4S-003). Scoring is a display rule,
//  not a stored metric and not a measure of personal growth.

import Foundation

struct TimerSessionActivity: Equatable {
    let skillId: UUID
    let minutes: Double
    let endedAt: Date
}

enum YearActivityCalendar {
    struct Day: Equatable, Identifiable {
        let start: Date
        /// 0 = no recorded timer activity. 1...5 are display levels only.
        let level: Int
        var id: Date { start }
    }

    struct Year: Equatable {
        let year: Int
        let days: [Day]
        let activeDayCount: Int
        let distinctSkillCount: Int
    }

    struct Bounds: Equatable {
        let earliestYear: Int
        let currentYear: Int
        /// False when no completed timer session falls in the current year or earlier.
        let hasRecordedActivity: Bool

        func contains(_ year: Int) -> Bool {
            year >= earliestYear && year <= currentYear
        }
    }

    /// `S + min(M / 60, 0.99)` when at least one skill was practised.
    /// One long session stays below 2. Several skills outrank it.
    static func score(distinctSkills: Int, minutes: Double) -> Double {
        guard distinctSkills > 0 else { return 0 }
        let safeMinutes = (minutes.isFinite && minutes > 0) ? minutes : 0
        let bonus = min(safeMinutes / 60, 0.99)
        let value = Double(distinctSkills) + bonus
        return value.isFinite ? value : Double(distinctSkills)
    }

    static func level(for score: Double) -> Int {
        guard score.isFinite, score > 0 else { return 0 }
        switch score {
        case ..<1.5: return 1
        case ..<2: return 2
        case ..<3: return 3
        case ..<4: return 4
        default: return 5
        }
    }

    static func acceptedSession(
        sourceRaw: String,
        skillId: UUID,
        minutes: Double,
        endedAt: Date
    ) -> TimerSessionActivity? {
        guard endedAt.timeIntervalSince1970.isFinite,
              let minutes = TimerSessionSample.minutes(sourceRaw: sourceRaw, durationMinutes: minutes)
        else { return nil }
        return TimerSessionActivity(skillId: skillId, minutes: minutes, endedAt: endedAt)
    }

    /// Earliest evidenced year through the current calendar year.
    /// Future-dated sessions do not open future years.
    static func bounds(sessions: [TimerSessionActivity], now: Date, calendar: Calendar) -> Bounds {
        let currentYear = calendar.component(.year, from: now)
        let evidenced = sessions.compactMap { session -> Int? in
            let year = calendar.component(.year, from: session.endedAt)
            return year <= currentYear ? year : nil
        }
        guard let earliest = evidenced.min() else {
            return Bounds(earliestYear: currentYear, currentYear: currentYear, hasRecordedActivity: false)
        }
        return Bounds(earliestYear: earliest, currentYear: currentYear, hasRecordedActivity: true)
    }

    static func year(_ year: Int, sessions: [TimerSessionActivity], calendar: Calendar) -> Year {
        let starts = dayStarts(in: year, calendar: calendar)
        var skillsByDay: [Date: Set<UUID>] = [:]
        var minutesByDay: [Date: Double] = [:]
        var skillsInYear = Set<UUID>()

        for session in sessions {
            let start = calendar.startOfDay(for: session.endedAt)
            guard calendar.component(.year, from: start) == year else { continue }
            skillsByDay[start, default: []].insert(session.skillId)
            minutesByDay[start, default: 0] += session.minutes
            skillsInYear.insert(session.skillId)
        }

        let days = starts.map { start -> Day in
            let skills = skillsByDay[start] ?? []
            let minutes = minutesByDay[start] ?? 0
            let value = score(distinctSkills: skills.count, minutes: minutes)
            return Day(start: start, level: level(for: value))
        }
        let active = days.filter { $0.level > 0 }.count
        return Year(
            year: year,
            days: days,
            activeDayCount: active,
            distinctSkillCount: active == 0 ? 0 : skillsInYear.count
        )
    }

    static func dayStarts(in year: Int, calendar: Calendar) -> [Date] {
        guard let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) else {
            return []
        }
        var day = calendar.startOfDay(for: start)
        var days: [Date] = []
        while calendar.component(.year, from: day) == year {
            days.append(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = calendar.startOfDay(for: next)
        }
        return days
    }
}

/// One calendar month of recorded events. Practice comes only from saved
/// timer or manual sessions. An obtained-skill date is a collection event,
/// not practice time. Hour totals are never spread across days.
enum MonthActivityCalendar {
    enum Mark: Equatable {
        case none
        case practice
        case obtained
        case both
    }

    struct Day: Equatable, Identifiable {
        let start: Date
        let number: Int
        let mark: Mark
        var id: Date { start }
    }

    struct Month: Equatable {
        let days: [Day]
        let leadingBlanks: Int
        let practiceDayCount: Int
        let obtainedDayCount: Int
    }

    static func mark(practiced: Bool, obtained: Bool) -> Mark {
        switch (practiced, obtained) {
        case (true, true): return .both
        case (true, false): return .practice
        case (false, true): return .obtained
        case (false, false): return .none
        }
    }

    static func month(
        containing anchor: Date,
        practiceDays: Set<Date>,
        obtainedDays: Set<Date>,
        calendar: Calendar
    ) -> Month {
        let parts = calendar.dateComponents([.year, .month], from: anchor)
        guard let first = calendar.date(from: parts),
              let range = calendar.range(of: .day, in: .month, for: first) else {
            return Month(days: [], leadingBlanks: 0, practiceDayCount: 0, obtainedDayCount: 0)
        }
        let weekday = calendar.component(.weekday, from: first)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        let days = range.compactMap { day -> Day? in
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: first) else { return nil }
            let start = calendar.startOfDay(for: date)
            let practiced = practiceDays.contains(start)
            let obtained = obtainedDays.contains(start)
            return Day(start: start, number: day, mark: mark(practiced: practiced, obtained: obtained))
        }
        return Month(
            days: days,
            leadingBlanks: leading,
            practiceDayCount: days.filter { $0.mark == .practice || $0.mark == .both }.count,
            obtainedDayCount: days.filter { $0.mark == .obtained || $0.mark == .both }.count
        )
    }
}
