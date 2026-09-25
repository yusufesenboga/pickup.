#if DEBUG
import PickupCore
import SwiftUI

/// Deterministic reference fixtures for screenshot QA only. Never loaded by Release
/// and never written to preferences, session storage, or the Screen Time report.
@MainActor enum DesignPreviewRoute {
    static var current: String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-dropItPreview"), index + 1 < arguments.count else { return nil }
        return arguments[index + 1]
    }
    @ViewBuilder static func screen(_ name: String) -> some View {
        if name == "today" || name == "goal" { DesignDashboardPreview(goal: name == "goal") }
        else if name == "island" { DropItIslandView(model: AppModel()) {} }
        else if name == "lock" { DropItLockPreview(seconds: 1431) }
        else { DropItOnboardingView(model: AppModel(), initialStep: ["permission":1,"apps":2,"brain":3][name] ?? 0) {} }
    }
}

private struct DesignDashboardPreview: View {
    let goal: Bool
    @State private var choices = DropItPreferences()
    @State private var tab = 0
    private var usage: DropItUsage {
        let today = Calendar.current.startOfDay(for: .now)
        var days: [Date: TimeInterval] = [today: 134 * 60]
        for offset in 1...7 {
            if let day = Calendar.current.date(byAdding: .day, value: -offset, to: today) { days[day] = 190 * 60 }
        }
        return .init(dailyDurations: days, apps: [.init(name: "Instagram", duration: 58 * 60), .init(name: "TikTok", duration: 49 * 60), .init(name: "YouTube", duration: 27 * 60)], preferences: choices)
    }
    var body: some View {
        ScrollView {
            if goal {
                VStack(alignment: .leading, spacing: 22) {
                    Text("your goal").font(DropIt.display(30))
                    GoalControls(preferences: $choices)
                    DropItGoalStats(usage: usage)
                }.padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 28)
            } else { DropItTodayContent(usage: usage) }
        }.background(DropIt.cream.ignoresSafeArea()).foregroundStyle(DropIt.ink)
            .safeAreaInset(edge: .bottom, spacing: 0) { DropItTabBar(selection: $tab) }
            .onAppear { tab = goal ? 1 : 0 }
    }
}
#endif
