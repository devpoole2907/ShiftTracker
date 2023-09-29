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
    
    init(title: String, action: ( () -> Void)? = nil) {
        self.title = title
        self.action = action
    }
    
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
        
        .glassModifier(cornerRadius: 30)
        .triggersHapticFeedbackWhenAppear()
        
   //     .frame(maxWidth: getRect().width - 50)
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
              
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .glassModifier(cornerRadius: 20)
        }
    }
    
}

struct CustomConfirmationAlert: CentrePopup {
    
    @Environment(\.colorScheme) var colorScheme
    
    let action: () -> Void
    let cancelAction: (() -> Void)?
    let title: String
    
    init(action: @escaping () -> Void, cancelAction: (() -> Void)? = nil, title: String) {
        self.action = action
        self.cancelAction = cancelAction
        self.title = title
    }
    
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
        .glassModifier(cornerRadius: 30)
       // .shadow(radius: 10)
        .triggersHapticFeedbackWhenAppear()
        
     //   .frame(maxWidth: getRect().width - 50)
        
        
    }
    
    func createCancelButton() -> some View {
        Button(action: {
            cancelAction?() ?? dismiss()
            dismiss()
        }) {
            Text("Cancel")
            
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .glassModifier(cornerRadius: 20)
        }
    }
    func createConfirmButton() -> some View {
        Button(action: {
            action()
            dismiss()
        }) {
            Text("Confirm")
                .bold()
           
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .glassModifier(cornerRadius: 20, darker: true)
           
        }
    }
    
}

struct CustomTripleActionPopup: CentrePopup {
    
    @Environment(\.colorScheme) var colorScheme
    
    let action: () -> Void
    let secondAction: () -> Void
    let cancelAction: (() -> Void)? = nil
    let title: String
    
    let firstActionText: String
    let secondActionText: String
    let cancelActionText: String = "Cancel"
    
    
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
            VStack(spacing: 4) {
                createFirstButton()
                createCentreButton()
                createCancelButton()
            }
        }

        .padding(.top, 12)
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        .glassModifier(cornerRadius: 30)
       // .shadow(radius: 10)
        .triggersHapticFeedbackWhenAppear()

        
    }
    
    func createCancelButton() -> some View {
        Button(action: {
            cancelAction?() ?? dismiss()
            dismiss()
        }) {
            Text(cancelActionText)
            
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .glassModifier(cornerRadius: 20)
        }
    }
    
    func createCentreButton() -> some View {
        Button(action: {
            secondAction()
            dismiss()
        }) {
            Text(secondActionText)
            
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .glassModifier(cornerRadius: 20)
        }
    }
    
    func createFirstButton() -> some View {
        Button(action: {
            action()
            dismiss()
        }) {
            Text(firstActionText)
                .bold()
           
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .glassModifier(cornerRadius: 20, darker: true)
           
        }
    }
    
}

struct CustomTopPopup: TopPopup {
    func createContent() -> some View {
        HStack(spacing: 0){
            Text("Cheese")
        } .padding(.vertical, 20)
            .padding(.leading, 24)
            .padding(.trailing, 16)
    }
    
    func configurePopup(popup: TopPopupConfig) -> TopPopupConfig {
        popup.horizontalPadding(20)
            .topPadding(42)
            .cornerRadius(16)
    }
    
}


