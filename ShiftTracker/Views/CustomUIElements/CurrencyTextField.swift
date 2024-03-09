//
//  CurrencyTextField.swift
//  ShiftTracker
//
//  Created by James Poole on 5/07/23.
//

import SwiftUI
import UIKit
// uiviewrepresentable instead of using swiftui because keyboard toolbars are broken in swiftui
struct CurrencyTextField: UIViewRepresentable {
    var placeholder: String
    @Binding var text: String
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.keyboardType = .decimalPad
        textField.textAlignment = .right
        textField.clearButtonMode = .whileEditing
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        addToolbar(textField, context: context)
        
        let currencyLabel = UILabel()
        currencyLabel.text = Locale.current.currencySymbol ?? "$"
        currencyLabel.sizeToFit()
        textField.leftView = currencyLabel
        textField.leftViewMode = .always
        
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }
    
    func addToolbar(_ textField: UITextField, context: Context) {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        toolbar.barStyle = .default
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: context.coordinator, action: #selector(context.coordinator.doneButtonTapped))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolbar.items = [flexSpace, doneButton]
        toolbar.sizeToFit()
        
        textField.inputAccessoryView = toolbar
    }
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CurrencyTextField
        var textField: UITextField?  // Keep a weak reference to the UITextField
        
        init(_ parent: CurrencyTextField) {
            self.parent = parent
        }
        
        func textFieldShouldClear(_ textField: UITextField) -> Bool {
                    parent.text = ""
                    return true
                }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            self.textField = textField  // Assign the weak reference
            if let newValue = textField.text as NSString? {
                parent.text = newValue.replacingCharacters(in: range, with: string)
            }
            return true
        }
        
        @objc func doneButtonTapped() -> Void {
            hideKeyboard()
        }
    }
    
}


import SwiftUI
import UIKit

struct IntegerTextField: UIViewRepresentable {
    var placeholder: String
    @Binding var text: String
    
    var alignLeft: Bool? = nil
    
    var showAlertSymbol: Bool? = nil

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.keyboardType = .numberPad
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.textAlignment = .right
        if let alignLeft {
            textField.textAlignment = .left
        }
        
        if showAlertSymbol ?? false {
                let alertIcon = UIImage(systemName: "exclamationmark.triangle.fill") // Using SF Symbols for the alert icon
                let alertIconView = UIImageView(image: alertIcon)
                alertIconView.tintColor = .gray // Set the color of the icon
            
                // Set the left view of the text field to the alert icon view
                textField.leftView = alertIconView
                textField.leftViewMode = .unlessEditing
            }
        
        
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
 
        textField.clearButtonMode = .whileEditing
        addToolbar(textField, context: context)

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        if let showAlertSymbol = showAlertSymbol, showAlertSymbol {
            uiView.leftView?.isHidden = !text.isEmpty // Show the alert icon only if the text is empty
        } else {
            uiView.leftView?.isHidden = true // Always hide the alert icon if showAlertSymbol is false or nil
        }
    }


    func addToolbar(_ textField: UITextField, context: Context) {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        toolbar.barStyle = .default

        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: context.coordinator, action: #selector(context.coordinator.doneButtonTapped))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        toolbar.items = [flexSpace, doneButton]
        toolbar.sizeToFit()

        textField.inputAccessoryView = toolbar
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: IntegerTextField

        init(_ parent: IntegerTextField) {
            self.parent = parent
        }

        func textFieldShouldClear(_ textField: UITextField) -> Bool {
            parent.text = ""
            return true
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            if string.isEmpty {
                parent.text = ""
                return true
            }

            let invalidCharacters = CharacterSet.decimalDigits.inverted
            if string.rangeOfCharacter(from: invalidCharacters) != nil {
                return false
            }

            if let newValue = textField.text as NSString? {
                parent.text = newValue.replacingCharacters(in: range, with: string)
            }

            return false
        }

        @objc func doneButtonTapped() -> Void {
            hideKeyboard()
        }
    }
}
