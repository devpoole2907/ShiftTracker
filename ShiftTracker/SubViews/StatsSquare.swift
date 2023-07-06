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
    @EnvironmentObject var jobSelectionViewModel: JobSelectionViewModel
    
    @FetchRequest var shifts: FetchedResults<OldShift>
    
    init(){
        let fetchRequest: NSFetchRequest<OldShift> = OldShift.fetchRequest()
        fetchRequest.predicate = nil
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)]
        _shifts = FetchRequest(fetchRequest: fetchRequest)
    }
    
    var body: some View {
        
        let subTextColor: Color = colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5)
        let headerColor: Color = colorScheme == .dark ? .white : .black
        HStack{
            VStack(alignment: .leading) {
                
                Text("This Week")
                    .font(.callout)
                    .bold()
                    .foregroundStyle(headerColor)
                if shiftManager.statsMode == .earnings {
                    Text("\(shiftManager.currencyFormatter.string(from: NSNumber(value: shiftManager.getTotalPay(from: shiftManager.getLastShifts(from: shifts, jobModel: jobSelectionViewModel, dateRange: .week)))) ?? "0")")
                        .font(.title)
                        .bold()
                        .foregroundStyle(headerColor)
                } else {
                    
                    Text("\(shiftManager.formatTime(timeInHours: shiftManager.getTotalHours(from: shiftManager.getLastShifts(from: shifts, jobModel: jobSelectionViewModel, dateRange: .week))))")
                    
                        .font(.title)
                        .bold()
                        .foregroundStyle(headerColor)
                }
                
                if shiftManager.statsMode == .earnings {
                    Text("\(shiftManager.currencyFormatter.string(from: NSNumber(value: shiftManager.addAllPay(shifts: shifts, jobModel: jobSelectionViewModel))) ?? "0") Total")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(subTextColor)
                } else {

                    Text("\(shiftManager.formatTime(timeInHours: shiftManager.addAllHours(shifts: shifts, jobModel: jobSelectionViewModel))) Total")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(subTextColor)
                }
                
            }
            .padding(.leading)
            Spacer()
        }
            .padding(.vertical, 8)
            .background(Color("SquaresColor"))
            .cornerRadius(12)
        
          
    }
}

struct StatsSquare_Previews: PreviewProvider {
    static var previews: some View {
        StatsSquare()
            .previewLayout(.fixed(width: 400, height: 200)) // Change the width and height as per your requirement
    }
}

