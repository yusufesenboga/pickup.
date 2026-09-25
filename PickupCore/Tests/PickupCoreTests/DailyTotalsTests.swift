import Foundation
import Testing
import PickupCore

struct DailyTotalsTests {
    let start = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func clipsBothBoundariesAndCountsOverlappingSessions() {
        let day = DateInterval(start: start, duration: 86_400)
        let sessions = [
            SessionSnapshot(id: UUID(), startedAt: start.addingTimeInterval(-600), endedAt: start.addingTimeInterval(600)),
            SessionSnapshot(id: UUID(), startedAt: day.end.addingTimeInterval(-300), endedAt: day.end.addingTimeInterval(300)),
            SessionSnapshot(id: UUID(), startedAt: day.end, endedAt: day.end.addingTimeInterval(60))
        ]
        let totals = DailyTotals(sessions: sessions, day: day, now: day.end.addingTimeInterval(600), appleTotal: 1_000)
        #expect(totals.loggedTotal == 900)
        #expect(totals.sessionCount == 2)
        #expect(totals.untracked == 100)
    }

    @Test func activeClipsToNowAndUntrackedNeverGoesNegative() {
        let day = DateInterval(start: start, duration: 86_400)
        let totals = DailyTotals(sessions: [.init(id: UUID(), startedAt: start, endedAt: nil)],
                                 day: day, now: start.addingTimeInterval(600), appleTotal: 100)
        #expect(totals.loggedTotal == 600)
        #expect(totals.untracked == 0)
    }

    @Test func emptyAndInvalidIntervalsAddNoTime() {
        let day = DateInterval(start: start, duration: 86_400)
        let totals = DailyTotals(sessions: [.init(id: UUID(), startedAt: start.addingTimeInterval(100), endedAt: start)],
                                 day: day, now: day.end, appleTotal: 90)
        #expect(totals.loggedTotal == 0)
        #expect(totals.sessionCount == 0)
        #expect(totals.untracked == 90)
    }

    @Test func daylightSavingDayUsesCalendarLength() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Chicago"))
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 8)))
        let day = try #require(calendar.dateInterval(of: .day, for: date))
        #expect(day.duration == 23 * 3_600)
        let totals = DailyTotals(sessions: [.init(id: UUID(), startedAt: day.start, endedAt: day.end)],
                                 day: day, now: day.end, appleTotal: day.duration)
        #expect(totals.loggedTotal == day.duration)
    }

    @Test func snapshotIsBoundedAndPendingDoesNotKeepCounting() throws {
        let records = (0..<2_000).map { index in
            SessionRecord(startedAt: start.addingTimeInterval(-Double(index) * 120),
                          status: .pendingEnd, pendingEndAt: start.addingTimeInterval(-Double(index) * 120 + 10))
        }
        let encoded = try SnapshotCodec.encode(records.map(\.snapshot), now: start)
        let decoded = try SnapshotCodec.decode(encoded.data)
        #expect(encoded.data.count < 100_000)
        #expect(decoded.count < records.count)
        #expect(decoded.first?.endedAt != nil)
        #expect(encoded.coverageStart > start.addingTimeInterval(-90 * 86_400))
    }

    @Test func oldSnapshotsExcludedButHistoryAndLongActiveSessionRemain() throws {
        let old = SessionSnapshot(id: UUID(), startedAt: start.addingTimeInterval(-100 * 86_400),
                                  endedAt: start.addingTimeInterval(-99 * 86_400))
        let active = SessionSnapshot(id: UUID(), startedAt: old.startedAt, endedAt: nil)
        let encoded = try SnapshotCodec.encode([old, active], now: start)
        #expect(try SnapshotCodec.decode(encoded.data) == [active])
    }
}
