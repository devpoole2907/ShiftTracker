//
//  MockupScheduleView.swift
//  ShiftTracker
//
//  Created by James Poole on 25/09/23.
//

import SwiftUI

struct MockupScheduleView: View {
    @State private var date = Date()
      let dateRange: ClosedRange<Date> = {
          let calendar = Calendar.current
          let startComponents = DateComponents(year: 2021, month: 12, day: 15)
          let endComponents = DateComponents(year: 2021, month: 12, day: 30, hour: 23, minute: 59, second: 59)
          return calendar.date(from:startComponents)!
          ...
          calendar.date(from:endComponents)!
      }()
      
      var body: some View {
          
          
          Image(systemName: "calendar.badge.clock")
              .symbolRenderingMode(.hierarchical)
              .resizable()
              .scaledToFit()
          
              .frame(maxWidth: 200)
              
              .foregroundStyle(.gray)
          
              .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
          
      }
}

#Preview {
    MockupScheduleView()
}
