import Foundation

public enum SessionExporter {
    public static func json(_ sessions: [SessionRecord]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(sessions)
    }

    public static func csv(_ sessions: [SessionRecord], now: Date) -> Data {
        let formatter = ISO8601DateFormatter()
        let rows = sessions.map { session in
            [session.id.uuidString, formatter.string(from: session.startedAt),
             session.endedAt.map(formatter.string) ?? "",
             session.pendingEndAt.map(formatter.string) ?? "",
             String(session.status.rawValue), String(Int(session.duration(at: now)))]
                .map { "\"" + $0.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
                .joined(separator: ",")
        }
        return Data((["id,startedAt,endedAt,pendingEndAt,status,durationSeconds"] + rows)
            .joined(separator: "\r\n").utf8)
    }
}
