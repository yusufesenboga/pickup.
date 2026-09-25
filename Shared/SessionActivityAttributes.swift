import ActivityKit
import Foundation
import PickupCore

struct SessionActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var phase: ActivityPhase
        var startedAt: Date
        var accentHex: String
        var showDetailInExpanded: Bool
        var elapsedAtUpdate: TimeInterval? = nil
    }

    var sessionID: UUID
}
