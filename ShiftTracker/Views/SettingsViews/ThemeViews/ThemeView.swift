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
    
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    
    var theme: Theme?
    
    let errorAction: () -> Void
    
    init(theme: Theme? = nil, errorAction: @escaping () -> Void){
        self.theme = theme
        self.errorAction = errorAction
    }
    
    
    var body: some View {
        
        NavigationStack {
            ZStack(alignment: .bottomTrailing){
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
                
                VStack(alignment: .trailing){
                    
                    
                    
                    
                    Button(action: {
                        
                        // save the theme
                        
                        // ensure there is no duplicate names (use .lowercased() to check)
                        // also dont allow naming it Default, and ignore case again
                        
                        let fetchRequest: NSFetchRequest<Theme> = Theme.fetchRequest()
                        var existingThemes: [Theme] = []
                        do {
                            existingThemes = try viewContext.fetch(fetchRequest)
                        } catch {
                            print("Error fetching themes: \(error)")
                        }
                        
                        let lowercasedExistingNames = existingThemes.compactMap { $0.name?.lowercased() }
                        
                        if (lowercasedExistingNames.contains(themeManager.editingThemeName.lowercased()) && themeManager.editingThemeName.lowercased() != themeManager.originalEditingThemeName?.lowercased()) || themeManager.editingThemeName.lowercased() == "default" {
                            dismiss()
                            OkButtonPopup(title: "Invalid Name", action: errorAction).showAndStack()
                        } else {
                            themeManager.updateOrCreateTheme(theme, in: viewContext)
                            dismiss()
                        }
                        
                        
                        
                        
                        
                    }){
                        Image(systemName: "folder.badge.plus")//.customAnimatedSymbol(value: )
                            .bold()
                    }
                    
                    
                    
                    
                    
                    .padding()
                    .glassModifier(cornerRadius: 20)
                    .padding(.trailing)
                    CustomThemePicker()
                        .padding(.bottom, 10)
                }
                
                
            } .onAppear {
                guard let theme = theme else { return }
                
                themeManager.loadEditingColors(from: theme)
                
            }
            
            .navigationTitle($themeManager.editingThemeName)
            
            .navigationBarTitleDisplayMode(.inline)
            
            
            .toolbar {
                /*  ToolbarItemGroup(placement: .navigationBarTrailing){
                 Button(action: {
                 themeManager.resetColorsToDefaults()
                 
                 }){
                 Text("Reset")
                 .bold()
                 
                 }
                 
                 
                 }*/
                
                ToolbarItem(placement: .topBarTrailing) {
                    CloseButton()
                }
                
            }
            
            
            
            
            
            
        }
    }
    
    struct ThemeView_Previews: PreviewProvider {
        static var previews: some View {
            ThemeView(errorAction: {})
                .environmentObject(ThemeDataManager())
        }
    }
}
