//
//  OvertimePanel.swift
//  ShiftTracker
//
//  Created by James Poole on 8/10/23.
//

import SwiftUI

struct OvertimePanel: View {
    
    @Binding var enabled: Bool
    @Binding var rate: Double
    @Binding var applyAfter: TimeInterval
    
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10){
            Toggle(isOn: $enabled) {
                HStack {
                    Text("Overtime").bold()
                }
            }
            .toggleStyle(CustomToggleStyle())
            
            Stepper(value: $rate, in: 1.25...3, step: 0.25) {
                
                HStack(spacing: 3) {
                    Text("Rate:").bold()
                    Text("\(rate, specifier: "%.2f")x")
                }
                
            }.disabled(!enabled)
            
            if #available(iOS 16.1, *){
                
                HStack {
                    
                    Text("Apply after:").bold()
                    TimePicker(timeInterval: $applyAfter)
                        .frame(maxHeight: 75)
                        .frame(maxWidth: getRect().width - 100)
                    
                }
                .disabled(!enabled)
                .opacity(enabled ? 1.0 : 0.5)
           
                
            } else {
                
                // due to a frame issue with wheel pickers on iOS 16 or lower, time picker is a sheet in those versions
                
                Button(action: action ){
                    HStack {
                        
                        Text("Apply after: ")
                        Spacer()
                        Text("\(formattedTimeInterval(applyAfter))")
                        
                        
                    }
                }
            }
            
            
        }.padding(.horizontal)
            .padding(.vertical, 10)
            .glassModifier(cornerRadius: 20)
    }
}
