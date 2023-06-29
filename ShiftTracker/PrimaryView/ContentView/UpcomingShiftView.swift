//
//  UpcomingShiftView.swift
//  ShiftTracker
//
//  Created by James Poole on 18/05/23.
//

import SwiftUI
import CoreData

struct UpcomingShiftView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var viewModel: ContentViewModel
    @EnvironmentObject var jobSelectionViewModel: JobSelectionViewModel
    
    @FetchRequest(
        entity: ScheduledShift.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ScheduledShift.startDate, ascending: true)],
        predicate: NSPredicate(format: "startDate > %@", Date() as NSDate),
        animation: .default)
    private var scheduledShifts: FetchedResults<ScheduledShift>
    
    @FetchRequest(
        entity: Job.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Job.uuid, ascending: true)],
        animation: .default)
    private var jobs: FetchedResults<Job>

    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM 'at' h:mm a"
        return formatter
    }()
    
    var body: some View {
        
        if let upcomingShift = scheduledShifts.first {
            Button(action: {
                if let upcomingShiftJob = upcomingShift.job {
                    if upcomingShiftJob != jobSelectionViewModel.fetchJob(in: viewContext){
                    CustomConfirmationAlert(action: {
                        jobSelectionViewModel.selectJob(upcomingShiftJob, with: jobs, shiftViewModel: viewModel)
                        
                    }, title: "Switch to this job?").showAndStack()
                    
                }
            }
            }){
            VStack(alignment: .leading) {
                
                Text("Upcoming Shift")
                    .font(.title3)
                    .bold()
                    .padding(.bottom, -1)
                Divider().frame(maxWidth: 200)
                HStack{
                    Image(systemName: upcomingShift.job?.icon ?? "briefcase.circle")
                        .foregroundColor(Color(red: Double(upcomingShift.job?.colorRed ?? 0), green: Double(upcomingShift.job?.colorGreen ?? 0), blue: Double(upcomingShift.job?.colorBlue ?? 0)))
                    VStack(alignment: .leading, spacing: 5){
                        Text("\(upcomingShift.job?.name ?? "Unknown")")
                            .bold()
                        Text("\(upcomingShift.startDate ?? Date(),formatter: Self.dateFormatter)")
                            .foregroundColor(.gray)
                            .bold()
                            .font(.footnote)
                            .padding(.leading, 1.4)
                    }
                }.padding(.vertical, 3)
                
            }
        }
    } else {
        VStack(alignment: .leading) {
            
            Text("Upcoming Shift")
                .font(.title3)
                .bold()
                .padding(.bottom, -1)
            Divider().frame(maxWidth: 200)
            HStack{
                Image(systemName: "briefcase.circle")
                Text("No Upcoming Shifts")
                
            }.foregroundColor(.gray)
                .font(.footnote)
                .bold()
                .padding(.vertical, 2)
            
        }
    }
    }
}

struct Previews_UpcomingShiftView_Previews: PreviewProvider {
    static var previews: some View {
        UpcomingShiftView()
    }
}

