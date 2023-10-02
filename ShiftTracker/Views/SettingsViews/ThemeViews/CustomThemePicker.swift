//
//  CustomThemePicker.swift
//  testEnvironment
//
//  Created by Louis Kolodzinski on 5/07/23.
//

import SwiftUI

struct CustomThemePicker: View {
    
    @EnvironmentObject var themeManager: ThemeDataManager

    var body: some View {
        
        VStack{
            
            switch themeManager.selectedColorToChange {
            case .customUIColorPicker:
                ThemeColorPicker (selectedColor: $themeManager.editingCustomUIColor)
                
            case .customTextColorPicker:
                ThemeColorPicker (selectedColor: $themeManager.editingCustomTextColor)
                
            case .earningsColorPicker:
                ThemeColorPicker (selectedColor: $themeManager.editingEarningsColor)
                
            case .taxColorPicker:
                ThemeColorPicker (selectedColor: $themeManager.editingTaxColor)
                
            case .timerColorPicker:
                ThemeColorPicker (selectedColor: $themeManager.editingTimerColor)
                
            case .breaksColorPicker:
                ThemeColorPicker (selectedColor: $themeManager.editingBreaksColor)
                
            case .tipsColorPicker:
                ThemeColorPicker (selectedColor: $themeManager.editingTipsColor)
            }
    
        }
    }
}



