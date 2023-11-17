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
import SwiftUIIntrospect

struct MainWithSideBarView: View {
    
    @FetchRequest(entity: Job.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Job.title, ascending: true)]) private var jobs: FetchedResults<Job>
    
    @AppStorage("AuthEnabled") private var authEnabled: Bool = false
    
    @AppStorage("isFirstLaunch", store: UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")) var isFirstLaunch = true
    
    @State private var showAddJobView = false
    
    @State private var jobId: NSManagedObjectID? = nil
    
    @State private var settingsPath: [Int] = []
    
    @State private var path = NavigationPath()
    @State private var schedulePath = NavigationPath()
    
    @StateObject var jobSelectionModel = JobSelectionManager()
    @StateObject var scheduleModel = SchedulingViewModel()
    @StateObject var sortSelection = SortSelection(in: PersistenceController.shared.container.viewContext)
    @StateObject var shiftManager = ShiftDataManager.shared
    @StateObject var scrollManager = ScrollManager()
    
    @EnvironmentObject var themeManager: ThemeDataManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var navigationState: NavigationState
    
    @Environment(\.managedObjectContext) private var context
    
    private let notificationManager = ShiftNotificationManager.shared

    @GestureState var gestureOffset: CGFloat = 0
    
    @State private var isSubscriptionChecked: Bool = false
    
    
    private func checkIfLocked() {
        
        print("checking if auth enabled...")
        
            if authEnabled {
                print("auth enabled!")
                navigationState.activeCover = .lockedView
            } else {
                print("auth is not enabled.")
            }
        }
    
    
    
    var body: some View {
        ZStack{
            NavigationView{
                ZStack(alignment: .bottom){
                
                    
                    tabsViews
             
                    if !navigationState.hideTabBar {
                        tabButtons
                        
                        
                        //    .blur(radius: Double((navigationState.offset / navigationState.sideBarWidth) * 4))
                        
                            .ignoresSafeArea(.keyboard)
                    }
                
            }.ignoresSafeArea(.keyboard)
                    .frame(width: getRect().width)
            
            
            
            
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarHidden(true)
                
                .toolbar{
                    ToolbarItemGroup(placement: .keyboard){
                        
                        KeyboardDoneButton()
                    }
                }
            
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
            
            .fullScreenCover(item: $navigationState.activeCover){ cover in
                switch cover {
                case .lockedView:
                    LockedView().customSheetBackground()
                case .jobView:
                    JobView(isEditJobPresented: .constant(true), selectedJobForEditing: .constant(nil))
                        .environmentObject(ContentViewModel.shared)
                        .environmentObject(jobSelectionModel)
                        .customSheetBackground()
                }
            }
            
         
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                print("I have entered the foreground")
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
            
        
            
            SideMenu()
                .disabled(!navigationState.showMenu || isFirstLaunch)
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
               
                    // setting this to height will break the views, pushing the nav bar down on ios 17.1 or above...
                       .frame(maxHeight: (UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? UIScreen.main.bounds.height - 90 : UIScreen.main.bounds.height - 160)
                    
                    
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
            
            if isFirstLaunch {
                IntroMainView(isFirstLaunch: $isFirstLaunch).frame(width: getRect().width)
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
    
    var tabsViews: some View {
        TabView(selection: $navigationState.currentTab) {
            NavigationStack{
                ContentView()
                    .blur(radius: navigationState.calculatedBlur)
                    .blur(radius: isFirstLaunch ? 50 : 0)
                    .allowsHitTesting(!navigationState.showMenu)
                
                    .background {
                        
                        themeManager.contentDynamicBackground.ignoresSafeArea()
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
                    JobOverview(navPath: $path, job: jobSelectionModel.fetchJob(in: context))
                        .blur(radius: navigationState.calculatedBlur)
                        .allowsHitTesting(!navigationState.showMenu)
                    
                        .background {
                            
                            themeManager.overviewDynamicBackground.ignoresSafeArea()
                        }
                    
                    
                }
                
                .introspect(.navigationStack, on: .iOS(.v16, .v17)) { controller in
                    print("I am introspecting!")

                    
                    let largeFontSize: CGFloat = UIFont.preferredFont(forTextStyle: .largeTitle).pointSize
                    let inlineFontSize: CGFloat = UIFont.preferredFont(forTextStyle: .body).pointSize

                    // Here we get San Francisco with the desired weight
                    let largeSystemFont = UIFont.systemFont(ofSize: largeFontSize, weight: .bold)
                    let inlineSystemFont = UIFont.systemFont(ofSize: inlineFontSize, weight: .bold)

                    // Will be SF Compact or standard SF in case of failure.
                    let largeFont: UIFont
                    
                    let inlineFont: UIFont

                    if let largeDescriptor = largeSystemFont.fontDescriptor.withDesign(.rounded) {
                        largeFont = UIFont(descriptor: largeDescriptor, size: largeFontSize)
                    } else {
                        largeFont = largeSystemFont
                    }
                    
                    if let inlineDescriptor = inlineSystemFont.fontDescriptor.withDesign(.rounded) {
                        inlineFont = UIFont(descriptor: inlineDescriptor, size: inlineFontSize)
                    } else {
                        inlineFont = inlineSystemFont
                    }
                    
                    let largeAttributes: [NSAttributedString.Key: Any] = [
                        .font: largeFont
                    ]

                    let inlineAttributes: [NSAttributedString.Key: Any] = [
                        .font: inlineFont
                    ]
                                        
                    controller.navigationBar.titleTextAttributes = inlineAttributes
                    
                    controller.navigationBar.largeTitleTextAttributes = largeAttributes
                    
                    
               
                }
                
                
                .environment(\.managedObjectContext, context)
                .environmentObject(jobSelectionModel)
                .environmentObject(navigationState)
                .environmentObject(sortSelection)
                .environmentObject(shiftManager)
                .environmentObject(scrollManager)
                
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
                
                
                
            }.ignoresSafeArea(.keyboard)
                .tag(Tab.timesheets)
                
            
            
            NavigationStack(path: $schedulePath){
                ScheduleView(navPath: $schedulePath)
                    .blur(radius: navigationState.calculatedBlur)
                    .allowsHitTesting(!navigationState.showMenu)
                
                    .background {
                        
                        themeManager.scheduleDynamicBackground.ignoresSafeArea()
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
                        
                        themeManager.settingsDynamicBackground.ignoresSafeArea()
                    }
                
            }
            .environment(\.managedObjectContext, context)
            .environmentObject(navigationState)
            .environmentObject(SettingsViewModel.shared)
            .navigationBarTitleDisplayMode(.inline)
            
            .tag(Tab.settings)
            
            
        } 
        
        
        .ignoresSafeArea(.keyboard)
    }
    

    var tabButtons: some View {
        VStack(spacing: 0){
            HStack(spacing: 0) {
                TabButton(tab: .home, useSystemImage: true)
                TabButton(tab: .timesheets, useSystemImage: true, action: {
                    
                    // scroll to top if any view in timesheets tab has been scrolled, otherwise pop to root or open side menu
                    
                    if scrollManager.timeSheetsScrolled {
                        scrollManager.scrollOverviewToTop.toggle()
                        scrollManager.timeSheetsScrolled = false
                    } else if path.isEmpty {
                        
                        navigationState.showMenu.toggle()
                        
                    } else {
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
    }
    
    
    
}



