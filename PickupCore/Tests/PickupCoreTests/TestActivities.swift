import Foundation
import PickupCore

actor TestActivities: SessionActivityClient {
    var sessionID: UUID?
    var phase: ActivityPhase?
    var startedAt: Date?
    var startCount = 0
    var updateCount = 0
    var fail = false
    func exists(for sessionID: UUID) -> Bool { self.sessionID == sessionID }
    func start(session: SessionRecord, phase: ActivityPhase, settings: PickupSettings) async throws {
        await Task.yield() // Exercise reentrancy under simultaneous Start events.
        if fail { throw CocoaError(.featureUnsupported) }
        sessionID = session.id
        startedAt = session.startedAt
        self.phase = phase
        startCount += 1
    }
    func update(session: SessionRecord, phase: ActivityPhase?, settings: PickupSettings) {
        updateCount += 1
        if let phase { self.phase = phase }
    }
    func endAll() { sessionID = nil; phase = nil }
    func setFail() { fail = true }
}
