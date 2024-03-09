//
//  TimePicker.swift
//  ShiftTracker
//
//  Created by James Poole on 21/04/23.
//

import SwiftUI

struct TimePicker: View{
    
    @Binding var timeInterval: TimeInterval
    var actionDate: Date?
        var upperBound: Date?
    
    @State private var selectedHour = 8
    @State private var selectedMinute = 30
    
    init(timeInterval: Binding<TimeInterval>, actionDate: Date? = nil, upperBound: Date? = nil) {
            _timeInterval = timeInterval
            _selectedHour = State(initialValue: Int(timeInterval.wrappedValue) / 3600)
            _selectedMinute = State(initialValue: Int(timeInterval.wrappedValue) % 3600 / 60)
        
        self.actionDate = actionDate
               self.upperBound = upperBound
        
        }

    var body: some View{
        
        let hourBinding = Binding<Int>(
                    get: { self.selectedHour },
                    set: {
                        self.selectedHour = $0
                        self.updateTimeInterval()
                    }
                )

                let minuteBinding = Binding<Int>(
                    get: { self.selectedMinute },
                    set: {
                        self.selectedMinute = $0
                        self.updateTimeInterval()
                    }
                )
     
            HStack {
                Picker(selection: hourBinding, label: Text("Hour")) {
                    ForEach(0..<24) { hour in
                        Text("\(hour)h").tag(hour)
                    }
                }
                .pickerStyle(WheelPickerStyle()).frame(maxWidth: 200)
                
                Picker(selection: minuteBinding, label: Text("Minute")) {
                    ForEach(0..<60) { minute in
                        Text("\(minute)m").tag(minute)
                    }
                }
                .pickerStyle(WheelPickerStyle()).frame(maxWidth: 200)
                
            }
        
            .onChange(of: timeInterval) { newValue in
                withAnimation {
                    selectedHour = Int(newValue) / 3600
                    selectedMinute = Int(newValue) % 3600 / 60
                }
                   }
            
         
    }
    
    private func updateTimeInterval() {
           var newTimeInterval = TimeInterval(selectedHour * 3600 + selectedMinute * 60)
        
        if let actionDate = actionDate, let upperBound = upperBound {
            let newDate = actionDate.addingTimeInterval(newTimeInterval)
            if newDate > upperBound {
                newTimeInterval = upperBound.timeIntervalSince(actionDate)
                selectedHour = Int(newTimeInterval) / 3600
                selectedMinute = Int(newTimeInterval) % 3600 / 60
            }
        }
           timeInterval = newTimeInterval
       }
}
