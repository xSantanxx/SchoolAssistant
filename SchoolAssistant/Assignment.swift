import Foundation
import SwiftData

enum AssignmentPriority: String, Codable, CaseIterable, Identifiable {
    case low, medium, high

    var id: String { rawValue }

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
        return calendar.date(byAdding: .weekOfYear, value: weeks, to: date)
    }
}
