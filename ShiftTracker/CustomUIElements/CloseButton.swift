//
//  CloseButton.swift
//  ShiftTracker
//
//  Created by James Poole on 30/06/23.
//

import SwiftUI
import UIKit

// wrapped UIKit exit button

struct CloseButton: UIViewRepresentable {
    private let action: () -> Void
    
    init(action: @escaping () -> Void) { self.action = action }
    
    func makeUIView(context: Context) -> UIButton {
        UIButton(type: .close, primaryAction: UIAction { _ in action() })
    }
    
    func updateUIView(_ uiView: UIButton, context: Context) {}
}
