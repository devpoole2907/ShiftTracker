//
//  LocationUpdateManager.swift
//  ShiftTracker
//
//  Created by James Poole on 2/04/23.
//

import Foundation
import Combine

class LocationUpdateManager: ObservableObject {
    @Published var didEnterRegion = false

    func locationManagerDidEnterRegion() {
        didEnterRegion.toggle()
    }
}

