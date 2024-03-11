//
//  PayPeriodSectionView.swift
//  ShiftTracker
//
//  Created by James Poole on 11/03/2024.
//

import SwiftUI

struct PayPeriodSectionView: View {
    
    @EnvironmentObject private var selectedJobManager: JobSelectionManager
    @EnvironmentObject private var overviewModel: JobOverviewViewModel
    
    
    @FetchRequest var shifts: FetchedResults<OldShift>
    
    var payPeriod: PayPeriod? = nil
    var job: Job? = nil
    
    let shiftManager = ShiftDataManager()
    
    init(payPeriod: PayPeriod? = nil, job: Job? = nil) {

        if let job = job, let payPeriod = payPeriod, let startDate = payPeriod.startDate, let endDate = payPeriod.endDate {
            
            let jobPredicate = NSPredicate(format: "job == %@", job)
            let datePredicate = NSPredicate(format: "shiftStartDate >= %@ AND shiftEndDate <= %@", startDate as CVarArg, endDate as CVarArg)
            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [jobPredicate, datePredicate])
            self._shifts = FetchRequest(
                entity: OldShift.entity(),
                sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)],
                predicate: compoundPredicate
            )
            
        } else {
            self._shifts = FetchRequest(
                entity: OldShift.entity(),
                sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)],
                predicate: .none
            )
        }
        

        
        
        self.payPeriod = payPeriod
        self.job = job

    }
    
    var body: some View {
        HStack {
            Image(systemName: "dollarsign.circle.fill").font(.largeTitle)
            
                
                
                
                
                if let payPeriod = payPeriod {
                    VStack(alignment: .leading){
                        HStack {
                            Text("Pay Period").bold().font(.headline)
                            Divider().frame(height: 8)
                            Text("\(payPeriod.periodRange)")
                                .font(.caption)
                                .bold()
                                .roundedFontDesign()
                                .foregroundStyle(.gray)
                        }
                        
                        Text(
                            shiftManager.statsMode == .earnings ? "\(shiftManager.currencyFormatter.string(from: NSNumber(value: shiftManager.addAllPay(shifts: shifts, jobModel: selectedJobManager))) ?? "0")" :
                                shiftManager.statsMode == .hours ? shiftManager.formatTime(timeInHours: shiftManager.addAllHours(shifts: shifts, jobModel: selectedJobManager)) :
                                shiftManager.formatTime(timeInHours: shiftManager.addAllBreaksHours(shifts: shifts, jobModel: selectedJobManager))
                        )
                        
                        .roundedFontDesign()
                        .bold()
                        .foregroundStyle(.gray)
                        .font(.subheadline)
                        
                    }
                    
                } else {
                    Text("Pay Periods").bold().font(.headline)
                }
                
                
            
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .bold()
            
                .font(.subheadline)
                .foregroundStyle(.gray)
                .padding(.trailing)
            
            
        }.contentShape(Rectangle())
        
            .contextMenu{
                
                
                
                Button(action: {
                    // exportPayPeriod(shifts)
                }){
                    HStack {
                        Text("Export Shifts")
                        Image(systemName: "square.and.arrow.up.fill")
                    }
                }
                
            }
        
        
        
    }
    
    
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    func exportPayPeriod(_ shifts: FetchedResults<OldShift>) {
        overviewModel.shiftSelectionForExport = Set(shifts.map { $0.objectID })
        overviewModel.activeSheet = .configureExportSheet
    }
    
}
