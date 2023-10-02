//
//  CustomChartModifiers.swift
//  ShiftTracker
//
//  Created by James Poole on 2/10/23.
//

import SwiftUI
import Charts

struct CustomChartXScale: ViewModifier {
    
    let useScale: Bool
    let domain: ClosedRange<Date>
    
    func body(content: Content) -> some View {
        if useScale {
            content
                .chartXScale(domain: domain, type: .linear)
        } else {
            content
        }
    }
}

extension View {
    func customChartXScale(useScale: Bool = true, domain: ClosedRange<Date>) -> some View {
        self.modifier(CustomChartXScale(useScale: useScale, domain: domain))
    }
}

struct CustomChartXSelection: ViewModifier {
    
    @Binding var selection: Date?
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            
            content.chartXSelection(value: $selection)
            
        } else {
            content
        }
    }
    
    
    
}

extension View {
    func customChartXSelectionModifier(selection: Binding<Date?>) -> some View {
        self.modifier(CustomChartXSelection(selection: selection))
    }
}

struct CustomChartOverlayModifier<V: View>: ViewModifier {
    
    // this overlay enabled is somewhat redudant now that we've discovered we can't use the gestures with tab view.
    
    @Binding var overlayEnabled: Bool
    let overlayContent: (ChartProxy) -> V
    
    func body(content: Content) -> some View {
        
        if #available(iOS 17.0, *) {
            // do nothing, use built-in modifier .chartXselection
            
            content
            
        } else {
            
            if overlayEnabled {
                content.chartOverlay(content: overlayContent)
            } else {
                content
            }
            
        }
    }
    
    
}

extension View {
    
    func conditionalChartOverlay<V: View>(overlayEnabled: Binding<Bool>, content: @escaping (ChartProxy) -> V) -> some View {
        
        self.modifier(CustomChartOverlayModifier(overlayEnabled: overlayEnabled, overlayContent: content))
        
    }
    
}
