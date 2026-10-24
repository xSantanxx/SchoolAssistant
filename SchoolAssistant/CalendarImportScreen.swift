import SwiftUI
import SwiftData
import EventKit

struct CalendarImportScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var eventStore = EKEventStore()
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var drafts: [CalendarClassDraft] = []
    @State private var isLoading = false
    @State private var showingReview = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        Form {
            Section("Find Your Classes") {
                Text("Choose a date range containing your usual class schedule. Events from calendars connected to this device will be available for review.")
                DatePicker("From", selection: $startDate, displayedComponents: .date)
                DatePicker("Through", selection: $endDate, displayedComponents: .date)
                Button {
                    Task { await loadEvents() }
                } label: {
                    if isLoading {
                        ProgressView("Reading Calendar…")
                    } else {
                        Text("Find Classes in Calendar")
                    }
                }
                .disabled(isLoading)
            }
            Section("Before Importing") {
                Text("You’ll select which events are classes and review or edit their names, weekdays, and times before confirming.")
                Text("Events with the same name in the same calendar are grouped. All-day, canceled, and overnight events are excluded.")
                Text("Imported times become weekly class schedules. This is a one-time import, not ongoing calendar sync. Your calendar events won’t be changed.")
            }
        }
        .navigationTitle("Import from Calendar")
        .sheet(isPresented: $showingReview) {
            NavigationStack {
                CalendarImportReviewScreen(drafts: drafts) {
                    showingReview = false
                    dismiss()
                }
            }
        }
        .alert("Calendar Import", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func loadEvents() async {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        guard let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)),
              end > start,
              let limit = calendar.date(byAdding: .year, value: 1, to: start), end <= limit else {
            errorMessage = "Choose an end date on or after the start date, within one year."
            showError = true
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            guard granted else {
                errorMessage = "Calendar access is off. Allow full Calendar access for SchoolAssistant in system Settings, or enter your classes manually."
                showError = true
                return
            }
            let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
            let events = eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
            let existing = try modelContext.fetch(FetchDescriptor<Meeting>())
            let importedKeys = Set(existing.compactMap(\.calendarImportKey))
            drafts = CalendarClassDraft.group(events: events).filter { !importedKeys.contains($0.id) }
            guard !drafts.isEmpty else {
                errorMessage = "No new timed events were found. Try another date range, check your connected calendars, or enter classes manually. Previously imported classes are skipped."
                showError = true
                return
            }
            showingReview = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct CalendarImportReviewScreen: View {
    @State private var drafts: [CalendarClassDraft]
    let onImported: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSaving = false

    init(drafts: [CalendarClassDraft], onImported: @escaping () -> Void) {
        _drafts = State(initialValue: drafts)
        self.onImported = onImported
    }

    private var selectedCount: Int { drafts.filter(\.isSelected).count }

    var body: some View {
        Form {
            Section {
                Text("Select only your classes. Check every weekday and time before confirming. Times are shown in your device’s time zone and will repeat weekly.")
            }
            ForEach($drafts) { $draft in
                CalendarClassReviewSection(draft: $draft)
            }
            Button("Confirm Import (\(selectedCount) classes)", action: importClasses)
                .disabled(selectedCount == 0 || isSaving)
        }
        .navigationTitle("Review Classes")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .alert("Couldn’t Import Classes", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func importClasses() {
        let selected = drafts.filter(\.isSelected)
        guard !selected.isEmpty, selected.allSatisfy(\.isValid) else {
            errorMessage = "Each selected class needs a name and valid meeting times. Ending times must be later than starting times on the same day."
            showError = true
            return
        }
        isSaving = true
        defer { isSaving = false }
        var inserted: [Meeting] = []
        do {
            let existing = try modelContext.fetch(FetchDescriptor<Meeting>())
            let importedKeys = Set(existing.compactMap(\.calendarImportKey))
            for draft in selected where !importedKeys.contains(draft.id) {
                guard let first = draft.schedules.first else { continue }
                let schoolClass = Meeting(name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
                                          day: first.day, sTime: first.start, eTime: first.end)
                schoolClass.calendarImportKey = draft.id
                if draft.schedules.count > 1 {
                    let second = draft.schedules[1]
                    schoolClass.secondDay = second.day
                    schoolClass.secondStartTime = second.start
                    schoolClass.secondEndTime = second.end
                }
                schoolClass.additionalSchedules = Array(draft.schedules.dropFirst(2))
                modelContext.insert(schoolClass)
                inserted.append(schoolClass)
            }
            try modelContext.save()
            Task { await ReminderManager.shared.refresh(context: modelContext, requestPermission: true) }
            onImported()
        } catch {
            for schoolClass in inserted { modelContext.delete(schoolClass) }
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

private struct CalendarClassReviewSection: View {
    @Binding var draft: CalendarClassDraft

    var body: some View {
        Section {
            Toggle("Import \(draft.name)", isOn: $draft.isSelected)
            Text(draft.calendarName)
                .font(.caption)
                .foregroundStyle(.secondary)
            if draft.isSelected {
                TextField("Class name", text: $draft.name)
                ForEach($draft.schedules) { $schedule in
                    VStack(alignment: .leading) {
                        Picker("Meeting day", selection: $schedule.day) {
                            ForEach(ClassMeetingTime.weekdays, id: \.self) { day in
                                Text(day).tag(day)
                            }
                        }
                        DatePicker("Starts", selection: $schedule.start, displayedComponents: .hourAndMinute)
                        DatePicker("Ends", selection: $schedule.end, displayedComponents: .hourAndMinute)
                        Button("Remove Meeting", role: .destructive) {
                            draft.schedules.removeAll { $0.id == schedule.id }
                        }
                    }
                }
            }
        }
    }
}
