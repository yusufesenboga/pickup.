import AppIntents

struct StartSessionIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Pickup: Start Session"
    static let description = IntentDescription("Start or resume your phone session without opening Pickup.")
    static let openAppWhenRun = false

    @MainActor func perform() async throws -> some IntentResult {
        try await AppServices.shared.get().coordinator.start()
        return .result()
    }
}
