import PickupCore
import SwiftUI

struct TodayView: View {
    @Bindable var model: AppModel
    let showsReport: Bool
    @State private var showShort = false

    private var todaySessions: [SessionRecord] {
        model.sessions.filter {
            Calendar.current.isDateInToday($0.startedAt) &&
            (showShort || $0.duration(at: .now) >= model.settings.minimumVisibleSessionLength)
        }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image("PickupGlyph").renderingMode(.template).resizable()
                            .scaledToFit().frame(width: 28, height: 28).foregroundStyle(.tint)
                        Text("PICKUP").font(.caption.weight(.bold)).tracking(3)
                        Spacer()
                        Text(Date.now, format: .dateTime.month(.abbreviated).day())
                            .font(.caption).foregroundStyle(Theme.secondary)
                    }
                    Text("A little more\naware.")
                        .font(.system(size: 40, weight: .semibold, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Your phone time, in plain sight.").foregroundStyle(Theme.secondary)
                }.padding(.vertical, 12)
            }.listRowBackground(Color.clear).listRowSeparator(.hidden)

            if !model.activitiesEnabled || model.activityIssue {
                Section { LiveActivityAccessCard(enabled: model.activitiesEnabled) }
                    .listRowBackground(Theme.card)
            }

            if let active = model.activeSession {
                Section {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("SESSION IN PROGRESS", systemImage: "circle.fill")
                            .font(.caption.weight(.bold)).tracking(1).foregroundStyle(.tint)
                        HStack {
                            Text(active.startedAt, style: .timer)
                                .font(.system(size: 42, weight: .medium, design: .rounded)).monospacedDigit()
                            Spacer()
                            Button("End", role: .destructive) { Task { await model.endSession() } }
                                .buttonStyle(.bordered)
                        }
                        NavigationLink(value: active.id) { Text("View session").font(.subheadline) }
                    }.padding(.vertical, 8)
                }.listRowBackground(Theme.card)
            }

            Section {
                if showsReport { ReportHostView(model: model, kind: .daily(Date.now)) }
            } header: { Text("The whole picture") }
                .listRowBackground(Theme.card)

            Section {
                Toggle("Show short sessions", isOn: $showShort).font(.subheadline)
                if todaySessions.isEmpty {
                    ContentUnavailableView("Room to be present", systemImage: "leaf",
                        description: Text("Your sessions will appear here when a chosen app opens. Finish Setup to connect your automations."))
                        .padding(.vertical, 16)
                }
                ForEach(todaySessions) { session in
                    NavigationLink(value: session.id) { SessionRow(session: session) }
                }
            } header: { Text("Today's sessions") }
                .listRowBackground(Theme.card)
        }
        .scrollContentBackground(.hidden).background(Theme.background)
        .navigationTitle("Today").navigationBarTitleDisplayMode(.inline)
        .refreshable { await model.refresh(foreground: true) }
    }
}
