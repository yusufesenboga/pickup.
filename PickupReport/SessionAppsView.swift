import SwiftUI

struct SessionAppsView: View {
    let configuration: SessionAppsConfiguration

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Apps with usage during the hour(s) of this session").font(.headline)
                Text("Hourly Screen Time buckets may include activity before or after this session.")
                    .font(.caption).foregroundStyle(.secondary)
                if configuration.rows.isEmpty && configuration.otherCount == 0 {
                    Text("No app activity reported yet. Try refreshing after Screen Time updates.")
                        .font(.subheadline).foregroundStyle(.secondary).padding(.vertical, 16)
                }
                ForEach(configuration.rows) { row in
                    HStack {
                        Text(row.name).font(.subheadline)
                        Spacer()
                        Text(L10n.format("%d min", max(1, Int(row.duration / 60))))
                            .monospacedDigit().foregroundStyle(Color(pickupHex: configuration.accentHex))
                    }
                    Divider()
                }
                if configuration.otherCount > 0 {
                    HStack {
                        Text(L10n.format("Other (%d apps)", configuration.otherCount))
                        Spacer()
                        Text(L10n.duration(configuration.otherDuration)).monospacedDigit()
                    }.font(.subheadline).foregroundStyle(.secondary)
                }
            }.padding(.vertical, 4)
        }.frame(maxWidth: .infinity, minHeight: 390, alignment: .topLeading)
            .background(Color.white)
            .foregroundStyle(DropIt.ink)
            .environment(\.colorScheme, .light)
    }
}
