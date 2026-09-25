import PickupCore
import SwiftUI

struct SessionRow: View {
    let session: SessionRecord

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(spacing: 14) {
                Image(systemName: session.status == .active ? "waveform.path" : "iphone")
                    .font(.title3).foregroundStyle(.tint)
                    .frame(width: 42, height: 46)
                    .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 5) {
                        Text(session.startedAt, style: .time)
                        Text("–")
                        if let end = session.effectiveEnd { Text(end, style: .time) }
                        else { Text("Now").foregroundStyle(.tint) }
                    }.font(.subheadline.weight(.semibold))
                    Text(session.status == .pendingEnd ? "Closed · can resume briefly" : "Phone session")
                        .font(.caption).foregroundStyle(Theme.secondary)
                }
                Spacer(minLength: 4)
                Text(L10n.duration(session.duration(at: context.date)))
                    .font(.subheadline.monospacedDigit().weight(.medium))
            }
            .padding(.vertical, 5)
            .accessibilityElement(children: .combine)
        }
    }
}
