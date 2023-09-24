//
//  OvertimeView.swift
//  ShiftTracker
//
//  Created by James Poole on 21/04/23.
//

import SwiftUI

struct OvertimeView: View{
    
    @Binding var overtimeAppliedAfter: TimeInterval
    
    @State private var selectedOvertimeHour = 8
    @State private var selectedOvertimeMinute = 30
    
    init(overtimeAppliedAfter: Binding<TimeInterval>) {
            _overtimeAppliedAfter = overtimeAppliedAfter
            _selectedOvertimeHour = State(initialValue: Int(overtimeAppliedAfter.wrappedValue) / 3600)
            _selectedOvertimeMinute = State(initialValue: Int(overtimeAppliedAfter.wrappedValue) % 3600 / 60)
        }

    var body: some View{
        
        let hourBinding = Binding<Int>(
                    get: { self.selectedOvertimeHour },
                    set: {
                        self.selectedOvertimeHour = $0
                        self.updateTimeInterval()
                    }
                )

                let minuteBinding = Binding<Int>(
                    get: { self.selectedOvertimeMinute },
                    set: {
                        self.selectedOvertimeMinute = $0
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
            
         
    }
    
    private func updateTimeInterval() {
            overtimeAppliedAfter = TimeInterval(selectedOvertimeHour * 3600 + selectedOvertimeMinute * 60)
        }
}
