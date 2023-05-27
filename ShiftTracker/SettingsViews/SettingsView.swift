//
//  SettingsView.swift
//  ShiftTracker
//
//  Created by James Poole on 19/03/23.
//

import SwiftUI
import UserNotifications
import CoreLocation
import LocalAuthentication

struct SettingsView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("isProVersion", store: UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")) var isProVersion = false
    @State private var showingProView = false
    @AppStorage("iCloudEnabled") private var iCloudSyncOn: Bool = false
    @AppStorage("AuthEnabled") private var authEnabled: Bool = false
    @AppStorage("TaxEnabled") private var taxEnabled: Bool = true
    @AppStorage("TipsEnabled") private var tipsEnabled: Bool = true
    @State private var isAuthenticated = false
    
    @State private var sharedUserDefaults = UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")!
    private let shiftKeys = ShiftKeys()
    
    @State private var deleteData = false
    
    @AppStorage("colorScheme") var userColorScheme: String = "system"
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        
        let proButtonColor: Color = colorScheme == .dark ? Color.orange : Color.cyan
        
        let backgroundColor: Color = colorScheme == .dark ? .white : .black
        let textColor: Color = colorScheme == .dark ? .black : .white
        
        
        
        
        
       // NavigationView{
        List{
            if !isProVersion{
                Section{
                    Button(action: {
                        showingProView = true
                    }) {
                        Group{
                            ZStack {
                                Color.primary.opacity(0.04)
                                    .cornerRadius(20)
                                    .frame(height: 80)
                                VStack(spacing: 2) {
                                    HStack{
                                        Text("ShiftTracker")
                                            .font(.title2)
                                            .bold()
                                            //.foregroundColor(textColor)
                                        Text("PRO")
                                            .font(.title)
                                            .bold()
                                            .foregroundColor(proButtonColor)
                                    }
                                    //.padding(.top, 3)
                                    
                                    Text("Upgrade Now")
                                        .font(.subheadline)
                                        .bold()
                                      //  .foregroundColor(textColor)
                                }
                            }
                            .frame(maxWidth: UIScreen.main.bounds.width - 20)
                        }//.padding(.bottom, 75)
                    }
                }.listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            Section{
             /*   if isSubscriptionActive(){
                    NavigationLink(destination: ProSettingsView()){
                        HStack {
                            Image(systemName: "briefcase")
                            Spacer().frame(width: 10)
                            Text("ShiftTracker Pro")
                        }
                    }
                }*/
                NavigationLink(destination: LocationView()){
                    HStack {
                        Image(systemName: "location")
                        Spacer().frame(width: 10)
                        Text("Location")
                            .font(.title2)
                            .bold()
                            .padding()
                    }
                }
                NavigationLink(destination: NotificationView()){
                    HStack {
                        Image(systemName: "bell")
                            .padding(.leading, 2)
                        Spacer().frame(width: 10)
                        Text("Notifications")
                            .font(.title2)
                            .bold()
                            .padding()
                    }
                }
                NavigationLink(destination: AppearanceView(userColorScheme: $userColorScheme)) {
                    HStack {
                        Image("AppearanceIconSymbol")
                            .padding(.leading, -1)
                        Spacer().frame(width: 10)
                        Text("Appearance")
                            .font(.title2)
                            .bold()
                            .padding()
                        Spacer()
                        Text("\(userColorScheme)".capitalized)
                            .foregroundColor(.gray)
                            .bold()
                            .padding()
                    }
                }
                /*NavigationLink(destination: TagsView().navigationTitle("Tags")){
                 HStack {
                 Image(systemName: "tag")
                 Spacer().frame(width: 10)
                 Text("Tags")
                 }
                 } */
                Toggle(isOn: $authEnabled){
                    HStack {
                        Image(systemName: "faceid")
                            .padding(.leading, 2)
                        Spacer().frame(width: 10)
                        Text("App Lock")
                            .font(.title2)
                            .bold()
                            .padding()
                    }
                }.toggleStyle(OrangeToggleStyle())
                    .onChange(of: authEnabled) { newValue in
                        if newValue {
                            authenticateUser { success in
                                if success {
                                    isAuthenticated = true
                                } else {
                                    authEnabled = false
                                }
                            }
                        } else {
                            isAuthenticated = false
                        }
                    }
                Toggle(isOn: $iCloudSyncOn) {
                    HStack {
                        Image("iCloudIconSymbol")
                           // .padding(.leading)
                        Spacer().frame(width: 10)
                        Text("iCloud Sync")
                            .font(.title2)
                            .bold()
                            .padding()
                    }
                }.toggleStyle(OrangeToggleStyle())
                    .onChange(of: iCloudSyncOn) { value in
                        PersistenceController.shared.updateCloudKitSyncStatus()
                    }
                Toggle(isOn: $tipsEnabled) {
                    HStack {
                        Image("TipsIconSymbol")
                            .padding(.leading, -2)
                        Spacer().frame(width: 10)
                        Text("Tips")
                            .font(.title2)
                            .bold()
                            .padding()
                    }
                }.toggleStyle(OrangeToggleStyle())
                //.padding()
                
                Toggle(isOn: $taxEnabled) {
                    HStack {
                        Image("TaxIconSymbol")
                            .padding(.leading, -1)
                        Spacer().frame(width: 10)
                        Text("Estimated Tax")
                            .font(.title2)
                            .bold()
                            .padding()
                    }
                }.toggleStyle(OrangeToggleStyle())
                    .onChange(of: taxEnabled){ value in
                        sharedUserDefaults.set(0.0, forKey: shiftKeys.taxPercentageKey)
                    }
            }
            .listRowSeparator(.hidden)
            //.listRowBackground(Color.clear)
            
            
            Section{
                NavigationLink(destination: TipView()){
                    HStack {
                        Image(systemName: "hammer.circle.fill")
                        Spacer().frame(width: 10)
                        Text("Support the Developer")
                            .font(.title2)
                            .bold()
                            .padding()
                    }
                }
                
            }
            .listRowSeparator(.hidden)
            //.listRowBackground(Color.clear)
            
            
            Section{
                if isSubscriptionActive(){
                    Text("Thank you for purchasing ShiftTracker Pro!")
                        .foregroundColor(.gray.opacity(0.3))
                        .font(.caption)
                }
                Text("Made by James Poole")
                    .foregroundColor(.gray.opacity(0.3))
                    .font(.caption)
                Text("Icons by Louie Kolodzinksi")
                    .foregroundColor(.gray.opacity(0.3))
                    .font(.caption)
            }.listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            Section{
                VStack(alignment: .leading){
                    Button(action: {
                        
                        CustomConfirmationAlert(action: {wipeCoreData(in: viewContext)}, title: "Are you sure you want to delete all your data?").present()
                    } ){
                        Text("Delete Data")
                            .bold()
                        
                    }.buttonStyle(.bordered)
                        .tint(.red)
                }
            }.listRowSeparator(.hidden)
            
        }.scrollContentBackground(.hidden)
            .padding(.horizontal)
            .listStyle(.plain)
            .navigationTitle("Settings")
            .toolbarRole(.editor)
            .scrollIndicators(.hidden)
        
            .fullScreenCover(isPresented: $showingProView) {
                NavigationStack{
                    ProView()
                        .toolbar{
                            ToolbarItem(placement: .navigationBarLeading){
                                Button(action: {
                                    self.showingProView = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .bold()
                                }
                            }
                        }
                }
                
            }
        
    //}
    }
    
    private func authenticateUser(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Unlock ShiftTracker"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
    
    
    
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}


struct ProSettingsView: View{
    
    @State private var isProVersion: Bool = true
    
    var body: some View{
        NavigationView{
            VStack{
                Form {
                    Button(action: {
                        isProVersion.toggle()

                        setUserSubscribed(isProVersion)
                    }) {
                        Text(isProVersion ? "Unsubscribe" : "Upgrade now")
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: UIScreen.main.bounds.width - 20) //maxHeight: 100)
                    .padding(.horizontal, 10)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(20)
                }
            }
        }.navigationTitle("ShiftTracker Pro")
        
    }
}


struct NotificationView: View{
    var body: some View{
                ScrollView{
                    
                    Button("Request notification access"){
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                            if success {
                                print("All set!")
                            } else if let error = error {
                                print(error.localizedDescription)
                            }
                        }
                        
                    }
                    .bold()
                    .padding()
                        .buttonStyle(.bordered)
                        .padding()
                    Button("Test notification"){
                        let content = UNMutableNotificationContent()
                        content.title = "ShiftTracker"
                        content.subtitle = "Ready to take a break? You've been working for __ hours and made $___ so far!"
                        content.sound = UNNotificationSound.default
                        
                        // show this notification five seconds from now
                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
                        
                        // choose a random identifier
                        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                        
                        // add our notification request
                        UNUserNotificationCenter.current().add(request)
                    }.bold()
                        .padding()
                            .buttonStyle(.bordered)
                            .padding()
                }
                
                .scrollContentBackground(.hidden)
            
            .navigationTitle("Notifications")
            .toolbarRole(.editor)
    }
    
}

struct LocationView: View{
    
    @StateObject private var locationManager = LocationDataManager()
    
    var body: some View{
                ScrollView{
                    
                    if locationManager.authorizationStatus != .authorizedAlways {
                        VStack(alignment: .leading, spacing: 10){
                            Text("Location settings are not set to always.")
                                .bold()
                                .font(.title3)
                                .padding()
                            Text("Please go to the Settings app and navigate to \"Privacy & Security\", \"Location Services\", and enable \"Always\" permissions for ShiftTracker.")
                                .font(.callout)
                                .padding()
                        }.padding()
                            .background(Color.primary.opacity(0.04))
                            .cornerRadius(12)
                            .padding()
                        
                        Button("Request location access"){
                            locationManager.requestAlways()
                        }.bold()
                        .padding()
                            .buttonStyle(.bordered)
                            .padding()
                        
                        
                    } else {
                        VStack(alignment: .leading, spacing: 10){
                            Text("Location settings are set to always.")
                                .bold()
                                .font(.title3)
                        }.padding()
                            .background(Color.primary.opacity(0.04))
                            .cornerRadius(12)
                            .padding()
                    }
                    
                  
                }.scrollContentBackground(.hidden)
            
            .navigationTitle("Location")
        .toolbarRole(.editor)
        
    }
}

struct AppearanceView: View {
    @Binding var userColorScheme: String
    
    var colorSchemes: [(String, String)] = [
        ("Light", "light"),
        ("Dark", "dark"),
        ("System", "system")
    ]
    
    var body: some View {
        List {
            ForEach(colorSchemes, id: \.1) { (name, value) in
                Button(action: {
                    userColorScheme = value
                }) {
                    HStack {
                        Text(name)
                        Spacer()
                        if userColorScheme == value {
                            Image(systemName: "checkmark")
                                .foregroundColor(.orange)
                        }
                    }.font(.title2)
                        .bold()
                        .padding()
                    
                }.listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }.scrollContentBackground(.hidden)
    
            .navigationTitle("Appearance")
        .toolbarRole(.editor)
    }
}


