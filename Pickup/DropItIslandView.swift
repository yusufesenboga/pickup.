import PickupCore
import SwiftUI

struct DropItIslandView: View {
    @Bindable var model: AppModel
    var settingsAction: () -> Void
    @State private var seconds = BrainMood.rotten.sampleSeconds
    @State private var expanded = false
    @State private var selectedRoast: String?
    @State private var lockPreview = false
    @State private var setupPresented = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if model.currentSession != nil || model.liveActivityRunning {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(model.liveActivityRunning ? "your brain is live" : "session controls").font(DropIt.display(22))
                            Button("turn off Dynamic Island") { Task { await model.endSession() } }
                                .buttonStyle(RaisedButtonStyle(secondary: true)).disabled(model.stoppingSession)
                            if model.activeSession != nil && model.lastEnd == nil {
                                Text("no Close event has arrived yet. connect the App Closed shortcut to stop the Island automatically when you leave a tracked app.")
                                    .font(DropIt.body(13)).foregroundStyle(DropIt.secondary)
                                Button("set up automatic stopping") { setupPresented = true }
                                    .font(DropIt.body(14, weight: .bold)).foregroundStyle(DropIt.purple)
                            }
                        }.padding(16).dropItCard(radius: 20)
                    }
                    Button { withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() } } label: {
                        IslandPreview(seconds: seconds, expanded: expanded, roast: selectedRoast).frame(maxWidth: .infinity)
                    }.buttonStyle(.plain).accessibilityHint("toggle compact and expanded preview").id("preview")
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("your brain on the island").font(DropIt.display(30))
                            Text("tap a stage, then tap the island to expand it. connect your shortcuts to bring it along when you scroll.")
                                .font(DropIt.body(14)).foregroundStyle(Color(pickupHex: "4A4450"))
                        }
                        Button(action: settingsAction) { Image(systemName: "gearshape").font(.system(size: 18)).frame(width: 28, height: 34) }
                            .buttonStyle(.plain).foregroundStyle(DropIt.secondary).accessibilityLabel("settings and setup")
                    }
                    HStack(spacing: 4) {
                        previewSegment("compact", selected: !expanded) { expanded = false }
                        previewSegment("expanded", selected: expanded) { expanded = true }
                    }.padding(4).background(Color(pickupHex: "F1EBE0"), in: RoundedRectangle(cornerRadius: 16))
                    ForEach(BrainMood.allCases, id: \.rawValue) { stage in
                        BrainStageRow(mood: stage, selected: BrainMood(elapsed: TimeInterval(seconds)) == stage) { seconds = stage.sampleSeconds; selectedRoast = nil }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("island roasts").font(DropIt.display(22))
                        Text("what the island says at each minute mark. tap to preview.")
                            .font(DropIt.body(14)).foregroundStyle(Color(pickupHex: "4A4450"))
                    }.padding(.top, 8)
                    ForEach(BrainMood.roastMinutes, id: \.self) { minute in
                        Button {
                            seconds = minute * 60; expanded = true; selectedRoast = BrainMood.roast(elapsed: TimeInterval(seconds))
                            withAnimation { proxy.scrollTo("preview", anchor: .top) }
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(minute) min").font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color(pickupHex: BrainMood(elapsed: TimeInterval(minute * 60)).timerHex))
                                    .frame(width: 58).padding(.vertical, 5).background(.black, in: RoundedRectangle(cornerRadius: 10))
                                Text(BrainMood.roast(elapsed: TimeInterval(minute * 60))).font(DropIt.body(14, weight: .bold))
                                    .padding(.top, 3).frame(maxWidth: .infinity, alignment: .leading).fixedSize(horizontal: false, vertical: true)
                            }.padding(.horizontal, 14).padding(.vertical, 12).dropItCard(radius: 20)
                        }.buttonStyle(.plain)
                    }
                    Button("preview on lock screen") { lockPreview = true }.buttonStyle(RaisedButtonStyle(secondary: true)).padding(.bottom, 8)
                    liveControls
                }.padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 28)
            }.scrollIndicators(.hidden)
        }
        .fullScreenCover(isPresented: $lockPreview) { DropItLockPreview(seconds: seconds) }
        .sheet(isPresented: $setupPresented) {
            NavigationStack {
                SetupView(model: model).toolbar { ToolbarItem(placement: .confirmationAction) { Button("done") { setupPresented = false } } }
            }.tint(DropIt.purple).preferredColorScheme(.light)
        }
    }
    private func previewSegment(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(DropIt.body(14, weight: .heavy)).frame(maxWidth: .infinity, minHeight: 40)
                .background(selected ? .white : .clear, in: RoundedRectangle(cornerRadius: 12))
                .compositingGroup().shadow(color: selected ? Color(pickupHex: "E3DBCD") : .clear, radius: 0, y: 2)
        }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
    }
    private var liveControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Circle().fill(model.liveActivityRunning ? Color(pickupHex: "55A570") : DropIt.muted).frame(width: 8, height: 8)
                Text(model.liveActivityRunning ? "your brain is live" : "ready for the real thing?").font(DropIt.display(20))
            }
            Button(model.liveActivityRunning ? "refresh live island" : "try my Dynamic Island") { Task { await model.testLiveActivity() } }
                .buttonStyle(RaisedButtonStyle()).disabled(model.testingLiveActivity)
            Button("connect my shortcuts") { setupPresented = true }.buttonStyle(RaisedButtonStyle(secondary: true))
            DisclosureGroup("how live updates work") {
                Text("the timer keeps ticking on its own. the brain and roast refresh when a session action runs or you return here. automatic app-open and app-close tracking needs the shortcuts setup.")
                    .font(DropIt.body(13)).foregroundStyle(DropIt.secondary).padding(.top, 8)
            }.font(DropIt.body(13, weight: .bold))
        }.padding(.top, 12)
    }
}

