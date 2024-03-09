//
//  ExportSquare.swift
//  ShiftTracker
//
//  Created by James Poole on 7/07/23.
//

import SwiftUI
import CoreData
import Haptics

struct ExportSquare: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var selectedJobManager: JobSelectionManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    @State private var showingProView = false
    
    @State private var isTapped: Bool = false
    
    var totalShifts: Int
    
    let action: () -> Void
    
    var body: some View {
        
        let headerColor: Color = colorScheme == .dark ? .white : .black
        
        VStack(alignment: .leading, spacing: 8){
            
            Text("Total Shifts")
                .bold()
                .font(.headline)
                .foregroundStyle(headerColor)
            
            Text("\(totalShifts)")
                .font(.largeTitle)
                .bold()
                .foregroundStyle(headerColor)
            Spacer()
            
        
            
            Button(action: {
                
                isTapped.toggle()
                
                if purchaseManager.hasUnlockedPro {
                    action()
                } else {
                    
                    showingProView.toggle()
                    
                }
                
                
                
            }){
                HStack{
                    Group {
                        Image(systemName: "square.and.arrow.up.fill").customAnimatedSymbol(value: $isTapped)
                        
                        
                        Text("Export")
                        
                        
                        
                    }
                    .bold()
                    .font(.subheadline)
                    .foregroundStyle(headerColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .glassModifier(cornerRadius: 12, applyPadding: false)
                .contentShape(Rectangle())
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.scale)
            .haptics(onChangeOf: isTapped, type: .light)
            
        }.padding()
            .glassModifier(cornerRadius: 12, applyPadding: false)
        
        // dont apply padding if invoices disabled, because the invoice square below is missing
            .padding(.bottom, selectedJobManager.fetchJob(in: viewContext)?.enableInvoices ?? true ? 8 : 0)
        
            .fullScreenCover(isPresented: $showingProView) {
                
                ProView()
                    .environmentObject(purchaseManager)
                
                    .customSheetBackground()
                
            }
        
        
    }
    
    
}
