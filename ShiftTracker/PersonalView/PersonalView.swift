//
//  PersonalView.swift
//  ShiftTracker
//
//  Created by James Poole on 20/04/23.
//
// Create/edit jobs, schedule shifts

import SwiftUI
import Haptics
import UIKit
import CoreLocation
import MapKit


struct PersonalView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    
    @EnvironmentObject var eventStore: EventStore
    
    @Environment(\.managedObjectContext) private var viewContext
       @FetchRequest(entity: Job.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Job.name, ascending: true)]) private var jobs: FetchedResults<Job>
    
    @State private var showAddJobView = false
    

    
    @State private var dateSelected: DateComponents?
    @State private var displayEvents = false
    
    var body: some View {
        
        let textColor: Color = colorScheme == .dark ? .white : .black
        
        NavigationStack {
            
            List {
               //Spacer(minLength: 300)
                 
                
                
                if !jobs.isEmpty{
                    Section {
                    ForEach(jobs, id: \.self) { job in
                        
                        NavigationLink(destination: EditJobView(job: job)){
                            VStack(alignment: .leading, spacing: 5){
                                Text(job.name ?? "")
                                    .foregroundColor(textColor)
                                    .font(.title2)
                                    .bold()
                                Text(job.title ?? "")
                                    .foregroundColor(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
                                    .font(.subheadline)
                                    .bold()
                                Text("$\(job.hourlyPay, specifier: "%.2f") / hr")
                                    .foregroundColor(.gray)
                                    .font(.footnote)
                                    .bold()
                            }
                        }
                    }
                    .onDelete(perform: deleteJob)
                }
                header: {
                    HStack{
                        Text("Jobs")
                            .font(.title)
                            .bold()
                            .textCase(nil)
                            .foregroundColor(textColor)
                            .padding(.leading, -12)
                        Spacer()
                        NavigationLink(destination: AddJobView()) {
                            Image(systemName: "plus")
                                .font(.title2)
                        }
                    }
                    .padding(.trailing, 16)
                }

                }
                else {
                    Section {
                        VStack(alignment: .center, spacing: 15){
                            Text("No jobs found.")
                                .font(.title3)
                                .bold()
                            
                            
                            NavigationLink(destination: AddJobView()){
                                        Text("Create one now")
                                            .bold()
                                            .foregroundColor(.orange)
                                            .padding(.vertical, 10)
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal, 85)

                        } .frame(maxWidth: .infinity)
                            .padding()
                    } header : {
                        HStack{
                            Text("Jobs")
                                .font(.title)
                                .bold()
                                .textCase(nil)
                                .foregroundColor(textColor)
                                .padding(.leading, -12)
                        }
                    }
                    
                }
                Section{
                   
                        CalendarView(interval: DateInterval(start: .distantPast, end: .distantFuture), eventStore: eventStore, dateSelected: $dateSelected, displayEvents: $displayEvents)
                        
                    
                } header : {
                    HStack{
                        Text("Schedule")
                            .font(.title)
                            .bold()
                            .textCase(nil)
                            .foregroundColor(textColor)
                            .padding(.leading, -12)
                        
                    }
                }
                .listRowBackground(Color.clear)
                
            
            }/*.sheet(isPresented: $showAddJobView) {
                AddJobView()
                    .environment(\.managedObjectContext, viewContext)
                    .presentationDetents([.fraction(0.7)])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.thinMaterial)
            }*/
            .navigationBarTitle("Personal", displayMode: .inline)
        }
        
    }
    
    
    private func deleteJob(at offsets: IndexSet) {
            for index in offsets {
                let job = jobs[index]
                viewContext.delete(job)
            }
            
            do {
                try viewContext.save()
            } catch {
                print("Failed to delete job: \(error.localizedDescription)")
            }
        }
    
}

struct PersonalView_Previews: PreviewProvider {
    static var previews: some View {
        PersonalView()
            .environmentObject(EventStore(preview: true))
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
