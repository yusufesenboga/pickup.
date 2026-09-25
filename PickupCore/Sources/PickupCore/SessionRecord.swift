import Foundation

public struct SessionRecord: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var startedAt: Date
    public var endedAt: Date?
    public var status: SessionStatus
    public var pendingEndAt: Date?

    public init(id: UUID = UUID(), startedAt: Date, endedAt: Date? = nil,
                status: SessionStatus = .active, pendingEndAt: Date? = nil) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.status = status
        self.pendingEndAt = pendingEndAt
    }

    public var effectiveEnd: Date? { endedAt ?? pendingEndAt }

    public func duration(at now: Date) -> TimeInterval {
        max(0, (effectiveEnd ?? now).timeIntervalSince(startedAt))
    }

    public var snapshot: SessionSnapshot {
        SessionSnapshot(id: id, startedAt: startedAt, endedAt: effectiveEnd)
    }
}
