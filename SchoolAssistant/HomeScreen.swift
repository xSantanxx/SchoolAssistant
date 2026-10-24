import SwiftUI
import SwiftData

struct HomeScreen: View {
    @AppStorage("userName") private var userName = ""
    @Query(filter: #Predicate<Assignment> { !$0.isCompleted },
           sort: \Assignment.assignedAt, order: .reverse)
    private var activeAssignments: [Assignment]
    @Query(filter: #Predicate<Assignment> { $0.isCompleted },
           sort: \Assignment.assignedAt, order: .reverse)
    private var completedAssignments: [Assignment]
    @State private var selectedAssignment: Assignment?
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    private let reminders = ReminderManager.shared

    var body: some View {
        List {
            ForEach(activeAssignments) { assignment in
                Button {
                    selectedAssignment = assignment
                } label: {
                    AssignmentRow(assignment: assignment)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteAssignment(assignment)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            ForEach(completedAssignments) { assignment in
                Button {
                    selectedAssignment = assignment
                } label: {
                    AssignmentRow(assignment: assignment)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteAssignment(assignment)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
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
        .safeAreaInset(edge: .bottom) {
            if !reminders.message.isEmpty {
                VStack(spacing: 8) {
                    Text(reminders.message)
                        .font(.caption)
                    if reminders.needsPermission {
                        Button("Enable Notifications") {
                            Task {
                                await reminders.refresh(context: modelContext, requestPermission: true)
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.regularMaterial)
            }
        }
        .task(id: scenePhase) {
            if scenePhase == .active {
                await reminders.refresh(context: modelContext)
            }
        }
        .alert("Couldn’t Delete Assignment", isPresented: $showDeleteError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage)
        }
        .navigationTitle("My Assignments")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                if !userName.isEmpty {
                    Text(String(userName.prefix(12)))
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
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
    private func deleteAssignment(_ assignment: Assignment) {
        let identifiers = reminders.notificationIdentifiers(for: assignment)
        if selectedAssignment?.persistentModelID == assignment.persistentModelID {
            selectedAssignment = nil
        }
        modelContext.delete(assignment)
        do {
            try modelContext.save()
            reminders.cancel(identifiers: identifiers)
            Task { await reminders.refresh(context: modelContext) }
        } catch {
            modelContext.rollback()
            deleteErrorMessage = error.localizedDescription
            showDeleteError = true
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
