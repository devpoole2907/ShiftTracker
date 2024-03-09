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
    
    @Binding var navPath: NavigationPath
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
                formatter.dateFormat = "E"
        return formatter
    }
    
    init(shifts: FetchedResults<OldShift>, statsMode: StatsMode, navPath: Binding<NavigationPath>) {
        viewModel = ChartSquareViewModel(shifts: shifts, statsMode: statsMode)
        _navPath = navPath
    }
    
    var body: some View {
        
        ZStack {
            
            Button(action: {navPath.append(2)}){
                VStack(alignment: .center) {
                    
                    navHeader
                    weeklyChart
                    
                }
            }.buttonStyle(PlainButtonStyle())
            
            // not sure why this was like this, come back later if any issue crops up
          //  NavigationLink(value: 2) { EmptyView() }.opacity(0.0)
            
            
            
        }
        .padding(.vertical, 8)
        .glassModifier(cornerRadius: 12, applyPadding: false)
    }
    
    var navHeader: some View {
        let headerColor: Color = colorScheme == .dark ? .white : .black
        return HStack(spacing: 5){
            
                Text("Activity")
                    .font(.callout)
                    .bold()
                    .foregroundStyle(headerColor)
                    .padding(.leading)
            
            Image(systemName: "chevron.right")
                .bold()
                .font(.caption)
                .font(.callout)
                .foregroundStyle(.gray)
    
            
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



