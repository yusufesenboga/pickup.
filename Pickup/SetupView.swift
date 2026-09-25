import SwiftUI

struct SetupView: View {
    @Bindable var model: AppModel
    @Environment(\.openURL) private var openURL
    @State private var shortcutFile: ExportItem?
    @State private var importError: String?
    @AppStorage("pickup.setup.appNames") private var setupAppNames = ""

    private var completedCount: Int {
        (model.screenTimeAuthorized ? 1 : 0) + (model.activitiesEnabled ? 1 : 0) +
        model.completedSteps.filter { (3...6).contains($0) }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("give your brain\na home.")
                        .font(DropIt.display(36))
                    Text("Connect your shortcuts once. Your brain comes along for the scroll.")
                        .foregroundStyle(Theme.secondary)
                    ProgressView(value: Double(completedCount), total: 6)
                    Text(L10n.format("%d of 6 steps complete", completedCount))
                        .font(.caption).foregroundStyle(Theme.secondary)
                }.padding(.vertical, 12)

                SetupStepCard(number: 1, title: L10n.text("Screen Time access"),
                    subtitle: L10n.text("Apple's totals give your logged sessions context. Access is optional; the timer works either way."),
                    complete: model.screenTimeAuthorized) {
                        Button(model.screenTimeAuthorized ? "Access granted" : "Allow Screen Time") {
                            Task { await model.authorizeScreenTime() }
                        }.buttonStyle(.bordered).disabled(model.screenTimeAuthorized)
                    }

                SetupStepCard(number: 2, title: L10n.text("Live Activities"),
                    subtitle: L10n.text("Keep a small reminder in the Dynamic Island, or on the Lock Screen on other iPhones."),
                    complete: model.activitiesEnabled) {
                        if model.activitiesEnabled {
                            Label("Live Activities allowed", systemImage: "checkmark.circle").foregroundStyle(.tint)
                            islandTestControls
                        } else { LiveActivityAccessCard(enabled: false) }
                        Text("The Island appears only during a session. Screen Time access and installing shortcuts do not start one. Test it here before finishing automation setup.")
                            .font(.caption).foregroundStyle(Theme.secondary)
                    }

                SetupStepCard(number: 3, title: L10n.text("Add the ready-made shortcuts"),
                    subtitle: L10n.text("The actions are already arranged. Add both shortcuts, then connect them to your apps below."),
                    complete: model.completedSteps.contains(3)) {
                        installShortcutButton(.start, title: "Add Start Shortcut")
                        installShortcutButton(.end, title: "Add End Shortcut")
                        Text("Tap Add Shortcut in Apple's preview. If these names are already in your library, keep your existing copies.")
                            .font(.caption).foregroundStyle(Theme.secondary)
                        if let wait = SetupConstants.shortcutManifest?.waitSeconds {
                            Text(L10n.format("Start Session → Wait %d seconds → Show Timer", wait))
                                .font(.caption).foregroundStyle(Theme.secondary)
                            if Int(model.settings.timerRevealDelay) != wait {
                                Text(L10n.format("Your preferred delay is %d seconds. After adding, edit the Start shortcut's Wait action to match.", Int(model.settings.timerRevealDelay)))
                                    .font(.caption).foregroundStyle(Theme.secondary)
                            }
                        }
                        Text("End Session ends the session immediately, with no Wait action.")
                            .font(.caption).foregroundStyle(Theme.secondary)
                        DisclosureGroup("Files and manual setup") {
                            VStack(alignment: .leading, spacing: 12) {
                                if SetupShortcut.start.fileURL != nil && SetupShortcut.end.fileURL != nil {
                                    Text("If a link won't open, share the prepared file to Shortcuts. If Shortcuts isn't listed, save it to Files and open it there.")
                                        .font(.caption).foregroundStyle(Theme.secondary)
                                    shortcutFileButton(.start, title: "Open Start Shortcut File")
                                    shortcutFileButton(.end, title: "Open End Shortcut File")
                                }
                                Text("Manual fallback: create Pickup Session with these actions:")
                                    .font(.caption).foregroundStyle(Theme.secondary)
                                instruction(1, "drop it.: Start Session")
                                instruction(2, L10n.format("Wait %d seconds", Int(model.settings.timerRevealDelay)))
                                instruction(3, "drop it.: Show Timer")
                                Text("Create Pickup End Session with just drop it.: End Session. Search for drop it. when adding actions; Wait is under Scripting.")
                                    .font(.caption).foregroundStyle(Theme.secondary)
                                openShortcutsButton
                            }.padding(.top, 8)
                        }.font(.subheadline)
                        completionToggle(3, "Both shortcuts are in my library")
                    }