struct DropItLockPreview: View {
    let seconds: Int
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            Color(pickupHex: "2B2733").ignoresSafeArea()
            Canvas { context, size in
                for index in -12...20 {
                    var p = Path(); let x = CGFloat(index) * 40
                    p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x + size.height, y: size.height))
                    context.stroke(p, with: .color(.white.opacity(0.035)), lineWidth: 20)
                }
            }.ignoresSafeArea()
            VStack(spacing: 8) {
                HStack {
                    Text("lock screen preview").font(DropIt.body(13, weight: .bold)).foregroundStyle(.white.opacity(0.65))
                    Spacer()
                    Button { dismiss() } label: { Image(systemName: "xmark").font(.system(size: 14, weight: .bold)).frame(width: 36, height: 36).background(.white.opacity(0.12), in: Circle()) }
                        .accessibilityLabel("close preview")
                }.padding(.horizontal, 24)
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day())).font(.system(size: 20, weight: .medium)).padding(.top, 35)
                Text(Date.now.formatted(.dateTime.hour(.defaultDigits(amPM: .omitted)).minute())).font(.system(size: 82, weight: .semibold, design: .rounded)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
                Spacer()
                LockCardPreview(seconds: seconds).padding(.horizontal, 16)
                Text("tap to go back").font(DropIt.body(14, weight: .semibold)).foregroundStyle(.white.opacity(0.6)).padding(.top, 16).padding(.bottom, 44)
            }
        }.foregroundStyle(.white).preferredColorScheme(.dark).onTapGesture { dismiss() }
    }
}

struct LockCardPreview: View {
    let seconds: Int
    var body: some View {
        let mood = BrainMood(elapsed: TimeInterval(seconds))
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                BrainView(mood: mood).frame(width: 64, height: 62)
                VStack(alignment: .leading, spacing: 5) {
                    Text("phone session · drop it").font(DropIt.body(12, weight: .bold)).foregroundStyle(.white.opacity(0.5))
                    Text(mood.lockMessage(elapsed: TimeInterval(seconds))).font(DropIt.body(18, weight: .heavy)).foregroundStyle(.white)
                }
                Spacer(minLength: 0)
                Text(DropItDuration.timer(seconds)).font(DropIt.display(30)).foregroundStyle(Color(pickupHex: mood.timerHex))
            }
            StageProgress(mood: mood)
        }.padding(18).background(Color(pickupHex: "19171E"), in: RoundedRectangle(cornerRadius: 28))
    }
}
