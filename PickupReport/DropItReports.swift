import DeviceActivity
import PickupCore
import SwiftUI

struct DropItTodayReport: DeviceActivityReportScene {
    nonisolated let context: DeviceActivityReport.Context = .dropItToday
    nonisolated let content: @Sendable (DropItUsage) -> DropItTodayContent
    nonisolated func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> DropItUsage {
        await DropItReportBuilder.make(data)
    }
}

struct DropItGoalReport: DeviceActivityReportScene {
    nonisolated let context: DeviceActivityReport.Context = .dropItGoal
    nonisolated let content: @Sendable (DropItUsage) -> DropItGoalStats
    nonisolated func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> DropItUsage {
        await DropItReportBuilder.make(data)
    }
}

private enum DropItReportBuilder {
    nonisolated static func make(_ data: DeviceActivityResults<DeviceActivityData>) async -> DropItUsage {
        let now = Date.now
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        var days: [Date: TimeInterval] = [:]
        var apps: [String: TimeInterval] = [:]
        for await device in data {
            for await segment in device.activitySegments {
                let date = calendar.startOfDay(for: segment.dateInterval.start)
                days[date, default: 0] += segment.totalActivityDuration
                if date == today {
                    for await category in segment.categories {
                        for await app in category.applications {
                            let name = app.application.localizedDisplayName ?? "another app"
                            apps[name, default: 0] += app.totalActivityDuration
                        }
                    }
                }
            }
        }
        let preferences = DropItPreferences.decode(ReportPreferences.shared()?.string(for: DropItPreferences.storageKey))
        return DropItUsage(dailyDurations: days, apps: apps.map { .init(name: $0.key, duration: $0.value) }, now: now, preferences: preferences)
    }
}
