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
                    .background(Color("SquaresColor"),in:
                                    RoundedRectangle(cornerRadius: 12, style: .continuous))
                
            }.listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }.onDelete(perform: delete)
    }
}


