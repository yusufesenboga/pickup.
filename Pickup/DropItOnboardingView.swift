import FamilyControls
import PickupCore
import SwiftUI

struct DropItOnboardingView: View {
    @Bindable var model: AppModel
    var initialStep = 0
    var completion: () -> Void
    @State private var step = 0
    @State private var mood = BrainMood.lockedIn
    @State private var connecting = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if step > 0 {
                        Button { withAnimation(.easeInOut(duration: 0.2)) { step -= 1 } } label: {
                            Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).frame(width: 44, height: 44)
                                .background(Color(pickupHex: "F1EBE0"), in: RoundedRectangle(cornerRadius: 14))
                        }.buttonStyle(.plain).accessibilityLabel("back")
                    }
                    switch step {
                    case 1: permission
                    case 2: selection
                    case 3: meetBrain
                    default: welcome
                    }
                }.frame(minHeight: max(0, geometry.size.height - 60), alignment: .topLeading)
                    .padding(.horizontal, 28).padding(.top, step == 0 ? 20 : 10).padding(.bottom, 40)
            }.scrollIndicators(.hidden)
        }.background(DropIt.cream.ignoresSafeArea()).foregroundStyle(DropIt.ink)
            .onAppear { step = initialStep }
    }

    private var welcome: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 50)
            VStack(alignment: .leading, spacing: 28) {
                BrainView().frame(width: 210, height: 201.6).frame(maxWidth: .infinity).padding(.bottom, 20)
                VStack(alignment: .leading, spacing: 28) {
                    Text("drop it.").font(DropIt.display(64)).tracking(-1.28)
                    Text("the app that bullies you off your phone. with love. kinda.")
                        .font(DropIt.body(20, weight: .semibold)).foregroundStyle(Color(pickupHex: "4A4450"))
                        .multilineTextAlignment(.leading).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            Spacer(minLength: 80)
            Button("let’s lock in") { step = 1 }.buttonStyle(RaisedButtonStyle())
        }.frame(maxWidth: .infinity)
    }

    private var permission: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("let drop it see your screen time").font(DropIt.display(38)).fixedSize(horizontal: false, vertical: true)
            Text("we only see how long you’re on apps. not your dms. we literally could not care less about your dms.")
                .font(DropIt.body(17)).foregroundStyle(Color(pickupHex: "4A4450"))
            VStack(alignment: .leading, spacing: 10) {
                permissionRow("minutes per app", yes: true)
                permissionRow("app-open events, after shortcut setup", yes: true)
                permissionRow("your messages, photos, anything else", yes: false)
            }.padding(.top, 6)
            Spacer(minLength: 8)
            HStack(alignment: .bottom, spacing: 10) {
                BrainView().frame(width: 72, height: 69)
                Text("apple makes you tap “continue”. don’t overthink it.")
                    .font(DropIt.body(14, weight: .semibold)).padding(.horizontal, 14).padding(.vertical, 12).dropItCard(radius: 20)
            }
            Button(connecting ? "connecting…" : "connect screen time") {
                Task {
                    connecting = true
                    await model.authorizeScreenTime()
                    connecting = false
                    if model.screenTimeAuthorized { step = 2 }
                }
            }.buttonStyle(RaisedButtonStyle()).disabled(connecting)
            if !model.screenTimeAuthorized {
                Button("i’ll connect it later") { step = 2 }.font(DropIt.body(13, weight: .semibold))
                    .foregroundStyle(DropIt.secondary).frame(maxWidth: .infinity).padding(.top, 2)
            }
        }
    }

    private func permissionRow(_ text: String, yes: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: yes ? "checkmark" : "xmark").font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(pickupHex: yes ? "3F8A1F" : "D8283A")).frame(width: 36, height: 36)
                .background(Color(pickupHex: yes ? "E9FBE0" : "FFE6E8"), in: RoundedRectangle(cornerRadius: 12))
            Text(text).font(DropIt.body(15, weight: .semibold)).fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading)
        }.padding(16).dropItCard(radius: 20)
    }

    private var selection: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("which apps are cooking you?").font(DropIt.display(36)).fixedSize(horizontal: false, vertical: true)
            TrackedAppsGrid(model: model)
            Spacer(minLength: 10)
            Text("daily limit, all apps combined").font(DropIt.body(15, weight: .heavy))
            HStack(spacing: 8) {
                ForEach([30,60,90,120], id: \.self) { minutes in
                    Button {
                        var preferences = model.dropIt; preferences.dailyLimitMinutes = minutes; model.saveDropIt(preferences)
                    } label: {
                        Text(DropItDuration.minutes(TimeInterval(minutes * 60))).font(DropIt.body(14, weight: .heavy))
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .foregroundStyle(model.dropIt.dailyLimitMinutes == minutes ? .white : DropIt.ink)
                            .background(model.dropIt.dailyLimitMinutes == minutes ? DropIt.purple : .white, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(model.dropIt.dailyLimitMinutes == minutes ? DropIt.purple : DropIt.line, lineWidth: 2))
                    }.buttonStyle(.plain).accessibilityAddTraits(model.dropIt.dailyLimitMinutes == minutes ? .isSelected : [])
                }
            }
            Button("next") { step = 3 }.buttonStyle(RaisedButtonStyle()).padding(.top, 8)
        }
    }

    private var meetBrain: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("meet your brain").font(DropIt.display(36))
            Text("it lives in your Dynamic Island. the longer you scroll, the worse it gets. tap one to preview it up top.")
                .font(DropIt.body(15)).foregroundStyle(Color(pickupHex: "4A4450"))
            IslandPreview(seconds: mood.sampleSeconds).frame(maxWidth: .infinity).padding(.vertical, 4)
            ForEach(BrainMood.allCases, id: \.rawValue) { stage in
                BrainStageRow(mood: stage, selected: stage == mood, onboarding: true) { mood = stage }
            }
            Spacer(minLength: 8)
            Button(model.testingLiveActivity ? "turning it on…" : "turn it on") {
                Task { await model.finishOnboarding(); completion() }
            }.buttonStyle(RaisedButtonStyle()).disabled(model.testingLiveActivity)
        }
    }
}

