import SwiftUI
import SwiftData

@Model
class Meeting {
    var name: String
    var day: String
    var sTime: Date
    var eTime: Date
    
    init(name: String, day: String, sTime: Date, eTime: Date) {
        self.name = name
        self.day = day
        self.sTime = sTime
        self.eTime = eTime
    }
}


struct ContentView: View {
    @State private var className = ""
    @State private var days = ""
    @State private var meetingDay1 = 0
    @State private var meetingDay2 = 0
    @State private var showMultipleDays = false
    @State private var meetingDateStart = Date()
    @State private var meetingDateEnd = Date()
    @State private var meetingDate1Start = Date()
    @State private var meetingDate1End = Date()
    @State private var meetingDate2Start = Date()
    @State private var meetingDate2End = Date()
    @State private var meetingDate1 = Date()
    @State private var meetingDate2 = Date()
    @State private var showAlert = false
    @State private var showSuccessAlert = false
    @Environment(\.modelContext) private var modelContent
    
    var body: some View {
        
        Form{
            TextField("Class name", text: $className)
            
            
            Button("Click if your class occurs on multiple days"){
                showMultipleDays.toggle()
            }
            
            if showMultipleDays {
                Picker("Meeting Day 1", selection: $meetingDay1){
                    Text("Monday").tag(0)
                    Text("Tuesday").tag(1)
                    Text("Wednesday").tag(2)
                    Text("Thursday").tag(3)
                    Text("Friday").tag(4)
                    Text("Saturday").tag(5)
                    Text("Sunday").tag(6)
                }
                
                DatePicker("Starting Time", selection: $meetingDate1Start, displayedComponents: .hourAndMinute)
                
                DatePicker("Ending Time", selection: $meetingDate1End, displayedComponents: .hourAndMinute)
                
                DatePicker("Meeting Date 2", selection: $meetingDate1, displayedComponents: .date)
                
                
                Picker("Meeting Day 2", selection: $meetingDay2){
                    Text("Monday").tag(0)
                    Text("Tuesday").tag(1)
                    Text("Wednesday").tag(2)
                    Text("Thursday").tag(3)
                    Text("Friday").tag(4)
                    Text("Saturday").tag(5)
                    Text("Sunday").tag(6)
                }
                
                DatePicker("Starting Time", selection: $meetingDate2Start, displayedComponents: .hourAndMinute)
                
                DatePicker("Ending Time", selection: $meetingDate2End, displayedComponents: .hourAndMinute)
                
                
            } else {
                
                Picker("Meeting Day", selection: $days){
                    Text("Monday").tag("Monday")
                    Text("Tuesday").tag("Tuesday")
                    Text("Wednesday").tag("Wednesday")
                    Text("Thursday").tag("Thursday")
                    Text("Friday").tag("Friday")
                    Text("Saturday").tag("Saturday")
                    Text("Sunday").tag("Sunday")
                }
                
                DatePicker("Starting Time", selection: $meetingDateStart, displayedComponents: .hourAndMinute)
                
                DatePicker("Ending Time", selection: $meetingDateEnd, displayedComponents: .hourAndMinute)
            }
            
            Button("Save"){
                
                if !className.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let newMeeting = Meeting(
                        name: className,
                        day: days,
                        sTime: meetingDateStart,
                        eTime: meetingDateEnd
                    )
                    
                    modelContent.insert(newMeeting)
                    showSuccessAlert = true
                } else {
                    showAlert = true
                }
            }
            .alert("Success!", isPresented: $showSuccessAlert){
                Button("Ok", role: .cancel){}
            } message: {
                Text("Your information has been succesfully added :)")
            }
            
            
            .alert("Missing class name", isPresented: $showAlert){
                Button("Ok", role: .cancel){}
            } message: {
                Text("You forgot to enter a class name!")
            }
        }
        
    }
}

#Preview {
    ContentView()
}

//#Playground {
//    _ = 1 + 2
//}
