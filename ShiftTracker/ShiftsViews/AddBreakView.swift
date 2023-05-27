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

