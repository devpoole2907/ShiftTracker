//
//  PageControlView.swift
//  ShiftTracker
//
//  Created by James Poole on 26/08/23.
//

import SwiftUI
import UIKit

// from github, allowing more customisation for the built in page dots vs swiftui

struct PageControlView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    @Binding var currentPage: Int
     var numberOfPages: Int

    func makeUIView(context: Context) -> UIPageControl {
        let uiView = UIPageControl()
        uiView.backgroundStyle = .prominent
        uiView.currentPage = currentPage
        uiView.numberOfPages = numberOfPages
        uiView.addTarget(context.coordinator, action: #selector(Coordinator.pageChanged), for: .valueChanged)
        return uiView
    }

    func updateUIView(_ uiView: UIPageControl, context: Context) {
      
            uiView.currentPage = currentPage
            uiView.numberOfPages = numberOfPages
        
    }
    
    
    class Coordinator: NSObject {
            var pageControl: PageControlView

            init(_ control: PageControlView) {
                self.pageControl = control
            }

            @objc func pageChanged(sender: UIPageControl) {
                withAnimation{
                    pageControl.currentPage = sender.currentPage
                }
            }
        }
    
}
