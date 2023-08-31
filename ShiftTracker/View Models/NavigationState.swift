//
//  NavigationState.swift
//  ShiftTracker
//
//  Created by James Poole on 31/08/23.
//

import SwiftUI

class NavigationState: ObservableObject {
    static let shared = NavigationState()
    
    @Published var gestureEnabled: Bool = true
    @Published var showMenu: Bool = false
    
    @Published var currentTab: Tab = .home
    
    @Published var hideTabBar = false
    
}
