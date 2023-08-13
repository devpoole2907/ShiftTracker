//
//  JobChartWidgetBundle.swift
//  JobChartWidget
//
//  Created by James Poole on 13/08/23.
//

import WidgetKit
import SwiftUI

@main
struct JobChartWidgetBundle: WidgetBundle {
    var body: some Widget {
        JobChartHoursWidget()
        JobChartEarningsWidget()
    }
}
