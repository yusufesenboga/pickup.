import SwiftUI
import UIKit

struct SetupAutomationGuide: View {
    let shortcut: SetupShortcut
    @Binding var appNames: String
    @Environment(\.openURL) private var openURL
    @State private var promptVisible = false
    @State private var copyNotice = false

    private var isOpening: Bool { shortcut == .opened }
    private var prompt: String {
        let apps = appNames.trimmingCharacters(in: .whitespacesAndNewlines)
        let selection = apps.isEmpty
            ? (isOpening
                ? L10n.text("Ask me during setup which installed apps to track. Use that selection in the App automation trigger.")
                : L10n.text("Use exactly the same apps as my Pickup Apps Opened automation. If you cannot read that selection, ask me during setup to choose the same apps."))
            : L10n.format("Use these installed apps in the trigger: %@. If a name is ambiguous or unavailable, ask me to resolve it during setup.", apps)
        if isOpening {
            return L10n.format("Create an iOS 27 shortcut named Pickup Apps Opened with an App automation trigger that runs whenever ANY selected app Is Opened. %@ Set Run Immediately, without asking before each run, and turn Notify When Run off if available. After the trigger, add one Run Shortcut action selecting the existing shortcut Pickup Session from my library. That shortcut already contains Start Session, Wait 50 seconds, and Show Timer. Do not add Open App, End Session, a repeating loop, or a second trigger. App selection is a setup choice, not an Ask Each Time action. If Pickup Session is unavailable, tell me to add it from Step 3 in Pickup before continuing. Do not substitute other actions. Show me the resulting trigger and actions so I can review and enable them.", selection)
        }
        return L10n.format("Create an iOS 27 shortcut named Pickup Apps Closed with an App automation trigger that runs whenever ANY selected app Is Closed. %@ Set Run Immediately, without asking before each run, and turn Notify When Run off if available. After the trigger add one Run Shortcut action selecting the existing shortcut Pickup End Session from my library. Do not add Wait, Start Session, Open App, a repeating loop, or a second trigger. App selection is a setup choice, not an Ask Each Time action. If Pickup End Session is unavailable, tell me to add it from Step 3 in Pickup before continuing. Do not substitute other actions. Show me the resulting trigger and action so I can review and enable them.", selection)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if #available(iOS 27, *) {
                if shortcut.installURL == nil && shortcut.fileURL == nil {
                    Text("Use Describe a Shortcut to build the automation from a prepared prompt.")
                        .font(.subheadline)
                }
                TextField("App names, optional (e.g. Instagram, YouTube)", text: $appNames, axis: .vertical)
                    .textFieldStyle(.roundedBorder).autocorrectionDisabled()
                Text("Use the same app list for Opened and Closed. Leave this blank to choose during setup.")
                    .font(.caption).foregroundStyle(Theme.secondary)
                Button {
                    UIPasteboard.general.setItems([["public.utf8-plain-text": prompt]],
                        options: [.localOnly: true, .expirationDate: Date.now.addingTimeInterval(600)])
                    copyNotice = true
                    if let url = URL(string: "shortcuts://create-shortcut") { openURL(url) }
                } label: {
                    Label("Copy Prompt & Open Shortcuts", systemImage: "doc.on.clipboard")
                }.buttonStyle(.bordered)
                if copyNotice {
                    Text("Prompt copied. Paste it into Describe a Shortcut, then review the selected apps and enable the automation. Copying does not complete setup.")
                        .font(.caption).foregroundStyle(Theme.secondary)
                }
                DisclosureGroup("Read the prompt", isExpanded: $promptVisible) {
                    Text(prompt).textSelection(.enabled).font(.caption).padding(.top, 6)
                }.font(.subheadline)
                Text("Apple may omit actions even when its summary describes them. Open Edit and check the actual trigger and Run Shortcut action before enabling. Do not enable another automation for the same event.")
                    .font(.caption).foregroundStyle(Theme.secondary)
            }
        }
    }
}
