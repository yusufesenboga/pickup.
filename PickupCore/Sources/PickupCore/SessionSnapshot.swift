import Foundation

public struct SessionSnapshot: Codable, Equatable, Sendable {
    public var id: UUID
    public var startedAt: Date
    public var endedAt: Date?

    public init(id: UUID, startedAt: Date, endedAt: Date?) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
}
