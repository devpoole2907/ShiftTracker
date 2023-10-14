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
        addToolbar(textField, context: context)
        
        let currencyLabel = UILabel()
                currencyLabel.text = Locale.current.currencySymbol ?? "$"
                currencyLabel.sizeToFit()
                textField.leftView = currencyLabel
                textField.leftViewMode = .always
        
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


