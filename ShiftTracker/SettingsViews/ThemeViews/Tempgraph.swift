//
//  Tempgraph.swift
//  testEnvironment
//
//  Created by Louis Kolodzinski on 4/07/23.
//

import SwiftUI
import Charts

struct TempGraph: View {
    
    @EnvironmentObject var themeColors: ThemeDataManager
    
    var body: some View {
        
        Chart{
            BarMark(
                x: .value("Shape Type", data[0].type),
                y: .value("Total Count", data[0].count)
            ).foregroundStyle(themeColors.earningsColor)
                .cornerRadius(10)
            BarMark(
                x: .value("Shape Type", data[1].type),
                y: .value("Total Count", data[1].count)
            ).foregroundStyle(themeColors.timerColor)
                .cornerRadius(10)
            BarMark(
                x: .value("Shape Type", data[2].type),
                y: .value("Total Count", data[2].count)
            ).foregroundStyle(themeColors.breaksColor)
                .cornerRadius(10)
            
        }
    }
}

struct ToyShape: Identifiable {
    var type: String
    var count: Double
    var id = UUID()
}
var data: [ToyShape] = [
    .init(type: "Mon", count: 5),
    .init(type: "Tue", count: 3),
    .init(type: "Wed", count: 4),
    .init(type: "Thu", count: 5),
    .init(type: "Fri", count: 6),
    .init(type: "Sat", count: 2)
]

    struct TempGraph_Previews: PreviewProvider {
        static var previews: some View {
            TempGraph()
                .environmentObject(ThemeDataManager()) // Add any necessary environment objects
        }
    }


