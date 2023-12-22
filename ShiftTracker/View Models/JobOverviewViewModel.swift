//
//  JobOverviewViewModel.swift
//  ShiftTracker
//
//  Created by James Poole on 8/10/23.
//

import Foundation
import SwiftUI
import CoreData

class JobOverviewViewModel: ObservableObject {
    @Published var showLargeIcon = true
    @Published var appeared: Bool = false // for icon tap
    @Published var isEditJobPresented: Bool = false
    @Published var payPeriodShiftsToExport: Set<NSManagedObjectID>? = nil
    
    var navigationLocation: Int = 0
    
    @Published var selectedShiftToDupe: OldShift?
    
    @Published var job: Job?
    
    @Published var activeSheet: ActiveOverviewSheet?
    
    init(job: Job? = nil) {
        self.job = job
    }
    
    func checkTitlePosition(geometry: GeometryProxy) {
        let minY = geometry.frame(in: .global).minY
        showLargeIcon = minY > 100  // adjust this threshold as needed
    }
    

}
