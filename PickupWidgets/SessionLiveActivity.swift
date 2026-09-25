import ActivityKit
import PickupCore
import SwiftUI
import WidgetKit

struct SessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SessionActivityAttributes.self) { context in
            SessionActivityView(state: context.state).padding(18)
                .activityBackgroundTint(Color(pickupHex: "19171E"))
                .activitySystemActionForegroundColor(.white)
                .widgetURL(sessionURL(context.attributes.sessionID))
        } dynamicIsland: { context in
            let elapsed = context.state.elapsedAtUpdate ?? 0
            let mood = BrainMood(elapsed: elapsed)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    BrainView(mood: mood).frame(width: 46, height: 44)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.startedAt, style: .timer).font(DropIt.display(29)).monospacedDigit()
                        .foregroundStyle(Color(pickupHex: mood.timerHex)).frame(width: 112).multilineTextAlignment(.trailing)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("phone session").font(DropIt.body(12, weight: .semibold)).foregroundStyle(.white.opacity(0.55))
                        Text(BrainMood.roast(elapsed: elapsed)).font(DropIt.body(17, weight: .heavy)).foregroundStyle(.white)
                    }
                }
            } compactLeading: {
                BrainView(mood: mood).frame(width: 27, height: 26)
            } compactTrailing: {
                if context.state.phase == .timer {
                    Text(context.state.startedAt, style: .timer).monospacedDigit().font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(pickupHex: mood.timerHex)).frame(width: 62)
                }
            } minimal: {
                BrainView(mood: mood).frame(width: 27, height: 26)
            }
            .widgetURL(sessionURL(context.attributes.sessionID))
            .keylineTint(Color(pickupHex: mood.timerHex))
        }
    }
    private func sessionURL(_ id: UUID) -> URL? { URL(string: "pickup://session/\(id.uuidString)") }
}
