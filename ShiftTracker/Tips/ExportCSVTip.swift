//
//  ExportCSVTip.swift
//  ShiftTracker
//
//  Created by James Poole on 9/03/24.
//


import TipKit


@available(iOS 17.0, *)
struct ExportCSVTip: TipKit.Tip {
    var title: Text {
        Text("CSV Exporting")
    }


    var message: Text? {
        Text("You can select specific shifts you wish to export in the ") +
        Text("Latest Shifts").italic() +
        Text(" and ") +
        Text("Activity").italic() +
        Text(" screens.")

    }


    var image: Image? {
        Image(systemName: "tablecells")
    }
}
