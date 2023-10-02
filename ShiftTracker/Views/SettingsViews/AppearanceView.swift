//
//  AppearanceView.swift
//  ShiftTracker
//
//  Created by James Poole on 5/09/23.
//

import SwiftUI

struct AppearanceView: View {
    @AppStorage("colorScheme") var userColorScheme: String = "system"
    
    @EnvironmentObject var themeManager: ThemeDataManager
    
    var colorSchemes: [(String, String)] = [
        ("Light", "light"),
        ("Dark", "dark"),
        ("System", "system")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10){
                ForEach(colorSchemes, id: \.1) { (name, value) in
                    
                    HStack(spacing: 16){
                        
                        Text(name)
                            .font(.title2)
                            .bold()
                        Spacer()
                        if userColorScheme == value {
                            CustomCheckbox().environmentObject(themeManager)
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white, lineWidth: 3)
                                .frame(maxWidth: 25, maxHeight: 25)
                        }
                        
                        
                        
                    }.padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
                        .glassModifier()
                        .onTapGesture {
                            withAnimation {
                                userColorScheme = value
                            }
                        }
                    
                }
                
                Toggle(isOn: $themeManager.pureDark) {
                
                SettingsRow(icon: "moon.haze.fill", title: "Pure Dark Mode")
                
                
            }.toggleStyle(CustomToggleStyle())
                   
                .padding()
                .glassModifier()
                
                
            }.padding(.horizontal)
        }//.scrollContentBackground(.hidden)
            
            .navigationTitle("Appearance")
        
    }
}
