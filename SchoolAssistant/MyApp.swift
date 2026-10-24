import SwiftUI
import SwiftData

@main struct MyApp: App {
    @AppStorage("userName") private var userName = ""

    init() {
        _ = ReminderManager.shared
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    WelcomeScreen()
                } else {
                    HomeScreen()
                }
            }
        }
        .modelContainer(for: [Meeting.self, Assignment.self])
    }
}
