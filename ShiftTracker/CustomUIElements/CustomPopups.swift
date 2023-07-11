//
//  CustomPopups.swift
//  ShiftTracker
//
//  Created by James Poole on 5/07/23.
//

import SwiftUI
import PopupView

struct OkButtonPopup: CentrePopup {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let action: (() -> Void)?
    
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup.horizontalPadding(28)
            .backgroundColour(Color.clear)
    }
    func createContent() -> some View {
        VStack(spacing: 5) {
            
            createTitle()
                .padding(.vertical)
            //Spacer(minLength: 32)
            //  Spacer.height(32)
            createConfirmButton()
            // .padding()
        }
        .padding(.top, 12)
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        
        .background(Color("SquaresColor"))
        .cornerRadius(20)
        .shadow(radius: 10)
        .triggersHapticFeedbackWhenAppear()
    }
    
    func createTitle() -> some View {
        Text(title)
            .bold()
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    
    func createConfirmButton() -> some View {
        Button(action: {
            action?() ?? dismiss()
            dismiss()
        }) {
            Text("OK")
                .bold()
                .foregroundColor(colorScheme == .dark ? .black : .white)
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(colorScheme == .dark ? .white : .black)
                .cornerRadius(8)
        }
    }
    
}

struct CustomConfirmationAlert: CentrePopup {
    
    @Environment(\.colorScheme) var colorScheme
    
    let action: () -> Void
    let cancelAction: (() -> Void)?
    let title: String
    
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup.horizontalPadding(10)
            .backgroundColour(Color.clear)
           // .cornerRadius(20)
        
    }
    func createContent() -> some View {
        
        VStack(spacing: 5) {
            
            Text(title)
                .bold()
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical)
            HStack(spacing: 4) {
                createCancelButton()
                createConfirmButton()
            }
        }

        .padding(.top, 12)
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        .background(Color("SquaresColor"))
        .cornerRadius(20)
        .shadow(radius: 10)
        .triggersHapticFeedbackWhenAppear()
    }
    
    func createCancelButton() -> some View {
        Button(action: {
            cancelAction?() ?? dismiss()
            dismiss()
        }) {
            Text("Cancel")
            
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(.primary.opacity(0.1))
                .cornerRadius(8)
        }
    }
    func createConfirmButton() -> some View {
        Button(action: {
            action()
            dismiss()
        }) {
            Text("Confirm")
                .bold()
                .foregroundColor(colorScheme == .dark ? .black : .white)
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(colorScheme == .dark ? .white : .black)
                .cornerRadius(8)
        }
    }
    
}
