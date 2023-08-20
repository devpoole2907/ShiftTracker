//
//  ConfigureExportView.swift
//  ShiftTracker
//
//  Created by James Poole on 13/08/23.
//

import SwiftUI
import CoreData

struct ConfigureExportView: View {
    @ObservedObject var viewModel: ExportViewModel = ExportViewModel()
    var shifts: FetchedResults<OldShift>
    var job: Job?
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        
        let buttonColor: Color = colorScheme == .dark ? Color.white : Color.black
        let textColor: Color = colorScheme == .dark ? .black : .white
        
        NavigationStack {
            List{
                Section(header: Text("Include Columns").bold().textCase(nil).fontDesign(.rounded)) {
                    ForEach(viewModel.selectedColumns.indices, id: \.self) { index in
                        Toggle(viewModel.selectedColumns[index].title, isOn: $viewModel.selectedColumns[index].isSelected).toggleStyle(CustomToggleStyle())
                            .bold()
                    }.listRowSeparator(.hidden)
                        .listRowBackground(Color("SquaresColor"))
                }
                
                Section {
                    Picker("Date Range", selection: $viewModel.selectedDateRange) {
                        ForEach(ExportViewModel.DateRange.allCases, id: \.self) { range in
                            Text(range.title).tag(range)
                        }
                    }.bold()
                    .listRowSeparator(.hidden)
                        .listRowBackground(Color("SquaresColor"))
                }.listRowSeparator(.hidden)
                    .listRowBackground(Color("SquaresColor"))
                
                
                ActionButtonView(title: "Export", backgroundColor: buttonColor, textColor: textColor, icon: "square.and.arrow.up.fill", buttonWidth: UIScreen.main.bounds.width - 60) {
                    
                    dismiss()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                        viewModel.exportCSV(shifts: shifts, viewContext: viewContext, job: job)
                    }
                    
                    
                }.listRowSeparator(.hidden)
                    .listRowBackground(Color("SquaresColor"))
                
            } //.scrollContentBackground(.hidden)
                .navigationTitle("Export")
            
            
                .toolbar{
                    ToolbarItem(placement: .navigationBarTrailing) {
                        CloseButton {
                            dismiss()
                        }
                    }
                }
            
        }
    }
}

class ExportViewModel: ObservableObject {
    @Published var selectedColumns: [ExportColumn] = ExportColumn.allCases
    @Published var selectedDateRange: DateRange = .all
    @Published var isShareSheetShowing = false
    
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
    
    
    
    func exportCSV(shifts: FetchedResults<OldShift>, viewContext: NSManagedObjectContext, job: Job?) {
        
        
        var fileName = "export.csv"
        
        if let job = job {
            
            fileName = "\(job.name ?? "") ShiftTracker export.csv"
            
        }
        
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        var csvText = selectedColumns.filter { $0.isSelected }.map { $0.title }.joined(separator: ",") + "\n"
        
        let filteredShifts: [OldShift] = shifts.filter { shift in
            switch selectedDateRange {
            case .all:
                return true
            case .year:
                return Calendar.current.isDate(shift.shiftStartDate ?? Date(), equalTo: Date(), toGranularity: .year)
            case .sixMonths:
                return Calendar.current.isDateInLastSixMonths(shift.shiftStartDate ?? Date())
            case .thisMonth:
                return Calendar.current.isDate(shift.shiftStartDate ?? Date(), equalTo: Date(), toGranularity: .month)
            case .thisWeek:
                return Calendar.current.isDate(shift.shiftStartDate ?? Date(), equalTo: Date(), toGranularity: .weekOfYear)
            }
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
                    
                    
                    
                    
                    /*
                     if selectedColumns.contains(where: { $0.id == "duration" }) { row += "\(shift.duration),"}
                     if selectedColumns.contains(where: { $0.id == "hourlyRate" }) { row += "\(shift.hourlyPay),"}
                     if selectedColumns.contains(where: { $0.id == "beforeTax" }) { row += "\(shift.totalPay),"}
                     if selectedColumns.contains(where: { $0.id == "afterTax" }) { row += "\(shift.taxedPay),"}
                     if selectedColumns.contains(where: { $0.id == "tips" }) { row += "\(shift.totalTips),"}
                     if selectedColumns.contains(where: { $0.id == "notes" }) { row += "\(shift.shiftNote ?? "")"} */
                    
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

extension Calendar {
    func isDateInLastSixMonths(_ date: Date) -> Bool {
        let sixMonthsAgo = self.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        return date >= sixMonthsAgo
    }
}
