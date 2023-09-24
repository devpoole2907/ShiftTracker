//
//  PageIntro.swift
//  ShiftTracker
//
//  Created by James Poole on 29/04/23.
//

import SwiftUI

struct PageIntro: Identifiable, Hashable {
    var id: UUID = .init()
    var introAssetImage: String
    var title: String
    var subTitle: String
    var displaysAction: Bool = false
    var displaysView: Bool = false
    
}

var pageIntros: [PageIntro] = [
    .init(introAssetImage: "TimeTracking", title: "Welcome to\nShiftTracker", subTitle: "Hey there! This is ShiftTracker, your new buddy for handling work stuff."),
    .init(introAssetImage: "LostTime", title: "Track your time", subTitle: "Ever lost track of time at work? Don't worry, we've got you. Log your hours with a single tap."),
    .init(introAssetImage: "LiveEarnings", title: "Live earnings", subTitle: "Track earnings in real-time. Our Lock Screen widgets offer a quick glance at your current earnings.", displaysView: true),
    .init(introAssetImage: "MultipleJobs", title: "Handle multiple jobs", subTitle: "More than one job? No problem. Switch between jobs like a pro and keep everything sorted."),
    .init(introAssetImage: "LocationBased", title: "Location-based clock in & out", subTitle: "Just walk into your work, and we'll clock you in. Same for when you leave. It's that simple."),
    .init(introAssetImage: "Scheduling", title: "Schedule shifts", subTitle: "Put your shift times in, and we'll make sure you never forget. No more oops-I-forgot-my-shift moments."),
  //  .init(introAssetImage: "Invoicing", title: "Invoice generation", subTitle: "Tired of messing with pay calculations? Just tell us your pay period, and we'll pop out those invoices."),
    .init(introAssetImage: "Statistics", title: "Statistics & Summaries", subTitle: "Wanna know more about your work patterns? We've got cool charts and summaries to help you out."),
    .init(introAssetImage: "SignUp", title: "Get Started", subTitle: "Ready to make shift tracking a breeze? Let's start by adding your first job.", displaysAction: true),
]
