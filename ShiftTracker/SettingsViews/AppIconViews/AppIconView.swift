//
//  ChangeAppIconView.swift
//  ShiftTracker
//
//  Created by Louis Kolodzinski on 20/07/23.
//

import SwiftUI
import UIKit

struct AppIconView: View {
    @EnvironmentObject var iconManager: AppIconManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    @Environment(\.colorScheme) var colorScheme
   
    @State private var showingProView = false

    var body: some View {
        
        let proButtonColor: Color = colorScheme == .dark ? Color.orange : Color.cyan
        
        let backgroundColor: Color = colorScheme == .dark ? .white : .black
        let textColor: Color = colorScheme == .dark ? .black : .white
        
            ScrollView {
                
                VStack {
                    if !purchaseManager.hasUnlockedPro{
                        Group{
                            Button(action: {
                                showingProView = true
                            }) {
                                Group{
                                    ZStack {
                                        backgroundColor
                                            .cornerRadius(20)
                                            .frame(height: 80)
                                        VStack(spacing: 2) {
                                            HStack{
                                                Text("ShiftTracker")
                                                    .font(.title2)
                                                    .bold()
                                                    .foregroundColor(textColor)
                                                Text("PRO")
                                                    .font(.title)
                                                    .bold()
                                                    .foregroundColor(proButtonColor)
                                            }
                                            //.padding(.top, 3)
                                            
                                            Text("Featuring Custom App Icons!")
                                                .font(.subheadline)
                                                .bold()
                                                .foregroundColor(textColor)
                                        }
                                    }
                                    .frame(maxWidth: UIScreen.main.bounds.width - 20)
                                }
                            }
                        }
                    }
                }.padding(.horizontal)
                
                
                VStack(spacing: 10) {
                    ForEach(AppIconManager.AppIcon.allCases) { appIcon in
                        HStack(spacing: 16) {
                            Image(appIcon.preview)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .cornerRadius(12)

                            Text(appIcon.description)
                                .bold()
                                //.font(.body17Medium)
                                
                            Spacer()
                            
                            if appIcon == iconManager.selectedAppIcon {
                                
                                CustomCheckbox()
                                    
                                
                            } else {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white, lineWidth: 3)
                                   
                                    .frame(maxWidth: 25, maxHeight: 25)
                                   
                            }
                            
                            
                        }
                        .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
                        .glassModifier()
                        .onTapGesture {
                            withAnimation {
                                
                                if !purchaseManager.hasUnlockedPro {
                                    showingProView.toggle()
                                } else {
                                    
                                    iconManager.changeIcon(to: appIcon)
                                }
                            }
                        }
                    }
                }.padding(.horizontal)
                
                
                    .fullScreenCover(isPresented: $showingProView) {
                        
                            ProView()
                            .presentationBackground(.ultraThinMaterial)
                        
                    }
                
                   
            }//.scrollContentBackground(.hidden)
            .navigationTitle("App Icon")
        
    }
}

struct ChangeAppIconView_Previews: PreviewProvider {
    static var previews: some View {
        AppIconView().environmentObject(AppIconManager())
        
    }
}



