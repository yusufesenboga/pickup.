import SwiftUI

@main struct PickupApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                .tint(DropIt.purple)
                .font(DropIt.body())
                .preferredColorScheme(.light)
        }
    }
}