struct TrackedAppsGrid: View {
    @Bindable var model: AppModel
    @State private var pickerPresented = false
    @State private var draft = FamilyActivitySelection()
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if model.hasTrackedApps {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(Array(model.applicationSelection.applicationTokens), id: \.self) { token in
                        Label(token).labelStyle(.verticalDropIt).frame(maxWidth: .infinity, minHeight: 98).padding(6)
                            .background(DropIt.lavender, in: RoundedRectangle(cornerRadius: 20))
                            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(DropIt.purple, lineWidth: 2))
                            .overlay(alignment: .topTrailing) { Image(systemName: "checkmark.circle.fill").foregroundStyle(DropIt.purple).padding(8) }
                    }
                    ForEach(Array(model.applicationSelection.categoryTokens), id: \.self) { token in
                        Label(token).labelStyle(.verticalDropIt).frame(maxWidth: .infinity, minHeight: 98).padding(6).dropItCard(radius: 20, color: DropIt.lavender)
                    }
                }
                if !model.applicationSelection.webDomainTokens.isEmpty {
                    Text("\(model.applicationSelection.webDomainTokens.count) websites selected").font(DropIt.body(14, weight: .bold))
                }
            } else {
                VStack(spacing: 16) {
                    BrainView(mood: .eepy).frame(width: 105, height: 101)
                    Text("pick your usual suspects").font(DropIt.display(21))
                    Text("choose apps or whole categories in Apple’s list. one selection covers your daily goal.")
                        .font(DropIt.body(14)).multilineTextAlignment(.center).foregroundStyle(DropIt.secondary)
                }.frame(maxWidth: .infinity).padding(24).dropItCard(radius: 24)
            }
            Button(model.hasTrackedApps ? "edit tracked apps" : "choose apps") {
                Task {
                    if !model.screenTimeAuthorized { await model.authorizeScreenTime() }
                    if model.screenTimeAuthorized { draft = model.applicationSelection; pickerPresented = true }
                }
            }.buttonStyle(RaisedButtonStyle(secondary: true))
        }
        .sheet(isPresented: $pickerPresented) {
            NavigationStack {
                FamilyActivityPicker(selection: $draft)
                    .navigationTitle("your usual suspects").navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("cancel") { pickerPresented = false } }
                        ToolbarItem(placement: .confirmationAction) { Button("done") { model.saveSelection(draft); pickerPresented = false } }
                    }
            }.tint(DropIt.purple)
        }
    }
}

private struct VerticalDropItLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 8) { configuration.icon.frame(width: 40, height: 40); configuration.title.font(DropIt.body(13, weight: .heavy)).lineLimit(2).multilineTextAlignment(.center) }
    }
}
private extension LabelStyle where Self == VerticalDropItLabelStyle {
    static var verticalDropIt: VerticalDropItLabelStyle { .init() }
}
