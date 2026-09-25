import SwiftUI

struct LiveActivityAccessCard: View {
    let enabled: Bool
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(enabled ? "Live Activity couldn't start" : "Live Activities are off", systemImage: "info.circle")
                .font(.headline)
            Text("Sessions still save. Enable Live Activities in Settings, or reopen a tracked app to retry.")
                .font(.subheadline).foregroundStyle(Theme.secondary)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }.buttonStyle(.bordered)
        }.padding(.vertical, 8)
    }
}
