//
//  GenericTip.swift
//  ShiftTracker
//
//  Created by James Poole on 9/03/24.
//

import Foundation
import TipKit


@available(iOS 17.0, *)
struct GenericTip: TipKit.Tip {
    
    var titleString: String
    var bodyString: String
    var icon: String
    
    var title: Text {
        Text(titleString)
    }


    var message: Text? {
        
        Text(bodyString)

    }


    var image: Image? {
        Image(systemName: icon)
    }
}
