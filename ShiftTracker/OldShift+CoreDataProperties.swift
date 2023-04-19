//
//  OldShift+CoreDataProperties.swift
//  ShiftTracker
//
//  Created by James Poole on 19/03/23.
//
//

import Foundation
import CoreData


extension ShiftTracker.OldShift {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OldShift> {
        return NSFetchRequest<OldShift>(entityName: "OldShift")
    }

    @NSManaged public var totalPay: Double
    @NSManaged public var taxedPay: Double
    @NSManaged public var shiftStartDate: Date?
    @NSManaged public var shiftEndDate: Date?
    @NSManaged public var hourlyPay: Double

}

extension ShiftTracker.OldShift : Identifiable {

}
