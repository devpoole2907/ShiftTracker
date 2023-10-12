//
//  LockedView.swift
//  ShiftTracker
//
//  Created by James Poole on 20/05/23.
//

import SwiftUI
import LocalAuthentication

struct LockedView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var themeManager: ThemeDataManager
    
    private let authManager = AuthManager()

    var body: some View {
        
        let textColor: Color = colorScheme == .dark ? .white : .black
        
        VStack {
            Spacer()
            
            VStack {
                
                Image(systemName: "lock.fill")
                    .font(.largeTitle)
                
                Text("ShiftTracker is locked.")
                    .font(.title2)
                    .bold()
                    .padding()
                
                Text("Please unlock to continue.")
                    .font(.callout)
                    .roundedFontDesign()
       
                
            }.padding(.vertical, 30)
                .padding(.horizontal
                ).glassModifier(cornerRadius: 20)
            
            
            
            Spacer()
            
            ActionButtonView(title: "Unlock", backgroundColor: .black, textColor: textColor, icon: "faceid", buttonWidth: getRect().width - 100, action: authUser)
            
                .padding(.vertical)
            
        
        }
        
        
        .onAppear{
         //   authUser()
        }
    }
    
    func authUser() {
        Task {
            let success = await authManager.authenticateUser()
            if success {
                dismiss()
            }
        }
    }
    
}

#Preview {
    LockedView()
}

