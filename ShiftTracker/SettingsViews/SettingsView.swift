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
    @Environment(\.scenePhase) var scenePhase
    
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var themeManager: ThemeDataManager
    @EnvironmentObject var locationManager: LocationDataManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    @StateObject var notificationManager = NotificationManager()
    @StateObject var iconManager = AppIconManager()
    
    @Binding var navPath: [Int]
    
    //let settingsScreens: [any View] = [ThemeView(, showingProView: <#Binding<Bool>#>), LocationView(), NotificationView(), AppearanceView()]
    
    var body: some View {
        
        let proButtonColor: Color = colorScheme == .dark ? Color.orange : Color.cyan
        
        let backgroundColor: Color = colorScheme == .dark ? .white : .black
        let textColor: Color = colorScheme == .dark ? .black : .white
        
        
        
        
        
        NavigationStack(path: $navPath){
            ScrollView{
                VStack{
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
                                            
                                            Text("Upgrade Now")
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
                    
                    VStack{
                        
                        
                        NavigationLink(value: 0){
                            
                            SettingsRow(icon: "paintpalette", title: "Theme", secondaryInfo: themeManager.isCustom ? "Custom" : "Default")
                            
                            
                        }.padding()
                            .background(Color("SquaresColor"))
                            .cornerRadius(12)
                        
                        
                        
                        NavigationLink(value: 1){
                            
                            if locationManager.authorizationStatus != .authorizedAlways {
                                SettingsRow(icon: "location", title: "Location", secondaryImage: "exclamationmark.triangle.fill")
                            } else {
                                SettingsRow(icon: "location", title: "Location", secondaryInfo: "Always")
                                
                            }
                            
                        }.padding()
                            .background(Color("SquaresColor"))
                            .cornerRadius(12)
                        
                        
                        NavigationLink(value: 2){
                            
                            if notificationManager.authorizationStatus != .authorized  {
                                SettingsRow(icon: "bell", title: "Notifications", secondaryImage: "exclamationmark.triangle.fill")
                                
                            } else {
                                SettingsRow(icon: "bell", title: "Notifications", secondaryInfo: "Enabled")
                                
                            }
                            
                            
                            
                            
                        }.padding()
                            .background(Color("SquaresColor"))
                            .cornerRadius(12)
                            .onAppear(perform: notificationManager.checkNotificationStatus)
                            .onChange(of: scenePhase) { newPhase in
                                if newPhase == .active {
                                    notificationManager.checkNotificationStatus()
                                }
                            }
                        
                        
                        NavigationLink(value: 3){
                            
                            SettingsRow(icon: "circle.lefthalf.filled", title: "Appearance", secondaryInfo: "\(userColorScheme)".capitalized)
                            
                        }.padding()
                            .background(Color("SquaresColor"))
                            .cornerRadius(12)
                        
                        
                        
                        
                        NavigationLink(value: 5){
                            
                            SettingsRow(icon: "photo.on.rectangle.angled", title: "App Icon", secondaryInfo: iconManager.selectedAppIcon != .primary ? "Custom" : "Default")
                            
                        }.padding()
                            .background(Color("SquaresColor"))
                            .cornerRadius(12)
                        
                        
                        
                    }
                    
                    VStack{
                    
                    Toggle(isOn: $authEnabled){
                        
                        SettingsRow(icon: "faceid", title: "App Lock")
                        
                    }.toggleStyle(CustomToggleStyle())
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
                        .padding()
                        .background(Color("SquaresColor"))
                        .cornerRadius(12)
                    Toggle(isOn: $iCloudSyncOn) {
                        
                        SettingsRow(icon: "icloud", title: "iCloud Sync")
                        
                    }.toggleStyle(CustomToggleStyle())
                        .onChange(of: iCloudSyncOn) { value in
                            PersistenceController.shared.updateCloudKitSyncStatus()
                        }
                        .padding()
                        .background(Color("SquaresColor"))
                        .cornerRadius(12)
                    Toggle(isOn: $tipsEnabled) {
                        SettingsRow(icon: "dollarsign.circle", title: "Tips")
                    }.toggleStyle(CustomToggleStyle())
                        .padding()
                        .background(Color("SquaresColor"))
                        .cornerRadius(12)
                    
                    Toggle(isOn: $taxEnabled) {
                        
                        SettingsRow(icon: "percent", title: "Estimated Tax")
                        
                        
                    }.toggleStyle(CustomToggleStyle())
                        .onChange(of: taxEnabled){ value in
                            sharedUserDefaults.set(0.0, forKey: shiftKeys.taxPercentageKey)
                        }
                        .padding()
                        .background(Color("SquaresColor"))
                        .cornerRadius(12)
                    
                    NavigationLink(value: 4){
                        
                        
                        SettingsRow(icon: "hammer", title: "Support the Developer", secondaryImage: "chevron.right")
                        
                    }.padding()
                        .background(Color("SquaresColor"))
                        .cornerRadius(12)
                    
                }
                    
                }.padding(.horizontal)
                
                
                
                
                VStack(spacing: 10){
                    if purchaseManager.hasUnlockedPro {
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
                }.padding(.vertical)
                    .padding(.horizontal)
                VStack(alignment: .leading){
                    Button(action: {
                        
                        CustomConfirmationAlert(action: {wipeCoreData(in: viewContext)}, cancelAction: nil, title: "Are you sure you want to delete all your data?").showAndStack()
                    } ){
                        Text("Delete Data")
                            .bold()
                        
                    }.buttonStyle(.bordered)
                        .tint(.red)
                }.padding(.horizontal)
                Spacer()
                
                
            }//.scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
       
            
                .onAppear {
                    
                    navigationState.gestureEnabled = true
                    
                }
            
                .navigationDestination(for: Int.self) { i in
                    
                    if i == 0 {
                        
                        ThemeView(showingProView: $showingProView)
                        
                    }
                    else if i == 1 {
                        
                        LocationView()
                        
                    } else if i == 2 {
                        
                        NotificationView()
                        
                    } else if i == 3 {
                        
                        AppearanceView()
                        
                    } else if i == 4 {
                        
                        TipView()
                        
                        
                    } else {
                        
                        AppIconView().environmentObject(iconManager)
                        
                    }
                    
                    
                    
                }
            
                .navigationTitle("Settings")
            
                .fullScreenCover(isPresented: $showingProView) {
                    
                        ProView()
                    
                    
                }
                .toolbar{
                    ToolbarItem(placement: .navigationBarLeading){
                        Button{
                            withAnimation{
                                navigationState.showMenu.toggle()
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .bold()
                            
                        }
                    }
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
        SettingsView(navPath: .constant([])).environmentObject(ThemeDataManager())
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
                        
                        //setUserSubscribed(isProVersion)
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

struct SettingsRow: View {
    var icon: String
    var title: String
    var secondaryInfo: String?
    var secondaryImage: String?
    
    init(icon: String, title: String, secondaryInfo: String? = nil, secondaryImage: String? = nil) {
        self.icon = icon
        self.title = title
        self.secondaryInfo = secondaryInfo
        self.secondaryImage = secondaryImage
    }
    
    var body: some View{
        HStack {
            
            Image(systemName: icon)
                .frame(width: 25, alignment: .center)
            Text(title)
                .font(.title2)
                .bold()
            
            Spacer()
            
            if let secondInfo = secondaryInfo {
                HStack(alignment: .center, spacing: 5){
                    Text(secondInfo)
                        .foregroundStyle(.gray)
                        .bold()
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                        .bold()
                        .font(.caption)
                        .padding(.top, 1)
                }.fontDesign(.rounded)
                
            } else if let secondImage = secondaryImage {
                
                Image(systemName: secondImage)
                    .foregroundStyle(.gray)
                    .bold()
                
            }
            
            
            
        }
    }
}


struct NotificationView: View{
    
    @StateObject var notificationManager = NotificationManager()
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View{
        ScrollView{
            
            SettingsCheckView(image: notificationManager.authorizationStatus == .authorized ? "checkmark.circle" : "exclamationmark.triangle", headline: notificationManager.authorizationStatus == .authorized ? "You're all set." : "Notification are not set to 'Allow'.", subheadline: notificationManager.authorizationStatus == .authorized ? "Notifications are enabled." : "Please go to the Settings app and navigate to \"Notifications\", \"ShiftTracker\", and enable \"Allow Notifications\" permissions for ShiftTracker.", checkmarkColor: notificationManager.authorizationStatus == .authorized ? .green : .orange)
          
                .onAppear(perform: notificationManager.checkNotificationStatus)
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active {
                        notificationManager.checkNotificationStatus()
                    }
                }

        }
        
        //.scrollContentBackground(.hidden)
        
        .navigationTitle("Notifications")
        
    }
    
}

struct SettingsCheckView: View {
    
    
    var image: String
    var headline: String
    var subheadline: String
    var checkmarkColor: Color
    
    var body: some View {
        
        
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
            Text(subheadline)
                .fontDesign(.rounded)
                .font(.callout)
                .padding()
        }.padding()
            .frame(minWidth: UIScreen.main.bounds.width - 80)
            .background(Color("SquaresColor"))
            .cornerRadius(12)
            .padding()
           
           
    }
    
    
}

struct LocationView: View{
    
    @EnvironmentObject private var locationManager: LocationDataManager
    
    var body: some View{
        ScrollView{
            
            
            
            SettingsCheckView(image: locationManager.authorizationStatus != .authorizedAlways ? "exclamationmark.triangle" : "checkmark.circle", headline: locationManager.authorizationStatus != .authorizedAlways ? "Location settings are not set to always." : "You're all set.", subheadline: locationManager.authorizationStatus != .authorizedAlways ? "Please go to the Settings app and navigate to \"Privacy & Security\", \"Location Services\", and enable \"Always\" permissions for ShiftTracker." : "Location settings are set to always.", checkmarkColor: locationManager.authorizationStatus != .authorizedAlways ? .orange : .green)
            
                
            
            
            
        }//.scrollContentBackground(.hidden)
        
            .navigationTitle("Location")
        
    }
}

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
                        .background(Color("SquaresColor"))
                        .cornerRadius(12)
                        .onTapGesture {
                            withAnimation {
                                userColorScheme = value
                            }
                        }
                    
                }
            }.padding(.horizontal)
        }//.scrollContentBackground(.hidden)
            
            .navigationTitle("Appearance")
        
    }
}


