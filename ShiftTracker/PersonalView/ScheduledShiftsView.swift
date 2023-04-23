//
//  ScheduledShiftsView.swift
//  ShiftTracker
//
//  Created by James Poole on 22/04/23.
//

import SwiftUI
import CoreData
import Charts
import Haptics

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
                    if !shifts.isEmpty {
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
                        }.scrollContentBackground(.hidden)
                    } else {
                        Text("You have no shifts scheduled on this date.")
                            .bold()
                        
                    }
                }
            }
            .navigationBarTitle(dateSelected?.date?.formatted(date: .long, time: .omitted) ?? "")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing){
                    Button(action: {
                        showCreateShiftSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateShiftSheet) {
            CreateShiftForm(jobs: jobs, dateSelected: dateSelected?.date, onShiftCreated: {
                showCreateShiftSheet = false
            })
            .environment(\.managedObjectContext, viewContext)
            .presentationDetents([.large])
            .presentationBackground(.thinMaterial)
            .presentationDragIndicator(.visible)
        }
    }
    
}

struct CreateShiftForm: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @Environment(\.colorScheme) var colorScheme
    
    let jobs: FetchedResults<Job>
    var dateSelected: Date?
    
    @State private var selectedJob: Job?
    @State private var startDate: Date
    @State private var endDate: Date
    
    @State private var selectedIndex: Int = 0
    
    
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
    
    
    @State var startAngle: Double = 0
    @State var toAngle: Double = 180
    
    @State var startProgress: CGFloat = 0
    @State var toProgress: CGFloat = 0.5
    
    var body: some View {
        
        let sliderColor: Color = colorScheme == .dark ? Color(.systemGray5) : .black
        
        
        
        NavigationStack {
            VStack(spacing: 5){
                
                //.padding(.top, 100)
                
                
                
                //.padding(.top, 45)
                
                
                VStack{
                    HStack(spacing: 25){
                        VStack(alignment: .leading, spacing: 8){
                            Label {
                                Text("Start")
                                    .bold()
                            } icon: {
                                Image(systemName: "figure.walk.arrival")
                                    .foregroundColor(.orange)
                            }
                            .font(.callout)
                            
                            Text(getTime(angle: startAngle).formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundColor(.gray)
                            
                            Text(getTime(angle: startAngle).formatted(date: .omitted, time: .shortened))
                                .font(.title2.bold())
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        
                        VStack(alignment: .leading, spacing: 8){
                            Label {
                                Text("End")
                                    .bold()
                            } icon: {
                                Image(systemName: "figure.walk.departure")
                                    .foregroundColor(.orange)
                            }
                            .font(.callout)
                            
                            Text(getTime(angle: toAngle, isEndDate: true).formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundColor(.gray)
                            
                            Text(getTime(angle: toAngle, isEndDate: true).formatted(date: .omitted, time: .shortened))
                                .font(.title2.bold())
                            
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    }
                    
                    //.padding()
                    .background(Color(.systemGray5),in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .padding(.top, -50)
                    
                    sleepTimeSlider()
                        .frame(maxHeight: screenBounds().height / 4)
                        .padding(.top, 200)
                    
                    
                    VStack(alignment: .leading){
                        Text("Selected Job:")
                            .font(.title)
                            .bold()
                            .padding(.horizontal)
                            .padding(.bottom, -50)
                        CardPicker(selectedJob: $selectedJob, jobs: jobs, selectedIndex: $selectedIndex)
                        //.padding(.horizontal)
                        
                    }.padding(.top, -100)
                    
                    
                    
                    Button {
                        startDate = getTime(angle: startAngle)
                        endDate = getTime(angle: toAngle, isEndDate: true)
                        selectedJob = jobs[selectedIndex]
                        createShift()
                    } label: {
                        Text("Schedule Shift")
                            .foregroundColor(.white)
                            .bold()
                            .padding(.vertical)
                            .padding(.horizontal, 40)
                            .background(.orange, in: Capsule())
                    }
                    
                }
                
            }
            .padding(.top, 35)
            
            .navigationBarTitle("Schedule a Shift")
        }
    }
    
    @ViewBuilder
    func sleepTimeSlider() -> some View{
        GeometryReader{ proxy in
            
            let width = proxy.size.width
            
            ZStack{
                
                ZStack {
                    ForEach(1...60, id: \.self) { index in
                        Rectangle()
                            .fill(index % 5 == 0 ? .gray : .black)
                        
                        
                        
                            .frame(width: 2, height: index % 5 == 0 ? 10 : 5)
                        
                            .offset(y: (width - 60) / 2)
                            .rotationEffect(.init(degrees: Double(index) * 6))
                    }
                    
                    let texts = [12,18,24,6]
                    ForEach(texts.indices, id: \.self){ index in
                        
                        Text("\(texts[index])")
                            .font(.caption.bold())
                            .foregroundColor(.gray)
                            .rotationEffect(.init(degrees: Double(index) * -90))
                            .offset(y: (width - 90) / 2)
                        
                            .rotationEffect(.init(degrees: Double(index) * 90))
                    }
                    
                    
                    
                    
                }
                
                
                
                Circle()
                    .stroke(.black.opacity(0.9), lineWidth: 50)
                
                
                
                let reverseRotation = (startProgress > toProgress) ? -Double((1 - startProgress) * 360) : 0
                Circle()
                    .trim(from: startProgress > toProgress ? 0 : startProgress, to: toProgress + (-reverseRotation / 360))
                    .stroke(Color(.systemGray5), style: StrokeStyle(lineWidth: 35, lineCap: .round, lineJoin: .round))
                    .rotationEffect(.init(degrees: -90))
                    .rotationEffect(.init(degrees: reverseRotation))
                
                
                Image(systemName: "figure.walk.arrival")
                    .font(.callout)
                    .foregroundColor(.black)
                    .frame(width: 30, height: 30)
                    .rotationEffect(.init(degrees: 90))
                    .rotationEffect(.init(degrees: -startAngle))
                    .background(.orange,in: Circle())
                    .offset(x: width / 2)
                    .rotationEffect(.init(degrees: startAngle))
                
                    .gesture(
                        DragGesture()
                            .onChanged({ value in
                                onDrag(value: value, fromSlider: true)
                            })
                    )
                    .rotationEffect(.init(degrees: -90))
                
                Image(systemName: "figure.walk.departure")
                    .font(.callout)
                    .foregroundColor(.black)
                    .frame(width: 30, height: 30)
                    .rotationEffect(.init(degrees: 90))
                    .rotationEffect(.init(degrees: -toAngle))
                    .background(.orange,in: Circle())
                    .offset(x: width / 2)
                
                    .rotationEffect(.init(degrees: toAngle))
                
                
                    .gesture(
                        DragGesture()
                            .onChanged({ value in
                                onDrag(value: value)
                            })
                    )
                    .rotationEffect(.init(degrees: -90))
                
                VStack(spacing: 8){
                    Text("\(getTimeDifference().0) hr")
                        .font(.largeTitle.bold())
                    Text("\(getTimeDifference().1) m")
                        .foregroundColor(.gray)
                }
                .scaleEffect(1.1)
                .haptics(onChangeOf: getTimeDifference().0, type: .light)
            }
        }
        .frame(width: screenBounds().width / 1.6, height: screenBounds().height / 1.6)
    }
    
    func onDrag(value: DragGesture.Value, fromSlider: Bool = false) {
        let vector = CGVector(dx: value.location.x, dy: value.location.y)
        
        let radians = atan2(vector.dy - 15, vector.dx - 15)
        
        var angle = radians * 180 / .pi
        if angle < 0 { angle = 360 + angle }
        let progress = angle / 360
        
        if fromSlider {
            self.startAngle = angle
            self.startProgress = progress
        } else {
            if angle < startAngle {
                angle += 360
            }
            self.toAngle = angle
            self.toProgress = progress
        }
    }
    
    
    func getTime(angle: Double, isEndDate: Bool = false) -> Date {
        let progress = angle / 360
        let totalMinutesIn24Hours = 24 * 60
        let minutes = Int(progress * Double(totalMinutesIn24Hours))
        
        let hour = (minutes / 60) % 24
        let minute = (minutes / 5) * 5 % 60
        
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        
        // Use the dateSelected value
        if let dateSelected = dateSelected {
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: dateSelected)
            components.year = dateComponents.year
            components.month = dateComponents.month
            components.day = dateComponents.day
        }
        
        // Handle end date moving to the next day
        if isEndDate && angle < startAngle {
            components.day! += 1
        }
        
        let calendar = Calendar.current
        let resultingDate = calendar.date(from: components) ?? Date()
        
        // If the end time is still earlier than the start time, add another day
        if isEndDate && resultingDate < getTime(angle: startAngle) {
            components.day! += 1
            return calendar.date(from: components) ?? Date()
        }
        
        return resultingDate
    }
    
    
    
    
    
    
    
    
    
    
    func getTimeDifference() -> (Int, Int) {
        let calendar = Calendar.current
        
        var components = calendar.dateComponents([.hour, .minute], from: getTime(angle: startAngle), to: getTime(angle: toAngle))
        
        if components.hour! < 0 {
            components.hour! += 24
        }
        
        if components.minute! < 0 {
            components.minute! += 60
            components.hour! -= 1
        }
        
        return (components.hour ?? 0, components.minute ?? 0)
    }
    
    
    
    
}

struct CardPicker: View {
    @Binding var selectedJob: Job?
    var jobs: FetchedResults<Job>
    @Binding var selectedIndex: Int
    
    var body: some View {
        TabView(selection: $selectedIndex){
            ForEach(jobs.indices, id: \.self) { index in
                CardView(job: jobs[index])
                    .tag(index)
            }
        }.tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}




// old add scheduled shift

/* Form {
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
 }.scrollContentBackground(.hidden)
 .navigationBarTitle("Create Shift")
 .toolbar {
 ToolbarItem(placement: .confirmationAction) {
 Button("Save", action: createShift)
 }
 } */

extension View {
    func screenBounds() -> CGRect {
        return UIScreen.main.bounds
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
    
    func formattedDuration() -> String {
        let interval = shift.endDate?.timeIntervalSince(shift.startDate ?? Date()) ?? 0
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
    
    var body: some View {
        VStack(alignment: .leading){
            HStack(spacing : 10){
                Image(systemName: shift.job?.icon ?? "briefcase.circle")
                    .foregroundColor(Color(red: Double(shift.job?.colorRed ?? 0), green: Double(shift.job?.colorGreen ?? 0), blue: Double(shift.job?.colorBlue ?? 0)))
                    .font(.system(size: 30))
                    .frame(width: UIScreen.main.bounds.width / 7)
                VStack(alignment: .leading, spacing: 5){
                    Text(shift.job?.name ?? "")
                        .font(.title2)
                        .bold()
                    Text(shift.job?.title ?? "")
                        .foregroundColor(Color(red: Double(shift.job?.colorRed ?? 0), green: Double(shift.job?.colorGreen ?? 0), blue: Double(shift.job?.colorBlue ?? 0)))
                        .font(.subheadline)
                        .bold()
                    Text(formattedDuration())
                        .bold()
                        .foregroundColor(.gray)
                    
                    
                    
                }
                
            }
            
            Chart{
                BarMark(
                    xStart: .value("Start Time", shift.startDate ?? Date()),
                    xEnd: .value("End Time", shift.endDate ?? Date())
                    //y: .value("Job", $0.job)
                ).foregroundStyle(Color(red: Double(shift.job?.colorRed ?? 0), green: Double(shift.job?.colorGreen ?? 0), blue: Double(shift.job?.colorBlue ?? 0)))
            }.chartXScale(domain: (shift.startDate?.addingTimeInterval(-3600) ?? Date())...(shift.endDate?.addingTimeInterval(3600) ?? Date()))
                .frame(height: 50)
            
            
            /*  Text("From \(dateFormatter.string(from: shift.startDate ?? Date())) to \(dateFormatter.string(from: shift.endDate ?? Date()))")
             .bold() */
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



struct CardView: View {
    var job: Job
    
    var body: some View {
        VStack(alignment: .leading){
            HStack(spacing : 10){
                Image(systemName: job.icon ?? "briefcase.circle")
                    .foregroundColor(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
                    .font(.system(size: 30))
                    .frame(width: UIScreen.main.bounds.width / 7)
                VStack(alignment: .leading, spacing: 5){
                    Text(job.name ?? "")
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
            }.frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            
        }
        .background(Color(.systemGray5),in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}
