import Foundation

public struct DailyTotals: Equatable, Sendable {
    public let loggedTotal: TimeInterval
    public let sessionCount: Int
    public let untracked: TimeInterval

    public init(sessions: [SessionSnapshot], day: DateInterval, now: Date, appleTotal: TimeInterval) {
        var total: TimeInterval = 0
        var count = 0
        for session in sessions {
            let start = max(session.startedAt, day.start)
            let end = min(session.endedAt ?? now, day.end, now)
            if end > start {
                total += end.timeIntervalSince(start)
                count += 1
            }
        }
        loggedTotal = total
        sessionCount = count
        untracked = max(0, appleTotal - total)
    }
}
