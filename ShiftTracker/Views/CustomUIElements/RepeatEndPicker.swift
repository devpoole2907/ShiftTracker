//
//  RepeatEndPicker.swift
//  ShiftTracker
//
//  Created by James Poole on 29/09/23.
//

import SwiftUI

struct RepeatEndPicker: View {
    
    private let options = ["1 month", "2 months", "3 months"]
    private let calendar = Calendar.current
    
    @State private var selectedIndex = 1
    @Binding var selectedRepeatEnd: Date
    @Binding var dateSelected: DateComponents?
    @State private var startDate: Date
    
    init(dateSelected: Binding<DateComponents?>, selectedRepeatEnd: Binding<Date>) {
        
        _dateSelected = dateSelected

        
        let defaultDate: Date = Calendar.current.date(from: dateSelected.wrappedValue ?? DateComponents()) ?? Date()
        _startDate = State(initialValue: defaultDate)
        
        
        self._selectedRepeatEnd = selectedRepeatEnd
        let defaultRepeatEnd = calendar.date(byAdding: .month, value: 2, to: startDate)!
        self._selectedIndex = State(initialValue: self.options.firstIndex(of: "\(2) months")!)
        // set the selectedIndex to the index of the default repeat end option
    }
    
    var body: some View {
        Picker("End Repeat", selection: $selectedIndex) {
            ForEach(0..<options.count) { index in
                Text(options[index]).tag(index)
            }
        }
        .onChange(of: selectedIndex) { value in
            let months = [1, 2, 3][value]
            selectedRepeatEnd = calendar.date(byAdding: .month, value: months, to: startDate)! // Use startDate instead of selectedRepeatEnd
        }
    }
    
}

