import Foundation
import PickupCore

struct DailySummaryConfiguration: Sendable {
    let appleTotal: TimeInterval
    let pickups: Int
    let firstPickup: Date?
    let totals: DailyTotals
    let snapshotIsComplete: Bool
    let hasSegments: Bool
    let accentHex: String
}
