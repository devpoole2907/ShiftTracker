//
//  BreaksListView.swift
//  ShiftTracker
//
//  Created by James Poole on 10/04/23.
//

import SwiftUI
import CoreData

struct BreaksListView: View {
    var breaks: [Break]? = nil
    
    @Environment(\.managedObjectContext) private var context
    
    @EnvironmentObject var themeManager: ThemeDataManager
    
    @EnvironmentObject var viewModel: DetailViewModel
    
    let breakManager = BreaksManager()
    
    var shift: OldShift?
    
    @State private var isAddingBreak = false
    @State private var newBreakStartDate = Date()
    @State private var newBreakEndDate = Date()
    @State private var isUnpaid = false
    
    var minimumStartDate: Date {
        return shift?.shiftStartDate ?? Date()
    }
    
    var maximumEndDate: Date {
        return shift?.shiftEndDate ?? Date()
    }
    
    private func delete(at index: Int) {
        
            let breakToDelete = breaks![index]
            breakManager.deleteBreak(context: context, breakToDelete: breakToDelete)
        
    }
    
    private func deleteTempBreak(at index: Int) {
        viewModel.tempBreaks.remove(at: index)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy   h:mm a"
        return formatter.string(from: date)
    }
    
    init(shift: OldShift? = nil){
        
        if let shift = shift {
            
            self.shift = shift
            
            if let shiftBreaks = shift.breaks as? Set<Break> {
                let sortedBreaks = shiftBreaks.sorted { $0.startDate ?? Date() < $1.startDate ?? Date() }
                self.breaks = sortedBreaks
            } else {
                self.breaks = []
            }
            
            
        }
        
        
    }
    
    
    var body: some View {
        
        if let _ = shift, let breaks = breaks {
            
            if breaks.isEmpty {
                BreaksHeaderView()
            }
            
            
        ForEach(Array(breaks.enumerated()), id: \.element) { index, breakItem in
            Section{
                VStack(alignment: .leading){
                    
                    BreakTitleDurationView(isUnpaid: breakItem.isUnpaid, breakLength: breakManager.breakLengthInMinutes(startDate: breakItem.startDate, endDate: breakItem.endDate))
                    
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
                        .scaleEffect(viewModel.isEditing ? 1.01 : 1.0) // Add a scale effect that pulses the picker
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isEditing)
                        .disabled(!viewModel.isEditing)
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
                        .scaleEffect(viewModel.isEditing ? 1.01 : 1.0) // Add a scale effect that pulses the picker
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isEditing)
                        .disabled(!viewModel.isEditing)
                    }
                }.padding()
                    .background(Color("SquaresColor"),in:
                                    RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                
                
                
            } header: {
                
                if index == 0 {
                    
                    BreaksHeaderView()
                    
                    
                }
                
            }
            
            .swipeActions(edge: .trailing) {
                if viewModel.isEditing {
                    Button(role: .destructive, action: { delete(at: index)
                    }) {
                        Image(systemName: "trash")
                    }
                }
            }
            
            
            
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        
        
        } else { // must be temp breaks, no shift passed to view
            
            if viewModel.tempBreaks.isEmpty {
                BreaksHeaderView()
            }
            
            ForEach(Array(viewModel.tempBreaks.enumerated()), id: \.element) { index, breakItem in
                Section{
                    VStack(alignment: .leading){
                        
                        BreakTitleDurationView(isUnpaid: breakItem.isUnpaid, breakLength: breakManager.breakLengthInMinutes(startDate: breakItem.startDate, endDate: breakItem.endDate))
                        
                        
                        HStack{
                            Text("Start:")
                                .bold()
                            //.padding(.horizontal, 15)
                                .frame(width: 50, alignment: .leading)
                                .padding(.vertical, 5)
                            
                            Text(formatDate(breakItem.startDate))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        HStack{
                            Text("End:")
                                .bold()
                                .frame(width: 50, alignment: .leading)
                            //.padding(.horizontal, 15)
                                .padding(.vertical, 5)
                            Text(formatDate(breakItem.endDate ?? Date()))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }.padding()
                        .background(Color("SquaresColor"),in:
                                        RoundedRectangle(cornerRadius: 12, style: .continuous))
                    
                } header: {
                    
                    if index == 0 {
                        
                        BreaksHeaderView()
                        
                        
                    }
                    
                }
                
                
                .swipeActions(edge: .trailing) {
                  
                        Button(role: .destructive, action: { deleteTempBreak(at: index)
                        }) {
                            Image(systemName: "trash")
                        }
                    
                }
                
                
                .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            
            
        }
    }
}


struct BreaksHeaderView: View {
    
    
    @EnvironmentObject var viewModel: DetailViewModel
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        
        HStack{
            Text("Breaks")
                .bold()
                .textCase(nil)
                .foregroundStyle(colorScheme == .dark ? .white : .black)
            
                .padding(.vertical, 5)
            
            Button(action: {
                viewModel.isAddingBreak = true
            }) {
                Image(systemName: "plus")
                    .bold()
            }.disabled(!viewModel.isEditing)
            
            Spacer()
            
        }.font(.title2)
            .padding(.horizontal, 5)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        
        
    }
    
    
}


struct BreakTitleDurationView: View {
    
    @EnvironmentObject var themeManager: ThemeDataManager
    
    var isUnpaid: Bool
    var breakLength: String
    
    
    var body: some View {
        
        
        VStack(alignment: .leading, spacing: 8){
            if isUnpaid{
                Text("Unpaid")
                    .font(.subheadline)
                    .foregroundStyle(themeManager.breaksColor)
                    .bold()
            }
            else {
                Text("Paid")
                    .font(.subheadline)
                    .foregroundStyle(themeManager.breaksColor)
                    .bold()
            }
            Text("\(breakLength)")
                .listRowSeparator(.hidden)
                .font(.subheadline)
                .bold()
        }
        Divider()
        
        
        
    }
    
    
}

