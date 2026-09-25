import Foundation

public struct PickupSettings: Codable, Equatable, Sendable {
    public var timerRevealDelay: Double = 50
    public var gracePeriod: Double = 30
    // Retained for decoding existing preferences; Close events are never discarded.
    public var startEndDebounce: Double = 5
    public var minimumVisibleSessionLength: Double = 60
    public var accentHex = "B5F36C"
    public var showDetailInExpanded = true
    public var showTimerImmediately = false

    public init() {}

    public var validated: Self {
        var copy = self
        copy.timerRevealDelay = finiteClamp(timerRevealDelay, 0...300, fallback: 50)
        copy.gracePeriod = finiteClamp(gracePeriod, 0...300, fallback: 30)
        copy.startEndDebounce = finiteClamp(startEndDebounce, 0...30, fallback: 5)
        copy.minimumVisibleSessionLength = finiteClamp(minimumVisibleSessionLength, 0...600, fallback: 60)
        if accentHex.count != 6 || UInt32(accentHex, radix: 16) == nil { copy.accentHex = "B5F36C" }
        return copy
    }

    private func finiteClamp(_ value: Double, _ range: ClosedRange<Double>, fallback: Double) -> Double {
        value.isFinite ? min(range.upperBound, max(range.lowerBound, value)) : fallback
    }
}
