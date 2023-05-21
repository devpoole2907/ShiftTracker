//
//  BreaksListView.swift
//  ShiftTracker
//
//  Created by James Poole on 10/04/23.
//

import SwiftUI
import CoreData

struct BreaksListView: View {
    let breaks: [Break]
    
    @Environment(\.managedObjectContext) private var context
    
    @Binding var isEditing: Bool
    
    let breakManager = BreaksManager()
    
    @State private var isAddingBreak = false
    @State private var newBreakStartDate = Date()
    @State private var newBreakEndDate = Date()
    @State private var isUnpaid = false
    
    let shift: OldShift
    
    var minimumStartDate: Date {
        return shift.shiftStartDate ?? Date()
    }
    
    var maximumEndDate: Date {
        return shift.shiftEndDate ?? Date()
    }
    
    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let breakToDelete = breaks[index]
            breakManager.deleteBreak(context: context, breakToDelete: breakToDelete)
        }
    }
    
    var body: some View {
        ForEach(breaks, id: \.self) { breakItem in
            Section{
                VStack(alignment: .leading){
                    VStack(alignment: .leading, spacing: 8){
                        if breakItem.isUnpaid{
                            Text("Unpaid")
                                .font(.subheadline)
                                .foregroundColor(.indigo)
                                .bold()
                        }
                        else {
                            Text("Paid")
                                .font(.subheadline)
                                .foregroundColor(.indigo)
                                .bold()
                        }
                        Text("\(breakManager.breakLengthInMinutes(startDate: breakItem.startDate, endDate: breakItem.endDate))")
                            .listRowSeparator(.hidden)
                            .font(.subheadline)
                            .bold()
                    }
                    Divider()
                    HStack{
                        Text("Start:")
                            .bold()
                        //.padding(.horizontal, 15)
                            .frame(width: 50, alignment: .leading)
                            .padding(.vertical, 5)
                        DatePicker("Start:", selection: Binding(
                            get: { breakItem.startDate ?? Date() },
                            set: { newValue in
                                let minStartDate = breakManager.previousBreakEndDate(for: breakItem, breaks: breaks) ?? minimumStartDate
                                if newValue >= minStartDate && newValue <= maximumEndDate {
                                    breakItem.startDate = newValue
                                    if let endDate = breakItem.endDate, endDate < newValue {
                                        breakItem.endDate = newValue
                                    }
                                }
                            }), displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .scaleEffect(isEditing ? 1.01 : 1.0) // Add a scale effect that pulses the picker
                        .animation(.easeInOut(duration: 0.2))
                        .disabled(!isEditing)
                    }
                    HStack{
                        Text("End:")
                            .bold()
                            .frame(width: 50, alignment: .leading)
                        //.padding(.horizontal, 15)
                            .padding(.vertical, 5)
                        DatePicker("End:", selection: Binding(
                            get: { breakItem.endDate ?? Date() },
                            set: { newValue in
                                if let startDate = breakItem.startDate, newValue >= startDate && newValue <= maximumEndDate {
                                    breakItem.endDate = newValue
                                }
                            }), displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .scaleEffect(isEditing ? 1.01 : 1.0) // Add a scale effect that pulses the picker
                        .animation(.easeInOut(duration: 0.2))
                        .disabled(!isEditing)
                    }
                }.padding()
                    .background(Color.primary.opacity(0.04),in:
                                    RoundedRectangle(cornerRadius: 12, style: .continuous))
                
            }.listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }.onDelete(perform: delete)
    }
}

struct AddBreakView: View {
    
    let breakManager = BreaksManager()
    
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(\.managedObjectContext) private var context
    
    let shift: OldShift
    
    @State private var newBreakStartDate = Date()
    @State private var newBreakEndDate = Date()
    @State private var isUnpaid = false
    @Binding var isAddingBreak: Bool
    
    var body: some View{
        
        NavigationStack{
            ScrollView {
                
                VStack(alignment: .leading, spacing: 15){
                    /*VStack(alignment: .leading, spacing: 10){
                        Text("Shift Start")
                            .foregroundColor(.gray)
                            .font(.title3)
                            .bold()
                        Text("\(breakManager.formattedDate(shift.shiftStartDate ?? Date()))")
                        //.foregroundColor(.white)
                            .font(.subheadline)
                        //  bold()
                        Text("Shift End")
                            .foregroundColor(.gray)
                            .font(.title3)
                            .bold()
                        Text("\(breakManager.formattedDate(shift.shiftEndDate ?? Date()))")
                        //.foregroundColor(.white)
                            .font(.subheadline)
                    } */
                    
                    
                    
                    VStack(alignment: .leading){
                        HStack{
                            Text("Start:")
                                .bold()
                                .frame(width: 50, alignment: .leading)
                            //.padding(.horizontal, 15)
                                .padding(.vertical, 5)
                            DatePicker("Start:", selection: $newBreakStartDate, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        HStack{
                            Text("End:")
                                .bold()
                                .frame(width: 50, alignment: .leading)
                            //.padding(.horizontal, 15)
                            DatePicker("End:", selection: $newBreakEndDate, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        Picker(selection: $isUnpaid, label: Text("Break Type")) {
                            Text("Paid").tag(false)
                            Text("Unpaid").tag(true)
                        }.pickerStyle(SegmentedPickerStyle())
                        
                    }.padding()
                        .background(Color.primary.opacity(0.04),in:
                                        RoundedRectangle(cornerRadius: 12, style: .continuous))
                    
                    Button(action: {
                        breakManager.addBreak(oldShift: shift, startDate: newBreakStartDate, endDate: newBreakEndDate, isUnpaid: isUnpaid, context: context)
                        isAddingBreak = false
                    }) {
                        Text("Add Break")
                        
                            .bold()
                        
                    }.listRowSeparator(.hidden)
                    
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(colorScheme == .dark ? .white : .black)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .cornerRadius(20)
                    
                }.listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(20)
                
                
            }.scrollContentBackground(.hidden)
                .navigationBarTitle("Add Break", displayMode: .inline)
        }
    }
}
