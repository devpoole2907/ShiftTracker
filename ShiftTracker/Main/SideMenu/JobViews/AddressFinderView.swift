//
//  AddressFinderView.swift
//  ShiftTracker
//
//  Created by James Poole on 27/03/23.
//

import SwiftUI
import CoreLocation
import MapKit

struct AddressFinderView: View {
    @State private var searchText = ""
    @State private var searchResults: [CLPlacemark] = []
    @State private var selectedAddress: CLPlacemark?
    @State private var mapAnnotation: IdentifiablePointAnnotation?
    
    @State private var addressConfirmSheet: Bool = false
    
    private let addressManager = AddressManager()
    
    @State private var bottomSheet: Bool = true
    @State private var hideDragIndicator: Bool = false
    
    
    @Binding var selectedAddressString: String?
    
    private let geocoder = CLGeocoder()
    private let defaults = UserDefaults.standard
    @Environment(\.colorScheme) var colorScheme
    
    let iconColor: Color
    let icon: String
    
    @StateObject private var locationManager = LocationDataManager()
    
    @Binding var mapRegion: MKCoordinateRegion
    @Binding var selectedRadius: Double
    
    init(selectedAddress: Binding<String?>, mapRegion: Binding<MKCoordinateRegion>, selectedRadius: Binding<Double>, icon: String, iconColor: Color) {
        _selectedAddressString = selectedAddress
        _mapRegion = mapRegion
        _selectedRadius = selectedRadius
        self.iconColor = iconColor
        self.icon = icon
        loadSavedAddress()
    }
    
