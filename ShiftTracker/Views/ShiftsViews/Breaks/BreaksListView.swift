//
//  BreaksListView.swift
//  ShiftTracker
//
//  Created by James Poole on 10/04/23.
//

import SwiftUI
import CoreData

struct BreaksListView: View {
    
    
    @Environment(\.managedObjectContext) private var context
    
    @EnvironmentObject var themeManager: ThemeDataManager
    
    @EnvironmentObject var viewModel: DetailViewModel
    
    let breakManager = BreaksManager()
    
     var showRealBreaks: Bool
    
    @State private var isAddingBreak = false
    @State private var newBreakStartDate = Date()
    @State private var newBreakEndDate = Date()
    @State private var isUnpaid = false
    
    private func delete(at index: Int) {
        
        let breakToDelete = viewModel.breaks[index]
            breakManager.deleteBreak(context: context, breakToDelete: breakToDelete)
        viewModel.breaks.remove(at: index)
    }
    
    private func deleteTempBreak(at index: Int) {
        viewModel.tempBreaks.remove(at: index)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy   h:mm a"
        return formatter.string(from: date)
    }

    
    var body: some View {
        
      //  if let breaks = breaks {
        
        if showRealBreaks {
            
        if viewModel.breaks.isEmpty {
                BreaksHeaderView()
            }
            
            
        ForEach(Array(viewModel.breaks.enumerated()), id: \.element) { index, breakItem in
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
                                let minStartDate = breakManager.previousBreakEndDate(for: breakItem, breaks: viewModel.breaks) ?? viewModel.selectedStartDate
                                if newValue >= minStartDate && newValue <= viewModel.selectedEndDate {
                                    breakItem.startDate = newValue
                                    if let endDate = breakItem.endDate, endDate < newValue {
                                        breakItem.endDate = newValue
                                    }
                                }
                                
                                viewModel.breakEdited.toggle()
                                
                                
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
                                if let startDate = breakItem.startDate, newValue >= startDate && newValue <= viewModel.selectedEndDate {
                                    breakItem.endDate = newValue
                                }
                                
                                viewModel.breakEdited.toggle()
                                
                            }), displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .scaleEffect(viewModel.isEditing ? 1.01 : 1.0) // Add a scale effect that pulses the picker
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isEditing)
                        .disabled(!viewModel.isEditing)
                    }
                }.padding()
                   // .glassModifier(cornerRadius: 20)
                
                
                
                
            } header: {
                
                if index == 0 {
                    
                    BreaksHeaderView()
                    
                    
                }
                
            }

            
            .swipeActions {
                if viewModel.isEditing {
                    Button(action: {
                        withAnimation {delete(at: index)
                        }}){
                        Image(systemName: "trash")
                    }.tint(Color.red)
                    
                }
                
            }
            
            
            
            .listRowBackground(Color.clear)

        }
        
        
        } else {
            
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
                                .frame(width: 50, alignment: .leading)
                                .padding(.vertical, 5)
                            
                            Text(formatDate(breakItem.startDate))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        HStack{
                            Text("End:")
                                .bold()
                                .frame(width: 50, alignment: .leading)
                                .padding(.vertical, 5)
                            Text(formatDate(breakItem.endDate ?? Date()))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }.padding()
                       // .glassModifier(cornerRadius: 20)
                    
                } header: {
                    
                    if index == 0 {
                        
                        BreaksHeaderView()
                        
                        
                    }
                    
                }

                
                
                .swipeActions {
                    if viewModel.isEditing {
                        Button(action: {
                            withAnimation {
                                deleteTempBreak(at: index)
                            }
                        }){
                            Image(systemName: "trash")
                        }.tint(Color.red)
                        
                    }
                    
                }
                
                
                .listRowBackground(Color.clear)
    
            }
            
            
        }
    }
}


struct BreaksHeaderView: View {
    
    
    @EnvironmentObject var viewModel: DetailViewModel
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        
        HStack{
            HStack {
            Text("Breaks")
                .bold()
                .textCase(nil)
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .font(.title2)
                .padding(.vertical, 5)
            
                Divider().frame(height: 10)
            
            Button(action: {
                viewModel.isAddingBreak = true
            }) {
                Image(systemName: "plus")
                    .bold()
                
            }.disabled(!viewModel.isEditing)
                    .font(.title3)
            
        }  .padding(.horizontal)
                .glassModifier(cornerRadius: 20)
            
            Spacer()
            
        }
            .padding(.horizontal, 5)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .padding(.bottom, 10)
        
            
        
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

