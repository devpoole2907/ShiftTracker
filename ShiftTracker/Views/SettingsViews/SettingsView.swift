//
//  SettingsView.swift
//  ShiftTracker
//
//  Created by James Poole on 19/03/23.
//

import SwiftUI

struct SettingsView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.scenePhase) var scenePhase
    
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var themeManager: ThemeDataManager
    @EnvironmentObject var locationManager: LocationDataManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var viewModel: SettingsViewModel
    
    @StateObject var notificationManager = NotificationManager()
    @StateObject var iconManager = AppIconManager()
    
    @Binding var navPath: [Int]

    private let authManager = AuthManager()
    
    var body: some View {
        
        let proButtonColor: Color = colorScheme == .dark ? Color.orange : Color.cyan
        
        let backgroundColor: Color = colorScheme == .dark ? .white : .black
        let textColor: Color = colorScheme == .dark ? .black : .white

            ScrollView{
                VStack{
                    if !purchaseManager.hasUnlockedPro{
                        Group{
                            Button(action: {
                                viewModel.showingProView = true
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
                                    .frame(maxWidth: getRect().width - 20)
                                }
                            }
                        }
                    }
                    
                    VStack{
                        
                        
                        NavigationLink(value: 0){
                            
                            SettingsRow(icon: "paintpalette", title: "Theme", secondaryInfo: themeManager.currentThemeName)
                            
                            
                        }.padding()
                            .glassModifier()
                        
                        
                        
                        NavigationLink(value: 1){
                            
                            if locationManager.authorizationStatus != .authorizedAlways {
                                SettingsRow(icon: "location", title: "Location", secondaryImage: "exclamationmark.triangle.fill")
                            } else {
                                SettingsRow(icon: "location", title: "Location", secondaryInfo: "Always")
                                
                            }
                            
                        }.padding()
                            .glassModifier()
                        
                        
                        NavigationLink(value: 2){
                            
                            if notificationManager.authorizationStatus != .authorized  {
                                SettingsRow(icon: "bell", title: "Notifications", secondaryImage: "exclamationmark.triangle.fill")
                                
                            } else {
                                SettingsRow(icon: "bell", title: "Notifications", secondaryInfo: "Enabled")
                                
                            }
                            
                            
                            
                            
                        }.padding()
                            .glassModifier()
                            .onAppear(perform: notificationManager.checkNotificationStatus)
                            .onChange(of: scenePhase) { newPhase in
                                if newPhase == .active {
                                    notificationManager.checkNotificationStatus()
                                }
                            }
                        
                        
                        NavigationLink(value: 3){
                            
                            SettingsRow(icon: "circle.lefthalf.filled", title: "Appearance", secondaryInfo: "\(viewModel.userColorScheme)".capitalized)
                            
                        }.padding()
                            .glassModifier()
                        
                        
                        
                        
                        NavigationLink(value: 5){
                            
                            SettingsRow(icon: "photo.on.rectangle.angled", title: "App Icon", secondaryInfo: iconManager.selectedAppIcon != .primary ? "Custom" : "Default")
                            
                        }.padding()
                            .glassModifier()
                        
                        
                        
                    }
                    
                    VStack{
                    
                        Toggle(isOn: $viewModel.authEnabled){
                        
                        SettingsRow(icon: "faceid", title: "App Lock")
                        
                    }.toggleStyle(CustomToggleStyle())
                            .onChange(of: viewModel.authEnabled) { newValue in
                            if newValue {
                                Task {
                                    let success = await authManager.authenticateUser()
                                    if success {
                                        viewModel.isAuthenticated = true
                                    } else {
                                        viewModel.authEnabled = false
                                    }
                                }

                            } else {
                                viewModel.isAuthenticated = false
                            }
                        }
                        .padding()
                        .glassModifier()
                        Toggle(isOn: $viewModel.iCloudSyncOn) {
                        
                        SettingsRow(icon: "icloud", title: "iCloud Sync")
                        
                    }.toggleStyle(CustomToggleStyle())
                            .onChange(of: viewModel.iCloudSyncOn) { value in
                            PersistenceController.shared.updateCloudKitSyncStatus()
                        }
                        .padding()
                        .glassModifier()
                        Toggle(isOn: $viewModel.tipsEnabled) {
                        SettingsRow(icon: "dollarsign.circle", title: "Tips")
                    }.toggleStyle(CustomToggleStyle())
                        .padding()
                        .glassModifier()
                    
                        Toggle(isOn: $viewModel.taxEnabled) {
                        
                        SettingsRow(icon: "percent", title: "Estimated Tax")
                        
                        
                    }.toggleStyle(CustomToggleStyle())
                            .onChange(of: viewModel.taxEnabled){ value in
                                if !value {
                                    viewModel.updateTax()
                                }
                        }
                        .padding()
                        .glassModifier()
                    
                    NavigationLink(value: 4){
                        
                        
                        SettingsRow(icon: "hammer", title: "Support the Developer", secondaryImage: "chevron.right")
                        
                    }.padding()
                            .glassModifier()
                    
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
                
                
            }.scrollContentBackground(.hidden)
          //  .background(Color(.systemGroupedBackground))
       
        
            
                .onAppear {
                    
                    navigationState.gestureEnabled = true
                    
                }
            
                .navigationDestination(for: Int.self) { i in
                    
                    if i == 0 {
                        
                     //   ThemeView(showingProView: $viewModel.showingProView)
                        
                        ThemesList(showingProView: $viewModel.showingProView)   .background(themeManager.settingsDynamicBackground.ignoresSafeArea())
                        
                        
                    }
                    else if i == 1 {
                        
                        SettingsCheckView(image: locationManager.authorizationStatus != .authorizedAlways ? "exclamationmark.triangle" : "checkmark.circle", headline: locationManager.authorizationStatus != .authorizedAlways ? "Location settings are not set to always." : "You're all set.", subheadline: locationManager.authorizationStatus != .authorizedAlways ? "Please go to the Settings app and navigate to \"Privacy & Security\", \"Location Services\", and enable \"Always\" permissions for ShiftTracker." : "Location settings are set to always.", checkmarkColor: locationManager.authorizationStatus != .authorizedAlways ? .orange : .green)
                    
                        .navigationTitle("Location")   .background(themeManager.settingsDynamicBackground.ignoresSafeArea())
                        
                    } else if i == 2 {
                        
                        SettingsCheckView(image: notificationManager.authorizationStatus == .authorized ? "checkmark.circle" : "exclamationmark.triangle", headline: notificationManager.authorizationStatus == .authorized ? "You're all set." : "Notifications are not set to 'Allow'.", subheadline: notificationManager.authorizationStatus == .authorized ? "Notifications are enabled." : "Please go to the Settings app and navigate to \"Notifications\", \"ShiftTracker\", and enable \"Allow Notifications\" permissions for ShiftTracker.", checkmarkColor: notificationManager.authorizationStatus == .authorized ? .green : .orange)  .background(themeManager.settingsDynamicBackground.ignoresSafeArea()) .navigationTitle("Notifications")
                        
                    } else if i == 3 {
                        
                        AppearanceView()  .background(themeManager.settingsDynamicBackground.ignoresSafeArea())
                        
                    } else if i == 4 {
                        
                        TipView()  .background(themeManager.settingsDynamicBackground.ignoresSafeArea())
                        
                        
                    } else {
                        
                        AppIconView().environmentObject(iconManager)  .background(themeManager.settingsDynamicBackground.ignoresSafeArea())
                        
                    }
                    
                    
                    
                }
            
                .navigationTitle("Settings")
            
                .fullScreenCover(isPresented: $viewModel.showingProView) {
                    
                        ProView()
                    // this one must be thin material due to the button behind it causing contrasting issues
                        .customSheetBackground(ultraThin: false)
                    
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










