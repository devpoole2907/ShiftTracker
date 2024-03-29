//
//  ShiftDetailRow.swift
//  ShiftTracker
//
//  Created by James Poole on 30/06/23.
//

import SwiftUI

struct ShiftDetailRow: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) var viewContext
    
    @EnvironmentObject var themeManager: ThemeDataManager
    
    @EnvironmentObject var selectedJobManager: JobSelectionManager
    
    let shiftManager = ShiftDataManager()
    
    
    
    let shift: OldShift
    
    var showTime: Bool = false
    
    init(shift: OldShift, showTime: Bool = false){
        
        self.showTime = showTime
        self.shift = shift
        
    }
    
    var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM"
        return formatter
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
    
    var body: some View {
        
        let textColor: Color = colorScheme == .dark ? .white : .black
        
        let shiftStartDate = shift.shiftStartDate ?? Date()
        let shiftEndDate = shift.shiftEndDate ?? Date()
        let duration = shift.duration / 3600.0
        
        let dateString = dateFormatter.string(from: shiftStartDate)
        let payString = String(format: "%.2f", shift.totalPay)
        let taxedPay = String(format: "%.2f", shift.taxedPay)
        let payMultiplier = String(format: "%.2f", shift.payMultiplier)
        
        let breakDuration = shift.breakDuration / 3600.0
        
        let job = shift.job
        
        if selectedJobManager.fetchJob(in: viewContext) != nil {

            VStack(alignment: .leading, spacing: 5){
                HStack{
                    Text("\(currencyFormatter.currencySymbol ?? "")\(payString)")
                        .foregroundStyle(textColor)
                        .font(.title)
                        .bold()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    if shift.taxedPay != shift.totalPay {
                        HStack(spacing: 2){
                            Image(systemName: "chart.line.downtrend.xyaxis")
                            Text("\(currencyFormatter.currencySymbol ?? "")\(taxedPay)")
                                .monospacedDigit()
                                .bold()
                                .lineLimit(1)
                                .allowsTightening(true)
                                .minimumScaleFactor(0.5)
                        }.foregroundStyle(themeManager.taxColor)
                            .font(.subheadline)
                            .roundedFontDesign()
                    }
                    
                    
                    HStack(spacing: 5){
                        if let tagSet = shift.tags as? Set<Tag> {
                            ForEach(Array(tagSet), id: \.self) { tag in
                                Circle()
                                    .foregroundStyle(Color(red: tag.colorRed, green: tag.colorGreen, blue: tag.colorBlue))
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                    
                }
                
                HStack(spacing: 6){
                Text(shiftManager.formatTime(timeInHours: duration))
                    .foregroundStyle(themeManager.timerColor)
                    .roundedFontDesign()
                    .font(.subheadline)
                    .bold()
                
                
                
                if shift.multiplierEnabled {
                    Text("x\(payMultiplier)")
                        .font(.caption)
                        .bold()
                        .roundedFontDesign()
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5))
                        .cornerRadius(6)
                }
                    if shift.breakDuration > 0 {
                        Text(shiftManager.formatTime(timeInHours: breakDuration))
                            .foregroundStyle(themeManager.breaksColor)
                            .roundedFontDesign()
                            .font(.subheadline)
                            .bold()
                    }
            }
                
                
                Text(showTime ? "\(timeFormatter.string(from: shiftStartDate )) - \(timeFormatter.string(from: shiftEndDate ))" : dateString)
                    .roundedFontDesign()
                    .foregroundColor(.gray)
                    .font(.footnote)
                    .bold()
            } .padding(.horizontal, 5)

            
                
                
                
            
            
        } else {
            
            
            HStack{
                
                VStack(spacing: 3){
                    
                    JobIconView(icon: job?.icon ?? "briefcase.fill", color: Color(red: Double(job?.colorRed ?? 0.0), green: Double(job?.colorGreen ?? 0.0), blue: Double(job?.colorBlue ?? 0.0)), font: .title3, padding: 12)
                    
              
                    
                    
                    HStack(spacing: 5){
                        if let tagSet = shift.tags as? Set<Tag> {
                            ForEach(Array(tagSet), id: \.self) { tag in
                                Circle()
                                    .foregroundStyle(Color(red: tag.colorRed, green: tag.colorGreen, blue: tag.colorBlue))
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }

                    
                }.frame(width: 40, alignment: .center)
                    .padding(10)
                VStack(alignment: .leading, spacing: 3){
                    
                    Text(job?.name ?? "Unknown")
                        .font(.title2)
                        .bold()
                        .lineLimit(1)
                    HStack(spacing: 6){
                        Text(shiftManager.formatTime(timeInHours: duration))
                            .foregroundStyle(.gray)
                            .roundedFontDesign()
                            .font(.subheadline)
                            .bold()
                        
                        if shift.multiplierEnabled {
                            Text("x\(payMultiplier)")
                                .font(.caption)
                                .bold()
                                .roundedFontDesign()
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5))
                                .cornerRadius(6)
                        }
                        
                        if shift.breakDuration > 0 {
                            Text(shiftManager.formatTime(timeInHours: breakDuration))
                                .foregroundStyle(themeManager.breaksColor)
                                .roundedFontDesign()
                                .font(.caption)
                                .bold()
                        }
                        
                    }
                    Text(showTime ? "\(timeFormatter.string(from: shiftStartDate )) - \(timeFormatter.string(from: shiftEndDate ))" : dateString)
                        .roundedFontDesign()
                        .foregroundColor(.gray)
                        .font(.footnote)
                        .bold()
                        
                        
                        
                    
                }
                
                Spacer()
                
                VStack(spacing: 3){
                    Text("\(currencyFormatter.currencySymbol ?? "")\(payString)")
                        .foregroundColor(textColor)
                        .font(.title3)
                        .bold()
                        .roundedFontDesign()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    if shift.taxedPay != shift.totalPay {
                        HStack(spacing: 2){
                            Image(systemName: "chart.line.downtrend.xyaxis")
                            Text("\(currencyFormatter.currencySymbol ?? "")\(taxedPay)")
                                .bold()
                                .lineLimit(1)
                                .allowsTightening(true)
                                .minimumScaleFactor(0.5)
                        }.foregroundStyle(themeManager.taxColor)
                            .font(.caption)
                            .roundedFontDesign()
                    }
                    
                    
                    
                    
                }
                 
                
            }.frame(alignment: .leading)
                .padding(.horizontal, 5)

            
        }
        
        
    }
}
