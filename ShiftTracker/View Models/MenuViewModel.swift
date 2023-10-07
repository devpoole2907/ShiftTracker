//
//  MenuViewModel.swift
//  ShiftTracker
//
//  Created by James Poole on 8/10/23.
//

import Foundation
import SwiftUI

class MenuViewModel: ObservableObject {
    @Published var selectedJobForEditing: Job?
    @Published var isEditJobPresented: Bool = false
    
    @Published var showAddJobView = false
    @Published var showingTagSheet = false
    @Published var showUpgradeScreen = false
    
    @AppStorage("selectedJobUUID") var storedSelectedJobUUID: String?
    // used for sub expiry
    @AppStorage("lastSelectedJobUUID") var lastSelectedJobUUID: String?
}
