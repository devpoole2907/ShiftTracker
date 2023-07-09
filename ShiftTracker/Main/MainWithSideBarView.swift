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
    
    @FetchRequest(entity: Job.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Job.title, ascending: true)]) private var jobs: FetchedResults<Job>
    
    @AppStorage("AuthEnabled") private var authEnabled: Bool = false
        @State private var showingLockedView = false
    
    @AppStorage("isFirstLaunch", store: UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")) var isFirstLaunch = true
    
    @State private var showAddJobView = false
    
    @State private var jobId: NSManagedObjectID? = nil
    
    @StateObject var viewModel = ContentViewModel()
    @StateObject var jobSelectionModel = JobSelectionViewModel()
    @StateObject var navigationState = NavigationState()
    @StateObject var shiftStore = ScheduledShiftStore()
    @StateObject var scheduleModel = SchedulingViewModel()
    
    
    private let notificationManager = ShiftNotificationManager.shared
    
    @Environment(\.managedObjectContext) private var context
    
    init(currentTab: Binding<Tab>) {
         self._currentTab = currentTab
         UITabBar.appearance().isHidden = true
     }
    
    @Binding var currentTab: Tab
    
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
        
        
        

        if !isFirstLaunch{
            NavigationView {
                ZStack{
                    
                    HStack(spacing: 0){
                        SideMenu()
                            .disabled(!navigationState.showMenu)
                            .environmentObject(navigationState)
                            .environmentObject(viewModel)
                            .environmentObject(jobSelectionModel)
                        
                        VStack(spacing: 0){
                            
                            TabView(selection: $currentTab) {
                                ContentView()
                                    .environment(\.managedObjectContext, context)
                                    .environmentObject(viewModel)
                                    .environmentObject(jobSelectionModel)
                                    .environmentObject(navigationState)
                                
                                    .navigationBarTitleDisplayMode(.inline)
                                    .navigationBarHidden(true)
                                    .tag(Tab.home)


                                        JobOverview()
                                            .environment(\.managedObjectContext, context)
                                            .environmentObject(jobSelectionModel)
                                            .environmentObject(navigationState)
                                            .tag(Tab.timesheets)
                                   
                                
                                ScheduleView()
                                    .environment(\.managedObjectContext, context)
                                    .environmentObject(navigationState)
                                    .environmentObject(jobSelectionModel)
                                    .environmentObject(shiftStore)
                                    .environmentObject(scheduleModel)
                                    .navigationBarTitleDisplayMode(.inline)
                         
                                    .tag(Tab.schedule)
                                
                            }
                            
                            
                            VStack(spacing: 0){
                                Divider()
                                HStack(spacing: 0) {
                                    TabButton(tab: .home, useSystemImage: true)
                                    TabButton(tab: .timesheets, useSystemImage: true) // Use system image for this tab only
                                    TabButton(tab: .schedule, useSystemImage: true)
                                }
                                .padding(.top, (UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? 10 : 15)
                                .padding(.bottom, (UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? 10 : 0)
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
                        )
                    }
                    .frame(width: getRect().width + sideBarWidth)
                    .offset(x: -sideBarWidth / 2)
                    .offset(x: offset > 0 ? offset : 0)
                    HStack {
                        if navigationState.showMenu {
                            Spacer()
                        }
                    VStack {
                        Spacer()
                    }
                    .frame(width: navigationState.showMenu ? 250 : (UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? 150 : 200)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation{
                            if navigationState.showMenu {
                                navigationState.showMenu = false
                            }
                        }
                    }
                    .gesture(
                        navigationState.gestureEnabled ? DragGesture()
                            .updating($gestureOffset, body: { value, out, _ in
                                
                                out = value.translation.width
                                
                            })
                            .onEnded(onEnd(value:)) : nil
                    )
                        if !navigationState.showMenu{
                            Spacer()
                        }
                        
                            
                }
            }

                
                
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarHidden(true)
                
            }
            .animation(.easeOut, value: offset == 0)
            .onChange(of: navigationState.showMenu) { newValue in
                if navigationState.showMenu && offset == 0{
                    offset = sideBarWidth
                    lastStoredOffset = offset
                }
                if !navigationState.showMenu && offset == sideBarWidth{
                    offset = 0
                    lastStoredOffset = 0
                }
            }
            .onChange(of: gestureOffset) { newValue in
                onChange()
            }
            
            .onChange(of: jobSelectionModel.selectedJobUUID) { newUUID in
                    jobId = jobs.first(where: { $0.uuid == newUUID })?.objectID
                }
            
            
                .fullScreenCover(isPresented: $showingLockedView) {
                        LockedView(isAuthenticated: $showingLockedView)
                            .interactiveDismissDisabled()
                        }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                            checkIfLocked()
                        }
            
            .onAppear(perform: {
                notificationManager.scheduleNotifications() // cancels and reschedules the next 20 scheduled shifts with notify == true
                
                notificationManager.updateRosterNotifications(viewContext: context)
                
                checkIfLocked()
            })
            
            .onAppear {
                if !isSubscriptionChecked {
                checkSubscriptionStatus()
                isSubscriptionChecked = true
                }
            }
            
            /*     .onAppear{ authModel.checkUserLoginStatus()
             if !isSubscriptionChecked {
             checkSubscriptionStatus()
             isSubscriptionChecked = true
             }
             
             } */
            
        } else {
            IntroMainView(isFirstLaunch: $isFirstLaunch)
            
            //.onAppear{ authModel.checkUserLoginStatus() }
        }
        
        
        
    }
    
    func onChange(){
        let sideBarWidth = getRect().width - 90
        offset = (gestureOffset != 0 ) ? (gestureOffset + lastStoredOffset < sideBarWidth ? gestureOffset + lastStoredOffset : offset) : offset
    }
    
func onEnd(value: DragGesture.Value) {
    let sideBarWidth = getRect().width - 90
    let translation = value.translation.width
    let velocity = value.predictedEndLocation.x - value.location.x

    withAnimation {
        if (translation + velocity / 2 > sideBarWidth / 2) {
            offset = sideBarWidth
            navigationState.showMenu = true
        } else {
            offset = 0
            navigationState.showMenu = false
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
        MainWithSideBarView(currentTab: .constant(.home))
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

