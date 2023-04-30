//
//  MainWithSideBarView.swift
//  ShiftTracker
//
//  Created by James Poole on 28/04/23.
//

import SwiftUI
import Firebase

struct MainWithSideBarView: View {
    
    
    @StateObject private var authModel = FirebaseAuthModel()
    
    @State var showMenu: Bool = false
    
    @Environment(\.managedObjectContext) private var context
    
    init(){
        UITabBar.appearance().isHidden = true
    }
    
    @State var currentTab: Tab = .home

    @State var offset: CGFloat = 0
    @State var lastStoredOffset: CGFloat = 0
    
    @GestureState var gestureOffset: CGFloat = 0
    
    @State private var isSubscriptionChecked: Bool = false
    
    var body: some View {
        
        let sideBarWidth = getRect().width - 90
        

        
        if authModel.userIsLoggedIn{
        NavigationView {
            
            
            HStack(spacing: 0){
                SideMenu(showMenu: $showMenu)
                    .environmentObject(authModel)
                VStack(spacing: 0){
                    
                    TabView(selection: $currentTab) {
                        ContentView(showMenu: $showMenu)
                            .environment(\.managedObjectContext, context)
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationBarHidden(true)
                            .tag(Tab.home)
                        
                        // Your custom view for Timesheets
                        ShiftsView()
                        //.navigationBarTitleDisplayMode(.inline)
                        //.navigationBarHidden(true)
                            .tag(Tab.timesheets)
                        
                        ScheduleView()
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationBarHidden(true)
                            .tag(Tab.schedule)
                        
                        SummaryView()
                        //.navigationBarTitleDisplayMode(.inline)
                        //.navigationBarHidden(true)
                            .tag(Tab.summary)
                    }
                    
                    
                    VStack(spacing: 0){
                        Divider()
                        HStack(spacing: 0) {
                            TabButton(tab: .home, useSystemImage: true)
                            TabButton(tab: .timesheets, useSystemImage: true) // Use system image for this tab only
                            TabButton(tab: .schedule, useSystemImage: true)
                            TabButton(tab: .summary, useSystemImage: true)
                        }
                        .padding([.top], 15)
                    }
                    
                    
                }
                .frame(width: getRect().width)
                .ignoresSafeArea(.keyboard)
                
                .overlay(
                    
                    Rectangle()
                        .fill(
                            Color.primary.opacity(Double((offset / sideBarWidth) / 5))
                        )
                        .ignoresSafeArea(.container, edges: .vertical)
                        .onTapGesture {
                            withAnimation{
                                showMenu.toggle()
                            }
                        }
                )
            }
            .frame(width: getRect().width + sideBarWidth)
            .offset(x: -sideBarWidth / 2)
            .offset(x: offset > 0 ? offset : 0)
            
            .gesture(
                currentTab == .home ? DragGesture()
                    .updating($gestureOffset, body: { value, out, _ in
                        out = value.translation.width
                    })
                    .onEnded(onEnd(value:)) : nil
            )
            
            
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            
        }
        .animation(.easeOut, value: offset == 0)
        .onChange(of: showMenu) { newValue in
            if showMenu && offset == 0{
                offset = sideBarWidth
                lastStoredOffset = offset
            }
            if !showMenu && offset == sideBarWidth{
                offset = 0
                lastStoredOffset = 0
            }
        }
        .onChange(of: gestureOffset) { newValue in
            onChange()
        }
        .onAppear{ authModel.checkUserLoginStatus()
                            if !isSubscriptionChecked {
                                checkSubscriptionStatus()
                                isSubscriptionChecked = true
                            }    
            
        }
        
        } else {
            IntroMainView()
                .environmentObject(authModel)
                .onAppear{ authModel.checkUserLoginStatus() }
        }
    }
    
    func onChange(){
        let sideBarWidth = getRect().width - 90
        offset = (gestureOffset != 0 ) ? (gestureOffset + lastStoredOffset < sideBarWidth ? gestureOffset + lastStoredOffset : offset) : offset
    }
    
    func onEnd(value: DragGesture.Value){
        let sideBarWidth = getRect().width - 90
        
        let translation = value.translation.width
        
        withAnimation{
            if translation > 0{
                if translation > (sideBarWidth / 2){
                    offset = sideBarWidth
                    showMenu = true
                }
                else {
                    
                    if offset == sideBarWidth{
                        return
                    }
                    
                    offset = 0
                    showMenu = false
                }
            } else {
                if -translation > (sideBarWidth / 2){
                    offset = 0
                    showMenu = false
                }
                else {
                    
                    if offset == 0 || !showMenu{
                        return
                    }
                    
                    offset = sideBarWidth
                    showMenu = true
                }
            }
        }
        
        lastStoredOffset = offset
    }
    
    @ViewBuilder
    func TabButton(tab: Tab, useSystemImage: Bool = false) -> some View {
        Button {
            withAnimation { currentTab = tab }
        } label: {
            if useSystemImage, let systemImage = tab.systemImage {
                Image(systemName: systemImage)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .foregroundColor(currentTab == tab ? .primary : .gray)
                    .frame(maxWidth: .infinity)
            } else if let image = tab.image {
                Image(image)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 23, height: 22)
                    .foregroundColor(currentTab == tab ? .primary : .gray)
                    .frame(maxWidth: .infinity)
            }
            
        }
    }

    private func checkSubscriptionStatus() {
           if isSubscriptionActive() {
               print("Subscription is active")
               // Perform any actions required when the subscription is active
           } else {
               print("Subscription is not active")
               // Perform any actions required when the subscription is not active
           }
       }
    
}

struct MainWithSideBarView_Previews: PreviewProvider {
    static var previews: some View {
        MainWithSideBarView()
    }
}


enum Tab: String, CaseIterable {
    case home = "Home"
    case timesheets = "Timesheets"
    case schedule = "Schedule"
    case summary = "Summary"
    
    var image: String? {
        switch self {
        case .home:
            return "Home"
        case .timesheets:
            return "Timesheets"
        case .schedule:
            return "Schedule"
        case .summary:
            return "Summary"
        }
    }
    
    var systemImage: String? {
        switch self {
        case .home:
            return "house.fill"
        case .timesheets:
            return "clock.fill"
        case .schedule:
            return "calendar"
        case .summary:
            return "chart.bar.fill"
        }
    }
}

