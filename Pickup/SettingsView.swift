import PickupCore
import SwiftUI

struct SettingsView: View {
    @Bindable var model: AppModel
    @State private var confirmsDeletion = false
    @State private var exportURL: URL?
    @State private var exportItem: ExportItem?

    var body: some View {
        Form {
            Section {
                Toggle("Show timer immediately", isOn: setting(\.showTimerImmediately))
                secondsStepper("Timer reveal delay", keyPath: \.timerRevealDelay, range: 0...300, step: 5)
                Text("This delay is a tutorial reference only. Change the Wait action in your shortcut to match. If Wait is unreliable, enable Show timer immediately.")
                    .font(.caption).foregroundStyle(Theme.secondary)
                secondsStepper("Grace period", keyPath: \.gracePeriod, range: 0...300, step: 5)
                Text("Closing a tracked app clears the Island immediately. Reopening within the grace period resumes the same session. Turning off the Island here ends the session completely.")
                    .font(.caption).foregroundStyle(Theme.secondary)
            } header: { Text("Advanced") }.listRowBackground(Theme.card)

            Section("Your data") {
                Button("Export sessions as JSON") { export(csv: false) }
                Button("Export sessions as CSV") { export(csv: true) }
                Button("Delete all data", role: .destructive) { confirmsDeletion = true }
            }.listRowBackground(Theme.card)

            Section("About") {
                LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nothing leaves your phone.").font(.headline)
                    Text("No accounts, servers, analytics, or cloud sync. Screen Time stays inside Apple's report extension. Exporting is always your choice.")
                        .font(.footnote).foregroundStyle(Theme.secondary)
                }.padding(.vertical, 8)
            }.listRowBackground(Theme.card)
        }.scrollContentBackground(.hidden).background(Theme.background).navigationTitle("Settings")
            .confirmationDialog("Delete all drop it. data?", isPresented: $confirmsDeletion, titleVisibility: .visible) {
                Button("Delete all data", role: .destructive) { Task { await model.deleteAll() } }
            } message: { Text("This permanently deletes sessions, resets your goals, app choices, settings and setup progress, and ends the Live Activity. Apple Screen Time and your Shortcuts automations are not deleted.") }
            .sheet(item: $exportItem, onDismiss: clearExport) { item in
                ShareSheet(url: item.url)
            }
    }

    private func setting<Value: Sendable>(_ keyPath: WritableKeyPath<PickupSettings, Value>) -> Binding<Value> {
        Binding(get: { model.settings[keyPath: keyPath] }, set: { value in
            var settings = model.settings
            settings[keyPath: keyPath] = value
            model.settings = settings
            Task { await model.saveSettings(settings) }
        })
    }

    private func secondsStepper(_ title: String, keyPath: WritableKeyPath<PickupSettings, Double>,
                                range: ClosedRange<Double>, step: Double) -> some View {
        Stepper(value: setting(keyPath), in: range, step: step) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.text(title))
                Text(L10n.format("%d seconds", Int(model.settings[keyPath: keyPath])))
                    .font(.caption).foregroundStyle(Theme.secondary)
            }
        }
    }

    private func export(csv: Bool) {
        Task {
            do {
                let records = try await AppServices.shared.get().coordinator.sessions()
                let data = try csv ? SessionExporter.csv(records, now: .now) : SessionExporter.json(records)
                let directory = FileManager.default.temporaryDirectory.appendingPathComponent("PickupExport-\(UUID())")
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                let url = directory.appendingPathComponent(csv ? "Pickup-sessions.csv" : "Pickup-sessions.json")
                try data.write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen])
                exportURL = url
                exportItem = ExportItem(url: url)
            } catch { model.errorMessage = error.localizedDescription }
        }
    }

    private func clearExport() {
        if let exportURL { try? FileManager.default.removeItem(at: exportURL.deletingLastPathComponent()) }
        exportURL = nil
    }
}
