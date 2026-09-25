import DeviceActivity
import PickupCore
import SwiftUI

struct DailySummaryReport: DeviceActivityReportScene {
    nonisolated let context: DeviceActivityReport.Context = .dailySummary
    nonisolated let content: @Sendable (DailySummaryConfiguration) -> DailySummaryView

    nonisolated func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> DailySummaryConfiguration {
        var appleTotal: TimeInterval = 0
        var pickups = 0
        var firstPickup: Date?
        var reportDay: DateInterval?
        var hasSegments = false
        for await device in data {
            for await segment in device.activitySegments {
                hasSegments = true
                reportDay = Calendar.current.dateInterval(of: .day, for: segment.dateInterval.start)
                appleTotal += segment.totalActivityDuration
                // Current SDK has no segment.numberOfPickups. Include device pickups
                // with no app activity as well as app-attributed pickups.
                pickups += segment.totalPickupsWithoutApplicationActivity
                if let first = segment.firstPickup { firstPickup = min(firstPickup ?? first, first) }
                for await category in segment.categories {
                    for await app in category.applications { pickups += app.numberOfPickups }
                }
            }
        }
        let now = Date.now
        let day = reportDay ?? Calendar.current.dateInterval(of: .day, for: now)
            ?? DateInterval(start: Calendar.current.startOfDay(for: now), duration: 86_400)
        let preferences = ReportPreferences.shared()
        let decoded = try? SnapshotCodec.decode(preferences?.data(for: SharedKeys.sessionsSnapshot))
        let coverage = preferences?.date(for: SharedKeys.snapshotCoverageStart)
        let complete = decoded != nil && coverage.map { $0 <= day.start } == true
        let totals = DailyTotals(sessions: decoded ?? [], day: day, now: now, appleTotal: appleTotal)
        return DailySummaryConfiguration(appleTotal: appleTotal, pickups: pickups, firstPickup: firstPickup,
            totals: totals, snapshotIsComplete: complete, hasSegments: hasSegments,
            accentHex: preferences?.settings.accentHex ?? "B5F36C")
    }
}
