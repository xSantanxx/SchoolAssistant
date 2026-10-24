import SwiftUI
import SwiftData

struct HomeScreen: View {
    @Query(filter: #Predicate<Assignment> { !$0.isCompleted },
           sort: \Assignment.assignedAt, order: .reverse)
    private var activeAssignments: [Assignment]
    @Query(filter: #Predicate<Assignment> { $0.isCompleted },
           sort: \Assignment.assignedAt, order: .reverse)
    private var completedAssignments: [Assignment]
    @State private var selectedAssignment: Assignment?

    var body: some View {
        List {
            ForEach(activeAssignments) { assignment in
                Button {
                    selectedAssignment = assignment
                } label: {
                    AssignmentRow(assignment: assignment)
                }
                .buttonStyle(.plain)
            }
            ForEach(completedAssignments) { assignment in
                Button {
                    selectedAssignment = assignment
                } label: {
                    AssignmentRow(assignment: assignment)
                }
                .buttonStyle(.plain)
            }
        }
        .overlay {
            if activeAssignments.isEmpty && completedAssignments.isEmpty {
                ContentUnavailableView(
                    "No assignments yet",
                    systemImage: "list.bullet.clipboard",
                    description: Text("Open My Classes and select a class to add an assignment.")
                )
            }
        }
        .navigationTitle("Assignments")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink("My Classes") {
                    ClassesScreen()
                }
            }
        }
        .sheet(item: $selectedAssignment) { assignment in
            NavigationStack {
                AssignmentDetailsScreen(assignment: assignment)
            }
        }
    }
}

private struct AssignmentRow: View {
    let assignment: Assignment

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(assignment.name)
                .font(.headline)
                .strikethrough(assignment.isCompleted)
            Text(assignment.schoolClass?.name ?? "Unknown class")
                .font(.subheadline)
            Text("Due \(assignment.dueDate.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
            if assignment.isCompleted {
                Label("Completed", systemImage: "checkmark.circle.fill")
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .opacity(assignment.isCompleted ? 0.5 : 1)
    }
}

#Preview {
    NavigationStack {
        HomeScreen()
    }
    .modelContainer(for: [Meeting.self, Assignment.self], inMemory: true)
}
