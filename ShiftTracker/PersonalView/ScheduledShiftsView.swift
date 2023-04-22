//
//  ScheduledShiftsView.swift
//  ShiftTracker
//
//  Created by James Poole on 22/04/23.
//

import SwiftUI
import CoreData

struct ScheduledShiftsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @Binding var dateSelected: DateComponents?
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ScheduledShift.startDate, ascending: true)], animation: .default)
    private var scheduledShifts: FetchedResults<ScheduledShift>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Job.name, ascending: true)],
        animation: .default)
    private var jobs: FetchedResults<Job>
    
    @State private var showCreateShiftSheet = false
    
    private func shiftsForSelectedDate() -> [ScheduledShift] {
        guard let dateSelected = dateSelected?.date?.startOfDay else { return [] }
        
        return scheduledShifts.filter {
            $0.startDate!.startOfDay == dateSelected
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let _ = dateSelected {
                    let shifts = shiftsForSelectedDate()
                    List {
                        ForEach(shifts, id: \.self) { shift in
                            ListViewRow(shift: shift)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        viewContext.delete(shift)
                                        try? viewContext.save()
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .navigationTitle(dateSelected?.date?.formatted(date: .long, time: .omitted) ?? "")
            .toolbar {
                            Button(action: {
                                showCreateShiftSheet = true
                            }) {
                                Image(systemName: "plus")
                            }
                        }
            .sheet(isPresented: $showCreateShiftSheet) {
                CreateShiftForm(jobs: jobs, dateSelected: dateSelected?.date, onShiftCreated: {
                    showCreateShiftSheet = false
                })
                .environment(\.managedObjectContext, viewContext)
            }
        }
    }
}

struct CreateShiftForm: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let jobs: FetchedResults<Job>
    let dateSelected: Date?
    
    @State private var selectedJob: Job?
    @State private var startDate: Date
    @State private var endDate: Date
    
    var onShiftCreated: () -> Void
    
    init(jobs: FetchedResults<Job>, dateSelected: Date?, onShiftCreated: @escaping () -> Void) {
        self.jobs = jobs
        self.dateSelected = dateSelected
        self.onShiftCreated = onShiftCreated
        
        let defaultDate = dateSelected ?? Date()
        _startDate = State(initialValue: defaultDate)
        _endDate = State(initialValue: defaultDate)
        _selectedJob = State(initialValue: jobs.first)
    }

    
    private func createShift() {
        let newShift = ScheduledShift(context: viewContext)
        newShift.startDate = startDate
        newShift.endDate = endDate
        newShift.job = selectedJob
        newShift.id = UUID()
        
        do {
            try viewContext.save()
            onShiftCreated()
            dismiss()
        } catch {
            print("Error creating shift: \(error.localizedDescription)")
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Job", selection: $selectedJob) {
                        ForEach(jobs, id: \.self) { job in
                            Text(job.name ?? "").tag(job as Job?)
                        }
                    }
                }
                
                Section(header: Text("Shift Time")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("End Date", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("Create Shift")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: createShift)
                }
            }
        }
    }
}





struct ListViewRow: View {
    let shift: ScheduledShift
    
    var dateFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter
        }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(shift.job?.name ?? "")
                .font(.title2)
                .bold()
            Text("From \(dateFormatter.string(from: shift.startDate ?? Date())) to \(dateFormatter.string(from: shift.endDate ?? Date()))")
        }
    }
}

struct ScheduledShiftView_Previews: PreviewProvider {
    static var dateComponents: DateComponents {
        var dateComponents = Calendar.current.dateComponents(
            [.month,
             .day,
             .year,
             .hour,
             .minute],
            from: Date())
        dateComponents.timeZone = TimeZone.current
        dateComponents.calendar = Calendar(identifier: .gregorian)
        return dateComponents
    }
    static var previews: some View {
        ScheduledShiftsView(dateSelected: .constant(dateComponents))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

