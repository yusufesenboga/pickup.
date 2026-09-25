import SwiftUI
import PickupCore

/// Vector reconstruction of the five-lobe character in the supplied design.
/// The 100 × 96 coordinate system keeps identical proportions from icon to hero.
struct BrainView: View {
    var mood: BrainMood = .lockedIn

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 100, size.height / 96)
            context.translateBy(x: (size.width - 100 * scale) / 2, y: (size.height - 96 * scale) / 2)
            context.scaleBy(x: scale, y: scale)
            let fill = Color(pickupHex: ["FF8FB3", "EEAABD", "C4C66C", "8F9B3B"][mood.rawValue])
            let shade = Color(pickupHex: ["E8618F", "C98097", "959A3F", "5F6B1E"][mood.rawValue])
            let ink = DropIt.ink
            func ellipse(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: Color) {
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h)), with: .color(color))
            }
            func rounded(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: Color, rotation: Double = 0) {
                var layer = context
                layer.translateBy(x: x + w / 2, y: y + h / 2)
                layer.rotate(by: .degrees(rotation))
                layer.fill(Path(roundedRect: CGRect(x: -w / 2, y: -h / 2, width: w, height: h), cornerRadius: min(w, h) / 2), with: .color(color))
            }
            func halfRound(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: Color, top: Bool) {
                let corners = RectangleCornerRadii(topLeading: top ? h : 0, bottomLeading: top ? 0 : h,
                                                  bottomTrailing: top ? 0 : h, topTrailing: top ? h : 0)
                context.fill(UnevenRoundedRectangle(cornerRadii: corners).path(in: CGRect(x: x, y: y, width: w, height: h)), with: .color(color))
            }
            func line(_ x: CGFloat, _ y: CGFloat, _ endX: CGFloat, _ endY: CGFloat, _ color: Color, _ width: CGFloat) {
                var path = Path(); path.move(to: CGPoint(x: x, y: y)); path.addLine(to: CGPoint(x: endX, y: endY))
                context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
            }
            for (x, y, w, h): (CGFloat, CGFloat, CGFloat, CGFloat) in [(2,22,52,52),(14,6,50,50),(38,4,50,50),(48,20,50,50),(20,34,60,60)] {
                let frame = CGRect(x: x, y: y, width: w, height: h)
                var lobe = context
                lobe.clip(to: Path(ellipseIn: frame))
                lobe.fill(Path(ellipseIn: frame), with: .color(shade))
                lobe.fill(Path(ellipseIn: frame.offsetBy(dx: 0, dy: -4.5)), with: .color(fill))
            }
            var highlight = context
            highlight.translateBy(x: 29, y: 16); highlight.rotate(by: .degrees(-20))
            highlight.fill(Path(ellipseIn: CGRect(x: -7, y: -4, width: 14, height: 8)), with: .color(.white.opacity(0.45)))
            rounded(48.25, 8, 3.5, 26, shade)
            for (x, angle): (CGFloat, Double) in [(25,-35),(81,35)] {
                var arc = Path(); arc.addArc(center: CGPoint(x: x, y: 41), radius: 9.5, startAngle: .degrees(225 + angle), endAngle: .degrees(315 + angle), clockwise: false)
                context.stroke(arc, with: .color(shade), lineWidth: 3)
            }
            if mood == .lockedIn {
                ellipse(20,60,10,6,Color(pickupHex: "FF4678").opacity(0.35))
                ellipse(68,60,10,6,Color(pickupHex: "FF4678").opacity(0.35))
            }
            if mood.rawValue >= 2 {
                let spots = Color(pickupHex: mood == .brainrot ? "7C7A2E" : "434B12")
                for (x,y,w): (CGFloat,CGFloat,CGFloat) in [(24,20,7),(62,13,5),(74,42,8),(10,48,5),(66,74,5)] { ellipse(x,y,w,w,spots) }
            }
            for x: CGFloat in [29,55] {
                ellipse(x-2.1,41.9,20.2,20.2,ink)
                ellipse(x,44,16,16,.white)
                if mood == .rotten {
                    ellipse(x + (x == 29 ? 6.5 : 3.5),48.5,6,6,Color(pickupHex: "E0263A"))
                    rounded(x-1,38.5,19,4.5,ink,rotation: x == 29 ? 24 : -24)
                } else {
                    let oddEye = mood == .brainrot && x == 55
                    ellipse(x + (oddEye ? 7 : 4.5),mood == .eepy ? 51 : (oddEye ? 50 : 48.5),oddEye ? 5 : 7.5,oddEye ? 5 : 7.5,ink)
                    if mood == .eepy || (mood == .brainrot && x == 29) {
                        let height: CGFloat = mood == .eepy ? 8.8 : 6.72
                        halfRound(x-1,43.5,18,height,fill,top: true)
                        line(x-1,43.5+height,x+17,43.5+height,ink,2.4)
                    }
                    if mood == .eepy {
                        var bag = Path(); bag.addArc(center: CGPoint(x: x+8, y: 61), radius: 6, startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
                        context.stroke(bag, with: .color(shade), lineWidth: 2.4)
                    }
                }
            }
            switch mood {
            case .lockedIn: halfRound(42,66,16,8,ink,top: false)
            case .eepy: rounded(44,70,12,2.8,ink)
            case .brainrot:
                ellipse(45,66,10,7,ink); rounded(51.5,71,3.5,13,Color(pickupHex: "B6E04A"))
            case .rotten: halfRound(41,67,18,8,ink,top: true)
            }
        }.aspectRatio(100 / 96, contentMode: .fit)
            .accessibilityLabel("brain: \(mood.title)")
    }
}
