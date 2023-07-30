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
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    
    @FetchRequest(
        entity: ScheduledShift.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ScheduledShift.startDate, ascending: true)],
        predicate: NSPredicate(format: "endDate > %@", Date() as NSDate),
        animation: .default)
    private var scheduledShifts: FetchedResults<ScheduledShift>
    
    @FetchRequest(
        entity: Job.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Job.uuid, ascending: true)],
        animation: .default)
    private var jobs: FetchedResults<Job>
    
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter
    }()
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    var body: some View {
        
        if let upcomingShift = scheduledShifts.first {
            Button(action: {
                
                let next24Hours = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                
                if upcomingShift.startDate ?? Date() < next24Hours {
                    if let upcomingShiftJob = upcomingShift.job {
                        
                        CustomConfirmationAlert(action: {
                            if upcomingShiftJob != jobSelectionViewModel.fetchJob(in: viewContext){
                                jobSelectionViewModel.selectJob(upcomingShiftJob, with: jobs, shiftViewModel: viewModel)
                            }
                            let startDate = max(Date(), upcomingShift.startDate ?? Date())
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                
                                
                                
                                let associatedTags = upcomingShift.tags as? Set<Tag> ?? []
                                let associatedTagIds = associatedTags.compactMap { $0.tagID }
                                                    viewModel.selectedTags = Set(associatedTagIds)
                                
                                
                                let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
                                   fetchRequest.predicate = NSPredicate(format: "name == %@", "Late")
                                
                                var lateTag: Tag?
                                
                                do {
                                        let matchingTags = try viewContext.fetch(fetchRequest)
                                    lateTag = matchingTags.first
                                    } catch {
                                        print("Failed to fetch late tag: \(error)")
                                        
                                    }
                                
                                if let lateTag = lateTag,
                                           let lateTagId = lateTag.tagID {
                                            // if the shift is late, select the late tag
                                            if Date() > upcomingShift.startDate ?? Date() {
                                                viewModel.selectedTags.insert(lateTagId)
                                            }
                                        }

                                
                                viewModel.startShiftButtonAction(using: viewContext, startDate: startDate, job: jobSelectionViewModel.fetchJob(in: viewContext)!)
                                

                            }
                            
                            
                            
                            
                            
                        }, cancelAction: nil, title: "Load this shift and associated tags?").showAndStack()
                        
                        
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
                        Image(systemName: upcomingShift.job?.icon ?? "")
                            .foregroundStyle(.white)
                            .font(.callout)
                            .padding(10)
                            .background {
                                
                                Circle()
                                    .foregroundStyle(Color(red: Double(upcomingShift.job?.colorRed ?? 0), green: Double(upcomingShift.job?.colorGreen ?? 0), blue: Double(upcomingShift.job?.colorBlue ?? 0)).gradient)
                                
                            }
                        
                        
                        VStack(alignment: .leading, spacing: 5){
                            Text("\(upcomingShift.job?.name ?? "")")
                                .bold()
                            HStack(alignment: .lastTextBaseline, spacing: 0) {
                                Text(
                                    Calendar.current.isDateInToday(upcomingShift.startDate ?? Date()) ?
                                    "Today at " :
                                        "\(upcomingShift.startDate ?? Date(), formatter: Self.dateFormatter) at "
                                )
                                .fontDesign(.rounded)
                                .foregroundColor(.gray)
                                .bold()
                                .font(.footnote)
                                
                                Text("\(upcomingShift.startDate ?? Date(), formatter: Self.timeFormatter)")
                                    .foregroundColor(
                                        Date() > upcomingShift.startDate ?? Date() ? .red :
                                            Calendar.current.date(byAdding: .hour, value: 1, to: Date())! > upcomingShift.startDate ?? Date() ? .orange :
                                                .gray
                                    )
                                    .fontDesign(.rounded)
                                    .bold()
                                    .font(.footnote)
                            }
                        }
                    }.padding(.vertical, 3)
                    
                }
            }.buttonStyle(.plain)
        } else {
            VStack(alignment: .leading) {
                
                Text("Upcoming Shift")
                    .font(.title3)
                    .bold()
                    .padding(.bottom, -1)
                Divider().frame(maxWidth: 200)
                HStack{
                    Image(systemName: "briefcase.fill")
                    Text("No Upcoming Shifts")
                    
                }.foregroundColor(.gray)
                    .font(.footnote)
                    .bold()
                    .padding(.vertical, 2)
                    .fontDesign(.rounded)
                
            }
        }
    }
}

struct Previews_UpcomingShiftView_Previews: PreviewProvider {
    static var previews: some View {
        UpcomingShiftView()
    }
}

