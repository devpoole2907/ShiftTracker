//
//  MapViewModel.swift
//  ShiftTracker
//
//  Created by James Poole on 7/10/23.
//

import SwiftUI
import Foundation
import MapKit

@available(iOS 17.0, *)
class MapViewModel: ObservableObject {
    
    let addressManager = AddressManager()
    
    @Published  var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ))
    @Published var mapSelection: MKMapItem?
    
    @Published var searchText = ""
    @Published var mapStyle: MapStyle = .hybrid
    @Published var bottomSheet: Bool = true
    @Published var selectedAddress: CLPlacemark?
    @Published var searchResults: [MKMapItem] = []
    @Published var addressConfirmSheet: Bool = false
    @Published var jobLocationCoordinate: CLLocationCoordinate2D?
    @Published var mapCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    
    @Published var lastSearchTask: DispatchWorkItem?
    @Published var initialSearch: Bool = false
    
    @Published var selectedRadius = 75.0
    @Published var selectedAddressString: String?
    
    var iconColor: Color = .cyan
    var icon: String = "briefcase.fill"
    var job: Job? = nil
    
    init(job: Job? = nil) {
        self.job = job
        
        if let jobColorRed = job?.colorRed, let jobColorBlue = job?.colorBlue, let jobColorGreen = job?.colorGreen {
            self.iconColor = Color(red: Double(jobColorRed), green: Double(jobColorGreen), blue: Double(jobColorBlue))
        }
        
        if let jobIcon = job?.icon {
            self.icon = jobIcon
        }
        
        if let locationSet = job?.locations, let location = locationSet.allObjects.first as? JobLocation {
            self.selectedAddressString = location.address
            self.selectedRadius = location.radius
            print("job has an address: \(location.address)")
        }
        
        loadAddress()
        
        
 
        
    }
    
    func loadAddress() {
        addressManager.loadSavedAddress(selectedAddressString: self.selectedAddressString) { region, annotation in
            guard let region else { return }
            
            self.cameraPosition = .region(region)
            
            self.jobLocationCoordinate = annotation?.coordinate
        
        }
    }
    
    init(iconColor: Color, icon: String) {
        self.icon = icon
        self.iconColor = iconColor
    }
    
    func setSelectedAddress(_ address: CLPlacemark) {
        
        selectedAddressString = address.formattedAddress
        createAnnotation(for: address)
        
    }
    
    func createAnnotation(for address: CLPlacemark) {
        
        self.searchResults.removeAll(keepingCapacity: false)
        
        self.jobLocationCoordinate = address.location?.coordinate
        
 
    }
    
    func searchForAddress() async {
        
  
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = self.searchText
        
        if let results = try? await MKLocalSearch(request: request).start() {
            self.searchResults = results.mapItems

            }
        
    }
    
    func searchSubmitted() async {
        guard !self.searchText.isEmpty else { return }
        print("awaiting search address")
        await self.searchForAddress()
        
        if let clRegion = self.searchResults.first?.placemark.region as? CLCircularRegion {
            let center = clRegion.center
            let radius = clRegion.radius
            
            let coordinateRegion = MKCoordinateRegion(center: center, latitudinalMeters: radius * 5.0, longitudinalMeters: radius * 5.0)
            
            self.cameraPosition = .region(coordinateRegion)
            
        }
    }
    
    func resultTapped(_ searchSuggestion: MKMapItem) {
        self.searchText = searchSuggestion.placemark.name ?? ""
        

        
        Task {
            await self.searchForAddress()
        }
        
        self.addressConfirmSheet = true
        self.selectedAddress = searchSuggestion.placemark
        
        if let clRegion = searchSuggestion.placemark.region as? CLCircularRegion {
            let center = clRegion.center
            let radius = clRegion.radius
            
            let coordinateRegion = MKCoordinateRegion(center: center, latitudinalMeters: radius * 2.0, longitudinalMeters: radius * 2.0)
            
            self.cameraPosition = .region(coordinateRegion)
            
        }
        
    }
    
    
    
    
}