                SetupStepCard(number: 4, title: L10n.text("When your apps open"),
                    subtitle: L10n.text("One automation covers several apps. Start with 3–5 you want to spend less time in."),
                    complete: model.completedSteps.contains(4)) {
                        if SetupShortcut.opened.installURL != nil || SetupShortcut.opened.fileURL != nil {
                            installShortcutButton(.opened, title: "Add App-Opened Automation")
                            Text("Review the apps in Apple's preview and enable the automation. Use one Opened automation for your chosen apps.")
                                .font(.caption).foregroundStyle(Theme.secondary)
                        }
                        automationFallback(.opened)
                        DisclosureGroup("Manual setup") {
                            VStack(alignment: .leading, spacing: 12) {
                                automationEditorInstruction
                                instruction(2, "Select several apps together and choose Is Opened")
                                instruction(3, "Select Run Immediately. Turn Notify When Run off if shown.")
                                instruction(4, "Add Run Shortcut → Pickup Session")
                                openShortcutsButton
                            }.padding(.top, 8)
                        }
                        Text("You don't need every app or a separate automation per app. Check each app you want in the same picker.")
                            .font(.caption).foregroundStyle(Theme.secondary)
                        completionToggle(4, "Opened automation created")
                    }

                SetupStepCard(number: 5, title: L10n.text("When your apps close"),
                    subtitle: L10n.text("Use the same apps as Opened so Pickup can end the session when you leave."),
                    complete: model.completedSteps.contains(5)) {
                        if SetupShortcut.closed.installURL != nil || SetupShortcut.closed.fileURL != nil {
                            installShortcutButton(.closed, title: "Add App-Closed Automation")
                            Text("Review the same app list, then enable the automation. Do not add a Wait action.")
                                .font(.caption).foregroundStyle(Theme.secondary)
                        }
                        automationFallback(.closed)
                        DisclosureGroup("Manual setup") {
                            VStack(alignment: .leading, spacing: 12) {
                                automationEditorInstruction
                                instruction(2, "Select the same apps together and choose Is Closed")
                                instruction(3, "Select Run Immediately. Turn Notify When Run off if shown.")
                                instruction(4, "Add Run Shortcut → Pickup End Session")
                                openShortcutsButton
                            }.padding(.top, 8)
                        }
                        completionToggle(5, "Closed automation created")
                    }

                SetupStepCard(number: 6, title: L10n.text("Take it for a spin"),
                    subtitle: L10n.text("Open a chosen app, stay there at least 10 seconds, then come back. Confirm a session appears below."),
                    complete: model.completedSteps.contains(6)) {
                        if model.lastStart == nil {
                            Text("No Start event has arrived yet. Run the Start shortcut or use Test Dynamic Island above. Then open a tracked app to check the automation.")
                                .font(.subheadline).foregroundStyle(Theme.secondary)
                        }
                        diagnostic("Last Start event", date: model.lastStart)
                        diagnostic("Last End event", date: model.lastEnd)
                        LabeledContent("Current session") {
                            Text(model.currentSession == nil ? "None" :
                                (model.activeSession == nil ? "Pending end" : "Active"))
                                .foregroundStyle(.tint)
                        }.font(.subheadline)
                        if let session = model.sessions.first { SessionRow(session: session) }
                        completionToggle(6, "I confirmed a session appeared")
                    }

