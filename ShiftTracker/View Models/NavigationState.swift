//
//  NavigationState.swift
//  ShiftTracker
//
//  Created by James Poole on 31/08/23.
//

import SwiftUI
import Combine

class NavigationState: ObservableObject {
    static let shared = NavigationState()
    
    
    
    @Published var gestureEnabled: Bool = true
    @Published var showMenu: Bool = false
    
    @Published var currentTab: Tab = .home
    
    @Published var hideTabBar = false
    
    @Published var activeCover: ActiveCover?
    @Published var activeSheet: ActiveSheet?
    
    @Published var offset: CGFloat = 0
    @Published var lastStoredOffset: CGFloat = 0
    
    @Published var sideBarWidth = UIScreen.main.bounds.width - 90
    
    
    @Published var calculatedBlur: Double = 0

        init() {
        
            // Recalculate blur whenever offset or sideBarWidth changes
            Publishers.CombineLatest($offset, $sideBarWidth)
                .map { offset, sideBarWidth in
                    return Double((offset / sideBarWidth) * 4)
                }
                .assign(to: &$calculatedBlur)
        }

    
}
