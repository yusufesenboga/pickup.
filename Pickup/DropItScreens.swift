import DeviceActivity
import FamilyControls
import PickupCore
import SwiftUI

struct DropItTodayView: View {
    @Bindable var model: AppModel
    var body: some View {
        ScrollView {
            if model.screenTimeAuthorized && model.hasTrackedApps {
                DropItReportHost(model: model, goal: false)
            } else {
                DropItTodayContent(usage: .init(dailyDurations: [:], apps: [], preferences: model.dropIt))
                TrackedAppsGrid(model: model).padding(.horizontal, 20).padding(.bottom, 28)
            }
        }.scrollIndicators(.hidden).refreshable { await model.refresh(foreground: true) }
    }
}

struct DropItGoalView: View {
    @Bindable var model: AppModel
    var settingsAction: () -> Void
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Text("your goal").font(DropIt.display(30))
                    Spacer()
                    Button(action: settingsAction) { Image(systemName: "gearshape").font(.system(size: 19, weight: .semibold)).frame(width: 44, height: 44) }
                        .buttonStyle(.plain).foregroundStyle(DropIt.secondary).accessibilityLabel("settings and setup")
                }
                GoalControls(preferences: Binding(get: { model.dropIt }, set: { model.saveDropIt($0) }))
                if model.screenTimeAuthorized && model.hasTrackedApps {
                    DropItReportHost(model: model, goal: true)
                } else {
                    DropItGoalStats(usage: .init(dailyDurations: [:], apps: [], preferences: model.dropIt))
                }
            }.padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 28)
        }.scrollIndicators(.hidden).refreshable { await model.refresh(foreground: true) }
    }
}

struct GoalControls: View {
    @Binding var preferences: DropItPreferences
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Text("daily limit, all tracked apps").font(DropIt.body(13, weight: .bold)).foregroundStyle(DropIt.muted)
                HStack {
                    limitButton("−", adjustment: -15)
                    Spacer(minLength: 8)
                    Text(DropItDuration.minutes(preferences.limit)).font(DropIt.display(50)).lineLimit(1).minimumScaleFactor(0.5)
                        .accessibilityValue("\(preferences.dailyLimitMinutes) minutes")
                    Spacer(minLength: 8)
                    limitButton("+", adjustment: 15)
                }
            }
            Text("instead, i’ll spend it on").font(DropIt.display(21))
            InterestFlow(spacing: 8) {
                ForEach(DropItPreferences.availableInterests, id: \.self) { interest in
                    let selected = preferences.interests.contains(interest)
                    Button {
                        if selected { preferences.interests.removeAll { $0 == interest } }
                        else { preferences.interests.append(interest) }
                    } label: {
                        Text(interest).font(DropIt.body(14, weight: .heavy)).padding(.horizontal, 16).frame(height: 44)
                            .foregroundStyle(selected ? .white : DropIt.ink)
                            .background(selected ? DropIt.purple : .white, in: Capsule())
                            .overlay(Capsule().strokeBorder(selected ? DropIt.purple : DropIt.line, lineWidth: 2))
                    }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
        }
    }
    private func limitButton(_ text: String, adjustment: Int) -> some View {
        Button {
            preferences.dailyLimitMinutes = min(720, max(15, preferences.dailyLimitMinutes + adjustment))
        } label: {
            Text(text).font(DropIt.body(26, weight: .heavy)).frame(width: 52, height: 52)
                .background(DropIt.cream, in: Circle()).overlay(Circle().strokeBorder(DropIt.line, lineWidth: 2))
                .compositingGroup().shadow(color: DropIt.line, radius: 0, y: 3)
        }.buttonStyle(.plain)
            .disabled(adjustment < 0 ? preferences.dailyLimitMinutes <= 15 : preferences.dailyLimitMinutes >= 720)
            .accessibilityLabel(adjustment < 0 ? "reduce daily limit by 15 minutes" : "increase daily limit by 15 minutes")
    }
}

struct InterestFlow: Layout {
    let spacing: CGFloat
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(subviews, width: proposal.width ?? 360).size
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let layout = arrange(subviews, width: bounds.width)
        for (index, point) in layout.points.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }
    private func arrange(_ subviews: Subviews, width: CGFloat) -> (size: CGSize, points: [CGPoint]) {
        var points: [CGPoint] = []; var x: CGFloat = 0; var y: CGFloat = 0; var rowHeight: CGFloat = 0
        for item in subviews {
            let size = item.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            points.append(CGPoint(x: x, y: y)); x += size.width + spacing; rowHeight = max(rowHeight, size.height)
        }
        return (CGSize(width: width, height: y + rowHeight), points)
    }
}

struct DropItReportHost: View {
    @Bindable var model: AppModel
    var goal: Bool
    var body: some View {
        DeviceActivityReport(goal ? .dropItGoal : .dropItToday, filter: filter)
            .id("\(goal)-\(model.reportRevision)")
            .frame(minHeight: goal ? 400 : 830)
            .background(DropIt.cream)
            .accessibilityLabel(goal ? "Screen Time goal report" : "Screen Time today report")
    }
    private var filter: DeviceActivityFilter {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let from = calendar.date(byAdding: .day, value: -30, to: today) ?? today
        let end = calendar.date(byAdding: .day, value: 1, to: today) ?? Date.now
        return DeviceActivityFilter(segment: .daily(during: DateInterval(start: from, end: end)),
                                    users: .all, devices: .init([.iPhone]),
                                    applications: model.applicationSelection.applicationTokens,
                                    categories: model.applicationSelection.categoryTokens,
                                    webDomains: model.applicationSelection.webDomainTokens)
    }
}

struct DropItSettingsView: View {
    @Bindable var model: AppModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink { ScrollView { TrackedAppsGrid(model: model).padding(20) }.background(DropIt.cream).navigationTitle("tracked apps") } label: { Label("tracked apps", systemImage: "square.grid.2x2") }
                    NavigationLink { SetupView(model: model) } label: { Label("shortcuts & island setup", systemImage: "bolt") }
                    NavigationLink { HistoryView(model: model) } label: { Label("session history", systemImage: "clock") }
                    NavigationLink { SettingsView(model: model) } label: { Label("timer settings & export", systemImage: "slider.horizontal.3") }
                }.listRowBackground(Color.white)
                Section {
                    Text("drop it.").font(DropIt.display(34))
                    Text("same brain. better boundaries.").font(DropIt.body(15)).foregroundStyle(DropIt.secondary)
                }.listRowBackground(Color.clear)
            }.scrollContentBackground(.hidden).background(DropIt.cream)
                .navigationDestination(for: UUID.self) { id in SessionDetailView(model: model, sessionID: id) }
                .navigationTitle("the boring stuff").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("done") { dismiss() } } }
        }.tint(DropIt.purple).font(DropIt.body()).preferredColorScheme(.light)
    }
}
