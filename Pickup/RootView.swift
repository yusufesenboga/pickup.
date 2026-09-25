import SwiftUI

struct RootView: View {
    @Bindable var model: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = 0
    @State private var path: [UUID] = []
    @State private var initialized = false
    @State private var settingsPresented = false

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                #if DEBUG
                if let preview = DesignPreviewRoute.current { DesignPreviewRoute.screen(preview) }
                else { appContent }
                #else
                appContent
                #endif
            }
            .navigationDestination(for: UUID.self) { id in SessionDetailView(model: model, sessionID: id).toolbar(.visible, for: .navigationBar) }
            .toolbar(.hidden, for: .navigationBar)
        }.background(DropIt.cream).foregroundStyle(DropIt.ink)
        .sheet(isPresented: $settingsPresented) { DropItSettingsView(model: model) }
        .alert("a little help here", isPresented: Binding(
            get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
                Button("got it", role: .cancel) { model.errorMessage = nil }
            } message: { Text(model.errorMessage ?? "") }
        .task {
            #if DEBUG
            if DesignPreviewRoute.current != nil { initialized = true; return }
            #endif
            await model.refresh(foreground: true)
            initialized = true
            guard model.storageReady else { return }
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(2)) } catch { break }
                guard scenePhase == .active else { continue }
                let pendingExpired = model.currentSession?.pendingEndAt.map {
                    Date.now.timeIntervalSince($0) > model.settings.gracePeriod
                } ?? false
                await model.refresh(foreground: pendingExpired)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await model.refresh(foreground: true) } }
        }
        .onOpenURL { url in
            guard url.scheme == "pickup", url.host == "session" else { return }
            Task {
                await model.refresh()
                let id = UUID(uuidString: url.lastPathComponent) ?? model.currentSession?.id
                if let id, model.sessions.contains(where: { $0.id == id }) {
                    selectedTab = 2; path = [id]
                }
            }
        }
    }

    @ViewBuilder private var appContent: some View {
        if !initialized { DropIt.cream.ignoresSafeArea().overlay { ProgressView().tint(DropIt.purple) } }
        else if !model.dropIt.onboardingComplete {
            DropItOnboardingView(model: model) { selectedTab = 2 }
        } else {
            Group {
                switch selectedTab {
                case 1: DropItGoalView(model: model) { settingsPresented = true }
                case 2: DropItIslandView(model: model) { settingsPresented = true }
                default: DropItTodayView(model: model)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DropIt.cream.ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) { DropItTabBar(selection: $selectedTab) }
        }
    }
}

struct DropItTabBar: View {
    @Binding var selection: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Button { selection = index } label: {
                    HStack(spacing: 7) {
                        if index == 2 { BrainView().frame(width: 14, height: 14).accessibilityHidden(true) }
                        else { Image(systemName: index == 0 ? "circle.fill" : "flame.fill").font(.system(size: 10)).foregroundStyle(index == 0 ? DropIt.purple : DropIt.orange) }
                        Text(["today", "goal", "island"][index]).font(DropIt.body(15, weight: .heavy))
                    }.frame(maxWidth: .infinity, minHeight: 46)
                        .foregroundStyle(selection == index ? DropIt.purpleShadow : DropIt.secondary)
                        .background(selection == index ? DropIt.lavender : .clear, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(selection == index ? DropIt.purple : .clear, lineWidth: 2))
                }.buttonStyle(.plain).accessibilityAddTraits(selection == index ? .isSelected : [])
            }
        }.padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 4)
            .background(DropIt.cream.ignoresSafeArea(edges: .bottom))
            .overlay(alignment: .top) { DropIt.line.frame(height: 2) }
    }
}
