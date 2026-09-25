import DeviceActivity
import ExtensionKit
import AppIntents
import SwiftUI

@main struct PickupReport: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        DropItTodayReport { DropItTodayContent(usage: $0) }
        DropItGoalReport { DropItGoalStats(usage: $0) }
        SessionAppsReport { configuration in SessionAppsView(configuration: configuration) }
        DailySummaryReport { configuration in DailySummaryView(configuration: configuration) }
    }
}
