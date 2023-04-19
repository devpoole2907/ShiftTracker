//
//  HighlightView.swift
//  ShiftTracker
//
//  Created by James Poole on 20/04/23.
//

import SwiftUI
import Charts

struct HighlightView: View {
    var title: String
    var subtitle: String
    var titleColor: Color
    var subtitleColor: Color
    var average: Double?
    var lastWeekAverage: Double?
    var thisWeekAverage: Double?
    
    let statsMode: StatsMode
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 2 // Add this line to limit to 2 decimal places
        return formatter
    }

    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .foregroundColor(titleColor)
                .font(.subheadline)
                .bold()
            Text(subtitle)
                .foregroundColor(subtitleColor)
                .font(.subheadline)
                .bold()
        }
        Section{
            VStack{
                HStack{
                    Text("")
                        .foregroundColor(subtitleColor)
                        .font(.title)
                        .bold()
                    Text("")
                        .foregroundColor(subtitleColor)
                        .font(.subheadline)
                        .bold()
                }
                Spacer()
                
                if let lastWeekAverage = lastWeekAverage {
                    if let thisWeekAverage = thisWeekAverage {
                        Chart {
                            BarMark(
                                x: .value("Average", thisWeekAverage)
                            ).foregroundStyle(statsMode == .earnings ? Color.green :
                                                statsMode == .hours ? Color.orange :
                                                statsMode == .breaks ? Color.indigo :
                                                Color.black)
                            .annotation(position: .trailing) {
                                Text("\(statsMode == .earnings ? currencyFormatter.string(from: NSNumber(value: thisWeekAverage)) ?? "" : String(format: "%.1f", thisWeekAverage))\(statsMode == .earnings ? "" : " hrs")")
                                
                                
                                    .foregroundColor(subtitleColor)
                                    .bold()
                                    .font(.title3)
                            }
                        }.frame(height: 55)
                            .padding(.bottom, 10)
                            .padding(.top, -15)
                        
                        Chart {
                            BarMark(
                                x: .value("Average", lastWeekAverage)
                            ).foregroundStyle(statsMode == .earnings ? Color.green :
                                                statsMode == .hours ? Color.orange :
                                                statsMode == .breaks ? Color.indigo :
                                                Color.black)
                            .annotation(position: .trailing) {
                                Text("\(statsMode == .earnings ? currencyFormatter.string(from: NSNumber(value: lastWeekAverage)) ?? "" : String(format: "%.1f", lastWeekAverage))\(statsMode == .earnings ? "" : " hrs")")
                                
                                
                                    .foregroundColor(subtitleColor)
                                    .bold()
                                    .font(.title3)
                            }
                        }.frame(height: 55)
                            .padding(.bottom, 10)
                            .padding(.top, -15)
                    }
                }
                else if let average = average {
                    Chart {
                        BarMark(
                            x: .value("Average", average)
                        ).foregroundStyle(statsMode == .earnings ? Color.green :
                                            statsMode == .hours ? Color.orange :
                                            statsMode == .breaks ? Color.indigo :
                                            Color.black)
                        .annotation(position: .trailing) {
                            Text("\(statsMode == .earnings ? currencyFormatter.string(from: NSNumber(value: average)) ?? "" : String(format: "%.1f", average))\(statsMode == .earnings ? "" : " hrs")")
                            
                            
                                .foregroundColor(subtitleColor)
                                .bold()
                                .font(.title3)
                        }
                    }.frame(height: 55)
                        .padding(.bottom, 10)
                        .padding(.top, -15)
                    
                }
            }
            //.padding(.bottom, 50)
            //.padding(.top, 10)
        }
    }
}

