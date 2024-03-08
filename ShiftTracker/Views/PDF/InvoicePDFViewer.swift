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
        // we will leave this empty as we don't need to update the PDF
    }
}

struct InvoiceViewSheet: View {
    
    let url: URL
    
    var body: some View {
        
        NavigationStack {
            ZStack(alignment: .bottomTrailing){
                InvoicePDFViewer(url: url).ignoresSafeArea()
                
                ShareLink(item: url, label: {
                    Image(systemName: "square.and.arrow.up.fill")
                })
                    .padding()
                        .glassModifier(cornerRadius: 20)
                        .padding()
                
            }
                .toolbar {
                    CloseButton()
                }
            
                .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}
