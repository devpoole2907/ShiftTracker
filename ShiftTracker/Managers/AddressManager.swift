//
//  AddressManager.swift
//  ShiftTracker
//
//  Created by James Poole on 31/08/23.
//

import Foundation
import CoreLocation
import MapKit

class AddressManager: ObservableObject {
    private let geocoder = CLGeocoder()
    private let defaults = UserDefaults.standard
    
    func loadSavedAddress(selectedAddressString: String?, completion: @escaping (MKCoordinateRegion?, IdentifiablePointAnnotation?) -> Void) {
        if let savedAddress = selectedAddressString {
            geocoder.geocodeAddressString(savedAddress) { placemarks, error in
                if let error = error {
                    print("Error geocoding address: \(error.localizedDescription)")
                } else if let placemarks = placemarks, let firstPlacemark = placemarks.first {
                    let annotation = IdentifiablePointAnnotation()
                    annotation.coordinate = firstPlacemark.location!.coordinate
                    annotation.title = firstPlacemark.formattedAddress
                    
                    if let coordinate = firstPlacemark.location?.coordinate {
                        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                        completion(region, annotation)
                    }
                }
            }
        }
    }
}
