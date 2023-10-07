//
//  AddressFinderMap.swift
//  ShiftTracker
//
//  Created by James Poole on 19/09/23.
//

import SwiftUI
import _MapKit_SwiftUI

@available(iOS 17.0, *)
struct AddressFinderMap: View {
    
    private let addressManager = AddressManager()
    
    @State private var searchText = ""
    @State private var mapStyle: MapStyle = .hybrid
    @State private var bottomSheet: Bool = true
    @State private var selectedAddress: CLPlacemark?
    @State private var searchResults: [MKMapItem] = []
    @State private var mapSelection: MKMapItem?
    @State private var addressConfirmSheet: Bool = false
    @State private var jobLocationCoordinate: CLLocationCoordinate2D?
    
    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ))
    
    @State private var mapCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    
    @Binding var selectedAddressString: String?
    @Binding var selectedRadius: Double
    
    let iconColor: Color
    let icon: String
    
    @Environment(\.isSearching) private var isSearching
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dismissSearch) private var dismissSearch
    
    @State private var lastSearchTask: DispatchWorkItem?
    @State private var initialSearch: Bool = false
    
    var body: some View {
        
        Map(position: $cameraPosition, selection: $mapSelection) {
            
            ForEach(searchResults, id: \.self) { mapItem in
                
                Marker(mapItem.placemark.name ?? "Unknown", coordinate: mapItem.placemark.coordinate)
                
            }
            
            if let jobLocationCoordinate = jobLocationCoordinate {
                Marker(selectedAddressString ?? "Unknown", systemImage: icon, coordinate: jobLocationCoordinate).tint(iconColor)
            }
            
            UserAnnotation()
            
        }//.mapStyle(.imagery(elevation: .realistic))
        .mapControls{
            MapCompass()
            MapUserLocationButton()
            MapPitchToggle()
        
        }
        
        .sheet(isPresented: $bottomSheet){
            
            NavigationStack{
                ScrollView{
                    
                    VStack(alignment: .leading, spacing: 10){
                        
                        ForEach(searchResults, id: \.self) { result in
                            HStack {
                              
                                Text(result.placemark.name ?? "Unknown")
                                
                                Spacer()
                                
                            }.padding()
                            .frame(maxWidth: .infinity)
                            .glassModifier(cornerRadius: 20)
                            .padding(.horizontal, 20)
                            
                                .onTapGesture {
                                    addressConfirmSheet = true
                                    selectedAddress = result.placemark
                                    
                                    if let clRegion = result.placemark.region as? CLCircularRegion {
                                        let center = clRegion.center
                                        let radius = clRegion.radius
                                        
                                        let coordinateRegion = MKCoordinateRegion(center: center, latitudinalMeters: radius * 2.0, longitudinalMeters: radius * 2.0)
                                        
                                        self.cameraPosition = .region(coordinateRegion)
                                        
                                    }
                               
                                }
                        }
                    }
                }.scrollContentBackground(.hidden)
                    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search work address") {
                        ForEach(searchResults, id: \.self) { suggestion in
                            VStack(alignment: .leading){
                                Text(suggestion.placemark.name ?? "")
                                    .font(.title3)
                                    .bold()
                                
                                Text(suggestion.placemark.formattedAddress ?? "")
                                    .font(.callout)
                                    .foregroundStyle(.gray)
                                    .fontDesign(.rounded)
                                
                            }
                        
                                    .onTapGesture {
                                        
                                        dismissSearch()
                                        
                                        self.searchText = suggestion.placemark.name ?? ""
                                        
                       
                                        
                                        Task {
                                            await searchForAddress()
                                        }
                                        
                                        addressConfirmSheet = true
                                        selectedAddress = suggestion.placemark
                                        
                                        if let clRegion = suggestion.placemark.region as? CLCircularRegion {
                                            let center = clRegion.center
                                            let radius = clRegion.radius
                                            
                                            let coordinateRegion = MKCoordinateRegion(center: center, latitudinalMeters: radius * 2.0, longitudinalMeters: radius * 2.0)
                                            
                                            self.cameraPosition = .region(coordinateRegion)
                                            
                                        }
                                        
                                        
                                        
                                    }
                            }
                        
                  
                        
                    }
                    .onSubmit(of: .search, {
                        
                        dismissSearch()
                        
                        // do something when the user submits the search query
                        Task {
                            
                            guard !searchText.isEmpty else { return }
                            print("awaiting search address")
                            await searchForAddress()
                            
                            if let clRegion = searchResults.first?.placemark.region as? CLCircularRegion {
                                let center = clRegion.center
                                let radius = clRegion.radius
                                
                                let coordinateRegion = MKCoordinateRegion(center: center, latitudinalMeters: radius * 5.0, longitudinalMeters: radius * 5.0)
                                
                                self.cameraPosition = .region(coordinateRegion)
                                
                            }
                            
                       
                            
                        }
                    })
                
                    .onChange(of: searchText) { newValue in
                        
                        // ensure string length is longer than 3
                        guard newValue.count >= 3 else {
                                return
                            }
                        
                        let delay: Double = initialSearch ? 0.2 : 0.5 // 0.5 is too long for initial search
                        
                        
                        lastSearchTask?.cancel()

                        let task = DispatchWorkItem {
                            Task {
                                await searchForAddress()
                            }
                        }

                        lastSearchTask = task

                        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task)
                        
                        initialSearch = false
                    }

                
                    .onAppear{
                        //locationManager.requestAuthorization()
                        addressManager.loadSavedAddress(selectedAddressString: selectedAddressString) { region, annotation in
                            
                            
                            guard let region else { return }
                            
                            self.cameraPosition = .region(region)
                            
                            self.jobLocationCoordinate = annotation?.coordinate
                        }
                        
                   
                        
                    }
                
                    .onChange(of: mapSelection) { oldValue, newValue in
                        
                        guard let newValue else { return }
                        addressConfirmSheet = true
                        selectedAddress = newValue.placemark
                        
                        
                    }
                
                    .navigationBarTitleDisplayMode(.inline)
                
                    .toolbar{
                        ToolbarItem(placement: .topBarTrailing) {
                            CloseButton()
                        }
                        
                        ToolbarItem(placement: .topBarLeading) {
                            
                            Text(selectedAddressString ?? "No address saved")
                                .bold()
                                .font(.headline)
                            
                        }
                        
                    }
                
                
                    
                
            }
            .presentationDetents([.fraction(0.2), .fraction(0.35), .fraction(0.45), .fraction(0.8)])
            .presentationDragIndicator(.hidden)
             .presentationBackground(.ultraThinMaterial)
            .presentationCornerRadius(12)
            .presentationBackgroundInteraction(.enabled)
            .interactiveDismissDisabled()
            
            .sheet(isPresented: $addressConfirmSheet){
                AddressConfirmView(address: $selectedAddress, radius: $selectedRadius, onConfirm: setSelectedAddress)
                    .presentationDetents([ .fraction(0.4), .medium])
                 .presentationBackground(.ultraThinMaterial)
                    .presentationCornerRadius(12)
                    .presentationDragIndicator(isSearching ? .hidden : .visible)
                    .presentationBackgroundInteraction(.enabled)
                
                
                    .onAppear{
                        dismissSearch()
                        hideKeyboard()
                    }
                
            }
            
        }
        
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarRole(.editor)
        
        
        
        
        
        
    }
    
    private func setSelectedAddress(_ address: CLPlacemark) {
        
        selectedAddressString = address.formattedAddress
        createAnnotation(for: address)
        
    }
    
    private func createAnnotation(for address: CLPlacemark) {
        
        searchResults.removeAll(keepingCapacity: false)
        
        jobLocationCoordinate = address.location?.coordinate
        
 
    }
    
    private func searchForAddress() async {
        
      /*  guard let mapRegion = cameraPosition.region else {
            
            print("failed mapregion during search")
            
            return }
        */
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText

       // request.region = cameraPosition.region!
        
        if let results = try? await MKLocalSearch(request: request).start() {
                searchResults = results.mapItems

            }
        
    }
    
    

    
    
}

#Preview {
    if #available(iOS 17.0, *) {
        AddressFinderMap(selectedAddressString: .constant(""), selectedRadius: .constant(75), iconColor: .indigo, icon: "paintpalette")
    } else {
        // Fallback on earlier versions
        
        Text("Invalid")
        
    }
}
