//
//  CurrencyTextField.swift
//  ShiftTracker
//
//  Created by James Poole on 5/07/23.
//

import SwiftUI

struct CurrencyTextField: View {
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
          
            Text(Locale.current.currencySymbol ?? "")
                .foregroundStyle(.gray)
            TextField(placeholder, text: $text)
        }
    }
}
