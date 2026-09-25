import AppIntents

struct EndSessionIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Pickup: End Session"
    static let description = IntentDescription("Close your phone session and immediately dismiss its Live Activity.")
    static let openAppWhenRun = false

    @MainActor func perform() async throws -> some IntentResult {
        try await AppServices.shared.get().coordinator.end()
        return .result()
    }
}
