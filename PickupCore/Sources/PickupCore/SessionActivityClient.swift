import Foundation

public protocol SessionActivityClient: Sendable {
    func exists(for sessionID: UUID) async -> Bool
    func start(session: SessionRecord, phase: ActivityPhase, settings: PickupSettings) async throws
    func update(session: SessionRecord, phase: ActivityPhase?, settings: PickupSettings) async
    func endAll() async
}
