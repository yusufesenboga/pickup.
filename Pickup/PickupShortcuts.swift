import AppIntents

struct PickupShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: StartSessionIntent(), phrases: ["Start a session in \(.applicationName)"],
                    shortTitle: "Start Session", systemImageName: "play.fill")
        AppShortcut(intent: ShowTimerIntent(), phrases: ["Show my timer in \(.applicationName)"],
                    shortTitle: "Show Timer", systemImageName: "timer")
        AppShortcut(intent: EndSessionIntent(), phrases: ["End my session in \(.applicationName)"],
                    shortTitle: "End Session", systemImageName: "stop.fill")
    }
}
