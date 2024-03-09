//
//  InvoiceViewModel.swift
//  ShiftTracker
//
//  Created by James Poole on 8/03/24.
//

import Foundation
import CoreData
import SwiftUI

class InvoiceViewModel: ObservableObject {
    
    @Published var tableCells: [ShiftTableCell] = []
    @Published var totalPay: Double = 0.0
    @Published var showPDFViewer = false
    
    //show pro view if they try export and arent pro
    @Published var showProView = false
    
    // input variables
    
    // user input
    // save users details for next time
    @AppStorage("userName") var userName: String = ""
    @AppStorage("userStreetAddress") var userStreetAddress = ""
    @AppStorage("userCity") var userCity = ""
    @AppStorage("userState") var userState = ""
    @AppStorage("userPostalCode") var userPostalCode = ""
    @AppStorage("userCountry") var userCountry = ""
    
    // might as well save the last invoice number in there, so they know to tick it up one
    @AppStorage("invoiceNumber") var invoiceNumber = "0001"
    @Published var invoiceDate = Date()
    @Published var dueDate = Date()
    
    
    // client input
    
    @Published var jobName = ""
    @Published var clientStreetAddress = ""
    @Published var clientCity = ""
    @Published var clientState = ""
    @Published var clientPostalCode = ""
    @Published var clientCountry = ""
    
    // tax input
    
    @AppStorage("taxAbbreviation") var taxAbbreviation = "GST"
    @Published var singleTaxRate = 0.0
    @Published var taxSelection: InterestOption = .single
    @Published var taxedPay: Double = 0.0
    @Published var taxTaken: Double = 0.0
    
    var url: URL? = nil
    
    var selectedShifts: Set<NSManagedObjectID>? = nil
    var shifts: FetchedResults<OldShift>? = nil
    var arrayShifts: [OldShift]? = nil
    var job: Job? = nil
    var singleExportShift: OldShift? = nil
    var viewContext: NSManagedObjectContext = PersistenceController.shared.container.viewContext
    
    
    init(shifts: FetchedResults<OldShift>? = nil, selectedShifts: Set<NSManagedObjectID>? = nil, job: Job? = nil, viewContext: NSManagedObjectContext, arrayShifts: [OldShift]? = nil, singleExportShift: OldShift? = nil){
        self.selectedShifts = selectedShifts
        self.shifts = shifts
        self.job = job
        self.viewContext = viewContext
        self.arrayShifts = arrayShifts
        self.singleExportShift = singleExportShift
        
        
        setupData()
        
    }
    
    init() {
        // wont always need the variables above loaded to use this model (for example when viewing an old invoice)
    }
    
    
    // this func is in two places, also in exportviewmodel. could consolidate it somewhere in future.
    private func shouldInclude(shift: OldShift) -> Bool {
        if let selectedShifts = selectedShifts {
            return selectedShifts.contains(shift.objectID)
        } /*else {
           return isShiftWithinDateRange(shift: shift)
           }*/
        
        return false
        
    }
    
    func setupData() {
        
        
        if let job = job {
            
            jobName = job.name ?? ""
            
            if let firstLocation = job.locations?.anyObject() as? JobLocation {
                let addressComponents = firstLocation.address?.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                
                if let components = addressComponents {
                    // Concatenate the street number and street name if both are present
                    clientStreetAddress = (components.count > 1 ? components[0] + " " : "") + (components.count > 0 ? components[1] : "")
                    clientCity = components.count > 2 ? components[2] : ""
                    clientState = components.count > 3 ? components[3] : ""
                    clientPostalCode = components.count > 4 ? components[4] : ""
                    clientCountry = components.count > 5 ? components[5] : ""
                }
            }
            
            singleTaxRate = job.tax
            
            
        }
        
        
        
        var filteredShifts: [OldShift] = []
        
        if let theShifts = shifts {
            filteredShifts = theShifts.filter { shouldInclude(shift: $0) }.reversed()
        } else if let arrayShifts = arrayShifts {
            filteredShifts = arrayShifts.filter { shouldInclude(shift: $0) }.reversed()
        }
        
        tableCells = filteredShifts.map { shift in
            let duration = shift.duration // Assuming you have a duration property in OldShift
            let rate = shift.hourlyPay // Assuming you have a rate property in OldShift
            let pay = shift.totalPay
            return ShiftTableCell(date: shift.shiftStartDate ?? Date(), duration: duration, rate: rate, pay: pay)
        }
        
        totalPay = tableCells.reduce(0) { $0 + $1.pay }
        
        
        
    }
    
