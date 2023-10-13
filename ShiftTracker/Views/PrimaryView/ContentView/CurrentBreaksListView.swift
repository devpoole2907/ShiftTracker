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
        
        
 
        Section{
            ForEach(Array(viewModel.tempBreaks.reversed()), id: \.self) { breakItem in
         
                VStack(alignment: .leading){
                    HStack{
                        VStack(alignment: .leading, spacing: 5){
                            if breakItem.isUnpaid{
                                Text("Unpaid")
                                    .font(.subheadline)
                                    .foregroundColor(viewModel.breakLengthInMinutes(startDate: breakItem.startDate, endDate: breakItem.endDate) == "N/A" ? textColor : themeManager.breaksColor)
                                    .bold()
                                    .roundedFontDesign()
                            }
                            else {
                                Text("Paid")
                                    .font(.subheadline)
                                    .foregroundColor(viewModel.breakLengthInMinutes(startDate: breakItem.startDate, endDate: breakItem.endDate) == "N/A" ? textColor : themeManager.breaksColor)
                                    .bold()
                                    .roundedFontDesign()
                            }
                            if viewModel.breakLengthInMinutes(startDate: breakItem.startDate, endDate: breakItem.endDate) == "N/A" {
                                BreakTimerView(timeElapsed: $viewModel.breakTimeElapsed)
                                
                            }
                            else {
                                Text("\(viewModel.breakLengthInMinutes(startDate: breakItem.startDate, endDate: breakItem.endDate))")
                                   // .listRowSeparator(.hidden)
                                    .font(.subheadline)
                                    .bold()
                                    .roundedFontDesign()
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
                            .disabled(viewModel.isOnBreak)
                            if !(viewModel.breakLengthInMinutes(startDate: breakItem.startDate, endDate: breakItem.endDate) == "N/A") {
                                DatePicker(
                                    "End Date",
                                    selection: Binding<Date>(
                                        get: {
                                            return breakItem.endDate ?? Date()
                                        },
                                        set: { newEndDate in
                                            
                                            let breakLength = viewModel.breakLength(startDate: breakItem.startDate, endDate: newEndDate)
                                                        if Double(breakLength) / 60 <= viewModel.timeElapsed {
                                                            let updatedBreak = TempBreak(
                                                                startDate: breakItem.startDate,
                                                                endDate: newEndDate,
                                                                isUnpaid: breakItem.isUnpaid
                                                            )
                                                            viewModel.updateBreak(oldBreak: breakItem, newBreak: updatedBreak)
                                                        }
                                        }
                                    ),
                                    in: breakItem.startDate...breakItem.startDate.addingTimeInterval((breakItem.endDate == breakItem.startDate ? 61 : viewModel.timeElapsed * 60)),
                                    displayedComponents: [.hourAndMinute])
                                .labelsHidden()
                                .disabled(viewModel.isOnBreak)
                            }
                        }
                    }
                }.padding(.vertical, 2)
            
            
                
                .swipeActions {
                    Button(action: {
                        withAnimation {
                            viewModel.deleteSpecificBreak(breakItem: breakItem)
                        }
                    }){
                        Image(systemName: "trash")
                    }.disabled(breakItem.endDate == nil)
                        .tint(Color.clear)
                }
            
        
    
        
    }
        
        
        } header : {
            
            
            HStack {
                Text("Breaks")
                    .font(.title2)
                    .bold()
                    .textCase(nil)
                    .foregroundColor(textColor)
                Spacer()
            }
          //  .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            
        }
        .listRowBackground(Rectangle().fill(Material.ultraThinMaterial))
       // .listRowSeparator(.hidden)
            
            
        }
    
        
}

