//
//  GlobalFunctions.swift
//  ShiftTracker
//
//  Created by James Poole on 30/04/23.
//

import Foundation

func isSubscriptionActive() -> Bool {
    
    let subscriptionStatus = UserDefaults.standard.bool(forKey: "subscriptionStatus")
    return subscriptionStatus
}

func setUserSubscribed(_ subscribed: Bool) {
    let userDefaults = UserDefaults.standard
    userDefaults.set(subscribed, forKey: "subscriptionStatus")
    if subscribed{
        print("set subscription to true ")
    }
    else {
        print("wtf goin on mayne")
    }
}
