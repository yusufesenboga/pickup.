import SwiftUI
import PickupCore

struct DropItTodayContent: View {
    let usage: DropItUsage
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(usage.now.formatted(.dateTime.weekday(.wide)).lowercased()).font(DropIt.display(26))
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill").font(.system(size: 14))
                    Text("\(usage.streak)\(usage.streak == 30 ? "+" : "") day streak").font(DropIt.body(15, weight: .heavy))
                }.foregroundStyle(Color(pickupHex: "B8560A")).padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Color(pickupHex: "FFF1E3"), in: Capsule())
            }
            VStack(spacing: 14) {
                Text(roast).font(DropIt.body(18, weight: .heavy)).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 18).padding(.vertical, 14)
                    .frame(maxWidth: 310).dropItCard(radius: 24)
                    .overlay(alignment: .bottom) {
                        SpeechTail().fill(.white).frame(width: 14, height: 9).offset(y: 7)
                    }
                BrainView(mood: mood).frame(width: 164, height: 157.44)
            }.frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 10) {
                Text("screen time today").font(DropIt.body(13, weight: .bold)).foregroundStyle(DropIt.muted)
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(usage.todayDuration.map(DropItDuration.minutes) ?? "—").font(DropIt.display(46)).minimumScaleFactor(0.65).lineLimit(1)
                    Spacer(minLength: 0)
                    if let duration = usage.todayDuration {
                        Text("\(DropItDuration.minutes(abs(duration - usage.preferences.limit))) \(duration > usage.preferences.limit ? "over" : "left")")
                            .font(DropIt.body(14, weight: .heavy)).foregroundStyle(duration > usage.preferences.limit ? Color(pickupHex: "D8283A") : DropIt.purple)
                    }
                }
                GeometryReader { geometry in
                    Capsule().fill(DropIt.line)
                    Capsule().fill(isOver ? DropIt.red : DropIt.purple)
                        .frame(width: geometry.size.width * min(1, max(0, (usage.todayDuration ?? 0) / usage.preferences.limit)))
                }.frame(height: 16)
                Text("limit \(DropItDuration.minutes(usage.preferences.limit))").font(DropIt.body(13, weight: .semibold)).foregroundStyle(DropIt.muted)
            }.padding(.horizontal, 20).padding(.vertical, 18).dropItCard()
            Text("the culprits").font(DropIt.display(22)).padding(.top, 4)
            if usage.apps.isEmpty {
                Text(usage.todayDuration == nil ? "your apps will show up when Screen Time has data. pull down to check again." : "nothing to roast yet. keep that energy.")
                    .font(DropIt.body(14)).foregroundStyle(DropIt.secondary).padding(.bottom, 18)
            } else {
                VStack(spacing: 16) {
                    ForEach(Array(usage.apps.prefix(3))) { app in CulpritRow(app: app, largest: usage.apps.first?.duration ?? 1, over: isOver) }
                }
            }
        }.foregroundStyle(DropIt.ink).padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 28)
            .background(DropIt.cream)
    }
    private var isOver: Bool { (usage.todayDuration ?? 0) > usage.preferences.limit }
    private var mood: BrainMood { isOver ? .rotten : ((usage.todayDuration ?? 0) > usage.preferences.limit * 0.8 ? .eepy : .lockedIn) }
    private var roast: String {
        guard let duration = usage.todayDuration else { return "your brain is ready. let’s see what we’re working with." }
        if isOver { return "\(DropItDuration.minutes(duration))?? bro your brain is soup. DROP IT." }
        if duration == 0 { return "zero scrolling? fresh brain. big aura." }
        return "\(DropItDuration.minutes(duration)). look at you having a life. keep it up."
    }
}

private struct SpeechTail: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path(); p.move(to: .zero); p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY)); p.addLine(to: CGPoint(x: rect.maxX,y: 0)); p.closeSubpath(); return p
    }
}

