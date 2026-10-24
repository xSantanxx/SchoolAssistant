import Foundation
import Observation
import SwiftData
import UserNotifications

struct ReminderTiming {
    static func assignmentDates(priority: AssignmentPriority, dueDate: Date,
                                now: Date = Date(), calendar: Calendar = .current) -> [Date] {
        let days = priority == .medium ? 2 : 4
        var dates: [Date] = []
        if let early = calendar.date(byAdding: .day, value: -days, to: dueDate) {
            dates.append(early)
        }
        if priority == .high {
            let startOfDay = calendar.startOfDay(for: dueDate)
            // Early-morning deadlines stay on the due day; midnight must use the prior minute.
            let finalReminder = dueDate == startOfDay
                ? dueDate.addingTimeInterval(-60)
                : max(startOfDay, dueDate.addingTimeInterval(-3600))
            dates.append(finalReminder)
        }
        return dates.filter { $0 > now && $0 < dueDate }
    }

    static func classComponents(day: String, endTime: Date,
                                calendar: Calendar = .current) -> DateComponents? {
        let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        guard let index = weekdays.firstIndex(of: day) else { return nil }
        var components = DateComponents()
        // Weekday numbering is explicitly Gregorian; hours follow the device's local time.
        components.calendar = Calendar(identifier: .gregorian)
        components.weekday = index + 1
        components.hour = calendar.component(.hour, from: endTime)
        components.minute = calendar.component(.minute, from: endTime)
        components.second = 0
        return components
    }
}

final class ReminderNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping @Sendable (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}

@MainActor
@Observable
final class ReminderManager {
    static let shared = ReminderManager()

    private(set) var message = ""
    private(set) var needsPermission = false
    private let center = UNUserNotificationCenter.current()
    private let notificationDelegate = ReminderNotificationDelegate()
    private var refreshing = false
    private var refreshAgain = false
    private var shouldRequestPermission = false
    private let prefix = "schoolassistant."

    private init() {
        center.delegate = notificationDelegate
    }

    // Serialize refreshes so a save or completion cannot leave an older schedule installed.
    func refresh(context: ModelContext, requestPermission: Bool = false) async {
        shouldRequestPermission = shouldRequestPermission || requestPermission
        refreshAgain = true
        guard !refreshing else { return }
        refreshing = true
        defer { refreshing = false }
        while refreshAgain {
            refreshAgain = false
            let request = shouldRequestPermission
            shouldRequestPermission = false
            do {
                try await synchronize(context: context, requestPermission: request)
            } catch {
                message = "Your data is saved, but reminders could not be updated: \(error.localizedDescription). Reopen the app to retry."
            }
        }
    }

    func cancel(for assignment: Assignment) {
        cancel(identifiers: notificationIdentifiers(for: assignment))
    }

    func notificationIdentifiers(for assignment: Assignment) -> [String] {
        guard let id = assignment.reminderID else { return [] }
        return (0...1).map { "\(prefix)assignment.\(id.uuidString).\($0)" }
    }

    func notificationIdentifiers(for schoolClass: Meeting) -> [String] {
        var identifiers: [String] = []
        if let id = schoolClass.reminderID {
            let count = 1 + (schoolClass.secondDay != nil ? 1 : 0) + (schoolClass.additionalSchedules?.count ?? 0)
            for index in 0..<count {
                let base = "\(prefix)class.\(id.uuidString).\(index)"
                identifiers.append(contentsOf: [base, "\(base).start"])
            }
        }
        for assignment in schoolClass.assignments ?? [] {
            if let id = assignment.reminderID {
                identifiers.append(contentsOf: (0...1).map { "\(prefix)assignment.\(id.uuidString).\($0)" })
            }
        }
        return identifiers
    }

