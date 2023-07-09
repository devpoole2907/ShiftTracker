//
//  ContentView.swift
//  testEnvironment
//
//  Created by Louis Kolodzinski on 4/07/23.
//

import SwiftUI
import CoreData
import Charts

struct ThemeView: View {
    
    @EnvironmentObject var themeManager: ThemeDataManager
    
    @AppStorage("isFirstAppear") var isFirstAppear = true
    
    
    @State private var sampleToggle = true
    
    @State private var showThemeInfoSheet = false
    //needs to return to false when done
    
    
    var body: some View {
        
        
        
            
            ZStack{
                ScrollView{
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    VStack{
                        PreviewTimerView()
                            .environmentObject(themeManager)
                        
                        // CustomThemePicker()
                        
                        HStack{
                            TempGraph()
                                .padding()
                                .frame(width: 200, height: 300)
                                .background(Color("SquaresColor"))
                                .cornerRadius(12)
                            
                            VStack{
                                Button(action: {
                                    themeManager.selectedColorToChange = .customTextColorPicker
                                }){
                                    Text("eat my booty hole")
                                        .padding()
                                        .frame(maxWidth: 150, maxHeight: 140)
                                        .background(Color("SquaresColor"))
                                        .cornerRadius(12)
                                        .foregroundStyle(themeManager.customTextColor)
                                        .font(.title)
                                        .bold()
                                }
                                ZStack{
                                    
                                    
                                    Toggle("", isOn: $sampleToggle)
                                    
                                    
                                    
                                    
                                    
                                    
                                        .labelsHidden()
                                    
                                        .padding()
                                        .toggleStyle(CustomToggleStyle())
                                        .tint(themeManager.customUIColor)
                                        .foregroundStyle(themeManager.customTextColor)
                                        .bold()
                                        .font(.title2)
                                        .frame(maxWidth: 150, maxHeight: 150)
                                    
                                        .background(Color("SquaresColor"))
                                        .cornerRadius(12)
                                    
                                    
                                    SelectableButton(id: 6, selectedButton: $themeManager.selectedButton, content: {
                                        // Spacer()
                                        Rectangle()
                                            .cornerRadius(12)
                                            .frame(maxWidth: 105, maxHeight: 120)
                                            .background(.clear)
                                            .opacity(0)
                                        
                                        
                                        
                                    }, action: {themeManager.selectedColorToChange = .customUIColorPicker})
                                    
                                    
                                }
                                
                                
                                
                                
                                
                            }
                        }
                        Spacer()
                        
                    }
                    
                    
                    
                }
                
                VStack{
                    Spacer()
                    CustomThemePicker()
                        .padding(.bottom, 10)
                }
                
            
        }
        
        .navigationBarTitle("Theme")
            
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing){
                Button(action: {
                    themeManager.resetColorsToDefaults()
                    
                }){
                    Text("Reset")
                        .bold()
                        
                }
                    .tint(Color.black)
                
                Button(action: {
                    showThemeInfoSheet.toggle()
                    
                }){
                    Image(systemName: "info.circle")
                        .bold()
                        
                }
                    .tint(Color.black)
                
            }
        }
            
        .onAppear {
            if isFirstAppear {
                
                themeManager.resetColorsToDefaults()
                
                showThemeInfoSheet.toggle()
                
                isFirstAppear = false
                
            }
        }
            
        .sheet(isPresented: $showThemeInfoSheet){
        
            ThemesGuideView()

            
            .presentationCornerRadius(25)
        }
    
        
        
        
        
    }
    
    struct ThemeView_Previews: PreviewProvider {
        static var previews: some View {
            ThemeView()
                .environmentObject(ThemeDataManager())
        }
    }
}
