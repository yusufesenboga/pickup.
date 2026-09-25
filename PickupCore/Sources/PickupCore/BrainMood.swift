import Foundation

public enum BrainMood: Int, CaseIterable, Codable, Sendable {
    case lockedIn, eepy, brainrot, rotten
    public init(elapsed: TimeInterval) {
        switch elapsed.isFinite ? max(0, elapsed) : 0 {
        case ..<300: self = .lockedIn
        case ..<600: self = .eepy
        case ..<1200: self = .brainrot
        default: self = .rotten
        }
    }
    public var title: String { ["locked in", "getting eepy", "brainrot", "rotten & mad"][rawValue] }
    public var islandMessage: String { ["locked in. for now.", "brain getting eepy…", "it’s giving brainrot", "DROP. IT. NOW."][rawValue] }
    public func lockMessage(elapsed: TimeInterval) -> String {
        switch self {
        case .lockedIn: "ok you just got here. be normal."
        case .eepy: "brain is getting eepy. wrap it up."
        case .brainrot: "it’s giving brainrot. \(Int(max(0, elapsed) / 60)) min of what exactly?"
        case .rotten: "ok this is embarrassing. PUT IT DOWN."
        }
    }
    public var range: String { ["0–5 min", "5–10 min", "10–20 min", "20+ min"][rawValue] }
    public var caption: String {
        ["fresh brain. big aura. enjoy it while it lasts.", "eyes getting heavy. the scroll is winning.", "actively decomposing. chat is this real.", "fully cooked and furious. it will yell at you."][rawValue]
    }
    public var timerHex: String { ["FF8FB3", "F5C25C", "C9D05A", "FF4D5E"][rawValue] }
    public var sampleSeconds: Int { [134, 460, 843, 1431][rawValue] }
    public static let roastMinutes = [1, 5, 10, 15, 20, 30]
    public static func roast(elapsed: TimeInterval) -> String {
        switch elapsed.isFinite ? max(0, elapsed) : 0 {
        case ..<300: "just checking one thing. sure bestie."
        case ..<600: "yea, yea you are socializing with friends on insta, for sure"
        case ..<900: "10 minutes. your brain just filed a complaint."
        case ..<1200: "this reel is not gonna fix your life."
        case ..<1800: "DROP IT. i’m not asking."
        default: "you’re not locked in. you’re locked up."
        }
    }
}

public enum DropItDuration {
    public static func minutes(_ duration: TimeInterval) -> String {
        let total = duration.isFinite ? Int(min(86_400 * 366, max(0, duration)) / 60) : 0
        return total < 60 ? "\(total)m" : "\(total / 60)h \(String(format: "%02d", total % 60))m"
    }
    public static func timer(_ seconds: Int) -> String {
        let value = max(0, seconds)
        return "\(value / 60):\(String(format: "%02d", value % 60))"
    }
}
