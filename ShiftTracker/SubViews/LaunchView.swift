//
//  LaunchView.swift
//  ShiftTracker
//
//  Created by James Poole on 19/03/23.
//

import SwiftUI
import UserNotifications

struct LaunchView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State private var isButtonTapped = false
    
    @State private var notificationButtonVisible = false
    @State private var locationButtonVisible = false
    @State private var mainElementsVisible = false
    @State private var welcomeVisible = false
    @State private var alwaysTextVisible = false
    
    @ObservedObject var locationManager: LocationDataManager = LocationDataManager()
    
    var body: some View {
        VStack(alignment: .center, spacing: 5){
            
            VStack(spacing: 15){
                Image("HomeIconSymbol")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)

                //.padding()
                Text("ShiftTracker")
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .bold()
                    //.padding()
            }.opacity(mainElementsVisible ? 1 : 0)
                .blur(radius: mainElementsVisible ? 0 : 10)
                .animation(.easeInOut(duration: 1.0))
                            .onAppear {
                                mainElementsVisible = true
                                welcomeVisible = true
                            }
            
            .padding()
            .padding(.top, 100)
            Text("Welcome to ShiftTracker.")
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .font(.title3)
                .bold()
                
                .padding()
                .opacity(welcomeVisible ? 1 : 0)
                    .blur(radius: welcomeVisible ? 0 : 10)
                    .animation(.easeInOut(duration: 1.0))

            
            VStack(spacing: 10){
                Text("For clock in reminders, allow notifications.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .font(.body)
                    .opacity(notificationButtonVisible ? 1 : 0)
                    .blur(radius: notificationButtonVisible ? 0 : 10)
                    .animation(.easeInOut(duration: 3.0))
                                .onAppear {
                                    notificationButtonVisible = true
                                }
                Text("For location based clock in and clock out reminders and other location based features, allow location access.")
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .opacity(locationButtonVisible ? 1 : 0)
                    .blur(radius: locationButtonVisible ? 0 : 10)
                    .animation(.easeInOut(duration: 3.0))
                
                   
            }
            .padding(25)

            VStack{
            Button(action: {
                withAnimation {
                        isButtonTapped.toggle()
                        notificationButtonVisible = false
                        locationButtonVisible = true
                    }
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        locationButtonVisible = true
                        //dismiss()
                    } else if let error = error {
                        print(error.localizedDescription)
                    }
                }
            }) {
                VStack(spacing: 10) {
                    Image(systemName: "bell.fill")
                        .foregroundColor(Color.accentColor)
                    Text("Allow Notifications")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 25)
                .frame(maxWidth: UIScreen.main.bounds.width / 2 + 100)
                .padding(.vertical, 8)
                //.background(Color.accentColor)
                .cornerRadius(12)
                .blur(radius: mainElementsVisible ? 0 : 5)
                .opacity(notificationButtonVisible ? 1 : 0)
                .animation(.easeInOut(duration: 4.5))
                            .onAppear {
                                notificationButtonVisible = true
                            }
                
            }.haptics(onChangeOf: isButtonTapped, type: .success)
                
               
                
                Button(action: {
                    locationManager.requestWhenInUse()
                    isButtonTapped.toggle()
                    locationButtonVisible = false
                    mainElementsVisible = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            dismiss()
                        }
                }) {
                    VStack(spacing: 10) {
                        Image(systemName: "location.fill")
                            .foregroundColor(Color.accentColor)
                        Text("Allow Location Access")
                        
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 25)
                    .frame(maxWidth: UIScreen.main.bounds.width / 2 + 100)
                    .padding(.vertical, 8)
                    .cornerRadius(12)
                    .blur(radius: mainElementsVisible ? 0 : 5)
                    .opacity(locationButtonVisible ? 1 : 0)
                                .animation(.easeInOut(duration: 2))
                                
                    .disabled(!locationButtonVisible)
                }.haptics(onChangeOf: isButtonTapped, type: .success)
                
                
                
                Text("Ensure location access is set to \"Always\" in settings.")
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .foregroundColor(.white)
                    .opacity(locationButtonVisible ? 1 : 0)
                    .blur(radius: locationButtonVisible ? 0 : 10)
                    .animation(.easeInOut(duration: 3.0))
                    .padding()
                    .padding(.horizontal, 50)
            }

            Spacer()

        }
    }
}

struct LaunchView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchView()
    }
}
