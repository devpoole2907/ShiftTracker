//
//  CustomUIKitTextField.swift
//  ShiftTracker
//
//  Created by James Poole on 16/10/23.
//

import SwiftUI
import UIKit

struct CustomUIKitTextField: UIViewRepresentable {
    var placeholder: String
    @Binding var text: String
    var centerAlign: Bool = false
    var rounded: Bool = false
    var largeFont: Bool = true
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.clearButtonMode = .whileEditing
        textField.autocorrectionType = .no
        
        let fontSize: CGFloat = largeFont ? UIFont.preferredFont(forTextStyle: .title1).pointSize : UIFont.preferredFont(forTextStyle: .body).pointSize
        
        var font = UIFont.boldSystemFont(ofSize: fontSize)
        
        if rounded {
            if let roundedDescriptor = font.fontDescriptor.withDesign(.rounded) {
                font = UIFont(descriptor: roundedDescriptor, size: fontSize) // Modified this line
            }
        }
        textField.font = font
        if centerAlign {
            textField.textAlignment = .center
        }
        addToolbar(textField, context: context)
        
        
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
        var parent: CustomUIKitTextField
        
        init(_ parent: CustomUIKitTextField) {
            self.parent = parent
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            if let newValue = textField.text as NSString? {
                parent.text = newValue.replacingCharacters(in: range, with: string)
            }
            return true
        }
        
        func textFieldShouldClear(_ textField: UITextField) -> Bool {
                    parent.text = ""
                    return true
                }
        
        @objc func doneButtonTapped() -> Void {
            hideKeyboard()
        }
    }
}
