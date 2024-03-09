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
    var leadingIcon: String? = nil
    var isPassword: Bool = false
    var hasPersistentLeadingIcon: Bool? = nil
    var alignLeft: Bool? = nil
    var capitaliseWords: Bool? = nil
    var isBold: Bool? = nil
    
    private var charLimit = 8
    
    init(text: Binding<String>, hint: String, leadingIcon: String? = nil, isPassword: Bool = false, hasPersistentLeadingIcon: Bool? = nil, alignLeft: Bool? = nil, capitaliseWords: Bool? = nil, isBold: Bool? = nil) {
        _text = text
        self.hint = hint
        self.leadingIcon = leadingIcon
        self.isPassword = isPassword
        self.hasPersistentLeadingIcon = hasPersistentLeadingIcon
        self.alignLeft = alignLeft
        self.capitaliseWords = capitaliseWords
        self.isBold = isBold
        
        // adds clear text button to text fields
        UITextField.appearance().clearButtonMode = .whileEditing
        
    }
    
    var textContentType: UITextContentType? {
            switch hint {
            case "Address":
                return .fullStreetAddress
            case "City":
                return .addressCity
            case "State":
                return .addressState
            case "Postal Code":
                return .postalCode
            case "Country":
                return .countryName
            default:
                return nil
            }
        }
    
    
    var body: some View {
        HStack(spacing: 0){
            
            
            if hasPersistentLeadingIcon ?? false {
                if let leadingIcon = leadingIcon {
                    Image(systemName: text.count <= charLimit ? leadingIcon : "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(text.count <= charLimit ? .gray : .orange)
                        .frame(width: 40, alignment: .leading)
                }
                
            } else {
            
            if text.isEmpty {
                // show leading icon warning triange only when the field is empty, just like uikit version
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.gray)
                    .frame(width: 40, alignment: .leading)
            } else {
                // Add some spacing to align the text properly when the icon is not shown
                Spacer()
                    .frame(width: 40)
            }
                
            }
            
            
            if isPassword{
                SecureField(hint, text: $text)
                    .multilineTextAlignment(alignLeft ?? false ? .leading : .trailing)
                 
            } else {
                TextField(hint, text: $text)
                    .padding(.leading, -15)
                    .multilineTextAlignment(alignLeft ?? false ? .leading : .trailing)
                    .textInputAutocapitalization(capitaliseWords ?? false ? .words : nil)
                    .textContentType(textContentType)
                    .fontWeight(isBold ?? false ? .bold : .regular)
            }
            
        }.padding(.horizontal)
            .padding(.vertical, 10)
            .glassModifier(cornerRadius: 20)
    }
}


