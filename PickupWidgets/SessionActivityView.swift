import PickupCore
import SwiftUI

struct SessionActivityView: View {
    let state: SessionActivityAttributes.ContentState
    var body: some View {
        let elapsed = state.elapsedAtUpdate ?? 0
        let mood = BrainMood(elapsed: elapsed)
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                BrainView(mood: mood).frame(width: 58, height: 56)
                VStack(alignment: .leading, spacing: 5) {
                    Text("phone session · drop it").font(DropIt.body(12, weight: .bold)).foregroundStyle(.white.opacity(0.5))
                    Text(mood.lockMessage(elapsed: elapsed)).font(DropIt.body(15, weight: .heavy)).foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Text(state.startedAt, style: .timer).font(DropIt.display(29)).monospacedDigit()
                    .foregroundStyle(Color(pickupHex: mood.timerHex)).multilineTextAlignment(.trailing)
                    .frame(width: 92).minimumScaleFactor(0.65).lineLimit(1)
            }
            StageProgress(mood: mood)
        }
    }
}