    func calculateTax() {
        if taxSelection != .none {
               let totalTax = totalPay * (singleTaxRate / 100)
               taxTaken = totalTax
               taxedPay = totalPay - totalTax
            print("tax taken is: \(taxTaken)")
           } else {
               print("you DIED")
               taxedPay = totalPay
               taxTaken = 0.0
           }
    }
    
    func uniquePdfUrl(in directory: URL, baseName: String, fileExtension: String = "pdf") -> URL {
        var finalName = baseName
        var fileUrl = directory.appendingPathComponent("\(finalName).\(fileExtension)")
        var counter = 1
        
        let fileManager = FileManager.default
        // Check if the file exists and append a number if it does
        while fileManager.fileExists(atPath: fileUrl.path) {
            finalName = "\(baseName) \(counter)"
            fileUrl = directory.appendingPathComponent("\(finalName).\(fileExtension)")
            counter += 1
        }
        
        return fileUrl
    }
    
    @MainActor func render() {
        
        
        
        let a4Size = CGSize(width: 595, height: 842)
        
        let jobDirectory = URL.documentsDirectory.appendingPathComponent(jobName) // creates directory under the job name
            try? FileManager.default.createDirectory(at: jobDirectory, withIntermediateDirectories: true, attributes: nil)
           
        
        let uniqueUrl = uniquePdfUrl(in: jobDirectory, baseName: "\(jobName) invoice \(invoiceNumber)")
        
        let cellsPerPage = 36 // we need to limit how many cells can be displayed on each page, they may have selected a massive amount of shifts we dont want it to cut off
        
        let totalPages = (tableCells.count + cellsPerPage - 1) / cellsPerPage
        
        
        // we need renderers for each invoiceview necessary, so we need to calculate how many pages there will be based on a 40 cell per page limit
        // then loop through each renderer
        
        
        // we need to get cgrect's for each renderer
        //  var box = getViewRenderSize(renderer: renderer)
        
        var box = CGRect(origin: .zero, size: a4Size)
        
        guard let consumer = CGDataConsumer(url: uniqueUrl as CFURL), let pdfContext = CGContext(consumer: consumer, mediaBox: &box, nil)
        else {
            return
            // show some kinda error here!
        }
        
        calculateTax()
        
        for pageIndex in 0..<totalPages {
            
            let startIndex = pageIndex * cellsPerPage
            let endIndex = min(startIndex + cellsPerPage, tableCells.count)
            var cellsForPage = Array(tableCells[startIndex..<endIndex])
            
            let emptyCellsNeeded = cellsPerPage - cellsForPage.count
            if emptyCellsNeeded > 0 {
                for _ in 0..<emptyCellsNeeded {
                    let emptyCell = ShiftTableCell(date: Date(), duration: 0, rate: 0, pay: 0, isEmpty: true)
                    cellsForPage.append(emptyCell)
                }
            }
            
            
            
            let isLastPage = (pageIndex == totalPages - 1)
            
            // let renderer = ImageRenderer(content: InvoiceView(isLastPage: isLastPage, tableCells: cellsForPage, totalPay: totalPay, invoiceNumber: invoiceNumber, invoiceDate: invoiceDate, dueDate: dueDate))
            
            
            
            let renderer = ImageRenderer(content: InvoiceView(isLastPage: isLastPage, tableCells: cellsForPage, totalPay: totalPay, taxedPay: taxedPay, taxTaken: taxTaken, taxRate: 18.50, abbreviation: taxAbbreviation, invoiceNumber: invoiceNumber, invoiceDate: invoiceDate, dueDate: dueDate, clientName: jobName, clientStreetAddress: clientStreetAddress, clientCity: clientCity, clientState: clientState, clientPostalCode: clientPostalCode, clientCountry: clientCountry, userName: userName, userStreetAddress: userStreetAddress, userCity: userCity, userState: userState, userPostalCode: userPostalCode, userCountry: userCountry))
            
            pdfContext.beginPDFPage(nil)
            
            pdfContext.scaleBy(x: 1.2, y: 1.2)
            
            
            renderer.render { size, context in
                let xOffset: CGFloat = 15
                let yOffset: CGFloat = 0
                pdfContext.translateBy(x: xOffset, y: yOffset)
                context(pdfContext)
            }
            pdfContext.endPDFPage()
            
        }
        
        pdfContext.closePDF()
        
        self.url = uniqueUrl
        
    }
    
    @MainActor func getViewRenderSize(renderer: ImageRenderer<InvoiceView>) -> CGRect {
        
        var box: CGRect = CGRect()
        
        renderer.render { size, renderer in
            // 4: Tell SwiftUI our PDF should be the same size as the views we're rendering
            //     var box = CGRect(origin: .zero, size: a4Size)
            box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            
            
        }
        
        return box
        
        
    }
    
    
    
    
}



