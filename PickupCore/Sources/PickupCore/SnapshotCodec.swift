import Foundation

public enum SnapshotCodec {
    public struct Encoded: Sendable {
        public let data: Data
        public let coverageStart: Date
    }

    public static func encode(_ snapshots: [SessionSnapshot], now: Date,
                              byteLimit: Int = SharedKeys.snapshotLimit) throws -> Encoded {
        let cutoff = now.addingTimeInterval(-Double(SharedKeys.retentionDays) * 86_400)
        let recent = snapshots.filter { ($0.endedAt ?? now) >= cutoff }
            .sorted { $0.startedAt > $1.startedAt }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        var low = 0
        var high = recent.count
        while low < high {
            let middle = (low + high + 1) / 2
            if try encoder.encode(Array(recent.prefix(middle))).count <= max(2, byteLimit) {
                low = middle
            } else { high = middle - 1 }
        }
        let kept = Array(recent.prefix(low))
        // Only claim complete coverage after every omitted interval has ended.
        let omittedEnd = recent.dropFirst(low).map { $0.endedAt ?? now }.max()
        let coverage = max(cutoff, omittedEnd ?? cutoff)
        return Encoded(data: try encoder.encode(kept), coverageStart: coverage)
    }

    public static func decode(_ data: Data?) throws -> [SessionSnapshot] {
        guard let data else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode([SessionSnapshot].self, from: data)
    }
}
