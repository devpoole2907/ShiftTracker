//
//  FirebaseJob.swift
//  ShiftTracker
//
//  Created by James Poole on 30/04/23.
//

import Foundation

struct FirebaseJob: Identifiable {
    var id: String
    var name: String
    var title: String
    var hourlyPay: Double
    var address: String
    var clockInReminder: Bool
    var clockOutReminder: Bool
    var autoClockIn: Bool
    var autoClockOut: Bool
    var overtimeEnabled: Bool
    var overtimeAppliedAfter: Int16
    var overtimeRate: Double
    var icon: String
    var colorRed: Float
    var colorGreen: Float
    var colorBlue: Float
    var payPeriodLength: Int16
    var payPeriodStartDay: Int16

}
