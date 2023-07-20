//
//  ChangeAppIconView.swift
//  ShiftTracker
//
//  Created by Louis Kolodzinski on 20/07/23.
//

import SwiftUI
import UIKit

struct ChangeAppIconView: View {
    @StateObject var viewModel = ChangeAppIconViewModel()

    var body: some View {
            ScrollView {
                VStack(spacing: 11) {
                    ForEach(ChangeAppIconViewModel.AppIcon.allCases) { appIcon in
                        HStack(spacing: 16) {
                            Image(uiImage: appIcon.preview)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .cornerRadius(12)
                            Text(appIcon.description)
                                //.font(.body17Medium)
                            Spacer()
                            
                            if appIcon == viewModel.selectedAppIcon {
                                
                                Image(systemName: "checkmark")
                                
                            }
                            
                            
                        }
                        .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
                        .background(Color.gray)
                        .cornerRadius(20)
                        .onTapGesture {
                            withAnimation {
                                viewModel.updateAppIcon(to: appIcon)
                            }
                        }
                    }
                }.padding(.horizontal)
                    .padding(.vertical, 40)
            }.scrollContentBackground(.hidden)
            .navigationTitle("App Icon")
        
    }
}

struct ChangeAppIconView_Previews: PreviewProvider {
    static var previews: some View {
        ChangeAppIconView()
    }
}



