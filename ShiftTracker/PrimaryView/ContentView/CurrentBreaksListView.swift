//
//  BreakRowView.swift
//  ShiftTracker
//
//  Created by James Poole on 11/07/23.
//

import SwiftUI

struct CurrentBreaksListView: View {
    @EnvironmentObject var viewModel: ContentViewModel // replace ViewModelType with your ViewModel's actual type
    @EnvironmentObject var themeManager: ThemeDataManager // replace ThemeManager with your actual theme manager type
    @Environment(\.colorScheme) var colorScheme
    
    
    var body: some View {
        
        let textColor: Color = colorScheme == .dark ? .white : .black
        
        
        Group {
            
            HStack{
                Text("Breaks").font(.title2).bold()
                    .textCase(nil)
                    .foregroundColor(textColor)
                Spacer()
            }.listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        
        ForEach(viewModel.tempBreaks.reversed(), id: \.self) { breakItem in
            Section {
                VStack(alignment: .leading){
                    HStack{
                        VStack(alignment: .leading, spacing: 8){
                            if breakItem.isUnpaid{
                                Text("Unpaid")
                                    .font(.subheadline)
                                    .foregroundColor(viewModel.breakLengthInMinutes(startDate: breakItem.startDate, endDate: breakItem.endDate) == "N/A" ? textColor : themeManager.breaksColor)
                                    .bold()
                            }
                            else {
                                Text("Paid")
                                    .font(.subheadline)
                                    .foregroundColor(viewModel.breakLengthInMinutes(startDate: breakItem.startDate, endDate: breakItem.endDate) == "N/A" ? textColor : themeManager.breaksColor)
                                    .bold()
                            }
                            if viewModel.breakLengthInMinutes(startDate: breakItem.startDate, endDate: breakItem.endDate) == "N/A" {
                                BreakTimerView(timeElapsed: $viewModel.breakTimeElapsed)
                                
                            }
                            else {
                                Text("\(viewModel.breakLengthInMinutes(startDate: breakItem.startDate, endDate: breakItem.endDate))")
                                    .listRowSeparator(.hidden)
                                    .font(.subheadline)
                                    .bold()
                            }
                        }
                        Spacer()
                        HStack{
                            DatePicker(
                                "Start Date",
                                selection: Binding<Date>(
                                    get: {
                                        return breakItem.startDate
                                    },
                                    set: { newStartDate in
                                        let updatedBreak = TempBreak(
                                            startDate: newStartDate,
                                            endDate: breakItem.endDate,
                                            isUnpaid: breakItem.isUnpaid
                                        )
                                        viewModel.updateBreak(oldBreak: breakItem, newBreak: updatedBreak)
                                    }
                                ),
                                in: viewModel.minimumStartDate(for: breakItem)...Date.distantFuture,
                                displayedComponents: [.hourAndMinute])
                            .labelsHidden()
                            DatePicker(
                                "End Date",
                                selection: Binding<Date>(
                                    get: {
                                        return breakItem.endDate ?? Date()
                                    },
                                    set: { newEndDate in
                                        let updatedBreak = TempBreak(
                                            startDate: breakItem.startDate,
                                            endDate: newEndDate,
                                            isUnpaid: breakItem.isUnpaid
                                        )
                                        viewModel.updateBreak(oldBreak: breakItem, newBreak: updatedBreak)
                                    }
                                ),
                                in: breakItem.startDate...Date.distantFuture,
                                displayedComponents: [.hourAndMinute])
                            .labelsHidden()
                            .disabled(viewModel.isOnBreak)
                        }
                    }
                }
            }
            .listRowBackground(Color("SquaresColor"))
            .listRowSeparator(.hidden)
            
            .swipeActions {
                Button(role: .destructive) {
                    viewModel.deleteSpecificBreak(breakItem: breakItem)
                } label: {
                    Image(systemName: "trash")
                }.disabled(breakItem.endDate == nil)
            }
            
        }
    }
        
    }
}

