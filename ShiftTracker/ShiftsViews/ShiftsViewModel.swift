//
//  ShiftsViewModel.swift
//  ShiftTracker
//
//  Created by James Poole on 7/04/23.
//

import Foundation
import SwiftUI
import Combine
import CoreData

class ShiftsViewModel: ObservableObject {
   // @Environment(\.managedObjectContext) private var viewContext
    
    
    @Published var searchText = ""
    
    @Published var isTotalShiftsTapped: Bool = false
    @Published var isTotalPayTapped: Bool = false
    @Published var isTaxedPayTapped: Bool = false
    @Published var isTotalHoursTapped: Bool = false
    @Published var isToggled = false
    @Published var isShareSheetShowing = false
    @Published var isEditing = false
    @Published var showAlert = false
    @Published var showingAddShiftSheet = false
    
    @Published var showProView = false
    
    @Published var searchBarOpacity: Double = 0.0
    @Published var searchBarScale: CGFloat = 0.9
    
    
    @Published var totalShiftsPay: Double = 0.0
    
    @Published var selectedShifts = Set<NSManagedObjectID>()
    
    
    func shiftSections(for shifts: FetchedResults<OldShift>) -> [(key: String, value: [OldShift])] {
        let sortedShifts: [OldShift]
        sortedShifts = shifts.sorted(by: { $0.shiftStartDate! > $1.shiftStartDate! })
        
        let groupedShifts = Dictionary(grouping: sortedShifts) { shift in
            let calendar = Calendar.current
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: shift.shiftStartDate!))!
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
            return "\(dateFormatter.string(from: startOfWeek)) - \(dateFormatter.string(from: endOfWeek))"
        }
        return groupedShifts.sorted(by: { $0.key > $1.key })
    }
    
    func filteredShifts(for shifts: FetchedResults<OldShift>) -> [OldShift] {
        if searchText.isEmpty {
            return Array(shifts)
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE d, MMMM"
            return Array(shifts.filter { shift in
                let dateText = dateFormatter.string(from: shift.shiftStartDate!).lowercased()
                return dateText.contains(searchText.lowercased())
            })
        }
    }
    
    func filteredShiftSections(for shifts: FetchedResults<OldShift>) -> [Date: [OldShift]] {
        let filteredShiftsArray = filteredShifts(for: shifts)
        return Dictionary(grouping: filteredShiftsArray, by: { shift in
            Calendar.current.startOfDay(for: shift.shiftStartDate!)
        })
    }

    
     var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
    

    
     func toggleSelection(for shift: OldShift) {
        let id = shift.objectID
        if selectedShifts.contains(id) {
            selectedShifts.remove(id)
        } else {
            selectedShifts.insert(id)
        }
    }
    
     func deleteShift(_ shift: OldShift, using context: NSManagedObjectContext) {
        context.delete(shift)
        do {
            try context.save()
        } catch {
            print("Error deleting shift: \(error)")
        }
    }
    
     func deleteSelectedShifts(shifts: FetchedResults<OldShift>, using context: NSManagedObjectContext) {
        for id in selectedShifts {
            if let shift = shifts.first(where: { $0.objectID == id }) {
                context.delete(shift)
            }
        }
        do {
            try context.save()
            selectedShifts.removeAll()
        } catch {
            print("Error deleting selected shifts: \(error)")
        }
    }
    
    
     var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM"
        return formatter
    }
    
    func addAllTaxedPay(shifts: FetchedResults<OldShift>) -> String {
        let total = shifts.reduce(0) { $0 + $1.taxedPay }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: total)) ?? "0.00"
    }
    
     func addAllPay(shifts: FetchedResults<OldShift>) -> String {
        let total = shifts.reduce(0) { $0 + $1.totalPay }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: total)) ?? "0.00"
    }
    
     func addAllHours(shifts: FetchedResults<OldShift>) -> String {
        let total = shifts.reduce(0) { $0 + $1.duration }
        let totalHours = total / 3600.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: totalHours)) ?? "0.00"
    }
    
    func shareButton(latestShifts: FetchedResults<OldShift>) {
        let fileName = "export.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        var csvText = "Start Date,End Date,Break Start,Break End,Before Tax,After Tax\n"
        
        for latestShift in latestShifts {
            csvText += "\(latestShift.shiftStartDate ?? Date()),\(latestShift.shiftEndDate ?? Date()),\(latestShift.breakStartDate ?? Date())\(latestShift.breakEndDate ?? Date()),\(latestShift.shiftEndDate ?? Date()),\(latestShift.totalPay ),\(latestShift.taxedPay )\n"
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
        
        //UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
        
        isShareSheetShowing.toggle()
    }
    
    
}
