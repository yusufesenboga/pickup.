import Foundation
import Testing
@testable import PickupCore

struct CoordinatorTests {
    private let epoch = Date(timeIntervalSince1970: 1_800_000_000)

    private func fixture() -> (SessionCoordinator, TestRepository, TestActivities, SharedPreferences) {
        let store = TestRepository()
        let activities = TestActivities()
        let preferences = SharedPreferences(defaults: UserDefaults(suiteName: "PickupTests.\(UUID())")!)
        return (SessionCoordinator(repository: store, activities: activities, preferences: preferences),
                store, activities, preferences)
    }

    @Test func startCreatesAndRepeatedStartIsIdempotent() async throws {
        let (sut, _, activity, preferences) = fixture()
        try await sut.start(now: epoch)
        try await sut.start(now: epoch.addingTimeInterval(10))
        let sessions = try await sut.sessions()
        #expect(sessions.count == 1)
        #expect(sessions.first?.startedAt == epoch)
        #expect(await activity.startCount == 1)
        #expect(await activity.updateCount == 1)
        #expect(preferences.date(for: SharedKeys.lastStartEventAt) == epoch.addingTimeInterval(10))
    }

    @Test func resumeWithinGraceKeepsOriginalStartAndResetsIcon() async throws {
        let (sut, _, activity, preferences) = fixture()
        try await sut.start(now: epoch)
        try await sut.showTimer(now: epoch.addingTimeInterval(50))
        try await sut.end(now: epoch.addingTimeInterval(80))
        let pending = try SnapshotCodec.decode(preferences.data(for: SharedKeys.sessionsSnapshot))
        #expect(pending.first?.endedAt == epoch.addingTimeInterval(80))
        #expect(await activity.sessionID == nil)
        try await sut.start(now: epoch.addingTimeInterval(100))
        let sessions = try await sut.sessions()
        #expect(sessions.count == 1)
        #expect(sessions.first?.status == .active)
        #expect(sessions.first?.pendingEndAt == nil)
        #expect(await activity.startedAt == epoch)
        #expect(await activity.phase == .iconOnly)
    }

    @Test func graceBoundaryIsInclusive() async throws {
        let (sut, _, _, _) = fixture()
        try await sut.start(now: epoch)
        try await sut.end(now: epoch.addingTimeInterval(10))
        try await sut.start(now: epoch.addingTimeInterval(40))
        #expect(try await sut.sessions().count == 1)
    }

    @Test func beyondGraceFinalizesAtCloseAndCreatesNew() async throws {
        let (sut, _, _, _) = fixture()
        try await sut.start(now: epoch)
        try await sut.end(now: epoch.addingTimeInterval(80))
        try await sut.start(now: epoch.addingTimeInterval(140))
        let sessions = try await sut.sessions()
        #expect(sessions.count == 2)
        #expect(sessions.last?.endedAt == epoch.addingTimeInterval(80))
        #expect(sessions.last?.status == .ended)
        #expect(sessions.first?.status == .active)
    }

    @Test func closeImmediatelyAfterOpenDismissesAndDoesNotRevive() async throws {
        let (sut, _, activity, preferences) = fixture()
        try await sut.start(now: epoch)
        try await sut.start(now: epoch.addingTimeInterval(100))
        try await sut.end(now: epoch.addingTimeInterval(102))
        #expect(try await sut.sessions().first?.status == .pendingEnd)
        #expect(await activity.sessionID == nil)
        #expect(preferences.date(for: SharedKeys.lastEndEventAt) == epoch.addingTimeInterval(102))
        try await sut.foreground(now: epoch.addingTimeInterval(103))
        try await sut.showTimer(now: epoch.addingTimeInterval(150))
        #expect(try await sut.sessions().first?.status == .pendingEnd)
        #expect(await activity.sessionID == nil)
        #expect(await activity.startCount == 1)
    }

    @Test func quickCloseThenOpenResumesOriginalSession() async throws {
        let (sut, _, activity, _) = fixture()
        try await sut.start(now: epoch)
        let originalID = try await sut.sessions().first?.id
        try await sut.end(now: epoch.addingTimeInterval(1))
        #expect(await activity.sessionID == nil)
        try await sut.start(now: epoch.addingTimeInterval(2))
        #expect(try await sut.sessions().count == 1)
        #expect(await activity.sessionID == originalID)
        #expect(await activity.startedAt == epoch)
    }

    @Test func manualStopIsImmediateAndCannotResumeOldSession() async throws {
        let (sut, _, activity, preferences) = fixture()
        try await sut.start(now: epoch)
        let originalID = try await sut.sessions().first?.id
        try await sut.stop(now: epoch.addingTimeInterval(1))
        #expect(try await sut.sessions().first?.status == .ended)
        #expect(try await sut.sessions().first?.endedAt == epoch.addingTimeInterval(1))
        #expect(await activity.sessionID == nil)
        // A manual Stop must not pretend that the Close automation is connected.
        #expect(preferences.date(for: SharedKeys.lastEndEventAt) == nil)
        try await sut.foreground(now: epoch.addingTimeInterval(2))
        try await sut.showTimer(now: epoch.addingTimeInterval(3))
        #expect(await activity.sessionID == nil)
        try await sut.start(now: epoch.addingTimeInterval(4))
        #expect(try await sut.sessions().count == 2)
        #expect(await activity.sessionID != originalID)
        #expect(await activity.startedAt == epoch.addingTimeInterval(4))
    }

