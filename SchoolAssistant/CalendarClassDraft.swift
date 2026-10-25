import Foundation
import EventKit

struct ClassMeetingTime: Codable, Identifiable {
    var id = UUID()
    var day: String
    var start: Date
    var end: Date

    static let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    var signature: String {
        let calendar = Calendar.current
        return "\(day)-\(calendar.component(.hour, from: start))-\(calendar.component(.minute, from: start))-\(calendar.component(.hour, from: end))-\(calendar.component(.minute, from: end))"
    }

    var isValid: Bool {
        let calendar = Calendar.current
        let startMinute = calendar.component(.hour, from: start) * 60 + calendar.component(.minute, from: start)
        let endMinute = calendar.component(.hour, from: end) * 60 + calendar.component(.minute, from: end)
        return Self.weekdays.contains(day) && endMinute > startMinute
    }
}

struct CalendarClassDraft: Identifiable {
    let id: String
    let calendarName: String
    var name: String
    var schedules: [ClassMeetingTime]
    var isSelected = false
    var isRegularActivity = false

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !schedules.isEmpty && schedules.allSatisfy(\.isValid)
    }

    static func group(events: [EKEvent]) -> [CalendarClassDraft] {
        var groups: [String: CalendarClassDraft] = [:]
        let calendar = Calendar.current
        let gregorian = Calendar(identifier: .gregorian)
        for event in events {
            guard !event.isAllDay, event.status != .canceled,
                  let start = event.startDate, let end = event.endDate,
                  end > start, calendar.isDate(start, inSameDayAs: end) else { continue }
            let name = (event.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }
            let calendarID = event.calendar.calendarIdentifier
            let key = "\(calendarID.count):\(calendarID)\(name.lowercased())"
            let schedule = ClassMeetingTime(
                day: ClassMeetingTime.weekdays[gregorian.component(.weekday, from: start) - 1],
                start: start, end: end
            )
            if groups[key] == nil {
                groups[key] = CalendarClassDraft(id: key, calendarName: event.calendar.title,
                                                name: name, schedules: [])
            }
            if groups[key]?.schedules.contains(where: { $0.signature == schedule.signature }) == false {
                groups[key]?.schedules.append(schedule)
            }
        }
        return groups.values.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
