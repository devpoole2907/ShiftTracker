//
//  MainWithSideBarView.swift
//  ShiftTracker
//
//  Created by James Poole on 28/04/23.
//

import SwiftUI
import Firebase
import UserNotifications
import CoreData

struct MainWithSideBarView: View {
    
    
    @AppStorage("AuthEnabled") private var authEnabled: Bool = false
        @State private var showingLockedView = false
    
    @AppStorage("isFirstLaunch", store: UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")) var isFirstLaunch = true
    
    @StateObject private var authModel = FirebaseAuthModel()
    
    @StateObject var viewModel = ContentViewModel()
    @StateObject var jobSelectionModel = JobSelectionViewModel()
    
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
    
    private func checkIfLocked() {
            if authEnabled {
                showingLockedView = true
            }
        }
    
    var body: some View {
        
        let sideBarWidth = getRect().width - 90
        
        
        
        // if authModel.userIsLoggedIn{
        if !isFirstLaunch{
            NavigationView {
                
                
                HStack(spacing: 0){
                    SideMenu(showMenu: $showMenu)
                        .environmentObject(authModel)
                        .environmentObject(viewModel)
                        .environmentObject(jobSelectionModel)
                    VStack(spacing: 0){
                        
                        TabView(selection: $currentTab) {
                            ContentView(showMenu: $showMenu)
                                .environment(\.managedObjectContext, context)
                                .environmentObject(viewModel)
                                .environmentObject(jobSelectionModel)
                            
                                .navigationBarTitleDisplayMode(.inline)
                                .navigationBarHidden(true)
                                .tag(Tab.home)
                            
                            
                            ShiftsView(showMenu: $showMenu)
                            
                                .tag(Tab.timesheets)
                            
                            ScheduleView(showMenu: $showMenu)
                                .navigationBarTitleDisplayMode(.inline)
                                .navigationBarHidden(true)
                                .tag(Tab.schedule)
                            
                        }
                        
                        
                        VStack(spacing: 0){
                            Divider()
                            HStack(spacing: 0) {
                                TabButton(tab: .home, useSystemImage: true)
                                TabButton(tab: .timesheets, useSystemImage: true) // Use system image for this tab only
                                TabButton(tab: .schedule, useSystemImage: true)
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
            
            
                .fullScreenCover(isPresented: $showingLockedView) {
                        LockedView(isAuthenticated: $showingLockedView)
                            .interactiveDismissDisabled()
                        }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                            checkIfLocked()
                        }
            
            .onAppear(perform: {
                let shifts = fetchUpcomingShifts()
                scheduleNotifications(for: shifts)
                checkIfLocked()
            })
            
            /*     .onAppear{ authModel.checkUserLoginStatus()
             if !isSubscriptionChecked {
             checkSubscriptionStatus()
             isSubscriptionChecked = true
             }
             
             } */
            
        } else {
            IntroMainView(isFirstLaunch: $isFirstLaunch)
                .environmentObject(authModel)
            //.onAppear{ authModel.checkUserLoginStatus() }
            
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
    
    func fetchUpcomingShifts() -> [ScheduledShift] {
        let fetchRequest: NSFetchRequest<ScheduledShift> = ScheduledShift.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "notifyMe == true")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ScheduledShift.reminderTime, ascending: true)]
        fetchRequest.fetchLimit = 15
        
        do {
            let shifts = try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
            return shifts
        } catch {
            print("Failed to fetch shifts: \(error.localizedDescription)")
            return []
        }
    }
    
    func scheduleNotifications(for shifts: [ScheduledShift]) {
        let center = UNUserNotificationCenter.current()
        
        center.removeAllPendingNotificationRequests()
        
        
        for shift in shifts {
            let content = UNMutableNotificationContent()
            content.title = "Shift Reminder"
            
            
            if let reminderDate = shift.startDate?.addingTimeInterval(-shift.reminderTime){
                content.body = "Your scheduled shift starts at \(shift.startDate)"
                
                let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: reminderDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
                
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                center.add(request)
            } else {
                return
            }
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
    
    var image: String? {
        switch self {
        case .home:
            return "Home"
        case .timesheets:
            return "Timesheets"
        case .schedule:
            return "Schedule"
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
        }
    }
}

