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
    
}

var pageIntros: [PageIntro] = [
    .init(introAssetImage: "TimeTracking", title: "Welcome to\nShiftTracker", subTitle: "A brief description of this app will go here"),
    .init(introAssetImage: "TimeTracking", title: "Track your time", subTitle: "Track some time etc, more description."),
    .init(introAssetImage: "Scheduling", title: "Schedule shifts", subTitle: "Enter your roster, and get reminded when you have an upcoming shift"),
        .init(introAssetImage: "Invoicing", title: "Invoice generation", subTitle: "Input your pay periods, and automatically generate invoices"),
    .init(introAssetImage: "Statistics", title: "Statistics & Summaries", subTitle: "View in depth statistics and summaries"),
    .init(introAssetImage: "SignUp", title: "Get Started", subTitle: "Lets start ShiftTracking.", displaysAction: true),
          ]
