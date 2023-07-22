//
//  CustomTextField.swift
//  ShiftTracker
//
//  Created by James Poole on 29/04/23.
//

import SwiftUI

struct CustomTextField: View {
    
    @Binding var text: String
    var hint: String
    var leadingIcon: Image
    var isPassword: Bool = false
    
    init(text: Binding<String>, hint: String, leadingIcon: Image, isPassword: Bool = false) {
        _text = text
        self.hint = hint
        self.leadingIcon = leadingIcon
        self.isPassword = isPassword
        
        // adds clear text button to text fields
        UITextField.appearance().clearButtonMode = .whileEditing
        
    }
    
    
    var body: some View {
        HStack(spacing: 0){
            leadingIcon
                .font(.callout)
                .foregroundStyle(.gray)
                .frame(width: 40, alignment: .leading)
            
            
            if isPassword{
                SecureField(hint, text: $text)
            } else {
                TextField(hint, text: $text)
                    .padding(.leading, -15)
            }
            
        }.padding(.horizontal)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.gray.opacity(0.1))
            }
    }
}


