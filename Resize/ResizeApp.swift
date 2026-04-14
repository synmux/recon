import SwiftUI

@main
struct ResizeApp: App {
    @State private var session = ResizeSession()
    @State private var router = ResizeRouter()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(session)
                .environment(router)
                .tint(Color.accent)
        }
    }
}
