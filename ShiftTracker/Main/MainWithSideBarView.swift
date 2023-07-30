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
    
    @State private var settingsPath: [Int] = []
    
    @State private var path = NavigationPath()
    @State private var schedulePath = NavigationPath()
    
    
   // @StateObject var viewModel = ContentViewModel()
    @StateObject var jobSelectionModel = JobSelectionManager()
    @EnvironmentObject var navigationState: NavigationState
    @StateObject var scheduleModel = SchedulingViewModel()
    
    @StateObject var shiftManager = ShiftDataManager.shared
    
    @EnvironmentObject var themeManager: ThemeDataManager
   // @EnvironmentObject var locationManager: LocationDataManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var sortSelection: SortSelection
    
    private let notificationManager = ShiftNotificationManager.shared
    
    @Environment(\.managedObjectContext) private var context
    
    init(/*currentTab: Binding<Tab>*/) {
        // self._currentTab = currentTab
         UITabBar.appearance().isHidden = true
     }
    
    //@Binding var currentTab: Tab
    
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
                        SideMenu(currentTab: $navigationState.currentTab)
                            .disabled(!navigationState.showMenu)
                            .environmentObject(navigationState)
                            .environmentObject(ContentViewModel.shared)
                            .environmentObject(jobSelectionModel)
                            .environmentObject(themeManager)
                        
                        VStack(spacing: 0){
                            
                            TabView(selection: $navigationState.currentTab) {
                                ContentView()
                                    .environment(\.managedObjectContext, context)
                                    .environmentObject(ContentViewModel.shared)
                                    .environmentObject(jobSelectionModel)
                                    .environmentObject(navigationState)
                                
                                    .navigationBarTitleDisplayMode(.inline)
                                    .navigationBarHidden(true)
                                    .tag(Tab.home)
                                
                                
                                JobOverview(navPath: $path)
                                    .environment(\.managedObjectContext, context)
                                    .environmentObject(jobSelectionModel)
                                    .environmentObject(navigationState)
                                    .environmentObject(shiftManager)
                                    .tag(Tab.timesheets)
                                
                                
                                ScheduleView(navPath: $schedulePath)
                                    .environment(\.managedObjectContext, context)
                                    .environmentObject(navigationState)
                                    .environmentObject(jobSelectionModel)
                                    .environmentObject(scheduleModel)
                                    .environmentObject(shiftManager)
                                    .navigationBarTitleDisplayMode(.inline)
                                
                                    .tag(Tab.schedule)
                                
                                SettingsView(navPath: $settingsPath)
                                    .environment(\.managedObjectContext, context)
                                    .environmentObject(navigationState)
                                    .navigationBarTitleDisplayMode(.inline)
                                
                                    .tag(Tab.settings)
                                
                                
                            }
                            
                            
                            VStack(spacing: 0){
                                HStack(spacing: 0) {
                                    TabButton(tab: .home, useSystemImage: true)
                                    TabButton(tab: .timesheets, useSystemImage: true, action: {
                                        
                                        if path.isEmpty {
                                            
                                            navigationState.showMenu.toggle()
                                            
                                        } else {
                                            // broken ios 17 beta 4
                                            
                                          
                                                
                                                 //path = NavigationPath()
                                                
                                            if path.count == 2 {
                                                
                                                path.removeLast()
                                                path.removeLast()
                                                
                                            }
                                             
                                            
                                        }
                                        
                                        
                                    })
                                    TabButton(tab: .schedule, useSystemImage: true, action: {
                                        
                                        if schedulePath.isEmpty {
                                            navigationState.showMenu.toggle()
                                        } else {
                                            schedulePath = NavigationPath()
                                        }
                                        
                                        
                                    })
                                    TabButton(tab: .settings, useSystemImage: true, action: {
                                        
                                        if settingsPath.isEmpty {
                                            
                                            navigationState.showMenu.toggle()
                                            
                                        } else {
                                            
                                            settingsPath = []
                                            
                                        }
                                        
                                    })
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
                    
                    if (navigationState.currentTab == .settings && settingsPath.isEmpty) || (navigationState.currentTab == .home || navigationState.currentTab == .schedule) || (navigationState.currentTab == .timesheets && path.isEmpty) {
                    
                    HStack {
                        if navigationState.showMenu {
                            Spacer()
                        }
                        VStack {
                            Spacer()
                        }
                        .frame(width: navigationState.showMenu ? 250 : (UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? 175 : 200)
                        .frame(height: (UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? UIScreen.main.bounds.height - 150 : UIScreen.main.bounds.height - 200)
                        
                        
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
                
                notificationManager.updateRosterNotifications(viewContext: context) // cancels and reschedules any roster reminders
                
                checkIfLocked()
                
                createTags(in: context)
                
                
                
                
                
            })
            
            .onAppear {
              
                
                  
                        
                        Task {
                            
                            do {
                                
                                try await purchaseManager.loadProducts()
                            } catch {
                                
                                print(error)
                            }
                            
                        }
                        
                     
                        
                        
                    
                
            }
            
            /*     .onAppear{ authModel.checkUserLoginStatus()
             if !isSubscriptionChecked {
             checkSubscriptionStatus()
             isSubscriptionChecked = true
             }
             
             } */
            
        } else {
            IntroMainView(isFirstLaunch: $isFirstLaunch).environmentObject(ContentViewModel.shared).environmentObject(jobSelectionModel)
                .onAppear {
                    
                    themeManager.resetColorsToDefaults()
                    
                    
                    
                }
            
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
    func TabButton(tab: Tab, useSystemImage: Bool = false, action: (() -> Void)? = nil) -> some View {
        Button {
            
            if navigationState.currentTab != tab {
                withAnimation {
                    navigationState.currentTab = tab
                }
                
            } else if let action {
                
                
                action()
                
                
            } else {
                
                navigationState.showMenu.toggle()
                
            }
            
            
        
                
                
            
            
            
        
            
        } label: {
            if useSystemImage, let systemImage = tab.systemImage {
                Image(systemName: systemImage)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .foregroundColor(navigationState.currentTab == tab ? .primary : .gray)
                    .frame(maxWidth: .infinity)
            } else if let image = tab.image {
                Image(image)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 23, height: 22)
                    .foregroundColor(navigationState.currentTab == tab ? .primary : .gray)
                    .frame(maxWidth: .infinity)
            }
            
        }
    }
    

    
    
    
}

struct MainWithSideBarView_Previews: PreviewProvider {
    static var previews: some View {
        //MainWithSideBarView(currentTab: .constant(.home))
        MainWithSideBarView()
    }
}


enum Tab: String, CaseIterable {
    case home = "Home"
    case timesheets = "Timesheets"
    case schedule = "Schedule"
    case settings = "Settings"
    
    var image: String? {
        switch self {
        case .home:
            return "Home"
        case .timesheets:
            return "Timesheets"
        case .schedule:
            return "Schedule"
        case .settings:
            return "Settings"
        
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
        case .settings:
            return "gear"
        }
    }
}

