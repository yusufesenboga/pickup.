import PickupCore

struct AppServicesContainer: Sendable {
    let preferences: SharedPreferences
    let coordinator: SessionCoordinator
}
