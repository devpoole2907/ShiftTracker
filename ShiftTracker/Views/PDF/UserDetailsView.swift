//
//  UserDetailsView.swift
//  ShiftTracker
//
//  Created by James Poole on 9/03/24.
//

import SwiftUI

struct UserDetailsView: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Your name").bold().font(.subheadline)
            Text("Street address")
            Text("Address line 2")
            Text("Country")
        }.font(.system(size: 8))
    }
    
}

#Preview {
    UserDetailsView()
}
