import Foundation
import PickupCore

enum ReportPreferences {
    static func shared() -> SharedPreferences? {
        guard let group = SharedKeys.appGroup(), let defaults = UserDefaults(suiteName: group) else { return nil }
        return SharedPreferences(defaults: defaults)
    }
}
