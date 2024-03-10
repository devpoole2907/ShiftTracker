//
//  InvoicesViewList.swift
//  ShiftTracker
//
//  Created by James Poole on 9/03/24.
//

import SwiftUI
import TipKit

struct InvoicesListView: View {
    
    @EnvironmentObject var themeManager: ThemeDataManager
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var selectedJobManager: JobSelectionManager
    @EnvironmentObject var overviewModel: JobOverviewViewModel
    @EnvironmentObject var scrollManager: ScrollManager
    
    @Environment(\.managedObjectContext) var viewContext
    
    @StateObject var invoiceViewModel = InvoiceViewModel()
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var files: [PdfFile] = []
    
    @State private var job: Job? = nil
    
    func fetchPDFFiles() -> [PdfFile] {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        var pdfFiles: [PdfFile] = []
        
        if let job = job, let jobName = job.name {
            let jobDirectory = documentsDirectory.appendingPathComponent(jobName)
            let directoryName = filesToDisplay == .invoice ? "Invoices" : "Timesheets"
            let specificDirectory = jobDirectory.appendingPathComponent(directoryName)
            pdfFiles = fetchPDFs(in: specificDirectory)
        } else { // no job selected, display all
            // Fetch all PDFs in the documents directory, including subdirectories
            let enumerator = fileManager.enumerator(at: documentsDirectory, includingPropertiesForKeys: [.creationDateKey], options: [], errorHandler: nil)
            while let url = enumerator?.nextObject() as? URL {
                if url.pathExtension == "pdf" && url.deletingLastPathComponent().lastPathComponent == (filesToDisplay == .invoice ? "Invoices" : "Timesheets") {
                    let attributes = try? fileManager.attributesOfItem(atPath: url.path)
                    let creationDate = attributes?[.creationDate] as? Date
                    pdfFiles.append(PdfFile(url: url, creationDate: creationDate))
                }
            }
        }
        
        return pdfFiles.sorted(by: { ($0.creationDate ?? Date.distantPast) > ($1.creationDate ?? Date.distantPast) })
    }

    
    func fetchPDFs(in directory: URL) -> [PdfFile] {
        let fileManager = FileManager.default
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey])
            return fileURLs.filter { $0.pathExtension == "pdf" }.map { url -> PdfFile in
                let attributes = try? fileManager.attributesOfItem(atPath: url.path)
                let creationDate = attributes?[.creationDate] as? Date
                return PdfFile(url: url, creationDate: creationDate)
            }
        } catch {
            print("Error fetching PDF files in directory \(directory): \(error)")
            return []
        }
    }
    
    
    func deletePDF(fileURL: URL) {
        do {
            try FileManager.default.removeItem(at: fileURL)
            files = fetchPDFFiles() // Refresh the list
        } catch {
            print("Error deleting file: \(error)")
        }
    }
    
    init(job: Job?) {
        
        _job = State(initialValue: job)
        
        _files = State(initialValue: fetchPDFFiles())
        
       
    }
    
    @State var filesToDisplay: PdfFileType = .invoice
    
    
    var body: some View {
        
        
        ZStack(alignment: .bottom){
        ScrollViewReader { proxy in
            
            
            List {
                
  
                
                if #available(iOS 17.0, *) {
                    if files.isEmpty {
                        
                        TipView(GenericTip(titleString: "You have no \(filesToDisplay.shortDescription)!", bodyString: "Create some by selecting shifts in the Latest Shifts and Activity views.", icon: "pencil.and.list.clipboard"))
                        
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        
                    }
                    
                }
                
                
                
                ForEach(Array(files.enumerated()), id: \.offset) { index, invoiceFile in
                    
                    
                    
                    
                    
                    NavigationLink(destination:
                                    
                                    InvoiceViewSheet(url: invoiceFile.url).environmentObject(invoiceViewModel).environmentObject(navigationState)
                        .toolbar(.hidden, for: .tabBar)
                        .onAppear {
                            navigationState.hideTabBar = true
                        }
                        .onDisappear {
                            navigationState.hideTabBar = false
                        }
                                   
                                   
                                   
                    ) {
                        
                        VStack(alignment: .leading, spacing: 4){
                            if let lastPathComponentURL = URL(string: invoiceFile.url.lastPathComponent) {
                                Text(lastPathComponentURL.deletingPathExtension().lastPathComponent).bold()
                            }
                            Divider().frame(maxWidth: 150)
                            
                            if let creationDate = invoiceFile.creationDate {
                                Text("Created: \(creationDate.formatted())")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                        }
                        
                    }.listRowBackground(Color.clear)
                    
                        .id(index)
                    
                    
                        .swipeActions {
                            Button(role: .destructive) {
                                deletePDF(fileURL: invoiceFile.url)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            if purchaseManager.hasUnlockedPro {
                                
                                ShareLink(item: invoiceFile.url, label: {
                                    Image(systemName: "square.and.arrow.up.fill")
                                })
                                
                            }
                            
                        }
                    
                        .contextMenu {
                            Button(role: .destructive) {
                                deletePDF(fileURL: invoiceFile.url)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            if purchaseManager.hasUnlockedPro {
                                
                                ShareLink(item: invoiceFile.url, label: {
                                    Text("Share")
                                    Image(systemName: "square.and.arrow.up.fill")
                                })
                                
                            }
                        }
                    
                    
                    
                        .background {
                            
                            // we dont need the geometry reader, performance is better just doing this
                            if index == 0 {
                                Color.clear
                                    .onDisappear {
                                        scrollManager.timeSheetsScrolled = true
                                        print("time sheets has been scrolled")
                                    }
                                    .onAppear {
                                        scrollManager.timeSheetsScrolled = false
                                        print("timesheets has not been scrolled")
                                    }
                            }
                        }
                }
                
                
                
                
            }.listStyle(.plain)
            
                .scrollContentBackground(.hidden)
                .onChange(of: scrollManager.scrollOverviewToTop) { value in
                    if value {
                        withAnimation(.spring) {
                            proxy.scrollTo(0, anchor: .top) // Scroll to the first item using its ID
                            print("Scrolled up to top of invoices")
                        }
                        DispatchQueue.main.async {
                            scrollManager.scrollOverviewToTop = false
                        }
                    }
                }
            
        }
            
            if job != nil { // display all if job isnt selected
                CustomSegmentedPicker(selection: $filesToDisplay, items: PdfFileType.allCases)
                    .frame(height: 30)
                    .glassModifier(cornerRadius: 20)
                    .padding(.horizontal)
                    .padding(.bottom)
                
                    .onChange(of: filesToDisplay) { _ in
                        files = fetchPDFFiles()
                    }
                
                
            }
        
    }
        
            .background {
                // this could be worked into the themeManagers pure dark mode?
                
                
                // weirdly enough it looks good switching to the settings background here
                if colorScheme == .dark {
                    themeManager.settingsDynamicBackground.ignoresSafeArea()
                } else {
                    Color.clear.ignoresSafeArea()
                }
            }
        
            .onAppear {
                       files = fetchPDFFiles()
                   }
        
        // couldve read the overviewmodel job from the get go perhaps, forgot about that mustve been some kinda duct tape fix...
        // well hey! a duct tape fix using a duct tape fix! it just works tm
            .onChange(of: overviewModel.job) { newJob in
                       job = newJob
                       files = fetchPDFFiles()
                   }
        
         
            .navigationTitle(job != nil ? filesToDisplay.shortDescription : "Invoices & Timesheets")
            .navigationBarTitleDisplayMode(job != nil ? .automatic : .inline)
    }
}

enum PdfFileType: Int, CaseIterable {
    
    case invoice
    case timesheet
    
    var shortDescription: String {
        switch self {
        case .invoice:
            return "Invoices"
        case .timesheet:
            return "Timesheets"
        }
    }
    
    var singularDescription: String {
        switch self {
        case .invoice:
            return "Invoice"
        case .timesheet:
            return "Timesheet"
        }
    }
    
    
}

extension PdfFileType: SegmentedItem {
    var contentType: SegmentedContentType {
        .text(shortDescription)
    }
}
