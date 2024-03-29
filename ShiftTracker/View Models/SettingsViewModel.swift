//
//  SettingsViewModel.swift
//  ShiftTracker
//
//  Created by James Poole on 5/09/23.
//

import Foundation
import SwiftUI
import LocalAuthentication

class SettingsViewModel: ObservableObject {
    
    static let shared = SettingsViewModel()
    
    private let shiftKeys = ShiftKeys()
    
    private var sharedUserDefaults = UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")!
    
    @Published var showingProView: Bool = false
    @Published var isAuthenticated: Bool = false
    @Published private var deleteData = false
    
    @AppStorage("iCloudEnabled") var iCloudSyncOn: Bool = false
    @AppStorage("AuthEnabled") var authEnabled: Bool = false
    @AppStorage("TaxEnabled") var taxEnabled: Bool = true
    @AppStorage("TipsEnabled") var tipsEnabled: Bool = true
    @AppStorage("colorScheme") var userColorScheme: String = "system"
    
    func updateTax(){
        sharedUserDefaults.set(0.0, forKey: shiftKeys.taxPercentageKey)
    }
    
    
    
    
}
