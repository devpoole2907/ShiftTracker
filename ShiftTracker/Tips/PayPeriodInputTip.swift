//
//  PayPeriodInputTip.swift
//  ShiftTracker
//
//  Created by James Poole on 24/12/23.
//

import TipKit


@available(iOS 17.0, *)
struct PayPeriodInputTip: TipKit.Tip {
    var title: Text {
        Text("Pay Periods")
    }


    var message: Text? {
        Text("Input the date your last pay period ended. This cannot be modified after being set.")
    }


    var image: Image? {
        Image(systemName: "dollarsign.circle.fill")
    }
}


