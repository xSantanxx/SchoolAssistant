import SwiftUI
import SwiftData

struct AssignmentDetailsScreen: View {
    let assignment: Assignment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        Form {
            LabeledContent("Name", value: assignment.name)
            LabeledContent("Class", value: assignment.schoolClass?.name ?? "Unknown class")
            LabeledContent("Assigned") {
                Text(assignment.assignedAt, format: .dateTime.year().month().day().hour().minute().second())
            }
            LabeledContent("Due") {
                Text(assignment.dueDate, format: .dateTime.year().month().day().hour().minute())
            }
            LabeledContent("Priority") {
                Text(assignment.priority.title)
            }
            if assignment.isCompleted {
                Label("Completed", systemImage: "checkmark.circle.fill")
            } else {
                Button("Mark Completed", action: completeAssignment)
            }
        }
        .navigationTitle("Assignment Details")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .alert("Couldn’t update assignment", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func completeAssignment() {
        assignment.isCompleted = true
        do {
            try modelContext.save()
            dismiss()
        } catch {
            assignment.isCompleted = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
