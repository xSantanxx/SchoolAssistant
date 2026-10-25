import SwiftUI
import SwiftData

enum DailyReminderSlot: String, CaseIterable, Identifiable {
    case morning, noon, evening

    var id: String { rawValue }
    var key: String { "dailyReminder.\(rawValue).minutes" }
    var defaultMinutes: Int {
        switch self {
        case .morning: 8 * 60
        case .noon: 12 * 60
        case .evening: 18 * 60
        }
    }
    var title: LocalizedStringResource {
        switch self {
        case .morning: "Morning"
        case .noon: "Noon"
        case .evening: "Evening"
        }
    }

    func minutes(defaults: UserDefaults = .standard) -> Int {
        guard defaults.object(forKey: key) != nil else { return defaultMinutes }
        let value = defaults.integer(forKey: key)
        return (0..<1440).contains(value) ? value : defaultMinutes
    }
}

struct DailyReminderSettings: View {
    @Environment(\.modelContext) private var modelContext
    private let reminders = ReminderManager.shared

    var body: some View {
        Form {
            Section("Daily Day Reminders") {
                ForEach(DailyReminderSlot.allCases) { slot in
                    DailyReminderTimePicker(slot: slot)
                }
                Text("Every day, we’ll remind you to write down your tasks. Tap a notification to add a task to Daily Work.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !reminders.message.isEmpty {
                Section("Notifications") {
                    Text(reminders.message)
                    if reminders.needsPermission {
                        Button("Enable Notifications") {
                            Task {
                                await reminders.refresh(context: modelContext, requestPermission: true)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .task {
            await reminders.refresh(context: modelContext, requestPermission: true)
        }
    }
}

private struct DailyReminderTimePicker: View {
    let slot: DailyReminderSlot
    @AppStorage private var minutes: Int
    @Environment(\.modelContext) private var modelContext

    init(slot: DailyReminderSlot) {
        self.slot = slot
        _minutes = AppStorage(wrappedValue: slot.defaultMinutes, slot.key)
    }

    var body: some View {
        DatePicker(selection: Binding(
            get: {
                Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60,
                                      second: 0, of: Date()) ?? Date()
            },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            }
        ), displayedComponents: .hourAndMinute) {
            Text(slot.title)
        }
        .onChange(of: minutes) {
            Task {
                await ReminderManager.shared.refresh(context: modelContext, requestPermission: true)
            }
        }
    }
}
