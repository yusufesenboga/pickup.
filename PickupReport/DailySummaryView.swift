import SwiftUI

struct DailySummaryView: View {
    let configuration: DailySummaryConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Screen Time (Apple)").font(.subheadline).foregroundStyle(.secondary)
                    Text(L10n.duration(configuration.appleTotal))
                        .font(.system(size: 36, weight: .medium, design: .rounded)).monospacedDigit()
                }
                Spacer()
                Image(systemName: "sun.max").font(.title2).foregroundStyle(Color(pickupHex: configuration.accentHex))
            }
            Divider()
            metric("Pickups (Apple)", value: configuration.pickups.formatted())
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Logged sessions")
                    Text(L10n.format("%d sessions", configuration.totals.sessionCount))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(configuration.snapshotIsComplete ? L10n.duration(configuration.totals.loggedTotal) : L10n.text("Unavailable"))
                    .monospacedDigit()
            }.font(.subheadline)
            metric("Untracked", value: configuration.snapshotIsComplete ?
                L10n.duration(configuration.totals.untracked) : L10n.text("Unavailable"), accent: true)
            if let first = configuration.firstPickup {
                HStack(spacing: 5) {
                    Text("First pickup")
                    Text(first, style: .time)
                }.font(.caption).foregroundStyle(.secondary)
            }
            if !configuration.snapshotIsComplete {
                Text("The shared session snapshot is unavailable or incomplete for this day. Open Pickup and refresh.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("Untracked is an estimate: Apple's total minus logged time. Resumed sessions include the brief gap between apps.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            if !configuration.hasSegments || configuration.appleTotal == 0 {
                Text("Apple has not reported usage yet, or today's total is zero.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }.padding(.vertical, 4).frame(maxWidth: .infinity, minHeight: 295, alignment: .topLeading)
            .background(Color.white)
            .foregroundStyle(DropIt.ink)
            .environment(\.colorScheme, .light)
    }

    private func metric(_ label: String, value: String, accent: Bool = false) -> some View {
        HStack {
            Text(L10n.text(label))
            Spacer()
            Text(value).monospacedDigit()
                .foregroundStyle(accent ? Color(pickupHex: configuration.accentHex) : .primary)
        }.font(.subheadline)
    }
}
