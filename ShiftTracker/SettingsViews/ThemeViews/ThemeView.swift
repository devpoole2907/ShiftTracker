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
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showThemeInfoSheet = false

    
    
    var body: some View {
            ZStack{
                ScrollView{
                    VStack{
                        PreviewTimerView()
                            .environmentObject(themeManager)
                        
                        // CustomThemePicker()
                        
                        HStack(alignment: .top){
                           /* TempGraph()
                               // .padding()
                               // .frame(width: 200, height: 300)
                                .background(Color("SquaresColor"))
                                .cornerRadius(12) */
                            
                           
                                
                                    
                                     

                                    SelectableButton(id: 6, selectedButton: $themeManager.selectedButton, content: {
                                        Toggle("Toggles", isOn: .constant(true))
                                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                                            .bold()
                                        
                                   
                                            .toggleStyle(CustomToggleStyle())
                                            .tint(themeManager.customUIColor)
                                            .padding(.horizontal)
                                            
                                    }, action: {themeManager.selectedColorToChange = .customUIColorPicker})
                                    
                                    
                                
         
                            
                        }
                        .padding(.horizontal)
                       
                        
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
                   
                
                Button(action: {
                    showThemeInfoSheet.toggle()
                    
                }){
                    Image(systemName: "info.circle")
                        .bold()
                        
                }
                   
                
            }
        }
            
        .onAppear {
            if isFirstAppear {
                
              
                
                showThemeInfoSheet.toggle()
                
                isFirstAppear = false
                
            }
        }
            
        .sheet(isPresented: $showThemeInfoSheet){
        
            ThemesGuideView()
                .presentationDetents([.fraction(0.8)])
                .presentationBackground(Color("allSheetBackground"))
            .presentationCornerRadius(35)
        }
    
        
        
        
        
    }
    
    struct ThemeView_Previews: PreviewProvider {
        static var previews: some View {
            ThemeView()
                .environmentObject(ThemeDataManager())
        }
    }
}
