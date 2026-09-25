import Foundation

struct SessionAppsConfiguration: Sendable {
    struct Row: Identifiable, Sendable {
        var id: String { name }
        let name: String
        let duration: TimeInterval
    }

    let rows: [Row]
    let otherCount: Int
    let otherDuration: TimeInterval
    let accentHex: String
}
