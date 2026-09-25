import DeviceActivity
import SwiftUI

struct ReportHostView: View {
    @Bindable var model: AppModel
    let kind: ReportKind
    @State private var refreshID = UUID()
    @State private var reportDate = Date.now

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if model.screenTimeAuthorized {
                HStack {
                    Label(kind.isDaily ? "DAILY OVERVIEW" : "APP ACTIVITY", systemImage: "chart.bar.xaxis")
                        .font(.caption.weight(.semibold)).foregroundStyle(Theme.secondary)
                    Spacer()
                    Button {
                        reportDate = .now
                        refreshID = UUID()
                    } label: { Image(systemName: "arrow.clockwise") }
                        .accessibilityLabel("Refresh report")
                }
                ZStack(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(0..<4) { index in
                            RoundedRectangle(cornerRadius: 5).fill(Theme.secondary.opacity(0.1))
                                .frame(width: index.isMultiple(of: 2) ? 190 : 140, height: 17)
                        }
                        Text("Waiting for Screen Time…").font(.caption).foregroundStyle(Theme.secondary)
                    }.accessibilityHidden(true)
                    DeviceActivityReport(kind.context, filter: kind.filter(at: reportDate))
                        .id("\(refreshID)-\(model.reportRevision)")
                        .frame(minHeight: kind.isDaily ? 295 : 390)
                }
                Text("Apple may take a few seconds to load or briefly show zeros. If the report stays blank, tap Refresh.")
                    .font(.caption2).foregroundStyle(Theme.secondary)
            } else {
                Label("Screen Time access needed", systemImage: "chart.bar.doc.horizontal")
                    .font(.headline)
                Text("See Apple's totals and app activity here. Your timer and session log work without this access.")
                    .font(.subheadline).foregroundStyle(Theme.secondary)
                Button("Allow Screen Time") { Task { await model.authorizeScreenTime() } }
                    .buttonStyle(.bordered)
            }
        }.padding(.vertical, 8)
    }
}
