import Foundation

public enum SharedKeys {
    public static let appGroupInfoKey = "PickupAppGroup"
    public static let settings = "settings"
    public static let sessionsSnapshot = "sessionsSnapshot"
    public static let snapshotCoverageStart = "snapshotCoverageStart"
    public static let lastStartEventAt = "lastStartEventAt"
    public static let lastEndEventAt = "lastEndEventAt"
    public static let activityIssue = "activityIssue"
    public static let completedSetupSteps = "completedSetupSteps"
    public static let snapshotLimit = 99_000
    public static let retentionDays = 90
    public static let maximumActivityDuration: TimeInterval = 8 * 60 * 60

    public static func appGroup(in bundle: Bundle = .main) -> String? {
        bundle.object(forInfoDictionaryKey: appGroupInfoKey) as? String
    }
}
