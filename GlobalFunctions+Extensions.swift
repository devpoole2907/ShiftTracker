//
//  GlobalFunctions.swift
//  ShiftTracker
//
//  Created by James Poole on 30/04/23.
//

import Foundation
import UIKit
import CoreLocation
import SwiftUI
import PopupView
import MapKit
import CoreData
import Haptics

func isSubscriptionActive() -> Bool {
    
    let subscriptionStatus = UserDefaults.standard.bool(forKey: "subscriptionStatus")
    return subscriptionStatus
}

func setUserSubscribed(_ subscribed: Bool) {
    let userDefaults = UserDefaults.standard
    userDefaults.set(subscribed, forKey: "subscriptionStatus")
    if subscribed{
        print("set subscription to true ")
    }
    else {
        print("subscription is false")
    }
}

extension UIColor {
    var rgbComponents: (Float, Float, Float) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: nil)
        return (Float(r), Float(g), Float(b))
    }
}

extension CLPlacemark {
    var formattedAddress: String {
        let components = [subThoroughfare, thoroughfare, locality, administrativeArea, postalCode, country].compactMap { $0 }
        return components.joined(separator: ", ")
    }
}

struct OkButtonPopup: CentrePopup {
    
    let title: String
    
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup.horizontalPadding(28)
    }
    func createContent() -> some View {
        VStack(spacing: 5) {
            
            createTitle()
                .padding(.vertical)
            //Spacer(minLength: 32)
            //  Spacer.height(32)
            createButtons()
            // .padding()
        }
        .padding(.top, 12)
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        .background(.primary.opacity(0.05))
        .triggersHapticFeedbackWhenAppear()
    }
}

extension OkButtonPopup {
    
    func createTitle() -> some View {
        Text(title)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    func createButtons() -> some View {
        HStack(spacing: 4) {
            createConfirmButton()
        }
    }
}

extension OkButtonPopup {
    func createConfirmButton() -> some View {
        Button(action: dismiss) {
            Text("OK")
                .bold()
                .foregroundColor(.white)
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(.black)
                .cornerRadius(8)
        }
    }
}

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

struct CustomConfirmationAlert: CentrePopup {
    
    @Environment(\.colorScheme) var colorScheme
    
    let action: () -> Void
    let title: String
    
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup.horizontalPadding(28)
    }
    func createContent() -> some View {
        

        
        VStack(spacing: 5) {
            
            createTitle()
                .padding(.vertical)
            createButtons()
        }

        .padding(.top, 12)
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        .background(colorScheme == .dark ? Color(.systemGray6) : .primary.opacity(0.04))
        .triggersHapticFeedbackWhenAppear()
    }
}

private extension CustomConfirmationAlert {
    
    func createTitle() -> some View {
        Text(title)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    func createButtons() -> some View {
        HStack(spacing: 4) {
            createCancelButton()
            createUnlockButton()
        }
    }
}

private extension CustomConfirmationAlert {
    func createCancelButton() -> some View {
        Button(action: dismiss) {
            Text("Cancel")
            
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(.primary.opacity(0.1))
                .cornerRadius(8)
        }
    }
    func createUnlockButton() -> some View {
        Button(action: {
            action()
            dismiss()
        }) {
            Text("Confirm")
                .bold()
                //.foregroundColor(.white)
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(.black)
                .cornerRadius(8)
        }
    }
}

class JobSelectionViewModel: ObservableObject {
    @Published var selectedJobUUID: UUID?
    @Published var selectedJobOffset: CGFloat = 0.0
    @Published var storedSelectedJobUUID: String = ""
    
    
    func fetchJob(in context: NSManagedObjectContext) -> Job? {
            guard let id = selectedJobUUID else { return nil }
            let request: NSFetchRequest<Job> = Job.fetchRequest()
            request.predicate = NSPredicate(format: "uuid == %@", id as CVarArg)
            request.fetchLimit = 1
            
            do {
                let results = try context.fetch(request)
                return results.first
            } catch {
                print("Error fetching job: \(error)")
                return nil
            }
        }
    
    func selectJob(_ job: Job, with jobs: FetchedResults<Job>, shiftViewModel: ContentViewModel) {
        if shiftViewModel.shift == nil {
            if let jobUUID = job.uuid {
                let currentIndex = jobs.firstIndex(where: { $0.uuid == jobUUID }) ?? 0
                let selectedIndex = jobs.firstIndex(where: { $0.uuid == selectedJobUUID }) ?? 0
                withAnimation(.spring()) {
                    selectedJobOffset = CGFloat(selectedIndex - currentIndex) * 60
                }
                selectedJobUUID = jobUUID
                shiftViewModel.selectedJobUUID = jobUUID
                shiftViewModel.hourlyPay = job.hourlyPay
                shiftViewModel.saveHourlyPay()
                shiftViewModel.taxPercentage = job.tax
                shiftViewModel.saveTaxPercentage()
                storedSelectedJobUUID = jobUUID.uuidString
            }
        } else {
            OkButtonPopup(title: "End your current shift to select another job.").present()
        }
    }
    
    
    
    
}


