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
            }
            
        }.padding(.horizontal, 15)
            .padding(.vertical, 15)
            .background {
                RoundedRectangle(cornerRadius: 50, style: .continuous)
                    .fill(.gray.opacity(0.1))
            }
    }
}


