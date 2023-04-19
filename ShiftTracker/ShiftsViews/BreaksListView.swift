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
    
    @State private var isEditing: Bool = false
    
    @State private var isAddingBreak = false
        @State private var newBreakStartDate = Date()
        @State private var newBreakEndDate = Date()
    @State private var isUnpaid = false
    
    let shift: OldShift
    
    func previousBreakEndDate(for breakItem: Break) -> Date? {
        let sortedBreaks = breaks.sorted { $0.startDate! < $1.startDate! }
        if let index = sortedBreaks.firstIndex(of: breakItem), index > 0 {
            return sortedBreaks[index - 1].endDate
        }
        return nil
    }

    
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    private func formattedDate(_ date: Date) -> String {
            dateFormatter.string(from: date)
        }
    
    func deleteBreak(context: NSManagedObjectContext, breakToDelete: Break) {
        // Remove the relationship between the break and its shift
        if let oldShift = breakToDelete.oldShift {
            oldShift.removeFromBreaks(breakToDelete)
        }

        // Delete the break from the context
        context.delete(breakToDelete)

        // Save the changes
        do {
            try context.save()
        } catch {
            print("Error deleting break: \(error)")
        }
    }
    
    func addBreak(oldShift: OldShift, startDate: Date, endDate: Date, isUnpaid: Bool) {
        let newBreak = Break(context: context)
        newBreak.startDate = startDate
        newBreak.endDate = endDate
        newBreak.isUnpaid = isUnpaid
        oldShift.addToBreaks(newBreak)

        do {
            try context.save()
        } catch {
            print("Error adding break: \(error)")
        }
    }

    
    private func delete(at offsets: IndexSet) {
            for index in offsets {
                let breakToDelete = breaks[index]
                deleteBreak(context: context, breakToDelete: breakToDelete)
            }
        }
    private func saveChanges() {
            do {
                try context.save()
            } catch {
                print("Error saving changes: \(error)")
            }
        }

    private func breakLengthInMinutes(startDate: Date?, endDate: Date?) -> String {
        guard let start = startDate, let end = endDate else { return "N/A" }
        let duration = end.timeIntervalSince(start)
        let minutes = Int(duration) / 60
        return "\(minutes) minutes"
    }

    var minimumStartDate: Date {
            return shift.shiftStartDate ?? Date()
        }
    
    var maximumEndDate: Date {
            return shift.shiftEndDate ?? Date()
        }
    
    var body: some View {
        NavigationStack{
            List{
                ForEach(breaks, id: \.self) { breakItem in
                    Section{
                        VStack(alignment: .leading){
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
                            Text("\(breakLengthInMinutes(startDate: breakItem.startDate, endDate: breakItem.endDate))")
                                .listRowSeparator(.hidden)
                                .font(.subheadline)
                                .bold()
                        
                    Divider()
                            DatePicker("Start:", selection: Binding(
                                                    get: { breakItem.startDate ?? Date() },
                                                    set: { newValue in
                                                        let minStartDate = previousBreakEndDate(for: breakItem) ?? minimumStartDate
                                                        if newValue >= minStartDate && newValue <= maximumEndDate {
                                                            breakItem.startDate = newValue
                                                            if let endDate = breakItem.endDate, endDate < newValue {
                                                                breakItem.endDate = newValue
                                                            }
                                                        }
                                                    }), displayedComponents: [.date, .hourAndMinute])
                                                .disabled(!isEditing)
                                                
                                                DatePicker("End:", selection: Binding(
                                                    get: { breakItem.endDate ?? Date() },
                                                    set: { newValue in
                                                        if let startDate = breakItem.startDate, newValue >= startDate && newValue <= maximumEndDate {
                                                            breakItem.endDate = newValue
                                                        }
                                                    }), displayedComponents: [.date, .hourAndMinute])
                                                .disabled(!isEditing)
                    }
                        
                }
                }.onDelete(perform: delete)
            }
        }.navigationTitle("Breaks")
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Done" : "\(Image(systemName: "pencil"))") {
                        isEditing.toggle()
                        saveChanges()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("\(Image(systemName: "plus"))") {
                        isAddingBreak = true
                    }
                }
            }.sheet(isPresented: $isAddingBreak) {
                
                if #available(iOS 16.4, *) {
                    NavigationView {
                        List {
                            
                            Section{
                                VStack(alignment: .leading, spacing: 10){
                                    Text("Shift Start")
                                        .foregroundColor(.gray)
                                        .font(.title3)
                                        .bold()
                                    Text("\(formattedDate(shift.shiftStartDate ?? Date()))")
                                        //.foregroundColor(.white)
                                        .font(.subheadline)
                                  //  bold()
                                    Text("Shift End")
                                        .foregroundColor(.gray)
                                        .font(.title3)
                                        .bold()
                                    Text("\(formattedDate(shift.shiftEndDate ?? Date()))")
                                        //.foregroundColor(.white)
                                        .font(.subheadline)
                                                                    }
                            
                
                                
                                VStack{
                                    DatePicker("Start:", selection: $newBreakStartDate, displayedComponents: [.date, .hourAndMinute])
                                    DatePicker("End:", selection: $newBreakEndDate, displayedComponents: [.date, .hourAndMinute])
                                    Picker(selection: $isUnpaid, label: Text("Break Type")) {
                                        Text("Paid").tag(false)
                                        Text("Unpaid").tag(true)
                                    }.pickerStyle(SegmentedPickerStyle())

                                }
                          
                            }.listRowSeparator(.hidden)
                       
                            Button(action: {
                                addBreak(oldShift: shift, startDate: newBreakStartDate, endDate: newBreakEndDate, isUnpaid: isUnpaid)
                                isAddingBreak = false
                            }) {
                                Text("Add Break")
                                
                                    .bold()
                                
                            }.listRowSeparator(.hidden)
                               
                                    .listRowBackground(Color.clear)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .navigationBarTitle("Add Break", displayMode: .inline)
                    }.presentationDetents([ .medium])
                        .presentationBackground(.ultraThinMaterial)
                        .presentationCornerRadius(12)
                        .presentationDragIndicator(.visible)
                }
                else {
                    NavigationStack {
                        List {
                            Section{
                                VStack(alignment: .leading, spacing: 10){
                                    Text("Shift Start")
                                        .foregroundColor(.gray)
                                        .font(.title2)
                                        .bold()
                                    Text("\(formattedDate(shift.shiftStartDate ?? Date()))")
                                        .foregroundColor(.white)
                                        .font(.title3)
                                        .bold()
                                  //  bold()
                                    Text("Shift End")
                                        .foregroundColor(.gray)
                                        .font(.title2)
                                        .bold()
                                    Text("\(formattedDate(shift.shiftEndDate ?? Date()))")
                                        .foregroundColor(.white)
                                        .font(.title3)
                                        .bold()
                                                                    }
                            
                                VStack{
                                    DatePicker("Start:", selection: $newBreakStartDate, displayedComponents: [.date, .hourAndMinute])
                                    DatePicker("End:", selection: $newBreakEndDate, displayedComponents: [.date, .hourAndMinute])
                                    Picker(selection: $isUnpaid, label: Text("Break Type")) {
                                        Text("Paid").tag(true)
                                        Text("Unpaid").tag(false)
                                    }.pickerStyle(SegmentedPickerStyle())
                                }
                            }.listRowSeparator(.hidden)
                      
                            
                            Button(action: {
                                addBreak(oldShift: shift, startDate: newBreakStartDate, endDate: newBreakEndDate, isUnpaid: isUnpaid)
                                isAddingBreak = false
                            }) {
                                Text("Add Break")
                                
                                    .bold()
                                
                            }.listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .navigationBarTitle("Add Break", displayMode: .inline)
                    }
                }
                
                
                
                
                
                
                
            }
    }
}


