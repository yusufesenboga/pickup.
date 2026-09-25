import AppIntents

struct ShowTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Pickup: Show Timer"
    static let description = IntentDescription("Reveal the elapsed time for your active phone session.")
    static let openAppWhenRun = false

    @MainActor func perform() async throws -> some IntentResult {
        try await AppServices.shared.get().coordinator.showTimer()
        return .result()
    }
}
