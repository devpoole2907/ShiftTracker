//
//  JobData.swift
//  ShiftTracker
//
//  Created by James Poole on 25/04/23.
//

import Foundation

struct JobData: Codable, Identifiable {
    let id: UUID
    let name: String
    let title: String
    let hourlyPay: Double
    let colorRed: Float
    let colorGreen: Float
    let colorBlue: Float
    let icon: String
}

func jobData(from job: Job) -> JobData {
    JobData(
        id: job.uuid ?? UUID(),
        name: job.name ?? "",
        title: job.title ?? "",
        hourlyPay: job.hourlyPay,
        colorRed: job.colorRed,
        colorGreen: job.colorGreen,
        colorBlue: job.colorBlue,
        icon: job.icon ?? ""
    )
}

