//
//  InvoicePDFViewer.swift
//  ShiftTracker
//
//  Created by James Poole on 9/03/24.
//

import SwiftUI
import PDFKit
import Combine

struct InvoicePDFViewer: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: UIViewRepresentableContext<InvoicePDFViewer>) -> PDFView {
     
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: self.url)
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: UIViewRepresentableContext<InvoicePDFViewer>) {

    }
}

class InvoiceRenameManager: ObservableObject {
    
    @Published var fileName: String = ""
    @Published var debouncedFileName: String = ""
    @Published var url: URL
    
    init(url: URL) {
        
        self.url = url
        self.fileName = url.deletingPathExtension().lastPathComponent

        setupTitleDebounce()
    }
    
    func setupTitleDebounce() {
        debouncedFileName = self.fileName
        $fileName.debounce(for: .seconds(0.75), scheduler: RunLoop.main)
            .assign(to: &$debouncedFileName)
    }
    
    func renameFile(to newName: String) {
            let newPath = url.deletingLastPathComponent().appendingPathComponent(newName).appendingPathExtension("pdf")
            do {
                try FileManager.default.moveItem(at: url, to: newPath)
                // Update the URL in the state to reflect the new file name
                self.url = newPath
            } catch {
                print("Failed to rename file: \(error)")
            }
        }
    
}

struct InvoiceViewSheet: View {
    
    @EnvironmentObject var viewModel: InvoiceViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var navigationState: NavigationState
    
    @StateObject var invoiceRenamer: InvoiceRenameManager
    
    var isSheet = false

    init(isSheet: Bool = false, url: URL) {
           
           self.isSheet = isSheet
           // Extract the file name without extension
        
        _invoiceRenamer = StateObject(wrappedValue: InvoiceRenameManager(url: url))
        
      
        
       }
    
  
    

    
    var body: some View {
        
 
            ZStack(alignment: .bottomTrailing){
                InvoicePDFViewer(url: invoiceRenamer.url).ignoresSafeArea()
                
             
                if purchaseManager.hasUnlockedPro {
                    ShareLink(item: invoiceRenamer.url, label: {
                        Image(systemName: "square.and.arrow.up.fill")
                    })
                    .padding()
                    .glassModifier(cornerRadius: 20)
                    .padding()
                    
                    .padding(.bottom, isSheet ? 0 : 25)
                    
                } else {
                    Button(action: {
                        viewModel.showProView.toggle()
                    }) {
                        Image(systemName: "square.and.arrow.up.fill")
                    }   .padding()
                        .glassModifier(cornerRadius: 20)
                        .padding()
                    
                        .padding(.bottom, isSheet ? 0 : 25)
                    
                }
                
            }.overlay {
                if !purchaseManager.hasUnlockedPro {
                    Group {
                        Text("ShiftTracker ").font(.title).bold().foregroundColor(Color.black)
                        +
                        Text("PRO").font(.largeTitle).fontWeight(.heavy).foregroundColor(Color.orange)
                    }.opacity(0.3)
                }
            }
        
            
            .fullScreenCover(isPresented: $viewModel.showProView) {
                ProView()
                    .environmentObject(purchaseManager)
                
                    .customSheetBackground()
            }
            
                .toolbar {
                    if isSheet {
                        ToolbarItem(placement: .topBarTrailing) {
                            CloseButton()
                        }
                    }
                    
                  
                    
                }
            
                .toolbar(.hidden, for: .bottomBar)
                .toolbar(.hidden, for: .tabBar)
                .toolbarRole(isSheet ? .automatic : .editor)
        
                .onChange(of: invoiceRenamer.debouncedFileName) { newName in
                    invoiceRenamer.renameFile(to: newName)
                      }
        
                .navigationTitle($invoiceRenamer.fileName)
                .navigationBarTitleDisplayMode(.inline)
     
    }
}