    private func defaultCoordinateRegion() -> MKCoordinateRegion {
        let defaultLatitude: CLLocationDegrees = 37.7749
        let defaultLongitude: CLLocationDegrees = -122.4194
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: defaultLatitude, longitude: defaultLongitude),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
    }
    
    private func createAnnotation(for address: CLPlacemark) {
        let annotation = IdentifiablePointAnnotation()
        annotation.coordinate = address.location!.coordinate
        annotation.title = address.formattedAddress
        mapAnnotation = annotation
    }
    
    
    
    
    var body: some View {
        
        
        
        let addressBackgroundColor: Color = colorScheme == .dark ? Color.orange.opacity(0.5) : Color.orange.opacity(0.8)
        let bottomBackgroundColor: Color = colorScheme == .dark ? Color(.systemGray6) : .white
        
        
        NavigationStack{
            if #available(iOS 16.4, *) {
                VStack(spacing: 10) {
                    ZStack(alignment: .topTrailing){
                        
                        Map(coordinateRegion: $mapRegion, showsUserLocation: true, annotationItems: mapAnnotation != nil ? [mapAnnotation!] : []) { annotation in
                            MapAnnotation(coordinate: annotation.coordinate) {
                                AnnotationView(coordinate: annotation.coordinate, addressConfirmSheet: $addressConfirmSheet, icon: icon, iconColor: iconColor)
                                    .id(annotation.id)
                            }
                        }.ignoresSafeArea()
                        Button(action: {
                            if let userLocation = locationManager.location?.coordinate {
                                mapRegion = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                            }
                        }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color(red: 28/255, green: 28/255, blue: 30/255))
                                .cornerRadius(12)
                                .padding(.trailing)
                                .padding(.bottom)
                        }
                        
                    }
                }.sheet(isPresented: $bottomSheet){
                    
                    NavigationStack{
                        List{
                            Section(header: Text("Saved Address").bold()){
                                VStack{
                                    Text(selectedAddressString ?? "No address saved")
                                        .font(.title3)
                                    
                                }
                            }
                            Section{
                                
                                ForEach(searchResults, id: \.self) { result in
                                    HStack {
                                        if result == selectedAddress {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.orange)
                                        } else {
                                            Image(systemName: "circle")
                                                .foregroundColor(.gray)
                                        }
                                        Text(result.formattedAddress)
                                        
                                    }.listRowSeparator(.hidden)
                                    //.listRowBackground(Color.clear)
                                        .onTapGesture {
                                            addressConfirmSheet = true
                                            selectedAddress = result
                                            //setSelectedAddress(result)
                                        }
                                }
                            }
                        }.scrollContentBackground(.hidden)
                            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search work address")
                            .onSubmit(of: .search, {
                                // do something when the user submits the search query
                                searchForAddress()
                                hideDragIndicator = false
                            })
                            .onChange(of: searchText) { newSearchText in
                                if !newSearchText.isEmpty {
                                    hideDragIndicator = true
                                }
                                if newSearchText.isEmpty{
                                    hideDragIndicator = false
                                }
                            }
                        
                    }
                    .presentationDetents([.fraction(0.35), .fraction(0.45), .fraction(0.8)])
                    .presentationDragIndicator(hideDragIndicator ? .hidden : .visible)
                    // .presentationBackground(.thinMaterial)
                    .presentationCornerRadius(12)
                    .presentationBackgroundInteraction(.enabled)
                    .interactiveDismissDisabled()
                    
                    .sheet(isPresented: $addressConfirmSheet){
                        AddressConfirmView(address: $selectedAddress, radius: $selectedRadius, onConfirm: setSelectedAddress)
                            .presentationDetents([ .fraction(0.4), .medium])
                        // .presentationBackground(.thinMaterial)
                            .presentationCornerRadius(12)
                            .presentationDragIndicator(.visible)
                            .presentationBackgroundInteraction(.enabled)
                        // .interactiveDismissDisabled()
                    }
                    
                }
                
            }
            else {
                List{
                    Section{
                        RoundedRectangle(cornerRadius: 20)
                            .fill(addressBackgroundColor)
                            .frame(height: 80)
                            .overlay(
                                Text(selectedAddress?.formattedAddress ?? "No address saved")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding()
                            )
                            .padding([.leading, .trailing, .bottom], -10)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    Section{
                        
                        ForEach(searchResults, id: \.self) { result in
                            HStack {
                                if result == selectedAddress {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(addressBackgroundColor)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                }
                                Text(result.formattedAddress)
                                
                            }.listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .onTapGesture {
                                    selectedAddress = result
                                    setSelectedAddress(result)
                                }
                        }
                        
                    }
                }.navigationTitle("Shift location")
                    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
                    .onSubmit(of: .search, {
                        // do something when the user submits the search query
                        searchForAddress()
                    })
                
                
                VStack{
                    HStack{
                        Text("Saved Address")
                            .font(.title)
                            .bold()
                            .padding()
                        Spacer()
                    }
                    RoundedRectangle(cornerRadius: 20)
                        .fill(addressBackgroundColor)
                        .frame(height: 80)
                        .overlay(
                            Text(selectedAddress?.formattedAddress ?? "No address saved")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .padding()
                        )
                        .padding([.leading, .trailing, .bottom], 20)
                    
                }
                .padding(.bottom, 50)
                .background(bottomBackgroundColor)
                
            }
        }.toolbarRole(.editor)
        
            .onAppear{
                //locationManager.requestAuthorization()
                addressManager.loadSavedAddress(selectedAddressString: selectedAddressString) { region, annotation in
                    self.mapRegion = region ?? self.mapRegion
                    self.mapAnnotation = annotation
                }
                
           
                
            }
  
        
    }
    
    private func searchForAddress() {
        geocoder.geocodeAddressString(searchText) { placemarks, error in
            if let error = error {
                print("Error geocoding address: \(error.localizedDescription)")
            } else if let placemarks = placemarks {
                searchResults = placemarks
                
                
                if let firstPlacemark = placemarks.first,
                   let coordinate = firstPlacemark.location?.coordinate {
                    DispatchQueue.main.async {
                        mapRegion = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                        createAnnotation(for: firstPlacemark)
                    }
                }
            }
        }
    }
    
    private func setSelectedAddress(_ address: CLPlacemark) {
        
        // OLD SAVE ADDRESS FROM SINGLE JOB SYSTEM
        /*   defaults.set(address.formattedAddress, forKey: "selectedAddress")
         defaults.synchronize()*/
        
        // NEW MULTI JOB SYSTEM, SAVE THE ADDRESS TO THE JOB
        selectedAddressString = address.formattedAddress
        createAnnotation(for: address)
        
    }
    
    
    
    private func loadSavedAddress() {
        // OLD SINGLE JOB SYSTEM LOAD //  if let savedAddress = defaults.string(forKey: "selectedAddress") {
        if let savedAddress = selectedAddressString {
            geocoder.geocodeAddressString(savedAddress) { placemarks, error in
                if let error = error {
                    print("Error geocoding address: \(error.localizedDescription)")
                } else if let placemarks = placemarks, let firstPlacemark = placemarks.first {
                    selectedAddress = firstPlacemark
                    searchResults = placemarks
                    
                    
                    if let coordinate = firstPlacemark.location?.coordinate {
                        DispatchQueue.main.async {
                            mapRegion = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                        }
                    }
                    createAnnotation(for: firstPlacemark)
                    
                }
            }
        }
    }
}

