//
//  CurrentShiftView.swift
//  ShiftTracker
//
//  Created by James Poole on 18/05/23.
//

import SwiftUI
import CoreData

struct CurrentShiftView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let startDate: Date
    
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM 'at' h:mm a"
        return formatter
    }()
    
    @State private var job: Job?
    
    init(jobUUID: UUID, startDate: Date) {
        let fetchRequest: NSFetchRequest<Job> = Job.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uuid == %@", jobUUID as NSUUID)
        fetchRequest.fetchLimit = 1
        
        do {
            let fetchedJobs = try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
            _job = State(initialValue: fetchedJobs.first)
        } catch {
            print("Failed to fetch job: \(error)")
            _job = State(initialValue: nil)
        }
        self.startDate = startDate
        
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Text("Current Shift")
                .font(.title3)
                .bold()
            Divider().frame(maxWidth: 200)
            
            if let job = job {
                HStack{
                    Image(systemName: job.icon ?? "briefcase.circle")
                        .foregroundColor(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
                    VStack(alignment: .leading, spacing: 5){
                        Text(job.name ?? "")
                            .bold()
                        Text("\(startDate,formatter: Self.dateFormatter)")
                            .foregroundColor(.gray)
                            .bold()
                            .font(.footnote)
                    }
                }.padding(.vertical, 5)
            } else {
                Text("No Job Found")
                    .bold()
            }
            
            
        }
    }
}
/*
 struct Previews_CurrentShiftView_Previews: PreviewProvider {
 static var previews: some View {
 CurrentShiftView(jobUUID: UUID(), startDate: Date())
 }
 }
 */
