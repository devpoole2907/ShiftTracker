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
        
        return pdfFiles
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
        
        
        List(invoices, id: \.url) { invoiceFile in
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
            
        }.listStyle(.plain)
        
            .scrollContentBackground(.hidden)
        
            .background {
                // this could be worked into the themeManagers pure dark mode?
                
                
                // weirdly enough it looks good switching to the settings background here
                if colorScheme == .dark {
                    themeManager.settingsDynamicBackground.ignoresSafeArea()
                } else {
                    Color.clear.ignoresSafeArea()
                }
            }
        
            .navigationTitle("Invoices")
    }
}
