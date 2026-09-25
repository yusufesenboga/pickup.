import DeviceActivity
import SwiftUI

struct SessionAppsReport: DeviceActivityReportScene {
    nonisolated let context: DeviceActivityReport.Context = .sessionApps
    nonisolated let content: @Sendable (SessionAppsConfiguration) -> SessionAppsView

    nonisolated func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> SessionAppsConfiguration {
        var durations: [String: TimeInterval] = [:]
        for await device in data {
            for await segment in device.activitySegments {
                for await category in segment.categories {
                    for await app in category.applications {
                        let name = app.application.localizedDisplayName ?? L10n.text("Unknown app")
                        durations[name, default: 0] += app.totalActivityDuration
                    }
                }
            }
        }
        let smallApps = durations.filter { $0.value > 0 && $0.value < 60 }
        var rows: [SessionAppsConfiguration.Row] = []
        for (name, duration) in durations where duration >= 60 {
            rows.append(.init(name: name, duration: duration))
        }
        rows.sort {
            if $0.duration == $1.duration { return $0.name < $1.name }
            return $0.duration > $1.duration
        }
        return SessionAppsConfiguration(rows: rows, otherCount: smallApps.count,
            otherDuration: smallApps.values.reduce(0, +),
            accentHex: ReportPreferences.shared()?.settings.accentHex ?? "B5F36C")
    }
}
