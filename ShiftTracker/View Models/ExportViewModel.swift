//
//  ExportViewModel.swift
//  ShiftTracker
//
//  Created by James Poole on 8/10/23.
//

import Foundation
import CoreData
import SwiftUI

class ExportViewModel: ObservableObject {
    @Published var selectedColumns: [ExportColumn] = ExportColumn.allCases
    @Published var selectedDateRange: DateRange = .all
    @Published var isShareSheetShowing = false
    
    var selectedShifts: Set<NSManagedObjectID>? = nil
    var shifts: FetchedResults<OldShift>? = nil
    var arrayShifts: [OldShift]? = nil
    var job: Job?
    var singleExportShift: OldShift? = nil
    var viewContext: NSManagedObjectContext
    
    init(shifts: FetchedResults<OldShift>? = nil, selectedShifts: Set<NSManagedObjectID>? = nil, job: Job? = nil, viewContext: NSManagedObjectContext, arrayShifts: [OldShift]? = nil, singleExportShift: OldShift? = nil){
        self.selectedShifts = selectedShifts
        self.shifts = shifts
        self.job = job
        self.viewContext = viewContext
        self.arrayShifts = arrayShifts
        self.singleExportShift = singleExportShift
    }
    
    struct ExportColumn: Identifiable {
        let id: String
        let title: String
        var isSelected: Bool
        static var allCases: [ExportColumn] {
            return [
                .init(id: "jobName", title: "Job Name", isSelected: true),
                .init(id: "startDate", title: "Start Date", isSelected: true),
                .init(id: "endDate", title: "End Date", isSelected: true),
                .init(id: "duration", title: "Duration", isSelected: true),
                .init(id: "hourlyRate", title: "Hourly Rate", isSelected: true),
                .init(id: "beforeTax", title: "Before Tax", isSelected: true),
                .init(id: "afterTax", title: "After Tax", isSelected: true),
                .init(id: "tips", title: "Tips", isSelected: true),
                .init(id: "notes", title: "Notes", isSelected: true)
            ]
        }
    }
    
    enum DateRange: CaseIterable {
        case all, year, sixMonths, thisMonth, thisWeek
        
        var title: String {
            switch self {
            case .all:
                return "All"
            case .year:
                return "Year"
            case .sixMonths:
                return "6 Months"
            case .thisMonth:
                return "This Month"
            case .thisWeek:
                return "This Week"
            }
        }
    }
    
    private func shouldInclude(shift: OldShift) -> Bool {
        if let selectedShifts = selectedShifts {
            return selectedShifts.contains(shift.objectID)
        } else {
            return isShiftWithinDateRange(shift: shift)
        }
    }
    
    private func isShiftWithinDateRange(shift: OldShift) -> Bool {

        guard let startDate = shift.shiftStartDate else {
               return false
           }
        
        switch selectedDateRange {
        case .all:
            return true
        case .year:
            return Calendar.current.isDate(startDate, equalTo: Date(), toGranularity: .year)
        case .sixMonths:
            return Calendar.current.isDateInLastSixMonths(startDate)
        case .thisMonth:
            return Calendar.current.isDate(startDate, equalTo: Date(), toGranularity: .month)
        case .thisWeek:
            return Calendar.current.isDate(startDate, equalTo: Date(), toGranularity: .weekOfYear)
        }

        }
    
    
    
    func exportCSV() {
        
        
        var fileName = "export.csv"
        
        if let job = job {
            
            fileName = "\(job.name ?? "") ShiftTracker export.csv"
            
        }
        
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        var csvText = selectedColumns.filter { $0.isSelected }.map { $0.title }.joined(separator: ",") + "\n"

        
        var filteredShifts: [OldShift] = []
        
        // shifts (oldshift) is for historyview, and arrayShifts is for ShiftsList due to how the shifts are loaded differently in those views
        
        // for exporting a single shift
        if let singleExportShift = singleExportShift {
            filteredShifts.append(singleExportShift)
        }
        else if let theShifts = shifts {
            filteredShifts = theShifts.filter { shouldInclude(shift: $0) }
        } else if let arrayShifts = arrayShifts {
            filteredShifts = arrayShifts.filter { shouldInclude(shift: $0) }
        }
        

        
        for shift in filteredShifts {
            
            if let jobid = job?.uuid {
                if shift.job?.uuid == jobid {
                    var row = ""
                    
                    if let column = selectedColumns.first(where: { $0.id == "jobName" }), column.isSelected {
                        row += "\(shift.job?.name ?? ""),"
                    }
                    if let column = selectedColumns.first(where: { $0.id == "startDate" }), column.isSelected {
                        row += "\(shift.shiftStartDate ?? Date()),"
                    }
                    
                    if let column = selectedColumns.first(where: { $0.id == "endDate"}), column.isSelected {
                        row += "\(shift.shiftStartDate ?? Date()),"
                    }
                    if let column = selectedColumns.first(where: {$0.id == "duration"}), column.isSelected {
                        row += "\(shift.duration),"
                    }
                    if let column = selectedColumns.first(where: {$0.id == "hourlyRate"}), column.isSelected {
                        row += "\(shift.hourlyPay),"
                    }
                    if let column = selectedColumns.first(where: { $0.id == "beforeTax"}), column.isSelected {
                        row += "\(shift.totalPay),"
                    }
                    
                    if let column = selectedColumns.first(where: { $0.id == "afterTax"}), column.isSelected {
                        row += "\(shift.taxedPay),"
                    }
                    
                    if let column = selectedColumns.first(where: { $0.id == "tips"}), column.isSelected {
                        row += "\(shift.totalTips),"
                    }
                    
                    if let column = selectedColumns.first(where: { $0.id == "notes"}), column.isSelected {
                        row += "\(shift.shiftNote ?? "")"
                    }
                    
                    csvText += "\(row)\n"
                }
                
            } else {
                
                var row = ""
                if selectedColumns.contains(where: { $0.id == "jobName" }) { row += "\(shift.job?.name ?? ""),"}
                if selectedColumns.contains(where: { $0.id == "startDate" }) { row += "\(shift.shiftStartDate ?? Date()),"}
                if selectedColumns.contains(where: { $0.id == "endDate" }) { row += "\(shift.shiftEndDate ?? Date()),"}
                if selectedColumns.contains(where: { $0.id == "duration" }) { row += "\(shift.duration),"}
                if selectedColumns.contains(where: { $0.id == "hourlyRate" }) { row += "\(shift.hourlyPay),"}
                if selectedColumns.contains(where: { $0.id == "beforeTax" }) { row += "\(shift.totalPay),"}
                if selectedColumns.contains(where: { $0.id == "afterTax" }) { row += "\(shift.taxedPay),"}
                if selectedColumns.contains(where: { $0.id == "tips" }) { row += "\(shift.totalTips),"}
                if selectedColumns.contains(where: { $0.id == "notes" }) { row += "\(shift.shiftNote ?? "")"}
                
                csvText += "\(row)\n"
                
            }
            
            
        }
        
        do {
            try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create file")
            print("\(error)")
        }
        print(path ?? "not found")
        
        var filesToShare = [Any]()
        filesToShare.append(path!)
        
        let av = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
        
        UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
        
        isShareSheetShowing.toggle()
        
    }
}
