//
//  ScheduledShiftListRow.swift
//  ShiftTracker
//
//  Created by James Poole on 2/10/23.
//

import SwiftUI

struct ScheduledShiftListRow: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var shiftStore: ShiftStore
    @EnvironmentObject var scheduleModel: SchedulingViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    let shift: SingleScheduledShift
    
    @AppStorage("lastSelectedJobUUID") private var lastSelectedJobUUID: String?
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
    
    func formattedDuration() -> String {
        let interval = shift.endDate.timeIntervalSince(shift.startDate )
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
    
    var body: some View {
                
                ZStack{
                    VStack(alignment: .leading){
                        
                        HStack(spacing : 10){
                            
                            VStack(spacing: 3){
                                
                                JobIconView(icon: shift.job?.icon ?? "briefcase.fill", color: Color(red: Double(shift.job?.colorRed ?? 0), green: Double(shift.job?.colorGreen ?? 0), blue: Double(shift.job?.colorBlue ?? 0)), font: .title3, padding: 12)
                                
                             
                                
                                HStack(spacing: 5){
                                    
                                    ForEach(Array(shift.tags), id: \.self) { tag in
                                            Circle()
                                                .foregroundStyle(Color(red: tag.colorRed, green: tag.colorGreen, blue: tag.colorBlue))
                                                .frame(width: 8, height: 8)
                                        }
                                    
                                }
                                
                                
                            }
                                
                               
                                .frame(width: UIScreen.main.bounds.width / 7)
                            VStack(alignment: .leading, spacing: 3){
                                Text(shift.job?.name ?? "")
                                    .font(.title2)
                                    .bold()
                                Text(shift.job?.title ?? "")
                                    .foregroundColor(Color(red: Double(shift.job?.colorRed ?? 0), green: Double(shift.job?.colorGreen ?? 0), blue: Double(shift.job?.colorBlue ?? 0)))
                                    .font(.subheadline)
                                    .bold()
                                    .roundedFontDesign()
                                
                                Text("\(dateFormatter.string(from: shift.startDate )) - \(dateFormatter.string(from: shift.endDate ))")
                                    .bold()
                                    .roundedFontDesign()
                                    .foregroundStyle(.gray)
                                    .font(.footnote)
                                
                                
                            }
                            Spacer()
                
                        }//.padding()
                        
                    }
                    VStack(alignment: .trailing){
                        HStack{
                            Spacer()
                            Menu{
                                if let shift = scheduleModel.fetchScheduledShift(id: shift.id, in: viewContext) {
                                    ScheduledShiftRowSwipeButtons(shift: shift, showText: true)
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .bold()
                                    .font(.title3)
                            }.contentShape(Rectangle())
                            
                            
                        }.padding(.top)
                        Spacer()
                        Text(formattedDuration())
                            .foregroundStyle(.gray)
                            .bold()
                            .padding(.bottom)
                            .roundedFontDesign()
                    }
                    
                    
                    
                }
            .opacity(!purchaseManager.hasUnlockedPro ? (shift.job?.uuid?.uuidString != lastSelectedJobUUID ? 0.5 : 1.0) : 1.0)
        
    }
}
