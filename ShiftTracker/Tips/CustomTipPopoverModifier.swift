//
//  CustomTipPopoverModifier.swift
//  ShiftTracker
//
//  Created by James Poole on 9/03/24.
//

import Foundation
import TipKit

struct CustomTipPopoverModifier: ViewModifier {
    
    var title: String
    var body: String
    var icon: String
    var position: Edge
    

    init(title: String, body: String, icon: String, position: Edge) {
        self.title = title
        self.body = body
        self.icon = icon
        self.position = position
    }
    
    
    @ViewBuilder
        func body(content: Content) -> some View {
            if #available(iOS 17.0, *) {
                let tip = GenericTip(titleString: title, bodyString: body, icon: icon)
                content.popoverTip(tip, arrowEdge: position)
            } else {
                content
            }
        }
    
}

extension View {
    func customTipPopover(title: String, body: String, icon: String, position: Edge) -> some View {
        self.modifier(CustomTipPopoverModifier(title: title, body: body, icon: icon, position: position))
    }
}
