//
//  StatsSquare.swift
//  ShiftTracker
//
//  Created by James Poole on 2/07/23.
//

import SwiftUI
import CoreData

struct StatsSquare: View {
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var shiftManager: ShiftDataManager
    @EnvironmentObject var selectedJobManager: JobSelectionManager
    
    @ObservedObject var viewModel: StatsSquareViewModel
    

        init(shifts: FetchedResults<OldShift>, shiftsThisWeek: FetchedResults<OldShift>) {
            viewModel = StatsSquareViewModel(shifts: shifts, weeklyShifts: shiftsThisWeek)
        }
    
    private var subTextColor: Color {
          return colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5)
      }

      private var headerColor: Color {
          return colorScheme == .dark ? .white : .black
      }

    var body: some View {

        
        HStack{
            VStack(alignment: .leading) {
                headerView
                
                if shiftManager.statsMode == .earnings {
                    Text("\(shiftManager.currencyFormatter.string(from: NSNumber(value: viewModel.weeklyEarnings)) ?? "0")")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(headerColor)
                    
                    Text("\(shiftManager.currencyFormatter.string(from: NSNumber(value: viewModel.totalEarnings)) ?? "0") Total")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(subTextColor)
                        .roundedFontDesign()
                    
                } else if shiftManager.statsMode == .hours {
                    
                    Text("\(shiftManager.formatTime(timeInHours: viewModel.weeklyHours))")
                    
                        .font(.title2)
                        .bold()
                        .foregroundStyle(headerColor)
                    
                    Text("\(shiftManager.formatTime(timeInHours: viewModel.totalHours)) Total")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(subTextColor)
                        .roundedFontDesign()
                    
                } else {
                    
                    Text("\(shiftManager.formatTime(timeInHours: viewModel.weeklyBreaks))")
                    
                        .font(.title2)
                        .bold()
                        .foregroundStyle(headerColor)
                    
                    Text("\(shiftManager.formatTime(timeInHours: viewModel.totalBreaks)) Total")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(subTextColor)
                        .roundedFontDesign()
                    
                }
                
                
                
            }
            .padding(.leading)
            Spacer()
        }
            .padding(.vertical, 16)
            .glassModifier(cornerRadius: 12, applyPadding: false)
        
        
        
          
    }
    
    var headerView: some View {
        Text("This Week")
            .font(.callout)
            .bold()
            .foregroundStyle(headerColor)
    }
    
    
    // this is better code but way worse performance...?
    
    /*
    
    private var valueView: some View {
        
        switch shiftManager.statsMode {
            
        case .earnings:
            return statView(weeklyValue: viewModel.weeklyEarnings, totalValue: viewModel.totalEarnings)
        case .hours:
            return statView(weeklyValue: viewModel.weeklyHours, totalValue: viewModel.totalHours, isTime: true)
        case .breaks:
            return statView(weeklyValue: viewModel.weeklyBreaks, totalValue: viewModel.totalBreaks, isTime: true)
            

        }
    }
    
    private func statView(weeklyValue: Double, totalValue: Double, isTime: Bool = false) -> some View {
            let weeklyString = isTime ? shiftManager.formatTime(timeInHours: weeklyValue) : shiftManager.currencyFormatter.string(from: NSNumber(value: weeklyValue)) ?? "0"
            let totalString = isTime ? shiftManager.formatTime(timeInHours: totalValue) : shiftManager.currencyFormatter.string(from: NSNumber(value: totalValue)) ?? "0"
            
            return VStack {
                Text(weeklyString)
                    .font(.title2)
                    .bold()
                    .foregroundStyle(headerColor)
                
                Text("\(totalString) Total")
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(subTextColor)
                    .roundedFontDesign()
            }
        }
    */
    
}
