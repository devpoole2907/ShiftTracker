//
//  ProView.swift
//  ShiftTracker
//
//  Created by James Poole on 26/03/23.
//

import SwiftUI

struct ProView: View {
    
    @AppStorage("isProVersion", store: UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")) var isProVersion: Bool = false

    @Environment(\.dismiss) var dismiss
    
    
    @Environment(\.colorScheme) var colorScheme
    
    
    var body: some View {
        
        let proButtonColor: Color = colorScheme == .dark ? Color.orange : Color.cyan
        let textColor: Color = colorScheme == .dark ? Color.white.opacity(0.9) : Color.white
        let backgroundColor: Color = colorScheme == .dark ? .black : Color.white
        let upgradeButtonTextColor: Color = colorScheme == .dark ? .white : Color.black
        
        
       // NavigationView {

            VStack{
                HStack{
                    Text("ShiftTracker")
                        .font(.title)
                        .bold()
                    Text("PRO")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundColor(proButtonColor)
                }
               
                VStack(alignment: .leading){
                    HStack {
                        Image(systemName: "clipboard")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundColor(proButtonColor)
                        Spacer().frame(width: 15)
                        Text("Multiple Jobs")
                            .font(.title2)
                            .bold()
                    }.listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 5)
                    HStack {
                        Image(systemName: "play.rectangle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundColor(proButtonColor)
                        Spacer().frame(width: 15)
                        Text("Live Activities")
                            .font(.title2)
                            .bold()
                            //.foregroundColor(textColor)
                    }.listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 5)
                    HStack {
                        Image(systemName: "location")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundColor(proButtonColor)
                        Spacer().frame(width: 15)
                        Text("Location based clock in & clock out")
                            .font(.title2)
                            .bold()
                            //.foregroundColor(textColor)
                    }.listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 5)
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundColor(proButtonColor)
                        Spacer().frame(width: 15)
                        Text("Data Exporting")
                            .font(.title2)
                            .bold()
                    }.listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 5)
                  /*  HStack {
                        Image(systemName: "timer")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundColor(proButtonColor)
                        Spacer().frame(width: 15)
                        Text("Automatic Breaks")
                            .font(.title2)
                            .bold()
                    }.listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 5)
                    HStack {
                        Image(systemName: "paperclip")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundColor(proButtonColor)
                        Spacer().frame(width: 15)
                        Text("Invoice Generation")
                            .font(.title2)
                            .bold()
                    }.listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 5)*/
                }.padding(.horizontal, 30)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack{
                        Text("UNLOCK")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(upgradeButtonTextColor)
                        Text("PRO")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .foregroundColor(proButtonColor)
                        Text("Features")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(upgradeButtonTextColor)
                    }
                    
                    .foregroundColor(textColor)
                }
                .padding()
                .cornerRadius(20)
                .frame(maxWidth: .infinity)
                
                HStack(spacing: 10){
                    Button(action: {
                        isProVersion = true
                        setUserSubscribed(true)
                        dismiss()
                    }) {
                        VStack{
                            Text("MONTHLY")
                                .font(.title2)
                                .fontWeight(.heavy)
                                .foregroundColor(upgradeButtonTextColor)
                                .lineLimit(1)
                                .allowsTightening(true)
                                
                            Text("$2.49")
                                .foregroundColor(proButtonColor)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .cornerRadius(20)
                        .padding()
                        .background(Color.primary.opacity(0.04),in:
                                        RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    Button(action: {
                        isProVersion = true
                        setUserSubscribed(true)
                        print("setting user subscribed to true")
                        dismiss()
                    }) {
                        VStack{
                            Text("YEARLY")
                                .font(.title2)
                                .fontWeight(.heavy)
                                .foregroundColor(upgradeButtonTextColor)
                                .lineLimit(1)
                                .allowsTightening(true)
                                
                            Text("$21.49")
                                .foregroundColor(proButtonColor)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
          
                        .cornerRadius(20)
                        .padding()
                        .background(Color.primary.opacity(0.04),in:
                                        RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }.padding(.horizontal, 30)
                
                Button(action: {
                    
                }) {
                    Text("Restore")
                        .bold()
                }.padding()
                
               // Spacer(minLength: 50)
            }
            
    
        //}.background(backgroundColor)
    }
}


struct ProView_Previews: PreviewProvider {
    static var previews: some View {
        ProView()
    }
}
