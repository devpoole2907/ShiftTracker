//
//  ScheduledShiftRow.swift
//  ShiftTracker
//
//  Created by James Poole on 8/10/23.
//

import SwiftUI

struct ScheduledShiftRow: View {
    
    @EnvironmentObject var shiftStore: ShiftStore
    @EnvironmentObject var scheduleModel: SchedulingViewModel
    
    @Environment(\.managedObjectContext) private var viewContext
    
    let shift: SingleScheduledShift
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View{
        HStack {
            // Vertical line
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(red: Double(shift.job?.colorRed ?? 0), green: Double(shift.job?.colorGreen ?? 0), blue: Double(shift.job?.colorBlue ?? 0)).gradient)
                .frame(width: 4)
            
            VStack(alignment: .leading) {
                Text(shift.job?.name ?? "")
                    .bold()
                    .roundedFontDesign()
                Text(shift.job?.title ?? "")
                    .foregroundStyle(.gray)
                    .roundedFontDesign()
                    .bold()
            }
            Spacer()
            
            VStack(alignment: .trailing){
            
                    Text(timeFormatter.string(from: shift.startDate))
                        .font(.subheadline)
                        .bold()
                        .roundedFontDesign()
                
              
                Text(timeFormatter.string(from: shift.endDate))
                        .font(.subheadline)
                        .bold()
                        .roundedFontDesign()
                        .foregroundStyle(.gray)
            }
        }
    }
}
