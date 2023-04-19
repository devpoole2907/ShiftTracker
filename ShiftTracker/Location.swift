//
//  Location.swift
//  ShiftTracker
//
//  Created by James Poole on 25/03/23.
//

import Foundation
import MapKit

struct Location: Identifiable, Codable, Equatable {
    
    var id: UUID
    var name: String
    var description: String
    let latitude: Double
    let longitude: Double
    
    //static let example = Location(id: UUID(), name: "1 Infinite Loop", description: "Wonder what this place is?", latitude: 37.331686, longitude: -122.030656)
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    static func ==(lhs: Location, rhs: Location) -> Bool {
        lhs.id == rhs.id
    }
    
    
}
