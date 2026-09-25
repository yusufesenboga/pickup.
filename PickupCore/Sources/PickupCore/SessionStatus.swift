import Foundation

public enum SessionStatus: Int, Codable, Sendable {
    case active, pendingEnd, ended
}
