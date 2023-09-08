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
    
    var shifts: [OldShift]
    
    
    var body: some View {
                        
        
        let subTextColor: Color = colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5)
        let headerColor: Color = colorScheme == .dark ? .white : .black
        
        
        let barColor: LinearGradient = {
                    switch shiftManager.statsMode {
                    case .earnings:
                        return LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 198 / 255, green: 253 / 255, blue: 80 / 255),
                                Color(red: 112 / 255, green: 218 / 255, blue: 65 / 255)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom)
                    case .hours:
                        return LinearGradient(
                            gradient: Gradient(colors: [Color.yellow, Color.orange]),
                            startPoint: .top,
                            endPoint: .bottom)
                    case .breaks:
                        return LinearGradient(
                            gradient: Gradient(colors: [Color.indigo, Color.purple]),
                            startPoint: .top,
                            endPoint: .bottom)
                    }
                }()
        
        
        HStack{
            VStack(alignment: .leading) {
                HStack(spacing: 5){
                    
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
                       // Spacer(minLength: 55)
                    }

                    Spacer()
                
                                   
                }

                
                
                Chart {
                    
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
             
                
              
            }
        }
            .padding(.vertical, 8)
            .glassModifier(cornerRadius: 12, applyPadding: false)
          
    }
    
    func animateGraph(){
        
      
    
            for(index,_) in shiftManager.recentShifts.enumerated(){
                
               // DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05){
                    withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.8, blendDuration: 0.8)){
                        shiftManager.recentShifts[index].animate = true
                        
                    }
                    
               // }

            }
            
    
            

            
   
            
            
            
        
        

    }
    
    func compareDates(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        let components1 = calendar.dateComponents([.year, .month, .day], from: date1)
        let components2 = calendar.dateComponents([.year, .month, .day], from: date2)
        return components1 == components2
    }

    
}



