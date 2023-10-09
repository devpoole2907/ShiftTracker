//
//  NavBarIconView.swift
//  ShiftTracker
//
//  Created by James Poole on 8/10/23.
//

import SwiftUI

struct NavBarIconView: View {
    
    @Binding var appeared: Bool
    @Binding var isLarge: Bool
    @ObservedObject var job: Job
    
    init(appeared: Binding<Bool>, isLarge: Binding<Bool> = .constant(true), job: Job) {
        _appeared = appeared
        _isLarge = isLarge
        self.job = job
    }
    
    var body: some View {
        
        let dimension: CGFloat = isLarge ? 25 : 15
        
        let jobColor = Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue))
        
        Image(systemName: job.icon ?? "briefcase.fill")
        
            .resizable()
            .scaledToFit()
            .frame(width: dimension, height: dimension)
            .shadow(color: .white, radius: 1.0)
            .customAnimatedSymbol(value: $appeared)
        
            .padding(isLarge ? 10 : 7)
            .foregroundStyle(Color.white)
            .background{
                Circle().foregroundStyle(jobColor.gradient).shadow(color: jobColor, radius: 2)
            }
            .frame(width: dimension * 1.76, height: dimension * 1.76)
        
    }
}

