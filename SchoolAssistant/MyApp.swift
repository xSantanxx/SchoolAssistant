import SwiftUI
import SwiftData

@main struct MyApp: App {
    init() {
        _ = ReminderManager.shared
    }

    var body: some Scene {
        WindowGroup {
            AppRootScreen()
        }
        .modelContainer(for: [Meeting.self, Assignment.self])
    }
}

private struct AppRootScreen: View {
    @AppStorage("userName") private var userName = ""
    @AppStorage("dailyLifeMode") private var isRegularActivity = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingDailyTask = false
    private let reminders = ReminderManager.shared

    private var canOpenDailyTask: Bool {
        scenePhase == .active && reminders.showDailyTask
    }

    var body: some View {
        NavigationStack {
            Group {
                if userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    WelcomeScreen()
                } else {
                    HomeScreen()
                }
            }
            .navigationDestination(isPresented: $showingDailyTask) {
                DailyTaskScreen {
                    showingDailyTask = false
                }
            }
        }
        .task(id: canOpenDailyTask) {
            guard canOpenDailyTask else { return }
            // Let activation and any existing sheet dismissal finish before navigating.
            await Task.yield()
            guard !Task.isCancelled, scenePhase == .active else { return }
            isRegularActivity = true
            showingDailyTask = true
            reminders.showDailyTask = false
        }
    }
}
