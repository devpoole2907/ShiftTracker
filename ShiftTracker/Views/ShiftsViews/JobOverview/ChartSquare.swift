//
//  ChartSquare.swift
//  ShiftTracker
//
//  Created by James Poole on 2/07/23.
//

import SwiftUI
import Charts
import CoreData

struct ChartSquare: View {
    
    @EnvironmentObject var shiftManager: ShiftDataManager
    @EnvironmentObject var selectedJobManager: JobSelectionManager
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var viewModel: ChartSquareViewModel
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
                formatter.dateFormat = "E"
        return formatter
    }
    
    init(shifts: FetchedResults<OldShift>, statsMode: StatsMode) {
        viewModel = ChartSquareViewModel(shifts: shifts, statsMode: statsMode)
    }
    
    var body: some View {
        VStack(alignment: .center) {
            navHeader
            weeklyChart
        }
        .padding(.vertical, 8)
        .glassModifier(cornerRadius: 12, applyPadding: false)
    }
    
    var navHeader: some View {
        let headerColor: Color = colorScheme == .dark ? .white : .black
        return HStack(spacing: 5){
            NavigationLink(value: 2) {
                Text("Activity")
                    .font(.callout)
                    .bold()
                    .foregroundStyle(headerColor)
                    .padding(.leading)
            }
            Spacer()
        }
    }
    
    var weeklyChart: some View {
        Chart {
            ForEach(viewModel.weeklyData.indices, id: \.self) { index in
                let yValue = viewModel.weeklyData[index]
                BarMark(
                    x: .value("Day", Calendar.current.date(byAdding: .day, value: -index, to: Date()) ?? Date(), unit: .weekday),
                    y: .value(shiftManager.statsMode.description, yValue),
                    width: 6
                )
                .foregroundStyle(shiftManager.statsMode.gradient)
                .clipShape(Capsule())
            }
        }
        
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 1)) { value in
                if let date = value.as(Date.self) {
                    let fullWeekdayString = dateFormatter.string(from: date)
                    let shortWeekdayString = String(fullWeekdayString.prefix(1))
                    AxisValueLabel(shortWeekdayString, centered: true, collisionResolution: .disabled)
                }
            }
        }

        .chartYAxis(.hidden)
        .padding(.horizontal, 10)
    }
}



