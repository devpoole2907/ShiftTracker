//
//  PageIntro.swift
//  ShiftTracker
//
//  Created by James Poole on 29/04/23.
//

import SwiftUI

struct PageIntro: Identifiable, Hashable {
    var id: UUID = .init()
    var introAssetImage: String? = nil
    var title: String
    var subTitle: String
    var displaysAction: Bool = false
    var customView: AnyView? = nil
    
    func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(introAssetImage)
            hasher.combine(title)
            hasher.combine(subTitle)
            hasher.combine(displaysAction)
           
        }
    
    static func == (lhs: PageIntro, rhs: PageIntro) -> Bool {
            return lhs.id == rhs.id &&
                lhs.introAssetImage == rhs.introAssetImage &&
                lhs.title == rhs.title &&
                lhs.subTitle == rhs.subTitle &&
                lhs.displaysAction == rhs.displaysAction
           
                // customView is not compared here
        }
    
    
}

var pageIntros: [PageIntro] = [
    .init(title: "Welcome to\nShiftTracker", subTitle: "Introducing ShiftTracker, a new approach to work management.", customView: AnyView(MockupWelcomeView())),
    .init(title: "Track Your Time", subTitle: "Never lose track of your work hours again. Log your time with just a tap.", customView: AnyView(MockupContentView())),
    .init(title: "Live Earnings", subTitle: "Stay updated with real-time earnings. Get quick insights right from your Lock Screen.", customView: AnyView(MockupLockscreenView())),
    .init(title: "Handle Multiple Jobs", subTitle: "Juggling multiple jobs? Easily switch and manage them all in one place.", customView: AnyView(MockupSideMenu())),
    .init(title: "Location-based Clock In & Out", subTitle: "Automatically clock in as you arrive and clock out when you leave.", customView: AnyView(MockupMapView())),
    .init(introAssetImage: "Scheduling", title: "Schedule Shifts", subTitle: "Set your shifts and leave the rest to us. No more forgotten work schedules.", customView: AnyView(MockupScheduleView())),
    //  .init(introAssetImage: "Invoicing", title: "Invoice generation", subTitle: "Tired of messing with pay calculations? Just tell us your pay period, and we'll pop out those invoices."),
    .init(introAssetImage: "Statistics", title: "Statistics & Summaries", subTitle: "Dive into your work patterns with insightful charts and statistics.", customView: AnyView(MockupStatisticsView())),
    .init(introAssetImage: "SignUp", title: "Get Started", subTitle: "Ready for a smoother shift-tracking experience? Begin by adding your first job.", displaysAction: true, customView: AnyView(MockupContinueView())),
]

