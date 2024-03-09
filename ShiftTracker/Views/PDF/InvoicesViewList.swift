//
//  InvoicesViewList.swift
//  ShiftTracker
//
//  Created by James Poole on 9/03/24.
//

import SwiftUI

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
    
    @State private var invoices: [InvoiceFile] = []
    
    @State private var job: Job? = nil
    
    func fetchPDFFiles() -> [InvoiceFile] {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        var pdfFiles: [InvoiceFile] = []
        
        if let job = job, let jobName = job.name {
            let jobDirectory = documentsDirectory.appendingPathComponent(jobName)
            pdfFiles = fetchPDFs(in: jobDirectory)
        } else { // no job selected, display all
            // Fetch all PDFs in the documents directory, including subdirectories
            let enumerator = fileManager.enumerator(at: documentsDirectory, includingPropertiesForKeys: [.creationDateKey], options: [], errorHandler: nil)
            while let url = enumerator?.nextObject() as? URL {
                if url.pathExtension == "pdf" {
                    let attributes = try? fileManager.attributesOfItem(atPath: url.path)
                    let creationDate = attributes?[.creationDate] as? Date
                    pdfFiles.append(InvoiceFile(url: url, creationDate: creationDate))
                }
            }
        }
        
        return pdfFiles.sorted(by: { ($0.creationDate ?? Date.distantPast) > ($1.creationDate ?? Date.distantPast) })
    }
    
    func fetchPDFs(in directory: URL) -> [InvoiceFile] {
        let fileManager = FileManager.default
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey])
            return fileURLs.filter { $0.pathExtension == "pdf" }.map { url -> InvoiceFile in
                let attributes = try? fileManager.attributesOfItem(atPath: url.path)
                let creationDate = attributes?[.creationDate] as? Date
                return InvoiceFile(url: url, creationDate: creationDate)
            }
        } catch {
            print("Error fetching PDF files in directory \(directory): \(error)")
            return []
        }
    }
    
    
    func deletePDF(fileURL: URL) {
        do {
            try FileManager.default.removeItem(at: fileURL)
            invoices = fetchPDFFiles() // Refresh the list
        } catch {
            print("Error deleting file: \(error)")
        }
    }
    
    init(job: Job?) {
        
        _job = State(initialValue: job)
        
        _invoices = State(initialValue: fetchPDFFiles())
        
       
    }
    
    
    var body: some View {
        
        ScrollViewReader { proxy in
            List(Array(invoices.enumerated()), id: \.offset) { index, invoiceFile in
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
                    Text(invoiceFile.url.lastPathComponent).bold()
                    
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
                       invoices = fetchPDFFiles()
                   }
        
        // couldve read the overviewmodel job from the get go perhaps, forgot about that mustve been some kinda duct tape fix...
        // well hey! a duct tape fix using a duct tape fix! it just works tm
            .onChange(of: overviewModel.job) { newJob in
                       job = newJob
                       invoices = fetchPDFFiles()
                   }
        
         
            .navigationTitle("Invoices")
    }
}
