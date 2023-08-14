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
    
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    
    let shiftManager = ShiftDataManager()
    
    
    
    let shift: OldShift
    
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
        let duration = shiftEndDate.timeIntervalSince(shiftStartDate) / 3600.0
        
        let dateString = dateFormatter.string(from: shiftStartDate)
        let payString = String(format: "%.2f", shift.totalPay)
        let taxedPay = String(format: "%.2f", shift.taxedPay)
        let payMultiplier = String(format: "%.2f", shift.payMultiplier)
        
        let job = shift.job
        
        if jobSelectionViewModel.fetchJob(in: viewContext) != nil {
            
            
            
            HStack{
            VStack(alignment: .leading, spacing: 5){
                HStack{
                    Text("\(currencyFormatter.currencySymbol ?? "")\(payString)")
                        .foregroundStyle(textColor)
                        .font(.title)
                        .bold()
                    
                    if shift.taxedPay > 0 {
                        HStack(spacing: 2){
                            Image(systemName: "chart.line.downtrend.xyaxis")
                            Text("\(currencyFormatter.currencySymbol ?? "")\(taxedPay)")
                                .monospacedDigit()
                                .bold()
                                .lineLimit(1)
                                .allowsTightening(true)
                        }.foregroundStyle(themeManager.taxColor)
                            .font(.subheadline)
                            .fontDesign(.rounded)
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
                Text(shiftManager.formatTime(timeInHours: duration))
                    .foregroundStyle(themeManager.timerColor)
                    .fontDesign(.rounded)
                    .font(.subheadline)
                    .bold()
                Text(dateString)
                    .fontDesign(.rounded)
                    .foregroundColor(.gray)
                    .font(.footnote)
                    .bold()
            }
                
                Spacer()
                
                if shift.multiplierEnabled {
                    Text("\(payMultiplier)x")
                        .font(.caption)
                        .bold()
                        .fontDesign(.rounded)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
        }
                
                
                
            
            
        } else {
            
            
            HStack{
                
                VStack(spacing: 3){
                    HStack{
                        Image(systemName: job?.icon ?? "briefcase.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                        
                    }
                    .padding(12)
                    .background {
                        
                        Circle()
                            .foregroundStyle(Color(red: Double(job?.colorRed ?? 0.0), green: Double(job?.colorGreen ?? 0.0), blue: Double(job?.colorBlue ?? 0.0)).gradient)
                            .frame(width: 40, height: 40)
                        
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

                    
                }.frame(width: 40, alignment: .center)
                    .padding(10)
                VStack(alignment: .leading, spacing: 3){
                    
                    Text(job?.name ?? "Unknown")
                        .font(.title2)
                        .bold()
                        .lineLimit(1)
                    HStack(spacing: 4){
                        Text(shiftManager.formatTime(timeInHours: duration))
                            .foregroundStyle(.gray)
                            .fontDesign(.rounded)
                            .font(.subheadline)
                            .bold()
                        
                        if shift.multiplierEnabled {
                            Text("\(payMultiplier)x")
                                .font(.caption)
                                .bold()
                                .fontDesign(.rounded)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                        Text(dateString)
                            .foregroundColor(.gray)
                            .fontDesign(.rounded)
                            .font(.footnote)
                            .bold()
                        
                        
                        
                    
                }
                
                Spacer()
                
                VStack(spacing: 3){
                    Text("\(currencyFormatter.currencySymbol ?? "")\(payString)")
                        .foregroundColor(textColor)
                        .font(.title3)
                        .bold()
                        .fontDesign(.rounded)
                    //.padding(.ver)
                    
                    if shift.taxedPay > 0 {
                        HStack(spacing: 2){
                            Image(systemName: "chart.line.downtrend.xyaxis")
                            Text("\(currencyFormatter.currencySymbol ?? "")\(taxedPay)")
                                .bold()
                                .lineLimit(1)
                                .allowsTightening(true)
                        }.foregroundStyle(themeManager.taxColor)
                            .font(.caption)
                            .fontDesign(.rounded)
                    }
                    
                    
                    
                    
                }
                 
                
            }.frame(alignment: .leading)
            
            
        }
        
        
    }
}
