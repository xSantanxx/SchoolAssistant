import SwiftUI
import SwiftData

struct ClassesScreen: View {
    @Query(sort: \Meeting.name) private var classes: [Meeting]
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""

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
                    "No classes yet",
                    systemImage: "books.vertical",
                    description: Text("Tap Add Class to create your first class.")
                )
            }
        }
        .navigationTitle("My Classes")
        .alert("Couldn’t Delete Class", isPresented: $showDeleteError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu("Add Class") {
                    NavigationLink("Enter Manually") {
                        ContentView()
                    }
                    NavigationLink("Import from Calendar") {
                        CalendarImportScreen()
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

#Preview {
    NavigationStack {
        ClassesScreen()
    }
    .modelContainer(for: [Meeting.self, Assignment.self], inMemory: true)
}
