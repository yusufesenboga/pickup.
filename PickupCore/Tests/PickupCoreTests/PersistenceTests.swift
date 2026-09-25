import Foundation
import Testing
import PickupCore

struct PersistenceTests {
    @Test func swiftDataRoundTripsStateUpdatesAndDeletions() async throws {
        let repository = try SwiftDataSessionRepository(inMemory: true)
        var session = SessionRecord(startedAt: .now)
        try await repository.commit([session])
        #expect(try await repository.load() == [session])
        session.status = .pendingEnd
        session.pendingEndAt = session.startedAt.addingTimeInterval(75)
        try await repository.commit([session])
        #expect(try await repository.load() == [session])
        try await repository.commit([])
        #expect(try await repository.load().isEmpty)
    }

    @Test func diskContainerCanReopenWithoutHostUI() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("Pickup.store")
        let session = SessionRecord(startedAt: .now)
        let first = try SwiftDataSessionRepository(storeURL: url)
        try await first.commit([session])
        let reopened = try SwiftDataSessionRepository(storeURL: url)
        #expect(try await reopened.load() == [session])
    }

    @Test func exportsArePortableAndIncludePendingEnd() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let record = SessionRecord(startedAt: now, status: .pendingEnd, pendingEndAt: now.addingTimeInterval(75))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        #expect(try decoder.decode([SessionRecord].self, from: SessionExporter.json([record])) == [record])
        let csv = String(decoding: SessionExporter.csv([record], now: now.addingTimeInterval(1_000)), as: UTF8.self)
        #expect(csv.contains("pendingEndAt"))
        #expect(csv.hasSuffix("\"75\""))
    }
}
