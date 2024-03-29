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
    @EnvironmentObject var selectedJobManager: JobSelectionManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var navigationState: NavigationState
    
    @AppStorage("lastSelectedJobUUID") private var lastSelectedJobUUID: String?
    
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
                
                // this should only start the shift if it is the selected job rather than switching it if subscription is expired
                
                
                
                let next24Hours = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                
                
                if !purchaseManager.hasUnlockedPro && upcomingShift.job?.uuid?.uuidString != lastSelectedJobUUID {
                    
                    withAnimation(.linear(duration: 0.4)) {
                        viewModel.upcomingShiftShakeTimes += 2
                    }
                    
                }
                
                else if upcomingShift.startDate ?? Date() < next24Hours {
                    if let upcomingShiftJob = upcomingShift.job {
                        
              
                            if upcomingShiftJob != selectedJobManager.fetchJob(in: viewContext){
                                selectedJobManager.selectJob(upcomingShiftJob, with: jobs, shiftViewModel: viewModel)
                            }
                   
                            // set the current upcoming shift for the start shift sheet to load and pop the start shift sheet
                            // action view/start shift sheet will populate all the necessary fields upon init
                        
                                viewModel.scheduledShift = upcomingShift
                          
                                navigationState.activeSheet = .startShiftSheet
        
                        
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
                        
                        JobIconView(icon: upcomingShift.job?.icon ?? "", color: !purchaseManager.hasUnlockedPro ? (upcomingShift.job?.uuid?.uuidString != lastSelectedJobUUID ? Color.gray : Color(red: Double(upcomingShift.job?.colorRed ?? 0), green: Double(upcomingShift.job?.colorGreen ?? 0), blue: Double(upcomingShift.job?.colorBlue ?? 0))) : Color(red: Double(upcomingShift.job?.colorRed ?? 0), green: Double(upcomingShift.job?.colorGreen ?? 0), blue: Double(upcomingShift.job?.colorBlue ?? 0)), font: .callout)
                        
                    
                        
                        
                        VStack(alignment: .leading, spacing: 5){
                            Text("\(upcomingShift.job?.name ?? "")")
                                .bold()
                            HStack(alignment: .lastTextBaseline, spacing: 0) {
                                Text(
                                    Calendar.current.isDateInToday(upcomingShift.startDate ?? Date()) ?
                                    "Today at " :
                                        "\(upcomingShift.startDate ?? Date(), formatter: Self.dateFormatter) at "
                                )
                                .roundedFontDesign()
                                .foregroundColor(.gray)
                                .bold()
                                .font(.footnote)
                                
                                Text("\(upcomingShift.startDate ?? Date(), formatter: Self.timeFormatter)")
                                    .foregroundColor(
                                        Date() > upcomingShift.startDate ?? Date() ? .red :
                                            Calendar.current.date(byAdding: .hour, value: 1, to: Date())! > upcomingShift.startDate ?? Date() ? .orange :
                                                .gray
                                    )
                                    .roundedFontDesign()
                                    .bold()
                                    .font(.footnote)
                            }
                        }
                    }.padding(.vertical, 3)
                    
                }
            }.buttonStyle(.plain)
            
                .opacity(!purchaseManager.hasUnlockedPro ? (upcomingShift.job?.uuid?.uuidString != lastSelectedJobUUID ? 0.5 : 1.0) : 1.0)
               // .allowsHitTesting(!purchaseManager.hasUnlockedPro ? (upcomingShift.job?.uuid?.uuidString != lastSelectedJobUUID ? false : true) : true)
            
                .haptics(onChangeOf: viewModel.upcomingShiftShakeTimes, type: .error)
                    
                
        } else {
            noUpcomingShifts
        }
    }
    
    
    var noUpcomingShifts: some View {
        return VStack(alignment: .leading) {
            
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
                .roundedFontDesign()
            
        }.onTapGesture {
         
                withAnimation(.linear(duration: 0.4)) {
                    viewModel.upcomingShiftShakeTimes += 2
                }
            
        }
    }
    
}

struct Previews_UpcomingShiftView_Previews: PreviewProvider {
    static var previews: some View {
        UpcomingShiftView()
    }
}

