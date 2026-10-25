import SwiftUI
import SwiftData

struct DailyTaskScreen: View {
    @Environment(\.modelContext) private var modelContext
    @State private var activity: Meeting?
    @State private var errorMessage = ""
    let onFinished: () -> Void

    var body: some View {
        VStack {
            Group {
                if let activity {
                    AddAssignmentScreen(schoolClass: activity, onSaved: onFinished)
                } else if !errorMessage.isEmpty {
                    ContentUnavailableView {
                        Label("Couldn’t Open Daily Work", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Try Again", action: loadActivity)
                    }
                } else {
                    ProgressView("Opening Daily Work…")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: onFinished)
            }
        }
        .task { loadActivity() }
    }

    private func loadActivity() {
        // The form can reappear after app activation; load its model only once.
        guard activity == nil else { return }
        do {
            activity = try DailyWorkActivity.fetchOrCreate(in: modelContext)
            errorMessage = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

enum DailyWorkActivity {
    // A dedicated marker keeps this group separate from user-named activities.
    static func fetchOrCreate(in context: ModelContext) throws -> Meeting {
        var descriptor = FetchDescriptor<Meeting>(predicate: #Predicate { $0.isDailyWork })
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            return existing
        }
        let activity = Meeting(name: "Daily Work", day: "", sTime: Date(), eTime: Date())
        activity.isRegularActivity = true
        activity.isDailyWork = true
        context.insert(activity)
        do {
            try context.save()
            return activity
        } catch {
            context.delete(activity)
            throw error
        }
    }
}
