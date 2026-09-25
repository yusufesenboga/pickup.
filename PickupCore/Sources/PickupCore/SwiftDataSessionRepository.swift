import Foundation
import SwiftData

public actor SwiftDataSessionRepository: SessionRepository {
    private let container: ModelContainer
    private var storedContext: ModelContext?

    public init(storeURL: URL? = nil, inMemory: Bool = false) throws {
        let schema = Schema([Session.self])
        let configuration: ModelConfiguration
        if let storeURL {
            configuration = ModelConfiguration("Pickup", schema: schema, url: storeURL,
                                               cloudKitDatabase: .none)
        } else {
            configuration = ModelConfiguration("Pickup", schema: schema,
                                               isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none)
        }
        container = try ModelContainer(for: schema, configurations: [configuration])
    }

    private var context: ModelContext {
        if let storedContext { return storedContext }
        let newContext = ModelContext(container)
        newContext.autosaveEnabled = false
        storedContext = newContext
        return newContext
    }

    public func load() throws -> [SessionRecord] {
        try context.fetch(FetchDescriptor<Session>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)]))
            .map(\.record)
    }

    public func commit(_ records: [SessionRecord]) throws {
        let context = context
        do {
            let existing = try context.fetch(FetchDescriptor<Session>())
            let byID = Dictionary(uniqueKeysWithValues: records.map { ($0.id, $0) })
            let existingIDs = Set(existing.map(\.id))
            for session in existing {
                if let record = byID[session.id] { session.apply(record) }
                else { context.delete(session) }
            }
            for record in records where !existingIDs.contains(record.id) {
                context.insert(Session(record: record))
            }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
