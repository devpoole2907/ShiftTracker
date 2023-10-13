//
//  ScrollManager.swift
//  ShiftTracker
//
//  Created by James Poole on 13/10/23.
//

import Foundation

class ScrollManager: ObservableObject {
    @Published var scrollOverviewToTop: Bool = false
    @Published var timeSheetsScrolled: Bool = false
}
