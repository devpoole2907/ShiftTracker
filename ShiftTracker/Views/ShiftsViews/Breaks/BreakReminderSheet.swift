//
//  BreakReminderSheet.swift
//  ShiftTracker
//
//  Created by James Poole on 21/12/23.
//

import SwiftUI

struct BreakReminderSheet: View {
    
    @Binding var breakReminderDate: Date
    @Binding var breakReminderTime: TimeInterval
    var actionDate: Date
    @Binding var enableReminder: Bool

    
    var body: some View {
        
        
            
       
                
                NavigationStack {
                    VStack {
                        
                        DatePicker(
                                            "Time",
                                            selection: $breakReminderDate,
                                            in: actionDate...(actionDate.addingTimeInterval(24 * 60 * 60)),
                                            displayedComponents: [.date, .hourAndMinute]
                        ).labelsHidden()
                       
                            .onChange(of: breakReminderDate) { newValue in
                                              
                                
                                breakReminderTime = newValue.timeIntervalSince(actionDate)
                                
                                          }
                        
                        TimePicker(timeInterval: $breakReminderTime)
                        
                        
                        
                            .onChange(of: breakReminderTime) { newTime in
                                if newTime <= 0 {
                                    enableReminder = false
                                } else {
                                    let newReminderDate = actionDate.addingTimeInterval(newTime)
                                    breakReminderDate = newReminderDate
                                }
                            }
                        
                        
                        Toggle(isOn: $enableReminder){
                            
                            Text("Break Reminder").bold()
                            
                        }.toggleStyle(CustomToggleStyle())
                            .padding(.horizontal)
                            .frame(maxWidth: UIScreen.main.bounds.width - 80)
                            .padding(.vertical, 10)
                            .glassModifier(cornerRadius: 20)
                        
                            .onChange(of: enableReminder) { value in
                                
                                if value && breakReminderTime <= 0 {
                                    
                                        breakReminderTime = 6000
                                    
                                }
                                
                            }
                        
                        
                        Spacer()
                        
                    }.onAppear {
                        
                        
                        breakReminderDate = actionDate.addingTimeInterval(breakReminderTime)
                        
                                  }
                    
                    .trailingCloseButton()
                    .navigationTitle("Break Reminder")
                    .navigationBarTitleDisplayMode(.inline)
                }
         
           
            
        
        
        
    }
}


