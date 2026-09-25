import Foundation

enum StorageError: LocalizedError {
    case appGroupUnavailable

    var errorDescription: String? {
        L10n.text("Shared storage is unavailable. Check the App Group and signing capabilities in Xcode, then reopen Pickup.")
    }
}
