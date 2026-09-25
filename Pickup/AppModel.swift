import ActivityKit
import FamilyControls
import Foundation
import Observation
import PickupCore

@MainActor @Observable final class AppModel {
    var sessions: [SessionRecord] = []
    var settings = PickupSettings()
    var errorMessage: String?
    var screenTimeAuthorized = false
    var activitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
    var lastStart: Date?
    var lastEnd: Date?
    var activityIssue = false
    var liveActivityRunning = false
    var testingLiveActivity = false
    var stoppingSession = false
    var completedSteps: Set<Int> = []
    var reportRevision = UUID()
    var dropIt = DropItPreferences()
    var applicationSelection = FamilyActivitySelection()

    var hasTrackedApps: Bool {
        !applicationSelection.applicationTokens.isEmpty || !applicationSelection.categoryTokens.isEmpty || !applicationSelection.webDomainTokens.isEmpty
    }

    func saveDropIt(_ choices: DropItPreferences) {
        dropIt = DropItPreferences(dailyLimitMinutes: choices.dailyLimitMinutes, interests: choices.interests,
                                  onboardingComplete: choices.onboardingComplete)
        do {
            try AppServices.shared.get().preferences.setString(dropIt.encoded, for: DropItPreferences.storageKey)
            reportRevision = UUID()
        } catch { errorMessage = error.localizedDescription }
    }

    func saveSelection(_ selection: FamilyActivitySelection) {
        do {
            let data = try JSONEncoder().encode(selection)
            try AppServices.shared.get().preferences.setString(String(data: data, encoding: .utf8), for: DropItPreferences.selectionKey)
            applicationSelection = selection
            reportRevision = UUID()
        } catch { errorMessage = error.localizedDescription }
    }

    func finishOnboarding() async {
        var choices = dropIt; choices.onboardingComplete = true; saveDropIt(choices)
        // Drop It shows its timer immediately. Existing Shortcut names stay stable.
        var updated = settings; updated.showTimerImmediately = true; updated.accentHex = "7B4DFF"
        await saveSettings(updated)
        await testLiveActivity()
    }

    var activeSession: SessionRecord? { sessions.first { $0.status == .active } }
    var currentSession: SessionRecord? { sessions.first { $0.status != .ended } }
    var storageReady: Bool { (try? AppServices.shared.get()) != nil }

    // MARK: Refresh

    func refresh(foreground: Bool = false) async {
        do {
            let services = try AppServices.shared.get()
            if foreground {
                try await services.coordinator.foreground()
                reportRevision = UUID()
            }
            sessions = try await services.coordinator.sessions()
            settings = services.preferences.settings
            dropIt = DropItPreferences.decode(services.preferences.string(for: DropItPreferences.storageKey))
            if let string = services.preferences.string(for: DropItPreferences.selectionKey),
               let data = string.data(using: .utf8),
               let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
                applicationSelection = selection
            } else { applicationSelection = FamilyActivitySelection() }
            lastStart = services.preferences.date(for: SharedKeys.lastStartEventAt)
            lastEnd = services.preferences.date(for: SharedKeys.lastEndEventAt)
            activityIssue = services.preferences.string(for: SharedKeys.activityIssue) != nil
            completedSteps = Set(services.preferences.integers(for: SharedKeys.completedSetupSteps))
            screenTimeAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
            activitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
            liveActivityRunning = Activity<SessionActivityAttributes>.activities.contains {
                ($0.activityState == .active || $0.activityState == .stale)
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func authorizeScreenTime() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            await refresh()
        } catch {
            errorMessage = L10n.text("Screen Time access was not granted. Your timer and session log still work. You can retry here at any time.")
            await refresh()
        }
    }

    // MARK: Mutations

    // Uses the real session path so setup tests exercise persistence and ActivityKit.
    // No permission/automation completion is inferred from a successful request.
    func testLiveActivity() async {
        guard !testingLiveActivity else { return }
        testingLiveActivity = true
        defer { testingLiveActivity = false }
        do {
            let coordinator = try AppServices.shared.get().coordinator
            if activeSession == nil { try await coordinator.start() }
            try await coordinator.showTimer()
            await refresh()
            if !liveActivityRunning {
                errorMessage = L10n.text("The session started, but iOS did not create its Live Activity. Check drop it.’s Live Activities setting and try again.")
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func endSession() async {
        guard !stoppingSession else { return }
        stoppingSession = true
        defer { stoppingSession = false }
        do {
            try await AppServices.shared.get().coordinator.stop()
            await refresh()
            reportRevision = UUID()
        } catch { errorMessage = error.localizedDescription }
    }

    func saveSettings(_ settings: PickupSettings) async {
        do {
            try AppServices.shared.get().preferences.setSettings(settings)
            await refresh(foreground: true)
        } catch { errorMessage = error.localizedDescription }
    }

    func setStep(_ step: Int, done: Bool) {
        if done { completedSteps.insert(step) } else { completedSteps.remove(step) }
        if let services = try? AppServices.shared.get() {
            services.preferences.setIntegers(Array(completedSteps).sorted(), for: SharedKeys.completedSetupSteps)
        }
    }

    func delete(ids: Set<UUID>) async {
        do {
            try await AppServices.shared.get().coordinator.delete(ids: ids)
            await refresh()
            reportRevision = UUID()
        } catch { errorMessage = error.localizedDescription }
    }

    func deleteAll() async {
        do {
            try await AppServices.shared.get().coordinator.deleteAll()
            await refresh()
            reportRevision = UUID()
        } catch { errorMessage = error.localizedDescription }
    }
}
