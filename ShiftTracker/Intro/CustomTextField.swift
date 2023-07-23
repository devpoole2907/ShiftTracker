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
    var leadingIcon: String
    var isPassword: Bool = false
    
    private var charLimit = 8
    
    init(text: Binding<String>, hint: String, leadingIcon: String, isPassword: Bool = false) {
        _text = text
        self.hint = hint
        self.leadingIcon = leadingIcon
        self.isPassword = isPassword
        
        // adds clear text button to text fields
        UITextField.appearance().clearButtonMode = .whileEditing
        
    }
    
    
    var body: some View {
        HStack(spacing: 0){
            
            Image(systemName: text.count <= charLimit ? leadingIcon : "exclamationmark.triangle.fill")
                .font(.callout)
                .foregroundStyle(text.count <= charLimit ? .gray : .orange)
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


