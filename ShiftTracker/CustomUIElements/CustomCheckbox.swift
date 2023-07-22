//
//  CustomCheckbox.swift
//  ShiftTracker
//
//  Created by Louis Kolodzinski on 21/07/23.
//

import SwiftUI

struct CustomCheckbox: View {
    
    @EnvironmentObject var themeManager: ThemeDataManager
    
    var body: some View {
        ZStack{
            
            Rectangle()
                .frame(maxWidth: 25, maxHeight: 25)
                .foregroundStyle(themeManager.customUIColor)
                .cornerRadius(6)
                
            
            Image(systemName: "checkmark")
                .bold()
                .foregroundStyle(.white)
            
            
        }
    }
}

struct CustomCheckbox_Previews: PreviewProvider {
    static var previews: some View {
        CustomCheckbox()
            .environmentObject(ThemeDataManager())
    }
}
