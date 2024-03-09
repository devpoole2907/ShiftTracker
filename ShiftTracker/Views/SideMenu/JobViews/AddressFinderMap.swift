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
    
    @EnvironmentObject var jobViewModel: JobViewModel
    @EnvironmentObject var mapViewModel: MapViewModel
    
    @Environment(\.isSearching) private var isSearching
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dismissSearch) private var dismissSearch
    
    var body: some View {
        
        Map(position: $mapViewModel.cameraPosition, selection: $mapViewModel.mapSelection) {
            
            ForEach(mapViewModel.searchResults, id: \.self) { mapItem in
                
                Marker(mapItem.placemark.name ?? "Unknown", coordinate: mapItem.placemark.coordinate)
                
            }
            
            if let jobLocationCoordinate = mapViewModel.jobLocationCoordinate {
                Marker(mapViewModel.selectedAddressString ?? "Unknown", systemImage: jobViewModel.selectedIcon, coordinate: jobLocationCoordinate).tint(jobViewModel.selectedColor)
            }
            
            UserAnnotation()
            
        }
        .mapControls{
            MapCompass()
            MapUserLocationButton()
            MapPitchToggle()
        
        }
        
        .onAppear {
            
                mapViewModel.bottomSheet = true
            
            
        }
        
        .sheet(isPresented: $mapViewModel.bottomSheet){

           NavigationStack{
                ScrollView{
                    
                    VStack(alignment: .leading, spacing: 10){
                        
                        ForEach(mapViewModel.searchResults, id: \.self) { result in
                            HStack {
                              
                                Text(result.placemark.name ?? "Unknown")
                                
                                Spacer()
                                
                            }.padding()
                            .frame(maxWidth: .infinity)
                            .glassModifier(cornerRadius: 20)
                            .padding(.horizontal, 20)
                            
                                .onTapGesture {
                                    mapViewModel.addressConfirmSheet = true
                                    mapViewModel.selectedAddress = result.placemark
                                    
                                    if let clRegion = result.placemark.region as? CLCircularRegion {
                                        let center = clRegion.center
                                        let radius = clRegion.radius
                                        
                                        let coordinateRegion = MKCoordinateRegion(center: center, latitudinalMeters: radius * 2.0, longitudinalMeters: radius * 2.0)
                                        
                                        mapViewModel.cameraPosition = .region(coordinateRegion)
                                        
                                    }
                               
                                }
                        }
                    }
                }.scrollContentBackground(.hidden)
                    .searchable(text: $mapViewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search work address") {
                        ForEach(mapViewModel.searchResults, id: \.self) { suggestion in
                            VStack(alignment: .leading){
                                Text(suggestion.placemark.name ?? "")
                                    .font(.title3)
                                    .bold()
                                
                                Text(suggestion.placemark.formattedAddress)
                                    .font(.callout)
                                    .foregroundStyle(.gray)
                                    .fontDesign(.rounded)
                                
                            }
                        
                                    .onTapGesture {
                                        
                                        dismissSearch()
                                        
                                        mapViewModel.resultTapped(suggestion)
                                        
                                        
                                    }
                            }
                        
                  
                        
                    }
                    .onSubmit(of: .search, {
                        
                        dismissSearch()
                        
                        
                        Task {
                            
                            await mapViewModel.searchSubmitted()
                            
                       
                            
                        }
                    })
                
                    .onChange(of: mapViewModel.searchText) { newValue in
                        
                        // ensure string length is longer than 3
                        guard newValue.count >= 3 else {
                                return
                            }
                        
                        let delay: Double = mapViewModel.initialSearch ? 0.2 : 0.5 // 0.5 is too long for initial search
                        
                        
                        mapViewModel.lastSearchTask?.cancel()

                        let task = DispatchWorkItem {
                            Task {
                                await mapViewModel.searchForAddress()
                            }
                        }

                        mapViewModel.lastSearchTask = task

                        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task)
                        
                        mapViewModel.initialSearch = false
                    }
                
                    .onChange(of: mapViewModel.mapSelection) { oldValue, newValue in
                        
                        guard let newValue else { return }
                        mapViewModel.addressConfirmSheet = true
                        mapViewModel.selectedAddress = newValue.placemark
                        
                        
                    }
                
                    .navigationBarTitleDisplayMode(.inline)
                
                    .toolbar{
                        ToolbarItem(placement: .topBarTrailing) {
                            CloseButton()
                        }
                        
                        ToolbarItem(placement: .topBarLeading) {
                            
                            Text(mapViewModel.selectedAddressString ?? "No address saved")
                                .bold()
                                .font(.headline)
                            
                        }
                        
                    }
                
                
                    
                
            }
            
                    
            .presentationDetents([.fraction(0.2), .fraction(0.35), .fraction(0.45), .fraction(0.8)])
            .presentationDragIndicator(.hidden)
         
            // broken on ios 17.4
         //    .presentationBackground(.ultraThinMaterial)
            .presentationCornerRadius(12)
            .presentationBackgroundInteraction(.enabled)
            .interactiveDismissDisabled()
            
            .sheet(isPresented: $mapViewModel.addressConfirmSheet){
                AddressConfirmView(address: $mapViewModel.selectedAddress, radius: $mapViewModel.selectedRadius, onConfirm: mapViewModel.setSelectedAddress)
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
    
    

    
    
}
@available(iOS 17.0, *)
struct TestMapView: View {
    
   
    var body: some View {
    
    Map {
        
        /*ForEach(mapViewModel.searchResults, id: \.self) { mapItem in
            
            Marker(mapItem.placemark.name ?? "Unknown", coordinate: mapItem.placemark.coordinate)
            
        }
        
        if let jobLocationCoordinate = mapViewModel.jobLocationCoordinate {
            Marker(mapViewModel.selectedAddressString ?? "Unknown", systemImage: jobViewModel.selectedIcon, coordinate: jobLocationCoordinate).tint(jobViewModel.selectedColor)
        }*/
        
        UserAnnotation()
        
    }
    .mapControls{
        MapCompass()
        MapUserLocationButton()
        MapPitchToggle()
        
    }
    
}
    
}
