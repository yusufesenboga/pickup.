import Foundation

public struct DropItUsage: Sendable {
    public struct App: Identifiable, Sendable {
        public var id: String { name }
        public let name: String
        public let duration: TimeInterval
        public init(name: String, duration: TimeInterval) { self.name = name; self.duration = duration }
    }
    public let dailyDurations: [Date: TimeInterval]
    public let apps: [App]
    public let now: Date
    public let preferences: DropItPreferences
    public let calendar: Calendar
    public init(dailyDurations: [Date: TimeInterval], apps: [App], now: Date = .now,
                preferences: DropItPreferences, calendar: Calendar = .current) {
        self.dailyDurations = dailyDurations.filter { $0.value.isFinite && $0.value >= 0 }
        self.apps = apps.filter { $0.duration.isFinite && $0.duration > 0 }
            .sorted { $0.duration == $1.duration ? $0.name < $1.name : $0.duration > $1.duration }
        self.now = now; self.preferences = preferences; self.calendar = calendar
    }
    public var today: Date { calendar.startOfDay(for: now) }
    public var todayDuration: TimeInterval? { dailyDurations[today] }
    /// Today remains provisional until midnight. Missing days never count as wins.
    public var streak: Int {
        var count = 0
        for offset in 1...30 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today),
                  let duration = dailyDurations[day], duration <= preferences.limit else { break }
            count += 1
        }
        return count
    }
    public var priorWeekAverage: TimeInterval? {
        let values = (1...7).compactMap { offset -> TimeInterval? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return dailyDurations[date]
        }
        // A single partial day is a poor baseline. Require all seven completed days.
        guard values.count == 7 else { return nil }
        return values.reduce(0, +) / 7
    }
    public var dailyTimeBack: TimeInterval? { priorWeekAverage.map { max(0, $0 - preferences.limit) } }
    public var monthlyHoursBack: Int? { dailyTimeBack.map { Int(($0 * 30 / 3600).rounded()) } }
    public var weekDays: [Date] {
        let weekday = calendar.component(.weekday, from: today)
        let mondayOffset = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -mondayOffset, to: today) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }
}
