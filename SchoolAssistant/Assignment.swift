import Foundation
import SwiftData

enum AssignmentPriority: String, Codable, CaseIterable, Identifiable {
    case low, medium, high

    var id: String { rawValue }

    var reminderDescription: LocalizedStringResource {
        switch self {
        case .low: "Low: one reminder 4 days before the due date."
        case .medium: "Medium: one reminder 2 days before the due date."
        case .high: "High: 4 days before, plus 1 hour before the deadline on the due day. For deadlines before 1 AM, the last reminder is at midnight; a midnight deadline is reminded 1 minute earlier."
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }
}

@Model
final class Assignment {
    var name: String
    var assignedAt: Date
    var dueDate: Date
    var priority: AssignmentPriority
    var isCompleted: Bool = false
    var schoolClass: Meeting?
    var reminderID: UUID?

    init(name: String, assignedAt: Date = Date(), dueDate: Date,
         priority: AssignmentPriority, schoolClass: Meeting) {
        self.name = name
        self.assignedAt = assignedAt
        self.dueDate = dueDate
        self.priority = priority
        self.schoolClass = schoolClass
    }

    static func dueDate(afterWeeks weeks: Int, from date: Date, calendar: Calendar = .current) -> Date? {
        guard weeks > 0 else { return nil }
        guard let day = calendar.date(byAdding: .weekOfYear, value: weeks, to: date) else { return nil }
        return calendar.date(bySettingHour: 23, minute: 59, second: 0, of: day)
    }
}