private struct CulpritRow: View {
    let app: DropItUsage.App
    let largest: TimeInterval
    let over: Bool
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(String(app.name.prefix(1))).font(DropIt.display(22)).frame(width: 48, height: 48)
                .background(iconColor, in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(app.name).lineLimit(1)
                    Spacer(minLength: 8)
                    Text(app.duration < 60 ? "<1m" : DropItDuration.minutes(app.duration))
                }.font(DropIt.body(16, weight: .heavy))
                GeometryReader { geometry in
                    Capsule().fill(DropIt.line)
                    Capsule().fill(over ? DropIt.red : DropIt.purple)
                        .frame(width: geometry.size.width * min(1, max(0, app.duration / max(largest, 1))))
                }.frame(height: 7)
                Text(caption).font(DropIt.body(13)).foregroundStyle(Color(pickupHex: "6B6570"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    private var iconColor: Color {
        switch app.name.lowercased() {
        case "instagram": Color(pickupHex: "F9C6D8")
        case "tiktok": Color(pickupHex: "C9F0EC")
        case "youtube": Color(pickupHex: "FFD0C4")
        default: DropIt.lavender
        }
    }
    private var caption: String {
        switch app.name.lowercased() {
        case "instagram": "looking at strangers’ vacations again. touch grass fr"
        case "tiktok": "the algorithm knows you better than your mom"
        case "youtube": "“one more video” is a lie and you know it"
        default: "just checking one thing turned into all this."
        }
    }
}

struct DropItGoalStats: View {
    let usage: DropItUsage
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text(usage.monthlyHoursBack.map { "\($0) hours" } ?? "time back").font(DropIt.display(46)).lineLimit(1).minimumScaleFactor(0.7)
                Text(usage.monthlyHoursBack == nil ? "more room for \(usage.preferences.interestPhrase)." : "back every month for \(usage.preferences.interestPhrase).")
                    .font(DropIt.body(16, weight: .bold)).fixedSize(horizontal: false, vertical: true)
                if let average = usage.priorWeekAverage, let back = usage.dailyTimeBack {
                    Text("\(DropItDuration.minutes(back)) a day vs your \(DropItDuration.minutes(average)) average")
                        .font(DropIt.body(13, weight: .semibold)).opacity(0.8)
                } else {
                    Text("your estimate appears after 7 complete days of Screen Time data.")
                        .font(DropIt.body(13, weight: .semibold)).opacity(0.8)
                }
            }.foregroundStyle(.white).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 22).padding(.vertical, 20)
                .background(DropIt.purple, in: RoundedRectangle(cornerRadius: 28))
                .compositingGroup().shadow(color: DropIt.purpleShadow, radius: 0, y: 6)
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    Text("\(usage.streak)\(usage.streak == 30 ? "+" : "")").font(DropIt.display(30)).foregroundStyle(.white)
                        .frame(width: 58, height: 58).background(DropIt.orange, in: Circle())
                        .compositingGroup().shadow(color: Color(pickupHex: "E0741A"), radius: 0, y: 4)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("day streak").font(DropIt.display(20))
                        Text("days under your current goal").font(DropIt.body(13, weight: .semibold)).foregroundStyle(DropIt.secondary)
                    }
                }
                HStack(spacing: 0) {
                    ForEach(usage.weekDays, id: \.self) { day in
                        VStack(spacing: 6) {
                            Text(day.formatted(.dateTime.weekday(.narrow))).font(DropIt.body(12, weight: .heavy)).foregroundStyle(DropIt.muted)
                            Text(mark(for: day)).font(DropIt.body(13, weight: .heavy)).foregroundStyle(.white)
                                .frame(width: 34, height: 34).background(dayColor(day), in: Circle())
                                .overlay(Circle().strokeBorder(dayColor(day) == .clear ? DropIt.line : .clear, lineWidth: 2.5))
                        }.frame(maxWidth: .infinity)
                    }
                }
                Text(status).font(DropIt.body(14, weight: .bold)).foregroundStyle(Color(pickupHex: over ? "8F1422" : "5A31D6"))
                    .frame(maxWidth: .infinity, alignment: .leading).padding(14)
                    .background(over ? Color(pickupHex: "FFE6E8") : DropIt.lavender, in: RoundedRectangle(cornerRadius: 18))
            }
        }.foregroundStyle(DropIt.ink).padding(.bottom, 6).background(DropIt.cream)
    }
    private var over: Bool { (usage.todayDuration ?? 0) > usage.preferences.limit }
    private var status: String {
        guard let duration = usage.todayDuration else { return "your next streak starts with one day. you’ve got this." }
        if over { return "you’re \(DropItDuration.minutes(duration - usage.preferences.limit)) over today. streak dies at midnight. rip bozo." }
        return "\(DropItDuration.minutes(usage.preferences.limit - duration)) left today. keep your brain fresh."
    }
    private func dayColor(_ day: Date) -> Color {
        guard day <= usage.today, let duration = usage.dailyDurations[day] else { return .clear }
        if duration > usage.preferences.limit { return DropIt.red }
        return day < usage.today ? DropIt.orange : .clear
    }
    private func mark(for day: Date) -> String {
        guard day <= usage.today, let duration = usage.dailyDurations[day] else { return "" }
        if duration > usage.preferences.limit { return "✕" }
        return day < usage.today ? "✓" : ""
    }
}
