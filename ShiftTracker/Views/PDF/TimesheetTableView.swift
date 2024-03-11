//
//  TimesheetTableView.swift
//  ShiftTracker
//
//  Created by James Poole on 11/03/2024.
//

import SwiftUI

struct TimesheetTableView: View {
    
    var tableCells: [ShiftTableCell]
    
    var showDescription: Bool
    
    let shiftManager = ShiftDataManager()
    
    var body: some View {
        
        // overtime is spewing the total time for some reason, omit for now
       
                    Grid {
                        GridRow {
                            Text("Date")
                            if showDescription {
                                Text("Description of Work")
                            }
                            Text("Start")
                            Text("Finish")
                            Text("Break")
                          //  Text("Overtime")
                            Text("Total")
                        }
                        .bold()
                        Divider()
                        ForEach(tableCells) { cell in
                            GridRow {
                                
                                if !cell.isEmpty {
                                    
                                    Text("\(cell.date.formatted(date: .abbreviated, time: .omitted))")
                                    
                                    if showDescription {
                                        Text("\(cell.notes)").frame(maxWidth: 65)
                                    }
                                    
                                    Text("\(cell.startTime.formatted(date: .omitted, time: .shortened))")
                                    Text("\(cell.endtime.formatted(date: .omitted, time: .shortened))")
                                    Text("\(shiftManager.formatTime(timeInHours: cell.breakDuration / 3600))")
                                 //   Text("\(shiftManager.formatTime(timeInHours: cell.overtimeDuration / 3600))")
                                    Text("\(shiftManager.formatTime(timeInHours: cell.duration / 3600))")
                                } else {
                                    Text(" ").hidden()
                                                           Text(" ").hidden()
                                                           Text(" ").hidden()
                                                           Text(" ").hidden()
                                }
                            }
                            
                        }
                    }.font(.system(size: 8))
                .foregroundStyle(.black)
       
        
    }
    
}

