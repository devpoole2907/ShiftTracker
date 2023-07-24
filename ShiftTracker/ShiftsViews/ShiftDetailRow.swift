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
        let payString = String(format: "%.2f", shift.taxedPay)
        
        let job = shift.job
        
        if jobSelectionViewModel.fetchJob(in: viewContext) != nil {
            
            
          
                
                VStack(alignment: .leading, spacing: 5){
                    HStack{
                        Text("\(currencyFormatter.currencySymbol ?? "")\(payString)")
                            .foregroundColor(textColor)
                            .font(.title)
                            .bold()
                        
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
                        .font(.subheadline)
                        .bold()
                    Text(dateString)
                        .foregroundColor(.gray)
                        .font(.footnote)
                        .bold()
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
                            .foregroundStyle(Color(red: Double(job?.colorRed ?? 0.0), green: Double(job?.colorGreen ?? 0.0), blue: Double(job?.colorBlue ?? 0.0)))
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
                    
                    Text(shiftManager.formatTime(timeInHours: duration))
                        .foregroundStyle(.gray)
                        .font(.subheadline)
                        .bold()
                    Text(dateString)
                        .foregroundColor(.gray)
                        .font(.footnote)
                        .bold()
                }
                
                Spacer()
                
                
                    Text("\(currencyFormatter.currencySymbol ?? "")\(payString)")
                        .foregroundColor(textColor)
                        .font(.title3)
                        .bold()
                        //.padding(.ver)
                    
                 
                
            }.frame(alignment: .leading)
            
            
        }
        
        
    }
}
