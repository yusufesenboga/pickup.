import DeviceActivity
import Foundation
import PickupCore
import SwiftUI

enum ReportKind {
    case daily(Date)
    case session(SessionRecord)

    var context: DeviceActivityReport.Context {
        switch self {
        case .daily: .dailySummary
        case .session: .sessionApps
        }
    }

    var isDaily: Bool {
        if case .daily = self { return true }
        return false
    }

    func filter(at now: Date) -> DeviceActivityFilter {
        switch self {
        case .daily(let date):
            let day = Calendar.current.dateInterval(of: .day, for: date)
                ?? DateInterval(start: Calendar.current.startOfDay(for: date), duration: 86_400)
            return DeviceActivityFilter(segment: .daily(during: day), users: .all, devices: .init([.iPhone]))
        case .session(let session):
            let interval = DateInterval(start: session.startedAt,
                end: max(session.startedAt.addingTimeInterval(1), session.effectiveEnd ?? now))
            return DeviceActivityFilter(segment: .hourly(during: interval), users: .all, devices: .init([.iPhone]))
        }
    }
}