    func cancel(identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    private func synchronize(context: ModelContext, requestPermission: Bool) async throws {
        var settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined && requestPermission {
            _ = try await center.requestAuthorization(options: [.alert, .sound])
            settings = await center.notificationSettings()
        }
        needsPermission = settings.authorizationStatus == .notDetermined
        guard settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
                || settings.authorizationStatus == .ephemeral else {
            message = needsPermission
                ? "Enable notifications for assignment deadlines, class start times, and end-of-class check-ins."
                : "Notifications are off. Enable them for SchoolAssistant in system Settings."
            return
        }

        let assignments = try context.fetch(FetchDescriptor<Assignment>())
        let classes = try context.fetch(FetchDescriptor<Meeting>())
        var addedIDs = false
        for assignment in assignments where assignment.reminderID == nil {
            assignment.reminderID = UUID()
            addedIDs = true
        }
        for schoolClass in classes where schoolClass.reminderID == nil {
            schoolClass.reminderID = UUID()
            addedIDs = true
        }
        if addedIDs { try context.save() }

        let now = Date()
        var requests: [(request: UNNotificationRequest, date: Date)] = []
        for assignment in assignments {
            guard !assignment.isCompleted else {
                cancel(for: assignment)
                continue
            }
            guard let id = assignment.reminderID else { continue }
            let dates = ReminderTiming.assignmentDates(priority: assignment.priority,
                                                        dueDate: assignment.dueDate, now: now)
            for (index, date) in dates.enumerated() {
                let content = UNMutableNotificationContent()
                content.title = assignment.name
                content.body = "\(assignment.schoolClass?.name ?? "Class"): due \(assignment.dueDate.formatted(date: .abbreviated, time: .shortened))."
                content.sound = .default
                var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
                components.calendar = Calendar.current
                components.timeZone = Calendar.current.timeZone
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: "\(prefix)assignment.\(id.uuidString).\(index)",
                                                    content: content, trigger: trigger)
                requests.append((request, date))
            }
        }

        for schoolClass in classes {
            guard let id = schoolClass.reminderID else { continue }
            var schedules = [(schoolClass.day, schoolClass.sTime, schoolClass.eTime)]
            if let day = schoolClass.secondDay, let start = schoolClass.secondStartTime, let end = schoolClass.secondEndTime {
                schedules.append((day, start, end))
            }
            schedules.append(contentsOf: (schoolClass.additionalSchedules ?? []).map { ($0.day, $0.start, $0.end) })
            for (index, schedule) in schedules.enumerated() {
                if let startComponents = ReminderTiming.classComponents(day: schedule.0, endTime: schedule.1) {
                    let startTrigger = UNCalendarNotificationTrigger(dateMatching: startComponents, repeats: true)
                    if let startDate = startTrigger.nextTriggerDate() {
                        let startContent = UNMutableNotificationContent()
                        startContent.title = "\(schoolClass.name) is starting"
                        startContent.body = "Hope you enjoy today's class."
                        startContent.sound = .default
                        let startRequest = UNNotificationRequest(
                            identifier: "\(prefix)class.\(id.uuidString).\(index).start",
                            content: startContent, trigger: startTrigger
                        )
                        requests.append((startRequest, startDate))
                    }
                }
                guard let components = ReminderTiming.classComponents(day: schedule.0, endTime: schedule.2) else { continue }
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                guard let nextDate = trigger.nextTriggerDate() else { continue }
                let content = UNMutableNotificationContent()
                content.title = "\(schoolClass.name) is over"
                content.body = "Were you assigned anything? Open My Classes and select \(schoolClass.name) to add an assignment."
                content.sound = .default
                let request = UNNotificationRequest(identifier: "\(prefix)class.\(id.uuidString).\(index)",
                                                    content: content, trigger: trigger)
                requests.append((request, nextDate))
            }
        }

        let pending = await center.pendingNotificationRequests()
        let otherCount = pending.filter { !$0.identifier.hasPrefix(prefix) }.count
        // Keep the nearest reminders within the system's pending-notification budget.
        let capacity = max(0, 64 - otherCount)
        let selected = Array(requests.sorted { $0.date < $1.date }.prefix(capacity))
        let selectedIDs = Set(selected.map { $0.request.identifier })
        let obsolete = pending.filter {
            $0.identifier.hasPrefix(prefix) && !selectedIDs.contains($0.identifier)
        }.map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: obsolete)
        for entry in selected {
            // Reusing an identifier replaces its existing request instead of duplicating it.
            try await center.add(entry.request)
        }
        message = requests.count > capacity
            ? "The nearest \(capacity) reminders are scheduled. Open the app regularly to schedule later reminders."
            : ""
    }
}
