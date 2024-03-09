//
//  InvoicePDFViewer.swift
//  ShiftTracker
//
//  Created by James Poole on 9/03/24.
//

import SwiftUI
import PDFKit

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

struct InvoiceViewSheet: View {
    
    @EnvironmentObject var viewModel: InvoiceViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var navigationState: NavigationState
    
    var isSheet = false
    let url: URL
    
    var body: some View {
        
 
            ZStack(alignment: .bottomTrailing){
                InvoicePDFViewer(url: url).ignoresSafeArea()
                
             
                if purchaseManager.hasUnlockedPro {
                    ShareLink(item: url, label: {
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
                        CloseButton()
                    }
                }
            
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbarBackground(.hidden, for: .bottomBar)
                .toolbarBackground(.hidden, for: .tabBar)
                .toolbarRole(isSheet ? .automatic : .editor) 
     
    }
}
