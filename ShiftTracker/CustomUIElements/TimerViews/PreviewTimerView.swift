//
//  PreviewTimerView.swift
//  ShiftTracker
//
//  Created by Louis Kolodzinski on 9/07/23.
//


import SwiftUI

struct PreviewTimerView: View {
    
    @EnvironmentObject var themeColors: ThemeDataManager
    
    @Environment(\.colorScheme) var colorScheme
    
    var textColor: Color {
            return colorScheme == .dark ? .white : .black
        }
    
    
    var body: some View {
      
            VStack(alignment: .center, spacing: 5) {
                Text("$555.05")
                    .font(.system(size: 60).monospacedDigit())
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .allowsTightening(true)
                
                    .foregroundColor(textColor)
                    
                 .padding(.top)
                
                HStack{
                    SelectableButton(id: 1, selectedButton: $themeColors.selectedButton, content: {
                        HStack(spacing: 10) {
                            Image(systemName: "chart.line.downtrend.xyaxis")
                                .font(.system(size: 15).monospacedDigit())
                                .fontWeight(.light)
                            Text("$444")
                                .font(.system(size: 20).monospacedDigit())
                                .bold()
                                .lineLimit(1)
                        }.foregroundColor(themeColors.taxColor)
                    }, action: {
                        themeColors.selectedColorToChange = .taxColorPicker
                    })
                    SelectableButton(id: 2, selectedButton: $themeColors.selectedButton, content: {
                        HStack(spacing: 10) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 15).monospacedDigit())
                                .fontWeight(.light)
                            Text("$10")
                                .font(.system(size: 20).monospacedDigit())
                                .bold()
                                .lineLimit(1)
                        }.foregroundColor(themeColors.tipsColor)
                    }, action: {
                         themeColors.selectedColorToChange = .tipsColorPicker
                    })
                    
                    
                    
                }
                
                Divider().frame(maxWidth: 200)
                
                SelectableButton(id: 3, selectedButton: $themeColors.selectedButton, content: {
                    HStack {
                        Text("09:41:00")
                            .font(.system(size: 30, weight: .bold).monospacedDigit())
                        
                    } .foregroundColor(themeColors.timerColor)
                }, action: {themeColors.selectedColorToChange = .timerColorPicker})
                
                SelectableButton(id: 4, selectedButton: $themeColors.selectedButton, content: {
                    HStack(spacing: 0) {
                        Text("00:10:09")
                            .font(.system(size: 12, weight: .bold).monospacedDigit())
                        
                    }.foregroundColor(themeColors.breaksColor)
                }, action: {themeColors.selectedColorToChange = .breaksColorPicker})
                
            }.frame(maxWidth: .infinity)
        
        .padding(.bottom)
        .glassModifier()
        .frame(maxWidth: 358)
    }
}
