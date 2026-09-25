import Foundation
import Testing
@testable import PickupCore

struct DropItTests {
    @Test func moodAndRoastBoundaries() {
        #expect(BrainMood(elapsed: -1) == .lockedIn)
        #expect(BrainMood(elapsed: .nan) == .lockedIn)
        #expect(BrainMood(elapsed: 299.99) == .lockedIn)
        #expect(BrainMood(elapsed: 300) == .eepy)
        #expect(BrainMood(elapsed: 599.99) == .eepy)
        #expect(BrainMood(elapsed: 600) == .brainrot)
        #expect(BrainMood(elapsed: 1199.99) == .brainrot)
        #expect(BrainMood(elapsed: 1200) == .rotten)
        #expect(BrainMood.roast(elapsed: 899) != BrainMood.roast(elapsed: 900))
        #expect(BrainMood.roast(elapsed: 1799) != BrainMood.roast(elapsed: 1800))
    }
    @Test func preferencesSurviveRoundTripAndRejectInvalidData() {
        let choices = DropItPreferences(dailyLimitMinutes: 0, interests: ["reading", "reading", "fake"], onboardingComplete: true)
        #expect(choices.dailyLimitMinutes == 15)
        #expect(choices.interests == ["reading"])
        #expect(DropItPreferences.decode(choices.encoded) == choices)
        #expect(DropItPreferences.decode("broken") == DropItPreferences())
        #expect(DropItPreferences(dailyLimitMinutes: Int.max).dailyLimitMinutes == 720)
    }
    @Test func streakStopsAtUnknownOrOverLimitAndExcludesToday() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Chicago"))
        let today = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 3)))
        let yesterday = try #require(calendar.date(byAdding: .day, value: -1, to: today))
        let earlier = try #require(calendar.date(byAdding: .day, value: -2, to: today))
        let choices = DropItPreferences(dailyLimitMinutes: 90)
        var days = [today: 6000.0, yesterday: 5400.0, earlier: 5300.0]
        var usage = DropItUsage(dailyDurations: days, apps: [], now: today, preferences: choices, calendar: calendar)
        #expect(usage.streak == 2)
        #expect(usage.priorWeekAverage == nil)
        #expect(usage.weekDays.count == 7)
        #expect(calendar.component(.weekday, from: try #require(usage.weekDays.first)) == 2)
        days[yesterday] = 5401
        usage = .init(dailyDurations: days, apps: [], now: today, preferences: choices, calendar: calendar)
        #expect(usage.streak == 0)
        days[yesterday] = nil
        usage = .init(dailyDurations: days, apps: [], now: today, preferences: choices, calendar: calendar)
        #expect(usage.streak == 0)
    }
    @Test func savingsRequireSevenCompletedDaysAndNeverGoNegative() throws {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: .now)
        var days: [Date: TimeInterval] = [today: 134 * 60]
        for offset in 1...7 { days[try #require(calendar.date(byAdding: .day, value: -offset, to: today))] = 190 * 60 }
        var usage = DropItUsage(dailyDurations: days, apps: [], now: today, preferences: .init(), calendar: calendar)
        #expect(usage.monthlyHoursBack == 50)
        #expect(usage.dailyTimeBack == 6000)
        usage = .init(dailyDurations: days, apps: [], now: today, preferences: .init(dailyLimitMinutes: 240), calendar: calendar)
        #expect(usage.monthlyHoursBack == 0)
    }
    @Test func missingDataDoesNotBecomeZeroUsage() {
        let usage = DropItUsage(dailyDurations: [:], apps: [], preferences: .init())
        #expect(usage.todayDuration == nil)
        #expect(usage.streak == 0)
        #expect(usage.monthlyHoursBack == nil)
        #expect(DropItDuration.minutes(.infinity) == "0m")
        #expect(DropItDuration.minutes(5399) == "1h 29m")
        #expect(DropItDuration.timer(134) == "2:14")
    }
    @Test func clearingDataRemovesGoalAndPrivateAppSelection() throws {
        let name = "DropItTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let preferences = SharedPreferences(defaults: defaults)
        preferences.setString(DropItPreferences(onboardingComplete: true).encoded, for: DropItPreferences.storageKey)
        preferences.setString("opaque-test-selection", for: DropItPreferences.selectionKey)
        preferences.clear()
        #expect(preferences.string(for: DropItPreferences.storageKey) == nil)
        #expect(preferences.string(for: DropItPreferences.selectionKey) == nil)
    }

}
