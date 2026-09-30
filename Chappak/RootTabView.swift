import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            SwimView()
                .tabItem { Label("Swim", systemImage: "figure.pool.swim") }
        }
    }
}

#Preview {
    RootTabView().environment(SwimStore.preview)
}
