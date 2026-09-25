import Foundation
import PickupCore

@MainActor enum AppServices {
    // This lazy bootstrap is also used by intents when the app has no UI scene.
    static let shared: Result<AppServicesContainer, Error> = Result {
        guard let group = SharedKeys.appGroup(),
              let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group),
              let defaults = UserDefaults(suiteName: group) else { throw StorageError.appGroupUnavailable }
        var storeDirectory = url.appendingPathComponent("Library/Application Support", isDirectory: true)
        try FileManager.default.createDirectory(at: storeDirectory, withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication])
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try storeDirectory.setResourceValues(resourceValues)
        let preferences = SharedPreferences(defaults: defaults)
        let repository = try SwiftDataSessionRepository(storeURL: storeDirectory.appendingPathComponent("Pickup.store"))
        return AppServicesContainer(preferences: preferences,
            coordinator: SessionCoordinator(repository: repository, activities: ActivityKitClient(), preferences: preferences))
    }
}
