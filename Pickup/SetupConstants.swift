import Foundation

enum SetupConstants {
    static let screenshotNames = [
        "SetupScreenTime", "SetupLiveActivities", "SetupShortcut",
        "SetupAutomationOpened", "SetupAutomationClosed", "SetupTest"
    ]

    static let shortcutManifest: ShortcutManifest? = {
        guard let url = Bundle.main.url(forResource: "ShortcutManifest", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let manifest = try? JSONDecoder().decode(ShortcutManifest.self, from: data),
              manifest.bundleIdentifier == Bundle.main.bundleIdentifier else { return nil }
        let team = Bundle.main.object(forInfoDictionaryKey: "PickupSigningTeam") as? String ?? ""
        guard team.isEmpty || team == manifest.teamIdentifier else { return nil }
        return manifest
    }()
}

struct ShortcutManifest: Decodable {
    let bundleIdentifier: String
    let teamIdentifier: String
    let waitSeconds: Int
    let installURLs: [String: String]?
}

enum SetupShortcut: String, Identifiable {
    case start = "Pickup Session"
    case end = "Pickup End Session"
    case opened = "Pickup Apps Opened"
    case closed = "Pickup Apps Closed"

    var id: String { rawValue }

    private var supportedOnThisOS: Bool {
        if self == .opened || self == .closed {
            if #available(iOS 27, *) { return true }
            return false
        }
        return true
    }

    var installURL: URL? {
        guard supportedOnThisOS else { return nil }
        guard let value = SetupConstants.shortcutManifest?.installURLs?[rawValue + ".shortcut"],
              let url = URL(string: value), url.scheme == "https", url.host == "www.icloud.com",
              url.path.hasPrefix("/shortcuts/") else { return nil }
        return url
    }

    var fileURL: URL? {
        guard supportedOnThisOS, SetupConstants.shortcutManifest != nil else { return nil }
        return Bundle.main.url(forResource: rawValue, withExtension: "shortcut")
    }
}
