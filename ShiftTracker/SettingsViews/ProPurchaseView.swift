//
//  ProPurchaseView.swift
//  ShiftTracker
//
//  Created by Louis Kolodzinski on 27/07/23.
//

import SwiftUI

struct ProPurchaseView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            VStack{
                
                Text("🥳")
                    .font(.system(size: 120))
                
                Group {
                    Text("Thanks for going")
                    
                 //   Text("going")
                }    .fontDesign(.rounded)
                    .font(.title).bold()
                
                    
                    Text("PRO")
                        .font(.system(size: 80))
                    /// .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundStyle(colorScheme == .dark ? .orange : .cyan)
                    
                
                
            }
            
            
        }
    }
}

struct ProPurchaseView_Previews: PreviewProvider {
    static var previews: some View {
        ProPurchaseView()
    }
}


