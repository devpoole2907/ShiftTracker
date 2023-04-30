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
        
        let proButtonColor: Color = colorScheme == .dark ? Color.orange.opacity(1.0) : Color.orange.opacity(1.0)
        let textColor: Color = colorScheme == .dark ? Color.white.opacity(0.9) : Color.white
        let backgroundColor: Color = colorScheme == .dark ? .black : Color.white
        let upgradeButtonTextColor: Color = colorScheme == .dark ? .white : Color.black
        
        
        NavigationView {

            VStack{
                Spacer(minLength: 50)
                HStack{
                    Text("ShiftTracker")
                        .font(.title)
                        .bold()
                    Text("PRO")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundColor(.orange)
                }
               
                List {
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
                        Image(systemName: "location.fill")
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
                        Text("Data exporting")
                            .font(.title2)
                            .bold()
                    }.listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 5)
                    HStack {
                        Image(systemName: "timer")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundColor(proButtonColor)
                        Spacer().frame(width: 15)
                        Text("Automatic breaks")
                            .font(.title2)
                            .bold()
                    }.listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 5)
                    HStack {
                        Image(systemName: "chart.bar.xaxis")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundColor(proButtonColor)
                        Spacer().frame(width: 15)
                        Text("Enhanced reports")
                            .font(.title2)
                            .bold()
                    }.listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 5)
                }.scrollContentBackground(.hidden)
                
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
                   
                    .foregroundColor(textColor)
                    
                    .foregroundColor(textColor)
                   
                    .foregroundColor(textColor)
                }
                .padding()
                //.background(Color.gray.opacity(0.5))
                .cornerRadius(20)
                .frame(maxWidth: .infinity)
                
                //Spacer()
                HStack(spacing: 1){
                    Button(action: {
                        // Update isProVersion boolean value
                        isProVersion.toggle()
                        // Save updated boolean value to shared user defaults
                        UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")?.setValue(isProVersion, forKey: "isProVersion")
                        dismiss()
                    }) {
                        VStack{
                            Text("MONTHLY")
                                .font(.title)
                                .fontWeight(.heavy)
                                .foregroundColor(upgradeButtonTextColor)
                                
                            Text("$2.49")
                                .foregroundColor(.orange)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        //.background(proButtonColor)
                        .cornerRadius(20)
                        .padding()
                    }
                    Button(action: {
                        // Update isProVersion boolean value
                        isProVersion.toggle()
                        // Save updated boolean value to shared user defaults
                        UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")?.setValue(isProVersion, forKey: "isProVersion")
                        setUserSubscribed(true)
                        print("setting user subscribed to true")
                        dismiss()
                    }) {
                        VStack{
                            Text("YEARLY")
                                .font(.title)
                                .fontWeight(.heavy)
                                .foregroundColor(upgradeButtonTextColor)
                                
                            Text("$21.49")
                                .foregroundColor(.orange)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        //.background(proButtonColor)
                        .cornerRadius(20)
                        .padding()
                    }
                }.padding(.horizontal, 30)
                Spacer(minLength: 50)
            }
            
           // .padding(.horizontal, 16)
        }.background(backgroundColor)
    }
}


struct ProView_Previews: PreviewProvider {
    static var previews: some View {
        ProView()
    }
}
