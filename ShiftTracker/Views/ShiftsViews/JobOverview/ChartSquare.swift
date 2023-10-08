//
//  ChartSquare.swift
//  ShiftTracker
//
//  Created by James Poole on 2/07/23.
//

import SwiftUI
import Charts
import CoreData

struct ChartSquare: View {
    
    @EnvironmentObject var shiftManager: ShiftDataManager
    
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    
    
    @Environment(\.colorScheme) var colorScheme
    
    var shifts: FetchedResults<OldShift>
    
    
    var body: some View {
        
        
     
            VStack(alignment: .center) {
                
                navHeader
                weeklyChart
             
                
              
            }
        
            .padding(.vertical, 8)
            .glassModifier(cornerRadius: 12, applyPadding: false)
          
    }
    
    var navHeader: some View {
        let headerColor: Color = colorScheme == .dark ? .white : .black
        return HStack(spacing: 5){
            
            HStack(spacing: 0){
                NavigationLink(value: 2) {
                    Group {
                        Text("Activity")
                            .font(.callout)
                            .bold()
                            .foregroundStyle(headerColor)
                            .padding(.leading)
                           
                        
                    }
                }
            }

            Spacer()
        
                           
        }
    }
    
    var weeklyChart: some View {
        return Chart {
            
            ForEach(shifts, id: \.self) { shift in
                
                BarMark(x: .value("Day", shift.shiftStartDate ?? Date(), unit: .weekday),
                        y: .value(shiftManager.statsMode.description, shiftManager.statsMode == .earnings ? shift.totalPay : shiftManager.statsMode == .hours ? (shift.duration / 3600) : (shift.breakDuration / 3600.0)
                                  
                                 ), width: 10
                )
                .foregroundStyle(shiftManager.statsMode.gradient)
                .cornerRadius(shiftManager.statsMode.cornerRadius)
               
                
                
            }
                
            
            
            
        }.chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .padding(.horizontal, 5)
        
            .frame(width: 100)
    }
    
}



