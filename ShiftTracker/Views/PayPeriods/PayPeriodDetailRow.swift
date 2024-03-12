//
//  PayPeriodDetailRow.swift
//  ShiftTracker
//
//  Created by James Poole on 10/03/24.
//

import SwiftUI

struct PayPeriodDetailRow: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    var payPeriod: PayPeriod
    
    let shiftManager = ShiftDataManager()
    
    @EnvironmentObject var themeManager: ThemeDataManager
    @EnvironmentObject var selectedJobManager: JobSelectionManager
    
    @FetchRequest var shifts: FetchedResults<OldShift>
    
    init(payPeriod: PayPeriod, job: Job) {
        self.payPeriod = payPeriod
               let jobPredicate = NSPredicate(format: "job == %@", job)
               let datePredicate = NSPredicate(format: "shiftStartDate >= %@ AND shiftEndDate <= %@", payPeriod.startDate! as CVarArg, payPeriod.endDate! as CVarArg)
               let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [jobPredicate, datePredicate])
               self._shifts = FetchRequest(
                   entity: OldShift.entity(),
                   sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)],
                   predicate: compoundPredicate
               )
        
           }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
    
    
    
    var body: some View {
        
        let textColor: Color = colorScheme == .dark ? .white : .black
        let currentDate = Date()
        
        VStack(alignment: .leading, spacing: 5){
            Text("\(payPeriod.periodRange)")
                .bold()
                .font(.title2)
                .lineLimit(1)
            
            HStack(spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    
                    let payString = String(format: "%.2f", payPeriod.totalPay)
                    
                    Text("\(shiftManager.currencyFormatter.string(from: NSNumber(value: shiftManager.addAllPay(shifts: shifts, jobModel: selectedJobManager))) ?? "0")")
                        .foregroundStyle(textColor)
                        .font(.title3)
                        .bold()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    
                    
                    Text(shiftManager.formatTime(timeInHours: shiftManager.addAllHours(shifts: shifts, jobModel: selectedJobManager)))
                        .foregroundStyle(themeManager.timerColor)
                        .roundedFontDesign()
                        .font(.subheadline)
                        .bold()
                    
                    
                }
                
                if let startDate = payPeriod.startDate, let endDate = payPeriod.endDate, currentDate >= startDate && currentDate <= endDate {
                                    Text("Current")
                                        .font(.caption)
                                        .bold()
                                        .roundedFontDesign()
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5))
                                        .cornerRadius(6)
                                }
                
                
                
            }
            
            Text("\(shifts.count) Shifts")
                .roundedFontDesign()
                .foregroundColor(.gray)
                .font(.footnote)
                .bold()
            
        }
        
        
    }
    
    
}
