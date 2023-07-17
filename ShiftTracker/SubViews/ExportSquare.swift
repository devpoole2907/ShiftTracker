//
//  ExportSquare.swift
//  ShiftTracker
//
//  Created by James Poole on 7/07/23.
//

import SwiftUI
import CoreData

struct ExportSquare: View {
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var shiftManager: ShiftDataManager
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    @State private var showingProView = false
    
    let action: () -> Void
    
    var body: some View {
        
        let subTextColor: Color = colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5)
        let headerColor: Color = colorScheme == .dark ? .white : .black
        
        VStack(alignment: .leading, spacing: 10){

                Text("Total Shifts")
                .bold()
                    .font(.headline)
        
            
            Text("\(shiftManager.totalShifts)")
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
                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                    .font(.title3)
                }
            }.padding(.horizontal)
                .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(colorScheme == .dark ? .white : .black)
                .cornerRadius(20)
                .buttonStyle(.plain)
                .contentShape(Rectangle())
        }.padding()
        .background(Color("SquaresColor"))
            .cornerRadius(12)

            .sheet(isPresented: $showingProView) {
                
                ProView()
                    .environmentObject(purchaseManager)
                
            }
        
        
    }
    
    
}

struct ExportSquare_Previews: PreviewProvider {
    static var previews: some View {
        
        let mockShiftManager = ShiftDataManager() // provide mock implementation
        let mockJobSelectionViewModel = JobSelectionManager() // provide mock implementation
        let mockManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType) // provide mock implementation
        
        
        ExportSquare(action: {})
            .environmentObject(mockShiftManager)
           // .environmentObject(mockNavigationState)
            .environmentObject(mockJobSelectionViewModel)
            .environment(\.managedObjectContext, mockManagedObjectContext)
            //.previewLayout(.fixed(width: 400, height: 200)) // Change the width and height as per your requirement
    }
}
