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
    
   

    var body: some View {
            ScrollView {
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
                        .background(Color("SquaresColor"))
                        .cornerRadius(12)
                        .onTapGesture {
                            withAnimation {
                                iconManager.changeIcon(to: appIcon)
                            }
                        }
                    }
                }.padding(.horizontal)
                   
            }.scrollContentBackground(.hidden)
            .navigationTitle("App Icon")
        
    }
}

struct ChangeAppIconView_Previews: PreviewProvider {
    static var previews: some View {
        AppIconView().environmentObject(AppIconManager())
        
    }
}


