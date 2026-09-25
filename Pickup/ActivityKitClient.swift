import ActivityKit
import Foundation
import PickupCore

// Stateless adapter: Activity handles stay inside each nonisolated call. The
// coordinator's FIFO permit serializes all lifecycle operations across awaits.
struct ActivityKitClient: SessionActivityClient {
    private var currentActivities: [Activity<SessionActivityAttributes>] {
        Activity<SessionActivityAttributes>.activities.filter {
            $0.activityState == .active || $0.activityState == .stale
        }
    }

    func exists(for sessionID: UUID) -> Bool {
        currentActivities.contains { $0.attributes.sessionID == sessionID }
    }

    func start(session: SessionRecord, phase: ActivityPhase, settings: PickupSettings) throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw CocoaError(.featureUnsupported)
        }
        let content = ActivityContent(state: state(session, phase: phase, settings: settings),
                                      staleDate: session.startedAt.addingTimeInterval(SharedKeys.maximumActivityDuration))
        _ = try Activity.request(attributes: SessionActivityAttributes(sessionID: session.id),
                                 content: content, pushType: nil)
    }

    func update(session: SessionRecord, phase: ActivityPhase?, settings: PickupSettings) async {
        for activity in currentActivities where activity.attributes.sessionID == session.id {
            let state = state(session, phase: phase ?? activity.content.state.phase, settings: settings)
            await activity.update(ActivityContent(state: state,
                staleDate: session.startedAt.addingTimeInterval(SharedKeys.maximumActivityDuration)))
        }
    }

    func endAll() async {
        for activity in Activity<SessionActivityAttributes>.activities {
            await activity.end(activity.content, dismissalPolicy: .immediate)
        }
    }

    private func state(_ session: SessionRecord, phase: ActivityPhase,
                       settings: PickupSettings) -> SessionActivityAttributes.ContentState {
        .init(phase: phase, startedAt: session.startedAt, accentHex: settings.accentHex,
              showDetailInExpanded: settings.showDetailInExpanded,
              elapsedAtUpdate: max(0, Date.now.timeIntervalSince(session.startedAt)))
    }
}
