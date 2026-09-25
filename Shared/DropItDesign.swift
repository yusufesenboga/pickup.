import SwiftUI
import PickupCore

/// Tokens measured from the Drop It reference. Used by all three native targets.
enum DropIt {
    static let cream = Color(pickupHex: "FBF7F0")
    static let ink = Color(pickupHex: "1D1B22")
    static let secondary = Color(pickupHex: "5F5866")
    static let muted = Color(pickupHex: "8A8290")
    static let line = Color(pickupHex: "ECE5DA")
    static let purple = Color(pickupHex: "7B4DFF")
    static let purpleShadow = Color(pickupHex: "5A31D6")
    static let lavender = Color(pickupHex: "F1EBFF")
    static let red = Color(pickupHex: "FF4D5E")
    static let orange = Color(pickupHex: "FF9A3C")
    static func display(_ size: CGFloat) -> Font { .custom("Caprasimo-Regular", size: size, relativeTo: .title) }
    static func body(_ size: CGFloat = 15, weight: Font.Weight = .regular) -> Font {
        .custom("Figtree-Light", size: size, relativeTo: .body).weight(weight)
    }
}

struct RaisedButtonStyle: ButtonStyle {
    var secondary = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(DropIt.body(secondary ? 16 : 18, weight: .heavy))
            .foregroundStyle(secondary ? DropIt.ink : .white)
            .frame(maxWidth: .infinity, minHeight: secondary ? 56 : 60)
            .background(secondary ? .white : DropIt.purple, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(secondary ? DropIt.line : .clear, lineWidth: 2))
            .compositingGroup().shadow(color: secondary ? DropIt.line : DropIt.purpleShadow, radius: 0, y: configuration.isPressed ? 1 : 5)
            .offset(y: configuration.isPressed ? 4 : 0)
    }
}

extension View {
    func dropItCard(radius: CGFloat = 26, color: Color = .white) -> some View {
        background(color, in: RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(DropIt.line, lineWidth: 2))
    }
}

struct BrainStageRow: View {
    let mood: BrainMood
    let selected: Bool
    var onboarding = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                BrainView(mood: mood).frame(width: onboarding ? 58 : 48, height: onboarding ? 56 : 46)
                    .frame(width: onboarding ? 64 : 48)
                VStack(alignment: .leading, spacing: 3) {
                    if onboarding {
                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) { title; range }
                            VStack(alignment: .leading, spacing: 2) { title; range }
                        }
                        Text(mood.caption).font(DropIt.body(13)).foregroundStyle(DropIt.secondary).fixedSize(horizontal: false, vertical: true)
                    } else { title; range }
                }.frame(maxWidth: .infinity, alignment: .leading)
                if !onboarding {
                    Text(DropItDuration.timer(mood.sampleSeconds)).font(.system(size: 14, weight: .semibold)).monospacedDigit()
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .foregroundStyle(Color(pickupHex: mood.timerHex)).background(.black, in: RoundedRectangle(cornerRadius: 10))
                }
            }.padding(12).padding(.trailing, 4)
                .background(selected ? DropIt.lavender : .white, in: RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(selected ? DropIt.purple : DropIt.line, lineWidth: 2))
        }.buttonStyle(.plain).accessibilityLabel("\(mood.title), \(mood.range)")
            .accessibilityAddTraits(selected ? .isSelected : [])
    }
    private var title: some View { Text(mood.title).font(DropIt.display(onboarding ? 19 : 18)).foregroundStyle(DropIt.ink) }
    private var range: some View { Text(mood.range).font(DropIt.body(12, weight: .bold)).foregroundStyle(DropIt.muted) }
}

struct StageProgress: View {
    var mood: BrainMood
    var body: some View {
        HStack(spacing: 5) {
            ForEach(BrainMood.allCases, id: \.rawValue) { stage in
                VStack(spacing: 5) {
                    Capsule().fill(Color(pickupHex: stage.timerHex).opacity(stage.rawValue <= mood.rawValue ? 1 : 0.25)).frame(height: 5)
                    Text(["0–5", "5–10", "10–20", "20+"][stage.rawValue]).font(DropIt.body(10, weight: .bold)).foregroundStyle(.white.opacity(0.45))
                }
            }
        }.accessibilityElement(children: .ignore).accessibilityLabel("brain stage: \(mood.range)")
    }
}

/// Explicit, tappable design preview; never confused with the system island.
struct IslandPreview: View {
    let seconds: Int
    var expanded = false
    var roast: String?
    var body: some View {
        let mood = BrainMood(elapsed: TimeInterval(seconds))
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                BrainView(mood: mood).frame(width: expanded ? 56 : 29, height: expanded ? 54 : 28)
                if expanded {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("phone session").font(DropIt.body(12, weight: .semibold)).foregroundStyle(Color(pickupHex: "8E8E93"))
                        Text(roast ?? mood.islandMessage).font(DropIt.body(17, weight: .heavy)).foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                } else { Spacer(minLength: 38) }
                Text(DropItDuration.timer(seconds)).font(expanded ? DropIt.display(27) : .system(size: 16, weight: .semibold))
                    .monospacedDigit().foregroundStyle(Color(pickupHex: mood.timerHex))
            }
            
        }.padding(.horizontal, expanded ? 18 : 12).padding(.vertical, expanded ? 16 : 7)
            .frame(width: expanded ? nil : 192)
            .background(.black, in: RoundedRectangle(cornerRadius: expanded ? 48 : 50))
            .accessibilityElement(children: .combine).accessibilityLabel("Preview. \(mood.title). \(DropItDuration.timer(seconds)). \(expanded ? (roast ?? mood.islandMessage) : "")")
    }
}
