//
//  ProPurchaseView.swift
//  ShiftTracker
//
//  Created by Louis Kolodzinski on 27/07/23.
//

import SwiftUI

struct PurchaseSuccessView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack{
                
                Text("🥳")
                    .font(.system(size: 120))
                
                Group {
                    Text("Thanks for going")
                    
         
                }   .roundedFontDesign()
                    .font(.title).bold()
                
                    
                    Text("PRO")
                        .font(.system(size: 80))
                        .fontWeight(.heavy)
                        .foregroundStyle(colorScheme == .dark ? Color.orange.gradient : Color.cyan.gradient)
                    
                
                
            }
            
            .toolbar {
                
                ToolbarItem(placement: .navigationBarLeading) {
                    
                    CloseButton()
                    
                    
                }
                
                
            }
            
        }
    }
}

struct ProPurchaseView_Previews: PreviewProvider {
    static var previews: some View {
        PurchaseSuccessView()
    }
}


