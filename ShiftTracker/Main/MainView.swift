//
//  MainView.swift
//  ShiftTracker
//
//  Created by James Poole on 19/03/23.
//

import SwiftUI
import Haptics
import UIKit
import LocalAuthentication


struct MainView: View {
    
    @Environment(\.managedObjectContext) private var context
    
    @EnvironmentObject var eventStore: EventStore
    
    @AppStorage("AuthEnabled") private var authEnabled: Bool = false
        @State private var showingLockedView = false

    
    private func checkIfLocked() {
            if authEnabled {
                showingLockedView = true
            }
        }
        
        
        var body: some View {

            TabView{
                ContentView()
                    .environment(\.managedObjectContext, context)
                    .tabItem {
                        VStack(alignment: .center){
                            Image("HomeIconSymbol")
                            Text("Home")
                        }
                    }
               ShiftsView()
                   .tabItem {
                       VStack(alignment: .center){
                           Image("ShiftsIconSymbol")
                           Text("Shifts")
                       }
                   }
                PersonalView()
                     .environmentObject(eventStore)
                    .tabItem {
                        VStack(alignment: .center){
                            Image(systemName: "person.text.rectangle.fill")
                            Text("Personal")
                        }
                    }
               SummaryView()
                   .tabItem {
                       VStack(alignment: .center){
                           Image("SummaryIconSymbol")
                           Text("Summary")
                       }
                   }
                
                SettingsView()
                    .tabItem {
                        VStack(alignment: .center){
                            Image("SettingsIconSymbol")
                            Text("Settings")
                        }
                    }
                
            }
            .sheet(isPresented: $showingLockedView) {
                if #available(iOS 16.4, *) {
                    LockedView(isAuthenticated: $showingLockedView)
                        .presentationDetents([ .large])
                        .presentationBackground(.thinMaterial)
                        .presentationCornerRadius(12)
                        .interactiveDismissDisabled()
                }
                else {
                    LockedView(isAuthenticated: $showingLockedView).interactiveDismissDisabled()
                }
   
                    }
            .onAppear(perform: {
                        checkIfLocked()
                    })
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                        checkIfLocked()
                    }
            }
 }
    
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView() .environmentObject(EventStore(preview: true))
        
    }
}

struct LockedView: View {
    @Binding var isAuthenticated: Bool

    private func authenticateUser() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Unlock ShiftTracker"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        isAuthenticated = false
                    } else {
                        // Handle the authentication error here if needed
                    }
                }
            }
        } else {
            // Handle the case where biometric authentication is not available
        }
    }

    var body: some View {
        VStack {
            Text("ShiftTracker is locked")
                .font(.title)
                .padding(.bottom, 20)

            Button(action: {
                authenticateUser()
            }) {
                Text("Unlock")
                    .font(.title)
                    .bold()
                    
            }
            .padding()
            .foregroundColor(.white)
                .bold()
                .background(Color.accentColor)
                .cornerRadius(20)
        }.onAppear{
            authenticateUser()
        }
    }
}

