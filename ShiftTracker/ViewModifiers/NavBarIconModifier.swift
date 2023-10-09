//
//  NavBarIconModifier.swift
//  ShiftTracker
//
//  Created by James Poole on 9/10/23.
//



import SwiftUI

struct NavBarIconModifier: ViewModifier { //do not use, has issues in nav bar "zooming"
    
    @Binding var appeared: Bool
    @Binding var isLarge: Bool
    @ObservedObject var job: Job
    
    let condition: () -> Bool
    
    func body(content: Content) -> some View {
        content.overlay(alignment: .topTrailing){
            
            NavBarIconView(appeared: $appeared, isLarge: $isLarge, job: job)
                .padding(.trailing, 20)
                .offset(x: 0, y: -55)
            
            
        }
    }
    
    
}

extension View {
    func navBarIcon(appeared: Binding<Bool>, isLarge: Binding<Bool>, job: Job, condition: @escaping () -> Bool) -> some View {
        self.modifier(NavBarIconModifier(appeared: appeared, isLarge: isLarge, job: job) {
            true
        })
    }
}
