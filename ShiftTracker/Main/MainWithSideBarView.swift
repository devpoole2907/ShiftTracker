//
//  MainWithSideBarView.swift
//  ShiftTracker
//
//  Created by James Poole on 28/04/23.
//

import SwiftUI
import UserNotifications
import CoreData
import Haptics

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
    
    @StateObject var jobSelectionModel = JobSelectionManager()
    @EnvironmentObject var navigationState: NavigationState
    @StateObject var scheduleModel = SchedulingViewModel()
    @StateObject var sortSelection = SortSelection(in: PersistenceController.shared.container.viewContext)
    
    @StateObject var shiftManager = ShiftDataManager.shared
    
    @EnvironmentObject var themeManager: ThemeDataManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    private let notificationManager = ShiftNotificationManager.shared
    
    @Environment(\.managedObjectContext) private var context
    

    
    @GestureState var gestureOffset: CGFloat = 0
    
    @State private var isSubscriptionChecked: Bool = false
    
    
    private func checkIfLocked() {
            if authEnabled {
                showingLockedView = true
            }
        }
    
    
    
    var body: some View {
        ZStack{
            NavigationView{
            ZStack(alignment: .bottom){
                Group{
                    TabView(selection: $navigationState.currentTab) {
                        NavigationStack{
                            ContentView()
                                .blur(radius: navigationState.calculatedBlur)
                                .allowsHitTesting(!navigationState.showMenu)
                            
                                .background {
                                    Rectangle().foregroundStyle(
                                        
                                        themeManager.contentViewGradient
                                    
                                    
                                    ).blur(radius: 50).ignoresSafeArea()
                                }
                            
                        
                        }
                        .environment(\.managedObjectContext, context)
                        .environmentObject(ContentViewModel.shared)
                        .environmentObject(jobSelectionModel)
                        .environmentObject(navigationState)
                        
                     
                        
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationBarHidden(true)
                        .tag(Tab.home)
                        
                        
                        ZStack(alignment: .bottomTrailing) {
                            NavigationStack(path: $path){
                                JobOverview(navPath: $path)
                                    .blur(radius: navigationState.calculatedBlur)
                                    .allowsHitTesting(!navigationState.showMenu)
                                
                                    .background {
                                        Rectangle().foregroundStyle(
                                            
                                            themeManager.jobOverviewGradient
                                        
                                        
                                        ).blur(radius: 50).ignoresSafeArea()
                                    }
                                
                                
                            }
                            .environment(\.managedObjectContext, context)
                            .environmentObject(jobSelectionModel)
                            .environmentObject(navigationState)
                            .environmentObject(sortSelection)
                            .environmentObject(shiftManager)
                            
                            if shiftManager.showModePicker {
                                
                                CustomSegmentedPicker(selection: $shiftManager.statsMode, items: StatsMode.allCases)
                                
                                    .frame(maxHeight: 30)
                                
                                    .glassModifier(cornerRadius: 20)
                                
                                    .frame(maxWidth: 165)
                                
                                
                                    .padding()
                                
                                
                                
                                    .haptics(onChangeOf: shiftManager.statsMode, type: .soft)
                                
                                    .contextMenu{
                                        ForEach(0..<shiftManager.statsModes.count) { index in
                                            Button(action: {
                                                withAnimation {
                                                    shiftManager.statsMode = StatsMode(rawValue: index) ?? .earnings
                                                    shiftManager.shiftDataLoaded.send(())
                                                }
                                            }) {
                                                HStack {
                                                    
                                                    Text(shiftManager.statsModes[index])
                                                        .textCase(nil)
                                                    if index == shiftManager.statsMode.rawValue {
                                                        Spacer()
                                                        Image(systemName: "checkmark")
                                                            .foregroundColor(.accentColor) // Customize the color if needed
                                                    }
                                                }
                                            }
                                        }
                                    }
                                
                            }
                            
                            
                            
                        }.tag(Tab.timesheets)
                            
                        
                        
                        NavigationStack(path: $schedulePath){
                            ScheduleView(navPath: $schedulePath)
                                .blur(radius: navigationState.calculatedBlur)
                                .allowsHitTesting(!navigationState.showMenu)
                            
                                .background {
                                    Rectangle().foregroundStyle(
                                        
                                        themeManager.scheduleGradient
                                    
                                    
                                    ).blur(radius: 50).ignoresSafeArea()
                                }
                            
                        }
                        .environment(\.managedObjectContext, context)
                        .environmentObject(navigationState)
                        .environmentObject(jobSelectionModel)
                        .environmentObject(scheduleModel)
                        .environmentObject(shiftManager)
                        .navigationBarTitleDisplayMode(.inline)
                        
                        .tag(Tab.schedule)
                        NavigationStack(path: $settingsPath){
                            SettingsView(navPath: $settingsPath)
                                .blur(radius: navigationState.calculatedBlur)
                                .allowsHitTesting(!navigationState.showMenu)
                               
                                .background {
                                    Rectangle().foregroundStyle(
                                        
                                        themeManager.settingsGradient
                                    
                                    
                                    ).blur(radius: 50).ignoresSafeArea()
                                }
                            
                        }
                        .environment(\.managedObjectContext, context)
                        .environmentObject(navigationState)
                        .environmentObject(SettingsViewModel.shared)
                        .navigationBarTitleDisplayMode(.inline)
                        
                        .tag(Tab.settings)
                        
                        
                    }
                    
                    
                    .ignoresSafeArea(.keyboard)
                    
                    
                    
                    VStack(spacing: 0){
                        HStack(spacing: 0) {
                            TabButton(tab: .home, useSystemImage: true)
                            TabButton(tab: .timesheets, useSystemImage: true, action: {
                                
                                if path.isEmpty {
                                    
                                    navigationState.showMenu.toggle()
                                    
                                } else {
                                    // broken ios 17 beta 4
                                    
                                    
                                    
                                    path = NavigationPath()
                                    
                                    
                                    
                                    
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
                        .ignoresSafeArea(.keyboard)
                        
                    }.ignoresSafeArea(.keyboard)
                    
                        .blur(radius: Double((navigationState.offset / navigationState.sideBarWidth) * 4))
                    
                }  .frame(width: getRect().width)
                    .ignoresSafeArea(.keyboard)
                
                
                
                SideMenu(currentTab: $navigationState.currentTab)
                    .disabled(!navigationState.showMenu)
                    .environmentObject(navigationState)
                    .environmentObject(ContentViewModel.shared)
                    .environmentObject(jobSelectionModel)
                    .environmentObject(themeManager)
                
                    .frame(width: getRect().width + 12 + navigationState.sideBarWidth)
                    .offset(x: -navigationState.sideBarWidth / 2)
                    .offset(x: navigationState.offset > 0 ? navigationState.offset + 12 : 0)
                
                
                if (navigationState.currentTab == .settings && settingsPath.isEmpty) || (navigationState.currentTab == .home || navigationState.currentTab == .schedule) || (navigationState.currentTab == .timesheets && path.isEmpty) {
                    
                    HStack {
                        if navigationState.showMenu {
                            Spacer()
                        }
                        VStack {
                            Spacer()
                        }
                        .frame(width: navigationState.showMenu ? 250 : (UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? 175 : 190)
                        .frame(height: (UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? UIScreen.main.bounds.height - 90 : UIScreen.main.bounds.height - 160)
                        
                        
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
                
            }.ignoresSafeArea(.keyboard)
            
            
            
            
            
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarHidden(true)
            
        }
          
            .animation(.easeOut, value: navigationState.offset == 0)
            .onChange(of: navigationState.showMenu) { newValue in
                withAnimation {
                    if navigationState.showMenu && navigationState.offset == 0{
                        navigationState.offset = navigationState.sideBarWidth
                        navigationState.lastStoredOffset = navigationState.offset
                    }
                    if !navigationState.showMenu && navigationState.offset == navigationState.sideBarWidth{
                        navigationState.offset = 0
                        navigationState.lastStoredOffset = 0
                    }
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
                
                // creates default theme and applies it if it doesnt exist
                createDefaultTheme(in: context, with: themeManager)
                
                
                // sets all jobs with auto clock in & out to false if subscription gone
                if !purchaseManager.hasUnlockedPro {
                    
                    purchaseManager.handleSubscriptionExpiry(in: context)
                    
                }
                
                
                
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
            
            if isFirstLaunch {
                IntroMainView(isFirstLaunch: $isFirstLaunch).environmentObject(ContentViewModel.shared).environmentObject(jobSelectionModel)
                    .onAppear {
                        
                        themeManager.resetColorsToDefaults()
                        
                        
                        
                    }
                
            }
        }.ignoresSafeArea(.keyboard)
 
    }
    
    func onChange(){
        let sideBarWidth = getRect().width - 90
        navigationState.offset = (gestureOffset != 0 ) ? (gestureOffset + navigationState.lastStoredOffset < sideBarWidth ? gestureOffset + navigationState.lastStoredOffset : navigationState.offset) : navigationState.offset
    }
    
func onEnd(value: DragGesture.Value) {
    let sideBarWidth = getRect().width - 90
    let translation = value.translation.width
    let velocity = value.predictedEndLocation.x - value.location.x

    withAnimation {
        if (translation + velocity / 2 > sideBarWidth / 2) {
            navigationState.offset = sideBarWidth
            navigationState.showMenu = true
        } else {
            navigationState.offset = 0
            navigationState.showMenu = false
        }
    }

    navigationState.lastStoredOffset = navigationState.offset
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