/*
 struct AddressTextField_Previews: PreviewProvider {
 static var previews: some View {
 AddressFinderView(job: <#Job#>)
 }
 } */

class IdentifiablePointAnnotation: MKPointAnnotation, Identifiable {
    let id = UUID()
}

struct AddressConfirmView: View {
    @Binding var address: CLPlacemark?
    @Binding var radius: Double
    @Environment(\.dismiss) var dismiss
    var onConfirm: ((CLPlacemark) -> Void)?
    
    var formattedStreetAddress: String {
        if let subThoroughfare = address?.subThoroughfare, let thoroughfare = address?.thoroughfare {
            return "\(subThoroughfare) \(thoroughfare)"
        }
        return ""
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading){
                HStack{
                    Text(formattedStreetAddress)
                        .font(.title)
                        .bold()
                        .padding(.leading, 15)
                        .padding(.top, -35)
                    Spacer()
                }
            }
            
            ScrollView{
                LazyVStack(alignment: .leading){
                Section{
                    
                    HStack{
                        
                        Button(action: {
                            if let address = address {
                                onConfirm?(address)
                                dismiss()
                            }
                        }) {
                            HStack(spacing: 5){
                                Image(systemName: "briefcase.fill")
                                Text("Set work address")
                                    .font(.subheadline)
                                
                                
                            }
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity)
                            .background(.black)
                            .cornerRadius(20)
                            
                        }
                    }
                    
                }.listRowBackground(Color.clear)
                        .padding(.horizontal)
               
                    VStack(alignment: .leading){
                        Text("Details").bold().textCase(nil).font(.title3)
                            .padding(.leading, 22)
                            .padding(.bottom, -2)
                    }
                    VStack(alignment: .leading, spacing: 5){
                        
                        
                            VStack(alignment: .leading, spacing: 5){
                            Text("Address")
                                .foregroundColor(.gray)
                                .font(.footnote)
                            Text(address?.formattedAddress ?? "")
                        }.padding()
                       // Divider()
                            //.padding(.horizontal, 10)
                           // .padding(.vertical, -10)
                            //.frame(maxHeight: 20)
                            
                            Divider()
                                    .padding(.horizontal, 10)
                            
                            VStack(alignment: .leading, spacing: 5){
                            Text("Radius")
                                .foregroundColor(.gray)
                                .font(.caption)
                            HStack {
                                Text("\(Int(radius ))m")
                                    .font(.subheadline)
                                    .bold()
                                Slider(value: $radius, in: 25...200)
                                    .padding(.horizontal, 15)
                            }
                        }.padding()
                    
                        
                    }.background(Color("SquaresColor"))
                        .cornerRadius(12)
                        .padding(.horizontal, 18)
                
            }
            }.scrollContentBackground(.hidden)
            

            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Spacer()
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
            }
        }
    }
}

struct AnnotationView: View {
    var coordinate: CLLocationCoordinate2D
    
    @State private var show = false
    @Binding var addressConfirmSheet: Bool
    @State private var id = UUID()
    
    let icon: String
    let iconColor: Color
    
    
    var body: some View {
        Image(systemName: icon)
            .font(.callout)
            .foregroundColor(.white)
            .padding()
            .background {
                
                Circle()
                    .foregroundStyle(iconColor.gradient)
                
                
            }.frame(width: 50, alignment: .center)
            .offset(y: show ? 0 : -30)
            .animation(.easeInOut(duration: 0.8), value: show)
            .onAppear {
                id = UUID()
                show = true
                
            }
            .onTapGesture {
                addressConfirmSheet = true
            }
    }
}
