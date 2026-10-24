import SwiftUI
import SwiftData

struct ClassesScreen: View {
    @Query(sort: \Meeting.name) private var classes: [Meeting]

    var body: some View {
        List(classes) { schoolClass in
            NavigationLink {
                AddAssignmentScreen(schoolClass: schoolClass)
            } label: {
                ClassScheduleRow(schoolClass: schoolClass)
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink("Add Class") {
                    ContentView()
                }
            }
        }
    }
}

private struct ClassScheduleRow: View {
    let schoolClass: Meeting

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(schoolClass.name)
                .font(.headline)
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
