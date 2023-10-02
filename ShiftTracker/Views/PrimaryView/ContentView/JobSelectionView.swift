//
//  JobSelectionView.swift
//  ShiftTracker
//
//  Created by James Poole on 28/04/23.
//

import SwiftUI
import CoreData

struct JobSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(entity: Job.entity(), sortDescriptors: [])
    private var jobs: FetchedResults<Job>
    
    @Binding var selectedJobUUID: UUID?
    @Environment(\.dismiss) var dismiss
    
    @State private var sharedUserDefaults = UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")!
    
    var body: some View {
        NavigationView {
            List {
                ForEach(jobs) { job in
                    Button(action: {
                        selectedJobUUID = job.uuid
                        sharedUserDefaults.set(job.uuid?.uuidString, forKey: "SelectedJobUUID")
                        dismiss()
                    }) {
                        HStack {
                            Text(job.name ?? "")
                            if selectedJobUUID == job.uuid {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("Select Job", displayMode: .inline)
        }
    }
}
