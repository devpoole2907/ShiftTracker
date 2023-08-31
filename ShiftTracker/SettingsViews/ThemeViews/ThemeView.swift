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
    
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    @AppStorage("isFirstAppear") var isFirstAppear = true
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @State private var showThemeInfoSheet = false
    @Binding var showingProView: Bool
    
    
    
    var body: some View {
            ZStack{
                ScrollView{
                    VStack{
                        PreviewTimerView()
                            .environmentObject(themeManager)
                        
                        // CustomThemePicker()
                        
                        HStack(alignment: .top){
                        
                                     

                                    SelectableButton(id: 6, selectedButton: $themeManager.selectedButton, content: {
                                        Toggle("Toggles", isOn: .constant(true))
                                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                                            .bold()
                                        
                                   
                                            .toggleStyle(CustomToggleStyle())
                                            .tint(themeManager.customUIColor)
                                            .padding(.horizontal)
                                            
                                    }, action: {themeManager.selectedColorToChange = .customUIColorPicker})
                                    .glassModifier(cornerRadius: 20)
                                    
                                    
                                
         
                            
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
            
            if !purchaseManager.hasUnlockedPro {
          
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                    dismiss()
                    showingProView.toggle()
                }
                
            }
            
            else if isFirstAppear {
                
              
                
                showThemeInfoSheet.toggle()
                
                isFirstAppear = false
                
            }
        }
            
        .sheet(isPresented: $showThemeInfoSheet){
        
            ThemesGuideView()
                .presentationDetents([.fraction(0.8)])
                .presentationBackground(.ultraThinMaterial)
            .presentationCornerRadius(35)
        }
    
  
        
        
        
    }
    
    struct ThemeView_Previews: PreviewProvider {
        static var previews: some View {
            ThemeView(showingProView: .constant(false))
                .environmentObject(ThemeDataManager())
        }
    }
}
