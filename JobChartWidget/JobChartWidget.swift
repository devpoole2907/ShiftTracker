//
//  JobChartWidget.swift
//  JobChartWidget
//
//  Created by James Poole on 13/08/23.
//

import WidgetKit
import SwiftUI
import CoreData

struct Provider: IntentTimelineProvider {
    
    typealias Entry = JobEntry
    typealias Intent = SelectJob
    
    
    func placeholder(in context: Context) -> JobEntry {
        JobEntry(date: Date(), job: nil)
    }

    func getSnapshot(for configuration: SelectJob, in context: Context, completion: @escaping (JobEntry) -> Void) {
        let job = fetchJob(byName: configuration.jobID ?? "")
            completion(JobEntry(date: Date(), job: job))
        }

        func getTimeline(for configuration: SelectJob, in context: Context, completion: @escaping (Timeline<JobEntry>) -> Void) {
            let job = fetchJob(byName: configuration.jobID ?? "")
            let entries = [JobEntry(date: Date(), job: job)]
            let timeline = Timeline<JobEntry>(entries: entries, policy: .atEnd)
            completion(timeline)
        }

    func fetchJob(byName name: String) -> Job? {
        // Implement your Core Data fetch logic using the name
        // For example:
        let request = NSFetchRequest<Job>(entityName: "Job")
        request.predicate = NSPredicate(format: "name == %@", name)
        do {
            let fetchedJobs = try PersistenceController.shared.container.viewContext.fetch(request)
            return fetchedJobs.first
        } catch {
            print("Failed to fetch job: \(error)")
            return nil
        }
    }


}

struct JobEntry: TimelineEntry {
    let date: Date
    let job: Job?
}

struct JobChartWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("Job name: \(entry.job?.name ?? "")")
            
            
            
           // Text(entry.emoji)
        }
    }
}

struct JobChartWidget: Widget {
    let kind: String = "JobChartWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: SelectJob.self, provider: Provider()) { entry in
          /*  if #available(iOS 17.0, *) {
                JobChartWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else { */
                JobChartWidgetEntryView(entry: entry)
                    .padding()
                    .background()
          //  }
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}


