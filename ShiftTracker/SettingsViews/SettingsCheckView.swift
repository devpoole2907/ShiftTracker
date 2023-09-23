//
//  SettingsCheckView.swift
//  ShiftTracker
//
//  Created by James Poole on 5/09/23.
//

import SwiftUI

struct SettingsCheckView: View {
    
    @EnvironmentObject var themeManager: ThemeDataManager
    
    var image: String
    var headline: String
    var subheadline: String
    var checkmarkColor: Color
    
    var body: some View {
        
        List{
            VStack(alignment: .center, spacing: 10){
                Image(systemName: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 50)
                    .bold().foregroundStyle(checkmarkColor)
                    .padding(.top)
                
                Text(headline)
                    .bold()
                    .font(.title3)
                    .padding(.bottom)
                    
                    .multilineTextAlignment(.center)
                Text(subheadline)
                    .multilineTextAlignment(.center)
                    .fontDesign(.rounded)
                    .font(.callout)
                    .padding()
            }.padding()
                .frame(minWidth: getRect().width - 80)
                .glassModifier(cornerRadius: 20)
                .padding(.horizontal, 40)
                .listRowBackground(Color.clear)
            
        }.scrollContentBackground(.hidden)
        
            .background(themeManager.settingsGradient)
    }
    
    
}
