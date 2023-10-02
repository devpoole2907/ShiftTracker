//
//  MockupMapView.swift
//  ShiftTracker
//
//  Created by James Poole on 25/09/23.
//

import SwiftUI
import MapKit

struct MockupMapView: View {

    
    
    var body: some View {
        
        ZStack(alignment: .bottomTrailing){
            Image(systemName: "map.fill")
                .symbolRenderingMode(.hierarchical)
                .resizable()
                .scaledToFit()
                .opacity(0.5)
            
            Image(systemName: "mappin")
                .symbolRenderingMode(.hierarchical)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 130)
              
            
        }
        .frame(maxWidth: 200)
            .foregroundStyle(.gray)
        
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
    }
    
}

#Preview {
    MockupMapView()
}
