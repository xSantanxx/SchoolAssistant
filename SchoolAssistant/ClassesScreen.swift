import SwiftUI
import SwiftData

struct ClassesScreen: View {
    var isRegularActivity = false
    @Query(sort: \Meeting.name) private var allClasses: [Meeting]
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""

    private var classes: [Meeting] {
        allClasses.filter { $0.isRegularActivity == isRegularActivity }
    }

    var body: some View {
        List(classes) { schoolClass in
            NavigationLink {
                AddAssignmentScreen(schoolClass: schoolClass)
            } label: {
                ClassScheduleRow(schoolClass: schoolClass)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    deleteClass(schoolClass)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .overlay {
            if classes.isEmpty {
                ContentUnavailableView(
                    isRegularActivity ? "No activities yet" : "No classes yet",
                    systemImage: "books.vertical",
                    description: Text(isRegularActivity ? "Tap Add Activity to create your first activity." : "Tap Add Class to create your first class.")
                )
            }
        }
        .navigationTitle(isRegularActivity ? "My Activities" : "My Classes")
        .alert(isRegularActivity ? "Couldn’t Delete Activity" : "Couldn’t Delete Class", isPresented: $showDeleteError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu(isRegularActivity ? "Add Activity" : "Add Class") {
                    NavigationLink("Enter Manually") {
                        ContentView(isRegularActivity: isRegularActivity)
                    }
                    NavigationLink("Import from Calendar") {
                        CalendarImportScreen(isRegularActivity: isRegularActivity)
                    }
                }
            }
        }
    }
    private func deleteClass(_ schoolClass: Meeting) {
        // Capture notification IDs before the cascading deletion invalidates the models.
        let identifiers = ReminderManager.shared.notificationIdentifiers(for: schoolClass)
        modelContext.delete(schoolClass)
        do {
            try modelContext.save()
            ReminderManager.shared.cancel(identifiers: identifiers)
            Task { await ReminderManager.shared.refresh(context: modelContext) }
        } catch {
            modelContext.rollback()
            deleteErrorMessage = error.localizedDescription
            showDeleteError = true
        }
    }
}

private struct ClassScheduleRow: View {
    let schoolClass: Meeting

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(schoolClass.name)
                .font(.headline)
            if schoolClass.isDailyWork {
                Text("Daily tasks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(schoolClass.additionalSchedules ?? []) { schedule in
                    Text(schedule.day)
                    Text("\(schedule.start.formatted(date: .omitted, time: .shortened)) – \(schedule.end.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                }
                Text(schoolClass.day)
                Text("\(schoolClass.sTime.formatted(date: .omitted, time: .shortened)) – \(schoolClass.eTime.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                if let day = schoolClass.secondDay,
                   let start = schoolClass.secondStartTime,
                   let end = schoolClass.secondEndTime {
                    Text(day)
                    Text("\(start.formatted(date: .omitted, time: .shortened)) – \(end.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ClassesScreen()
    }
    .modelContainer(for: [Meeting.self, Assignment.self], inMemory: true)
}
