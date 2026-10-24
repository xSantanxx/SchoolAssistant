import SwiftUI
import SwiftData

struct AddAssignmentScreen: View {
    let schoolClass: Meeting

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar
    @State private var name = ""
    @State private var priority = AssignmentPriority.medium
    @State private var useWeeks = false
    @State private var weeks = 1
    @State private var manualDueDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: Date()) ?? Date()
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        Form {
            Section("Assignment") {
                LabeledContent("Class", value: schoolClass.name)
                TextField("Assignment name", text: $name)
                Text("The assigned date and time are recorded automatically when you save.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Priority", selection: $priority) {
                    ForEach(AssignmentPriority.allCases) { priority in
                        Text(priority.title).tag(priority)
                    }
                }
            }

            Section("Priority Reminders") {
                ForEach(AssignmentPriority.allCases) { priority in
                    Text(priority.reminderDescription)
                        .font(.caption)
                }
                Text("Reminder times that have already passed are skipped. Notifications require permission in System Settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            AssignmentDueDateFields(
                useWeeks: $useWeeks,
                weeks: $weeks,
                manualDueDate: $manualDueDate
            )

            Button("Save Assignment", action: saveAssignment)
        }
        .navigationTitle("Add Assignment")
        .alert("Couldn’t save assignment", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func saveAssignment() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Enter an assignment name."
            showError = true
            return
        }

        let assignedAt = Date()
        let calculatedDueDate = useWeeks
            ? Assignment.dueDate(afterWeeks: weeks, from: assignedAt, calendar: calendar)
            : manualDueDate
        guard let dueDate = calculatedDueDate else {
            errorMessage = "Choose a valid number of weeks."
            showError = true
            return
        }

        let assignment = Assignment(
            name: trimmedName,
            assignedAt: assignedAt,
            dueDate: dueDate,
            priority: priority,
            schoolClass: schoolClass
        )
        modelContext.insert(assignment)
        do {
            try modelContext.save()
            Task { await ReminderManager.shared.refresh(context: modelContext, requestPermission: true) }
            dismiss()
        } catch {
            modelContext.delete(assignment)
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

private struct AssignmentDueDateFields: View {
    @Binding var useWeeks: Bool
    @Binding var weeks: Int
    @Binding var manualDueDate: Date
    @Environment(\.calendar) private var calendar

    var body: some View {
        Section("Due Date") {
            Picker("Set due date", selection: $useWeeks) {
                Text("Choose a date").tag(false)
                Text("Number of weeks").tag(true)
            }
            if useWeeks {
                Stepper("Weeks: \(weeks)", value: $weeks, in: 1...520)
                if let date = Assignment.dueDate(afterWeeks: weeks, from: Date(), calendar: calendar) {
                    LabeledContent("Calculated due date") {
                        Text(date, format: .dateTime.year().month().day().hour().minute())
                    }
                }
            } else {
                DatePicker("Due date", selection: $manualDueDate, displayedComponents: [.date, .hourAndMinute])
            }
        }
    }
}
