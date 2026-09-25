import Foundation

/// User choices only. Screen Time results never leave the report extension.
public struct DropItPreferences: Codable, Equatable, Sendable {
    public var dailyLimitMinutes: Int
    public var interests: [String]
    public var onboardingComplete: Bool
    public static let storageKey = "dropIt.preferences.v1"
    public static let selectionKey = "dropIt.applicationSelection.v1"
    public static let availableInterests = ["the gym", "reading", "sleep", "friends irl", "touching grass", "cooking", "learning a skill", "making stuff"]

    public init(dailyLimitMinutes: Int = 90, interests: [String] = ["the gym", "reading"], onboardingComplete: Bool = false) {
        self.dailyLimitMinutes = min(720, max(15, dailyLimitMinutes))
        self.interests = Self.availableInterests.filter { interests.contains($0) }
        self.onboardingComplete = onboardingComplete
    }
    public var limit: TimeInterval { TimeInterval(dailyLimitMinutes * 60) }
    public var interestPhrase: String { interests.isEmpty ? "your life offline" : interests.joined(separator: " & ") }
    public static func decode(_ string: String?) -> Self {
        guard let data = string?.data(using: .utf8), let value = try? JSONDecoder().decode(Self.self, from: data) else { return Self() }
        return Self(dailyLimitMinutes: value.dailyLimitMinutes, interests: value.interests, onboardingComplete: value.onboardingComplete)
    }
    public var encoded: String? {
        (try? JSONEncoder().encode(self)).flatMap { String(data: $0, encoding: .utf8) }
    }
}
