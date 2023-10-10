//
//  ActivityIndicator.swift
//  ShiftTracker
//
//  Created by James Poole on 10/10/23.
//

import SwiftUI

import SwiftUI
import UIKit

struct ActivityIndicator: UIViewRepresentable {
    var isAnimating: Bool
    
    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(style: .large)
        return indicator
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

