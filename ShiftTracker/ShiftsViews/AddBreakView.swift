//
//  AddBreakView.swift
//  ShiftTracker
//
//  Created by James Poole on 28/05/23.
//

import SwiftUI
import CoreData

struct AddBreakView: View {
    
    let breakManager = BreaksManager()
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @Environment(\.managedObjectContext) private var context
    
    let shift: OldShift
    
    @State private var newBreakStartDate: Date
    @State private var newBreakEndDate: Date
    @State private var isUnpaid: Bool
    @Binding var isAddingBreak: Bool
    
    
    init(shift: OldShift, isAddingBreak: Binding<Bool>){
        _newBreakStartDate = State(initialValue: shift.shiftStartDate ?? Date())
        _newBreakEndDate = State(initialValue: shift.shiftEndDate ?? Date())
        _isUnpaid = State(initialValue: false)
        _isAddingBreak = isAddingBreak
        self.shift = shift
    }
    
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
                                .padding(.vertical, 5)
                            DatePicker("Start:", selection: $newBreakStartDate, in: (shift.shiftStartDate ?? .distantPast)...(shift.shiftEndDate ?? .distantFuture), displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        HStack{
                            Text("End:")
                                .bold()
                                .frame(width: 50, alignment: .leading)
                            DatePicker("End:", selection: $newBreakEndDate, in: (shift.shiftStartDate ?? .distantPast)...(shift.shiftEndDate ?? .distantFuture), displayedComponents: [.date, .hourAndMinute])
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
            
                .toolbar{
                    ToolbarItem(placement: .navigationBarTrailing) {
                        CloseButton {
                            dismiss()
                        }
                    }
                }
            
        }
    }
}

