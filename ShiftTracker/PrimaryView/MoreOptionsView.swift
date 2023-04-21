//
//  MoreOptionsView.swift
//  ShiftTracker
//
//  Created by James Poole on 29/03/23.
//

import SwiftUI
import UIKit

struct MoreOptionsView: View{
    @AppStorage("clockInReminder") private var clockInReminder: Bool = false
    @AppStorage("clockOutReminder") private var clockOutReminder: Bool = false
    @AppStorage("autoClockIn") private var autoClockIn: Bool = false
    @AppStorage("autoClockOut") private var autoClockOut: Bool = false
    @AppStorage("isProVersion", store: UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")) var isProVersion = false
    @State private var sharedUserDefaults = UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")!
    
    // tags stuff
    @AppStorage("tagList") private var tagsList: Data = Data()
    @State private var tags: [Tag] = []
    @State private var selectedTag: Tag? = nil
    
    @State private var overtimeRate = 1.25
    @State private var overtimeAppliedAfter: TimeInterval = 8.0
    @State private var overtimeEnabled: Bool = false
    
    private let shiftKeys = ShiftKeys()
    
    
    @State private var showingProView = false
    
    @Environment(\.colorScheme) var colorScheme
    
    init(){
        //self._overtimeRate = .init(initialValue: sharedUserDefaults.double(forKey: shiftKeys.overtimeMultiplierKey))
        self._overtimeAppliedAfter = .init(initialValue: sharedUserDefaults.double(forKey: shiftKeys.overtimeAppliedAfterKey))
        self._overtimeEnabled = .init(initialValue: sharedUserDefaults.bool(forKey: shiftKeys.overtimeEnabledKey))
        
        let storedOvertimeRate = sharedUserDefaults.double(forKey: shiftKeys.overtimeMultiplierKey)
        
        self._overtimeRate = .init(initialValue: storedOvertimeRate != 0 ? storedOvertimeRate: 1.25)
        
    }

    func formattedTimeInterval(_ timeInterval: TimeInterval) -> String {
            let hours = Int(timeInterval) / 3600
            let minutes = Int(timeInterval) % 3600 / 60
            return "\(hours)h \(minutes)m"
        }
    
    func saveOvertimeEnabledState(_ isEnabled: Bool) {
        sharedUserDefaults.set(isEnabled, forKey: shiftKeys.overtimeEnabledKey)
    }

    
    var body: some View{
        
        
               //let backgroundColor: Color = colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : .white
        let proButtonColor: Color = colorScheme == .dark ? Color.orange.opacity(0.5) : Color.orange.opacity(0.8)
        let iconColor: Color = colorScheme == .dark ? .white : .black
             
        
        NavigationStack{
                VStack{
                    List{
                        if !isProVersion{
                            Section{
                            Button(action: {
                                showingProView = true // set the state variable to true to show the sheet
                            }) {
                                Group{
                                    ZStack {
                                        Color.black
                                            .cornerRadius(20)
                                            .frame(height: 80)
                                        VStack(spacing: 2) {
                                            HStack{
                                                Text("ShiftTracker")
                                                    .font(.title2)
                                                    .bold()
                                                    .foregroundColor(Color.white)
                                                Text("PRO")
                                                    .font(.title)
                                                    .bold()
                                                    .foregroundColor(Color.orange)
                                            }
                                            //.padding(.top, 3)
                                       
                                            Text("Featuring auto clocking in & out!")
                                                .font(.subheadline)
                                                .bold()
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .frame(maxWidth: UIScreen.main.bounds.width - 20) //maxHeight: 100)
                                    .shadow(radius: 2, x: 0, y: 1)
                                }//.padding(.bottom, 75)
                            }
                            }.listRowBackground(Color.clear)
                    }
                        
                    /*    Section(header: Text("Overtime")){
                            
                            Toggle(isOn: $overtimeEnabled){
                                HStack {
                                    Image(systemName: "person.crop.circle.badge.clock")
                                    Spacer().frame(width: 10)
                                    Text("Enable Overtime")
                                }
                            }.onChange(of: overtimeEnabled) { newValue in
                                saveOvertimeEnabledState(newValue)
                            }
                            .toggleStyle(OrangeToggleStyle())
                            
                            Stepper(value: overtimeRateBinding, in: 1.25...3, step: 0.25) {
                                HStack{
                                    Image(systemName: "speedometer")
                                    Spacer().frame(width: 10)
                                    Text("Rate: \(overtimeRate, specifier: "%.2f")x")
                                }
                            }.disabled(!overtimeEnabled)
                            NavigationLink(destination: OvertimeView(overtimeAppliedAfter: $overtimeAppliedAfter)) {
                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                    Text("Overtime applied after")
                                    Spacer()
                                    Text("\(formattedTimeInterval(overtimeAppliedAfter))")
                                        .foregroundColor(.gray)
                                }
                            }.disabled(!overtimeEnabled)
                            
                        }.listRowSeparator(.hidden)
                        
                        */
                        /*
                         NavigationLink(destination: HourlyPayCalculator().navigationBarTitle(Text("Hourly Pay Calculator"))) {
                             HStack {
                                 Image(systemName: "clock.circle")
                                 Spacer().frame(width: 10)
                                 Text("Calculate hourly from annual")
                             }
                         }
                         */
                        
                        
                    }.listStyle(.insetGrouped)
                    //.scrollContentBackground(.hidden)
                    
                    
                    
                }.onAppear(perform: loadData)
                .sheet(isPresented: $showingProView) { // present the sheet with ProView
                    if #available(iOS 16.4, *) {
                        ProView()
                            .presentationDetents([ .large])
                            .presentationDragIndicator(.visible)
                            .presentationBackground(.thinMaterial)
                            .presentationCornerRadius(12)
                    }
                    else {
                        ProView()
                    }
                }
        }
    }
    
    func loadData() {
        if let decodedData = try? JSONDecoder().decode([Tag].self, from: tagsList) {
            tags = decodedData
        }
    }
    
}

struct MoreOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        MoreOptionsView()
    }
}

extension UIImage {
    func resized(to newSize: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            let hScale = newSize.height / size.height
            let vScale = newSize.width / size.width
            let scale = max(hScale, vScale) // scaleToFill
            let resizeSize = CGSize(width: size.width*scale, height: size.height*scale)
            var middle = CGPoint.zero
            if resizeSize.width > newSize.width {
                middle.x -= (resizeSize.width-newSize.width)/2.0
            }
            if resizeSize.height > newSize.height {
                middle.y -= (resizeSize.height-newSize.height)/2.0
            }
            
            draw(in: CGRect(origin: middle, size: resizeSize))
        }
    }
}


