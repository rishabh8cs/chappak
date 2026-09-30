import SwiftUI

@main
struct ChappakApp: App {
    @State private var swimStore = SwimStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(swimStore)
        }
    }
}