                Text("Messages and Camera are not tracked unless you add them to both automations. The daily summary shows untracked time. Pickup does not detect unlocks or automatically know when you lock the phone.")
                    .font(.footnote).foregroundStyle(Theme.secondary).padding(.vertical, 12)
            }.padding(20)
        }.background(Theme.background).navigationTitle("Setup").navigationBarTitleDisplayMode(.inline)
            .sheet(item: $shortcutFile) { item in ShareSheet(url: item.url) }
            .alert("Couldn't Open Shortcut", isPresented: Binding(
                get: { importError != nil }, set: { if !$0 { importError = nil } }
            )) {
                Button("OK", role: .cancel) { importError = nil }
            } message: { Text(L10n.text(importError ?? "")) }
    }

    @ViewBuilder private func automationFallback(_ shortcut: SetupShortcut) -> some View {
        if shortcut.installURL != nil || shortcut.fileURL != nil {
            DisclosureGroup("File and prompt fallback") {
                VStack(alignment: .leading, spacing: 12) {
                    if shortcut.fileURL != nil {
                        shortcutFileButton(shortcut, title: "Open Automation File")
                        Text("Share the file to Shortcuts, or save it to Files and open it there.")
                            .font(.caption).foregroundStyle(Theme.secondary)
                    }
                    SetupAutomationGuide(shortcut: shortcut, appNames: $setupAppNames)
                }.padding(.top, 8)
            }
        } else {
            SetupAutomationGuide(shortcut: shortcut, appNames: $setupAppNames)
        }
    }

    @ViewBuilder private var automationEditorInstruction: some View {
        if #available(iOS 27, *) {
            instruction(1, "Shortcuts → new shortcut → editor → Automation → App")
        } else {
            instruction(1, "Shortcuts → Automation → + → App")
        }
    }

    private var islandTestControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                Task { await model.testLiveActivity() }
            } label: {
                Label(model.activeSession == nil ? "Test Dynamic Island" : "Show Timer Now", systemImage: "timer")
                    .foregroundStyle(Theme.background)
            }.buttonStyle(.borderedProminent).disabled(model.testingLiveActivity)
            Text("Starts or resumes a real session and shows its timer immediately. Go to the Home Screen to check the Island; end the session when finished.")
                .font(.caption).foregroundStyle(Theme.secondary)
            if model.liveActivityRunning {
                Label("Live Activity is running", systemImage: "checkmark.circle").foregroundStyle(.tint)
                Text("iOS controls where it appears. Check the Island or Lock Screen; press and hold the Island to expand it.")
                    .font(.caption).foregroundStyle(Theme.secondary)
            } else if model.activityIssue {
                LiveActivityAccessCard(enabled: model.activitiesEnabled)
            }
            if model.currentSession != nil || model.liveActivityRunning {
                Button("End Session", role: .destructive) { Task { await model.endSession() } }
                    .buttonStyle(.bordered).disabled(model.stoppingSession)
            }
        }
    }

    private func installShortcutButton(_ shortcut: SetupShortcut, title: String) -> some View {
        Button {
            importError = nil
            if let url = shortcut.installURL {
                openURL(url) { accepted in
                    if !accepted {
                        importError = "The install link couldn't open. Use the file fallback in this setup step."
                    }
                }
            } else if let url = shortcut.fileURL {
                shortcutFile = ExportItem(url: url)
            } else {
                importError = "The prepared shortcuts aren't available for this build. Use the manual setup below."
            }
        } label: {
            Label(L10n.text(title), systemImage: "plus.app")
                .foregroundStyle(Theme.background)
        }.buttonStyle(.borderedProminent)
    }

    private func shortcutFileButton(_ shortcut: SetupShortcut, title: String) -> some View {
        Button(L10n.text(title)) {
            if let url = shortcut.fileURL { shortcutFile = ExportItem(url: url) }
        }.buttonStyle(.bordered)
    }

    private var openShortcutsButton: some View {
        Button("Open Shortcuts") {
            if let url = URL(string: "shortcuts://") { openURL(url) }
        }.buttonStyle(.bordered)
    }

    private func instruction(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number, format: .number).monospacedDigit().foregroundStyle(.tint).frame(width: 18)
            Text(L10n.text(text)).fixedSize(horizontal: false, vertical: true)
        }.font(.subheadline)
    }

    private func completionToggle(_ step: Int, _ title: String) -> some View {
        Toggle(L10n.text(title), isOn: Binding(get: { model.completedSteps.contains(step) },
            set: { model.setStep(step, done: $0) })).font(.subheadline)
    }

    private func diagnostic(_ title: String, date: Date?) -> some View {
        LabeledContent(L10n.text(title)) {
            if let date { Text(date, format: .dateTime.hour().minute().second()) }
            else { Text("Not yet") }
        }.font(.subheadline)
    }
}
