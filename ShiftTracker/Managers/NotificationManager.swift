//
//  NotificationManager.swift
//  ShiftTracker
//
//  Created by James Poole on 31/08/23.
//

import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    @Published var authorizationStatus: UNAuthorizationStatus?
    
    init() {
        checkNotificationStatus()
    }
    
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    
}
