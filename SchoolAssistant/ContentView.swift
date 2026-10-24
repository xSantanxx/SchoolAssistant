import SwiftUI
import SwiftData

@Model
class Meeting {
    var name: String
    var day: String
    var sTime: Date
    var eTime: Date
    // Optional fields keep existing single-day classes compatible.
    var secondDay: String?
    var secondStartTime: Date?
    var secondEndTime: Date?
    
    init(name: String, day: String, sTime: Date, eTime: Date) {
        self.name = name
        self.day = day
        self.sTime = sTime
        self.eTime = eTime
    }
}


struct MeetingTimeSelection {
    var start: Date
    var end: Date
    let initialEnd: Date

    init(now: Date = Date()) {
        start = now
        end = now
        initialEnd = now
    }

    var hasChangedEndingTime: Bool {
        // The picker exposes only hours and minutes, so ignore seconds and dates.
        let calendar = Calendar.current
        return calendar.component(.hour, from: end) != calendar.component(.hour, from: initialEnd)
            || calendar.component(.minute, from: end) != calendar.component(.minute, from: initialEnd)
    }
}

struct ContentView: View {
    @State private var className = ""
    @State private var days = ""
    @State private var meetingDay1 = ""
    @State private var meetingDay2 = ""
    @State private var showMultipleDays = false
    @State private var singleTime = MeetingTimeSelection()
    @State private var firstTime = MeetingTimeSelection()
    @State private var secondTime = MeetingTimeSelection()
    @State private var meetingDate1 = Date()
    @State private var meetingDate2 = Date()
    @State private var showAlert = false
    @State private var validationMessage = ""
    @State private var showSuccessAlert = false
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        
        Form {
            
            NavigationLink("My Classes") {
                HomeScreen()
            }

            TextField("Class name", text: $className)
            
            
            Button("Click if your class occurs on multiple days"){
                showMultipleDays.toggle()
            }
            
            if showMultipleDays {
                Picker("Meeting Day 1", selection: $meetingDay1){
                    Text("Select a day").tag("")
                    Text("Monday").tag("Monday")
                    Text("Tuesday").tag("Tuesday")
                    Text("Wednesday").tag("Wednesday")
                    Text("Thursday").tag("Thursday")
                    Text("Friday").tag("Friday")
                    Text("Saturday").tag("Saturday")
                    Text("Sunday").tag("Sunday")
                }
                
                DatePicker("Starting Time", selection: $firstTime.start, displayedComponents: .hourAndMinute)
                
                DatePicker("Ending Time", selection: $firstTime.end, displayedComponents: .hourAndMinute)
                
                DatePicker("Meeting Date 2", selection: $meetingDate1, displayedComponents: .date)
                
                
                Picker("Meeting Day 2", selection: $meetingDay2){
                    Text("Select a day").tag("")
                    Text("Monday").tag("Monday")
                    Text("Tuesday").tag("Tuesday")
                    Text("Wednesday").tag("Wednesday")
                    Text("Thursday").tag("Thursday")
                    Text("Friday").tag("Friday")
                    Text("Saturday").tag("Saturday")
                    Text("Sunday").tag("Sunday")
                }
                
                DatePicker("Starting Time", selection: $secondTime.start, displayedComponents: .hourAndMinute)
                
                DatePicker("Ending Time", selection: $secondTime.end, displayedComponents: .hourAndMinute)
                
                
            } else {
                
                Picker("Meeting Day", selection: $days){
                    Text("Select a day").tag("")
                    Text("Monday").tag("Monday")
                    Text("Tuesday").tag("Tuesday")
                    Text("Wednesday").tag("Wednesday")
                    Text("Thursday").tag("Thursday")
                    Text("Friday").tag("Friday")
                    Text("Saturday").tag("Saturday")
                    Text("Sunday").tag("Sunday")
                }
                
                DatePicker("Starting Time", selection: $singleTime.start, displayedComponents: .hourAndMinute)
                
                DatePicker("Ending Time", selection: $singleTime.end, displayedComponents: .hourAndMinute)
            }
            
            Button("Save", action: saveClass)
            .alert("Success!", isPresented: $showSuccessAlert){
                Button("Ok", role: .cancel){}
            } message: {
                Text("Your information has been succesfully added :)")
            }
            
            
            .alert("Couldn’t save class", isPresented: $showSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveErrorMessage)
            }
            .alert("Check class details", isPresented: $showAlert){
                Button("Ok", role: .cancel){}
            } message: {
                Text(validationMessage)
            }
        }
    }

    private func saveClass() {
        let name = className.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            showValidation("Enter a class name.")
            return
        }

        let validDays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        if showMultipleDays {
            guard validDays.contains(meetingDay1), validDays.contains(meetingDay2) else {
                showValidation("Select a day for both meetings.")
                return
            }
            guard meetingDay1 != meetingDay2 else {
                showValidation("Choose two different meeting days.")
                return
            }
            guard firstTime.hasChangedEndingTime else {
                showValidation("Change the ending time for Meeting Day 1 from its initial time.")
                return
            }
            guard secondTime.hasChangedEndingTime else {
                showValidation("Change the ending time for Meeting Day 2 from its initial time.")
                return
            }
        } else {
            guard validDays.contains(days) else {
                showValidation("Select a meeting day.")
                return
            }
            guard singleTime.hasChangedEndingTime else {
                showValidation("Change the ending time from its initial time.")
                return
            }
        }

        let time = showMultipleDays ? firstTime : singleTime
        let newMeeting = Meeting(
            name: name,
            day: showMultipleDays ? meetingDay1 : days,
            sTime: time.start,
            eTime: time.end
        )
        if showMultipleDays {
            newMeeting.secondDay = meetingDay2
            newMeeting.secondStartTime = secondTime.start
            newMeeting.secondEndTime = secondTime.end
        }

        modelContext.insert(newMeeting)
        do {
            try modelContext.save()
            showSuccessAlert = true
        } catch {
            modelContext.delete(newMeeting)
            saveErrorMessage = error.localizedDescription
            showSaveError = true
        }
    }

    private func showValidation(_ message: String) {
        validationMessage = message
        showAlert = true
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
    .modelContainer(for: Meeting.self, inMemory: true)
}
