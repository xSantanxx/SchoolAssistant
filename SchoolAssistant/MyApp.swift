import SwiftUI
import SwiftData

@main struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeScreen()
            }
        }
        .modelContainer(for: [Meeting.self, Assignment.self])
    }
}
