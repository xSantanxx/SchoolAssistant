//
//  HomeScreen.swift
//  SchoolAssistant
//
//  Created by Dmitri Power on 10/24/26.
//


import SwiftUI
import SwiftData

struct HomeScreen: View {
    
    @Query private var meetings: [Meeting]
    var body: some View {
                
        
        Text("Classes saved: \(meetings.count)")
        List(meetings) {
            meeting in
            VStack(alignment: .leading){
                Text(meeting.name)
                Text(meeting.day)
                Text("\(meeting.sTime.formatted(date: .omitted, time: .shortened)) – \(meeting.eTime.formatted(date: .omitted, time: .shortened))")
                if let day = meeting.secondDay,
                   let start = meeting.secondStartTime,
                   let end = meeting.secondEndTime {
                    Text(day)
                    Text("\(start.formatted(date: .omitted, time: .shortened)) – \(end.formatted(date: .omitted, time: .shortened))")
                }
            }
        }
        .navigationTitle(Text("My Classes"))
    }
}













#Preview {
    NavigationStack {
        HomeScreen()
    }
    .modelContainer(for: Meeting.self, inMemory: true)
}
