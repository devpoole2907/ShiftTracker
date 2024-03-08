//
//  ClientDetailsView.swift
//  ShiftTracker
//
//  Created by James Poole on 9/03/24.
//

import SwiftUI

struct ClientDetailsView: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Invoice to").foregroundStyle(.white).padding(.horizontal).background(Color.black.opacity(0.5)).padding(.vertical, 2).font(.caption)
            Text("Client name")
            Text("Street address")
            Text("Address line 2")
            Text("Country")
        }.font(.system(size: 8))
    }
    
}

#Preview {
    ClientDetailsView()
}
