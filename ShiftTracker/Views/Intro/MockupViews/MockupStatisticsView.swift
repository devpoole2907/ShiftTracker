//
//  MockupStatisticsView.swift
//  ShiftTracker
//
//  Created by James Poole on 25/09/23.
//

import SwiftUI
import Charts

struct MockupStatisticsView: View {
    var body: some View {
        
        VStack(alignment: .trailing){
            Text("A total")
            Text("Of many sorts")
            Text("literally any text can go here")
                .multilineTextAlignment(.trailing)
               
            Chart {
                ForEach(data) { shape in
                    BarMark(
                        x: .value("Shape Type", shape.type),
                        y: .value("Total Count", shape.count)
                    ).clipShape(Capsule())
                    
                    
                }
            }.chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .opacity(0.8)
            
        }
        .frame(maxWidth: 200)
        .foregroundStyle(.gray)
        .redacted(reason: .placeholder)
    }
}

#Preview {
    MockupStatisticsView()
}
