import Foundation
import PickupCore

actor TestRepository: SessionRepository {
    var records: [SessionRecord] = []
    var failWrites = false
    func load() -> [SessionRecord] { records }
    func commit(_ records: [SessionRecord]) throws {
        if failWrites { throw CocoaError(.fileWriteUnknown) }
        self.records = records
    }
    func setFailWrites() { failWrites = true }
}
