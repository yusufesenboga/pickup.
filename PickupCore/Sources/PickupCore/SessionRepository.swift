import Foundation

public protocol SessionRepository: Sendable {
    func load() async throws -> [SessionRecord]
    func commit(_ records: [SessionRecord]) async throws
}
