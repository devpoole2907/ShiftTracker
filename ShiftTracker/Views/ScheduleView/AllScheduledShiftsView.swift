//
//  AllScheduledShiftsView.swift
//  ShiftTracker
//
//  Created by James Poole on 16/05/23.
//

import SwiftUI
import CoreData

struct AllScheduledShiftsView: View {
    
    @EnvironmentObject var shiftStore: ShiftStore
    @EnvironmentObject var scheduleModel: SchedulingViewModel
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @Binding var navPath: NavigationPath
    
    @Environment(\.colorScheme) var colorScheme
    
    static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, d MMM"
            return formatter
        }()
    
    var nextShiftDate: Date? {
        let currentDate = Date()
        return shiftStore.shifts
            .compactMap { $0.startDate.startOfTheDay() }
            .filter { $0 >= currentDate.startOfTheDay() }
            .min()
    }
    
    private var allShiftsDict: [UUID: OldShift] {
        Dictionary(uniqueKeysWithValues: allShifts.map { ($0.shiftID ?? UUID(), $0) })
       }
    
    @FetchRequest(
                sortDescriptors: ShiftSort.default.descriptors,
                animation: .default)
            private var allShifts: FetchedResults<OldShift>

    
    var body: some View {
        
        let textColor: Color = colorScheme == .dark ? .white : .black
        
        
        if !scheduleModel.isEmpty {
            

            
            ScrollViewReader { scrollProxy in
                List {
                    ForEach(scheduleModel.groupedShifts.keys.sorted(by: <), id: \.self) { date in
                        Section {
                            ForEach(scheduleModel.groupedShifts[date] ?? [], id: \.self) { shift in
                                
                                if let oldShift = allShiftsDict[shift.id] {
                                    NavigationLink(value: oldShift) {
                                        ScheduledShiftRow(shift: shift)
                                            .environmentObject(shiftStore)
                                            .environmentObject(scheduleModel)
                                    }
                                    .swipeActions {
                                        
                                        Button(action: {
                                            shiftStore.deleteOldShift(oldShift, in: viewContext)
                                            
                                            Task {
                                                await scheduleModel.loadGroupedShifts(shiftStore: shiftStore, scheduleModel: scheduleModel)
                                            }
                                            
                                        }) {
                                            Image(systemName: "trash")
                                        }.tint(Color.clear)
                                    }
                                    
                                }
                                                      else {
                                                               ScheduledShiftRow(shift: shift)
                                                                    .environmentObject(shiftStore)
                                                                    .environmentObject(scheduleModel)
                                                                    .padding(.trailing)
                                                          
                                                          
                                                                    .swipeActions(allowsFullSwipe: false) {
                                                                        if let shift = scheduleModel.fetchScheduledShift(id: shift.id, in: viewContext) {
                                                                            ScheduledShiftRowSwipeButtons(shift: shift)
                                                                        }
                                                                    }
                                                          
                                                            }
                            }
                            
                        } header: { Text(Self.dateFormatter.string(from: date)).textCase(.uppercase).bold().foregroundColor(Calendar.current.isDateInToday(date) ? .cyan : textColor)
                          
                          }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .foregroundColor(date < Date() ? .gray : textColor)
                    }
                    
                    Spacer(minLength: 100)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    
                }
                  //
                .onAppear {
                    
                    
                    print("Should scroll is \(scheduleModel.shouldScrollToNextShift)")
                
                   
                    if let nextShiftDate = nextShiftDate, scheduleModel.shouldScrollToNextShift {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            scrollProxy.scrollTo(nextShiftDate, anchor: .top)
                        }
                    }
                    
                    scheduleModel.shouldScrollToNextShift = false
                    
                }
                
                .navigationDestination(for: OldShift.self) { shift in
                    
                    
                    DetailView(shift: shift, navPath: $navPath)
                    
                    
                }
                
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                .background(.ultraThinMaterial)
                
            }
        
          
        
        
        } else {
            ZStack {
                Color.clear
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()

                Text("You don't have any shifts scheduled.")
                    .bold()
                    .padding()
            }

        }
    }
    

    
    
}



