import Foundation

public actor SessionCoordinator {
    private let repository: any SessionRepository
    private let activities: any SessionActivityClient
    private let preferences: SharedPreferences
    private var occupied = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    public init(repository: any SessionRepository, activities: any SessionActivityClient,
                preferences: SharedPreferences) {
        self.repository = repository
        self.activities = activities
        self.preferences = preferences
    }

    // MARK: Serialization

    // An actor alone is reentrant across ActivityKit/repository awaits. Hold a FIFO
    // permit for the whole event so concurrent Shortcuts cannot create two sessions.
    private func acquire() async {
        if !occupied { occupied = true; return }
        await withCheckedContinuation { waiters.append($0) }
    }

    private func release() {
        if waiters.isEmpty { occupied = false }
        else { waiters.removeFirst().resume() }
    }

    // MARK: Intent events

    public func start(now: Date = .now) async throws {
        await acquire()
        defer { release() }
        preferences.setDate(now, for: SharedKeys.lastStartEventAt)
        let settings = preferences.settings
        var records = try await repository.load()
        if let index = records.firstIndex(where: { $0.status == .pendingEnd }) {
            let end = records[index].pendingEndAt ?? now
            if now.timeIntervalSince(end) <= settings.gracePeriod {
                records[index].status = .active
                records[index].pendingEndAt = nil
                try await persist(records, now: now)
                await requestActivity(for: records[index], settings: settings)
                return
            }
            records[index].status = .ended
            records[index].endedAt = end
            records[index].pendingEndAt = nil
        }
        if let active = records.first(where: { $0.status == .active }) {
            // Idempotent data; recover an expired/dismissed activity at the next Start.
            if !(await activities.exists(for: active.id)) {
                await requestActivity(for: active, settings: settings)
            } else {
                // Refresh the brain without resetting the session or reveal phase.
                await activities.update(session: active, phase: nil, settings: settings)
            }
            try await persist(records, now: now)
            return
        }
        let session = SessionRecord(startedAt: now)
        records.append(session)
        try await persist(records, now: now)
        await requestActivity(for: session, settings: settings)
    }

    public func showTimer(now: Date = .now) async throws {
        await acquire()
        defer { release() }
        guard let session = try await repository.load().first(where: { $0.status == .active }) else { return }
        let settings = preferences.settings
        if !(await activities.exists(for: session.id)) {
            await requestActivity(for: session, settings: settings, phase: .timer)
        } else {
            await activities.update(session: session, phase: .timer, settings: settings)
        }
    }

    public func end(now: Date = .now) async throws {
        await acquire()
        defer { release() }
        preferences.setDate(now, for: SharedKeys.lastEndEventAt)
        // Every Close matters, including a short visit. Dropping a Close leaves
        // the activity running indefinitely if no other event follows it.
        // Dismiss first so orphan activities and failed saves cannot prevent Stop.
        await activities.endAll()
        var records = try await repository.load()
        guard let index = records.firstIndex(where: { $0.status == .active }) else { return }
        records[index].status = .pendingEnd
        records[index].pendingEndAt = now
        try await persist(records, now: now)
    }

    /// Explicit user stop: finalize immediately instead of leaving a resumable session.
    public func stop(now: Date = .now) async throws {
        await acquire()
        defer { release() }
        await activities.endAll()
        var records = try await repository.load()
        for index in records.indices where records[index].status != .ended {
            records[index].endedAt = records[index].pendingEndAt ?? now
            records[index].pendingEndAt = nil
            records[index].status = .ended
        }
        try await persist(records, now: now)
    }

    // MARK: Foreground and data operations

    public func foreground(now: Date = .now) async throws {
        await acquire()
        defer { release() }
        var records = try await repository.load()
        // Keep pending sessions resumable during grace, including a brief visit to Pickup.
        for index in records.indices where records[index].status == .pendingEnd {
            let end = records[index].pendingEndAt ?? now
            if now.timeIntervalSince(end) > preferences.settings.gracePeriod {
                records[index].status = .ended
                records[index].endedAt = end
                records[index].pendingEndAt = nil
            }
        }
        try await persist(records, now: now)
        if let active = records.first(where: { $0.status == .active }) {
            if !(await activities.exists(for: active.id)) {
                await requestActivity(for: active, settings: preferences.settings)
            } else {
                await activities.update(session: active, phase: nil, settings: preferences.settings)
            }
        } else { await activities.endAll() }
    }

    public func sessions() async throws -> [SessionRecord] {
        await acquire()
        defer { release() }
        return try await repository.load().sorted { $0.startedAt > $1.startedAt }
    }

    public func delete(ids: Set<UUID>, now: Date = .now) async throws {
        await acquire()
        defer { release() }
        let records = try await repository.load()
        let deletesCurrent = records.contains { ids.contains($0.id) && $0.status != .ended }
        try await persist(records.filter { !ids.contains($0.id) }, now: now)
        if deletesCurrent { await activities.endAll() }
    }

    public func deleteAll(now: Date = .now) async throws {
        await acquire()
        defer { release() }
        try await repository.commit([])
        preferences.clear()
        try preferences.writeSnapshot([], now: now)
        await activities.endAll()
    }

    private func persist(_ records: [SessionRecord], now: Date) async throws {
        try await repository.commit(records)
        try preferences.writeSnapshot(records, now: now)
    }

    private func requestActivity(for session: SessionRecord, settings: PickupSettings,
                                 phase: ActivityPhase? = nil) async {
        await activities.endAll()
        do {
            try await activities.start(session: session,
                                       phase: phase ?? (settings.showTimerImmediately ? .timer : .iconOnly),
                                       settings: settings)
            preferences.setString(nil, for: SharedKeys.activityIssue)
        } catch {
            // Timer permissions/errors must never discard a successfully saved session.
            preferences.setString("activityUnavailable", for: SharedKeys.activityIssue)
        }
    }
}