    @Test func stopPendingAndRepeatedStopPreserveCloseTime() async throws {
        let (sut, _, activity, _) = fixture()
        try await sut.start(now: epoch)
        try await sut.end(now: epoch.addingTimeInterval(1))
        try await sut.stop(now: epoch.addingTimeInterval(2))
        try await sut.stop(now: epoch.addingTimeInterval(3))
        let session = try await sut.sessions().first
        #expect(session?.status == .ended)
        #expect(session?.endedAt == epoch.addingTimeInterval(1))
        #expect(session?.pendingEndAt == nil)
        #expect(await activity.sessionID == nil)
    }

    @Test func closeAndStopDismissOrphanActivities() async throws {
        let (sut, _, activity, _) = fixture()
        let orphan = SessionRecord(startedAt: epoch)
        try await activity.start(session: orphan, phase: .timer, settings: PickupSettings())
        try await sut.end(now: epoch)
        #expect(await activity.sessionID == nil)
        try await activity.start(session: orphan, phase: .timer, settings: PickupSettings())
        try await sut.stop(now: epoch)
        #expect(await activity.sessionID == nil)
        #expect(try await sut.sessions().isEmpty)
    }

    @Test func closeDismissesEvenWhenSavingFails() async throws {
        let (sut, repository, activity, _) = fixture()
        try await sut.start(now: epoch)
        await repository.setFailWrites()
        await #expect(throws: (any Error).self) { try await sut.end(now: epoch.addingTimeInterval(1)) }
        #expect(await activity.sessionID == nil)
    }

    @Test func manualStopDismissesEvenWhenSavingFails() async throws {
        let (sut, repository, activity, _) = fixture()
        try await sut.start(now: epoch)
        await repository.setFailWrites()
        await #expect(throws: (any Error).self) { try await sut.stop(now: epoch.addingTimeInterval(1)) }
        #expect(await activity.sessionID == nil)
    }

    @Test func endAndShowWithNoSessionDoNothing() async throws {
        let (sut, _, activity, _) = fixture()
        try await sut.end(now: epoch)
        try await sut.showTimer(now: epoch)
        #expect(try await sut.sessions().isEmpty)
        #expect(await activity.startCount == 0)
    }

    @Test func repeatedEndPreservesFirstClose() async throws {
        let (sut, _, _, _) = fixture()
        try await sut.start(now: epoch)
        try await sut.end(now: epoch.addingTimeInterval(10))
        try await sut.end(now: epoch.addingTimeInterval(15))
        #expect(try await sut.sessions().first?.pendingEndAt == epoch.addingTimeInterval(10))
    }

    @Test func foregroundRespectsGraceThenFinalizes() async throws {
        let (sut, _, _, _) = fixture()
        try await sut.start(now: epoch)
        try await sut.end(now: epoch.addingTimeInterval(10))
        try await sut.foreground(now: epoch.addingTimeInterval(20))
        #expect(try await sut.sessions().first?.status == .pendingEnd)
        try await sut.foreground(now: epoch.addingTimeInterval(41))
        let session = try await sut.sessions().first
        #expect(session?.endedAt == epoch.addingTimeInterval(10))
        #expect(session?.status == .ended)
    }

    @Test func timerRevealAndRecoveryUseOriginalStart() async throws {
        let (sut, _, activity, _) = fixture()
        try await sut.start(now: epoch)
        try await sut.showTimer(now: epoch.addingTimeInterval(50))
        #expect(await activity.phase == .timer)
        await activity.endAll()
        try await sut.showTimer(now: epoch.addingTimeInterval(30_000))
        #expect(await activity.startCount == 2)
        #expect(await activity.startedAt == epoch)
        #expect(await activity.phase == .timer)
        try await sut.end(now: epoch.addingTimeInterval(30_010))
        try await sut.showTimer(now: epoch.addingTimeInterval(30_020))
        #expect(await activity.sessionID == nil)
    }

    @Test func foregroundRecoversMissingActivity() async throws {
        let (sut, _, activity, _) = fixture()
        try await sut.start(now: epoch)
        await activity.endAll()
        try await sut.foreground(now: epoch.addingTimeInterval(30_000))
        #expect(await activity.startCount == 2)
        #expect(try await sut.sessions().count == 1)
    }

    @Test func deniedActivitiesStillSaveSessionsAndImmediatePreferenceWorks() async throws {
        let (sut, _, activity, preferences) = fixture()
        var settings = PickupSettings()
        settings.showTimerImmediately = true
        try preferences.setSettings(settings)
        try await sut.start(now: epoch)
        #expect(await activity.phase == .timer)
        try await sut.deleteAll(now: epoch)
        await activity.setFail()
        try await sut.start(now: epoch)
        #expect(try await sut.sessions().count == 1)
        #expect(preferences.string(for: SharedKeys.activityIssue) != nil)
    }

    @Test func concurrentStartsCannotCreateDuplicateSessions() async throws {
        let (sut, _, activity, _) = fixture()
        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<50 { group.addTask { try await sut.start(now: epoch) } }
            try await group.waitForAll()
        }
        #expect(try await sut.sessions().count == 1)
        #expect(await activity.startCount == 1)
    }

    @Test func deletingActiveSessionClearsActivityAndSnapshot() async throws {
        let (sut, _, activity, preferences) = fixture()
        try await sut.start(now: epoch)
        let ids = try await Set(sut.sessions().map(\.id))
        try await sut.delete(ids: ids, now: epoch)
        #expect(try await sut.sessions().isEmpty)
        #expect(await activity.sessionID == nil)
        #expect(try SnapshotCodec.decode(preferences.data(for: SharedKeys.sessionsSnapshot)).isEmpty)
    }

    @Test func failedSaveNeverStartsActivityAndReleasesQueue() async throws {
        let (sut, repository, activity, _) = fixture()
        await repository.setFailWrites()
        await #expect(throws: (any Error).self) { try await sut.start(now: epoch) }
        #expect(await activity.startCount == 0)
        #expect(try await sut.sessions().isEmpty)
    }
}
