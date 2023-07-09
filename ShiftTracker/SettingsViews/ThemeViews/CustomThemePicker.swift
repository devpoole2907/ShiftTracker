//
//  CustomThemePicker.swift
//  testEnvironment
//
//  Created by Louis Kolodzinski on 5/07/23.
//

import SwiftUI

struct CustomThemePicker: View {
    
    @EnvironmentObject var themeColors: ThemeDataManager

    var body: some View {
        
        VStack{
            
            switch themeColors.selectedColorToChange {
            case .customUIColorPicker:
                ThemeColorPicker (selectedColor: $themeColors.customUIColor)
                
            case .customTextColorPicker:
                ThemeColorPicker (selectedColor: $themeColors.customTextColor)
                
            case .earningsColorPicker:
                ThemeColorPicker (selectedColor: $themeColors.earningsColor)
                
            case .taxColorPicker:
                ThemeColorPicker (selectedColor: $themeColors.taxColor)
                
            case .timerColorPicker:
                ThemeColorPicker (selectedColor: $themeColors.timerColor)
                
            case .breaksColorPicker:
                ThemeColorPicker (selectedColor: $themeColors.breaksColor)
                
            case .tipsColorPicker:
                ThemeColorPicker (selectedColor: $themeColors.tipsColor)
            }
    
        }
    }
}



