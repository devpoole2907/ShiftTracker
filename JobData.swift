//
//  JobData.swift
//  ShiftTracker
//
//  Created by James Poole on 25/04/23.
//

import Foundation

struct JobData: Codable, Identifiable, Hashable {
    var id: UUID?
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

    init(uuid: UUID, name: String, title: String, hourlyPay: Double, address: String, clockInReminder: Bool, clockOutReminder: Bool, autoClockIn: Bool, autoClockOut: Bool, overtimeEnabled: Bool, overtimeAppliedAfter: Int16, overtimeRate: Double, icon: String, colorRed: Float, colorGreen: Float, colorBlue: Float, payPeriodLength: Int16, payPeriodStartDay: Int16) {
        self.id = uuid
        self.name = name
        self.title = title
        self.hourlyPay = hourlyPay
        self.address = address
        self.clockInReminder = clockInReminder
        self.clockOutReminder = clockOutReminder
        self.autoClockIn = autoClockIn
        self.autoClockOut = autoClockOut
        self.overtimeEnabled = overtimeEnabled
        self.overtimeAppliedAfter = overtimeAppliedAfter
        self.overtimeRate = overtimeRate
        self.icon = icon
        self.colorRed = colorRed
        self.colorGreen = colorGreen
        self.colorBlue = colorBlue
        self.payPeriodLength = payPeriodLength
        self.payPeriodStartDay = payPeriodStartDay
    }
}


func jobData(from job: Job) -> JobData {
    
    var address = ""
        if let locationSet = job.locations, let location = locationSet.allObjects.first as? JobLocation {
            address = location.address ?? ""
        }
    
    return JobData(
        uuid: job.uuid ?? UUID(),
        name: job.name ?? "",
        title: job.title ?? "",
        hourlyPay: job.hourlyPay,
        address: address,
        clockInReminder: job.clockInReminder,
        clockOutReminder: job.clockOutReminder,
        autoClockIn: job.autoClockIn,
        autoClockOut: job.autoClockOut,
        overtimeEnabled: job.overtimeEnabled,
        overtimeAppliedAfter: Int16(job.overtimeAppliedAfter),
        overtimeRate: job.overtimeRate,
        icon: job.icon ?? "",
        colorRed: job.colorRed,
        colorGreen: job.colorGreen,
        colorBlue: job.colorBlue,
        payPeriodLength: job.payPeriodLength,
        payPeriodStartDay: job.payPeriodStartDay
    )
}

