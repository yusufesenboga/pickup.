import Foundation
import SwiftData

@Model public final class Session {
    @Attribute(.unique) public var id: UUID
    public var startedAt: Date
    public var endedAt: Date?
    public var status: SessionStatus
    public var pendingEndAt: Date?

    public init(record: SessionRecord) {
        id = record.id
        startedAt = record.startedAt
        endedAt = record.endedAt
        status = record.status
        pendingEndAt = record.pendingEndAt
    }

    public var record: SessionRecord {
        SessionRecord(id: id, startedAt: startedAt, endedAt: endedAt,
                      status: status, pendingEndAt: pendingEndAt)
    }

    public func apply(_ record: SessionRecord) {
        startedAt = record.startedAt
        endedAt = record.endedAt
        status = record.status
        pendingEndAt = record.pendingEndAt
    }
}
