import Foundation

// UserDefaults is thread-safe. No mutable state is held outside its APIs.
public final class SharedPreferences: @unchecked Sendable {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults) { self.defaults = defaults }

    public var settings: PickupSettings {
        guard let data = defaults.data(forKey: SharedKeys.settings),
              let value = try? JSONDecoder().decode(PickupSettings.self, from: data) else {
            return PickupSettings()
        }
        return value.validated
    }

    public func setSettings(_ value: PickupSettings) throws {
        defaults.set(try JSONEncoder().encode(value.validated), forKey: SharedKeys.settings)
    }

    public func date(for key: String) -> Date? { defaults.object(forKey: key) as? Date }
    public func setDate(_ date: Date, for key: String) { defaults.set(date, forKey: key) }
    public func data(for key: String) -> Data? { defaults.data(forKey: key) }
    public func string(for key: String) -> String? { defaults.string(forKey: key) }
    public func setString(_ value: String?, for key: String) { defaults.set(value, forKey: key) }
    public func integers(for key: String) -> [Int] { defaults.array(forKey: key) as? [Int] ?? [] }
    public func setIntegers(_ value: [Int], for key: String) { defaults.set(value, forKey: key) }

    public func writeSnapshot(_ records: [SessionRecord], now: Date) throws {
        let result = try SnapshotCodec.encode(records.map(\.snapshot), now: now)
        // Conservative coverage first: interruption can hide an estimate, never overstate it.
        defaults.set(result.coverageStart, forKey: SharedKeys.snapshotCoverageStart)
        defaults.set(result.data, forKey: SharedKeys.sessionsSnapshot)
    }

    public func clear() {
        for key in [SharedKeys.settings, SharedKeys.sessionsSnapshot, SharedKeys.snapshotCoverageStart,
                    SharedKeys.lastStartEventAt, SharedKeys.lastEndEventAt,
                    SharedKeys.activityIssue, SharedKeys.completedSetupSteps,
                    DropItPreferences.storageKey, DropItPreferences.selectionKey] {
            defaults.removeObject(forKey: key)
        }
    }
}
