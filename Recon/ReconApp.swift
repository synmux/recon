import SwiftUI

@main
struct ReconApp: App {
    @State private var session = ReconSession()
    @State private var router = ReconRouter()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(session)
                .environment(router)
                .tint(Color.accent)
        }
    }
}
