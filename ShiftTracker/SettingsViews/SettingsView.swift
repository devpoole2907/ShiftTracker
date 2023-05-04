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
    
    @AppStorage("isProVersion", store: UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")) var isProVersion = false
    @State private var showingProView = false
    @AppStorage("iCloudEnabled") private var iCloudSyncOn: Bool = false
    @AppStorage("AuthEnabled") private var authEnabled: Bool = false
    @AppStorage("TaxEnabled") private var taxEnabled: Bool = true
    @AppStorage("TipsEnabled") private var tipsEnabled: Bool = true
    @State private var isAuthenticated = false
    
    @State private var sharedUserDefaults = UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")!
    private let shiftKeys = ShiftKeys()
    
    @AppStorage("colorScheme") var userColorScheme: String = "system"
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        
        let proButtonColor: Color = colorScheme == .dark ? Color.orange.opacity(0.5) : Color.orange.opacity(0.8)
        
        
      
        
        
        
        

                
                List{
                    if !isProVersion{
                        Section{
                        Button(action: {
                            showingProView = true // set the state variable to true to show the sheet
                        }) {
                            Group{
                                ZStack {
                                    Color.black
                                        .cornerRadius(20)
                                        .frame(height: 80)
                                    VStack(spacing: 2) {
                                        HStack{
                                            Text("ShiftTracker")
                                                .font(.title2)
                                                .bold()
                                                .foregroundColor(Color.white)
                                            Text("PRO")
                                                .font(.title)
                                                .bold()
                                                .foregroundColor(Color.orange)
                                        }
                                        //.padding(.top, 3)
                                   
                                        Text("Upgrade Now")
                                            .font(.subheadline)
                                            .bold()
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(maxWidth: UIScreen.main.bounds.width - 20)
                                .shadow(radius: 2, x: 0, y: 1)//maxHeight: 100)
                            }//.padding(.bottom, 75)
                        }
                        }.listRowBackground(Color.clear)
                }
                    Section{
                        if isProVersion{
                            NavigationLink(destination: ProSettingsView(isProVersion: $isProVersion)){
                                HStack {
                                    Image(systemName: "briefcase")
                                    Spacer().frame(width: 10)
                                    Text("ShiftTracker Pro")
                                }
                            }
                        }
                        NavigationLink(destination: LocationView()){
                             HStack {
                                 Image(systemName: "bell.fill")
                                 Spacer().frame(width: 10)
                                 Text("Location")
                             }
                         }
                       NavigationLink(destination: NotificationView()){
                            HStack {
                                Image(systemName: "bell.fill")
                                Spacer().frame(width: 10)
                                Text("Notifications")
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
                                    .padding(.leading, -2)
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
                        if isProVersion{
                            Text("Thank you for purchasing ShiftTracker Pro!")
                                .foregroundColor(.gray.opacity(0.3))
                                .font(.caption)
                        }
                        Text("Made by James Poole")
                            .foregroundColor(.gray.opacity(0.3))
                            .font(.caption)
                        Text("Icons & sounds by Louie Kolodzinksi")
                            .foregroundColor(.gray.opacity(0.3))
                            .font(.caption)
                    }.listRowBackground(Color.clear)
                    
                }.scrollContentBackground(.hidden)
                .padding(.horizontal)
                .listStyle(.plain)
            
            
                
                
                
                
            
            //.padding(.vertical, 16)
           // .navigationBarTitle("Settings", displayMode: .inline)
               
                .toolbarRole(.editor)
            
            .sheet(isPresented: $showingProView) { // present the sheet with ProView
                if #available(iOS 16.4, *) {
                    ProView()
                        .presentationDetents([.large])
                        .presentationBackground(.thinMaterial)
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(50)
                }
                else {
                    ProView()
                }
            }
        
        
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
    
    @Binding var isProVersion: Bool
    
    var body: some View{
        NavigationView{
            VStack{
                Form {
                    Button(action: {
                        // Update isProVersion boolean value
                        isProVersion.toggle()
                        // Save updated boolean value to shared user defaults
                        UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")?.setValue(isProVersion, forKey: "isProVersion")
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
        NavigationView{
            VStack{
                List{
                    
                    Button("Request notification access"){
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                            if success {
                                print("All set!")
                            } else if let error = error {
                                print(error.localizedDescription)
                            }
                        }
                        
                    }.listRowBackground(Color.clear)
                    .foregroundColor(.orange)
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
                    }.foregroundColor(.orange)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                
                .scrollContentBackground(.hidden)
            }
            
        }.navigationTitle("Notifications")
        
    }
    
}

struct LocationView: View{
    
    @State private var locationManager = CLLocationManager()
    
    @State private var autoClockIn = false
    @State private var autoClockOut = false
    
    init(){
        locationManager.requestAlwaysAuthorization()
        
        
    }
    
    var body: some View{
        NavigationView{
            VStack{
                List{
                    
                    Button("Request location access"){
                        locationManager.requestAlwaysAuthorization()
                    }
                    Section(header: Text("Location settings must be set to 'Always'")){
                        Toggle(isOn: $autoClockIn) {
                            Text("Automatically clock in")
                        }
                        Toggle(isOn: $autoClockOut) {
                            Text("Automatically clock out")
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }.scrollContentBackground(.hidden)
            }
        }.navigationTitle("Location")
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
                    }
                    
                }.listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }.scrollContentBackground(.hidden)
        .navigationBarTitle("Appearance")
        .toolbarRole(.editor)
    }
}


