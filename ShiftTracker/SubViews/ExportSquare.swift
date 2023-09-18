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
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    @State private var showingProView = false
    
    @State private var isTapped: Bool = false
    
    var totalShifts: Int
    
    let action: () -> Void
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 10){
            
            Text("Total Shifts")
                .bold()
                .font(.headline)
            
            
            Text("\(totalShifts)")
                .font(.largeTitle)
                .bold()
            
            Spacer()
            
            Button(action: {
                
                
                
                if purchaseManager.hasUnlockedPro {
                    action()
                } else {
                    
                    showingProView.toggle()
                    
                }
                
                
                
            }){
                HStack{
                    Group {
                        Image(systemName: "square.and.arrow.up.fill")
                        
                        
                        Text("Export")
                        
                        
                        
                    }
                    .bold()
                    .font(.subheadline)
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 10)
                .glassModifier(cornerRadius: 12, applyPadding: false)
                .contentShape(Rectangle())
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.scale)
            .haptics(onChangeOf: isTapped, type: .light)
            
        }.padding()
            .glassModifier(cornerRadius: 12, applyPadding: false)
        
            .fullScreenCover(isPresented: $showingProView) {
                
                ProView()
                    .environmentObject(purchaseManager)
                
                    .presentationBackground(.ultraThinMaterial)
                
            }
        
        
    }
    
    
}
