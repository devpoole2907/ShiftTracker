//
//  ScheduleView.swift
//  ShiftTracker
//
//  Created by James Poole on 18/04/23.
//

import SwiftUI

struct ScheduleView: View {
    
    @EnvironmentObject var eventStore: EventStore
    @State private var dateSelected: DateComponents?
    @State private var displayEvents = false
    
    var body: some View {
        
        
        NavigationStack{
            ScrollView{
                CalendarView(interval: DateInterval(start: .distantPast, end: .distantFuture), eventStore: eventStore, dateSelected: $dateSelected, displayEvents: $displayEvents)
            }.navigationBarTitle("Schedule")
        }
    }
}

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView()
            .environmentObject(EventStore(preview: true))
    }
}
