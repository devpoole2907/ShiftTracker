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
import Foundation
import UserNotifications

struct ScheduledShiftsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @Environment(\.presentationMode) var presentationMode
    
    @Environment(\.colorScheme) var colorScheme
    
    
    @Binding var dateSelected: DateComponents?
    @Binding var showMenu: Bool
    
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
    
    func cancelNotification(for scheduledShift: ScheduledShift) {
        let identifier = "ScheduledShift-\(scheduledShift.objectID)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    


    
    var body: some View {
        NavigationStack {
            Group {
                if let _ = dateSelected {
                    let shifts = shiftsForSelectedDate()
                    if !shifts.isEmpty {
                        List {
                            ForEach(shifts, id: \.objectID) { shift in
                                ListViewRow(shift: shift)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            cancelNotification(for: shift)
                                            viewContext.delete(shift)
                                            try? viewContext.save()
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                    }
                                    .listRowBackground(Color.primary.opacity(0.05))
                            }
                        }.scrollContentBackground(.hidden)
                    } else {
                        Text("You have no shifts scheduled on this date.")
                            .bold()
                        
                    }
                }
            }
            .navigationBarTitle(dateSelected?.date?.formatted(date: .long, time: .omitted) ?? "", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing){
                    Button(action: {
                        if jobs.isEmpty {
                            presentationMode.wrappedValue.dismiss()
                            OkButtonPopupWithAction(title: "Create a job before scheduling a shift.", action: {showMenu.toggle()}).present()
                                
                        } else {
                            showCreateShiftSheet = true
                        }
                    }) {
                        Image(systemName: "plus")
                            .bold()
                    }.padding()
                }
            }
        }
        .sheet(isPresented: $showCreateShiftSheet) {
            CreateShiftForm(jobs: jobs, dateSelected: dateSelected?.date, onShiftCreated: {
                showCreateShiftSheet = false
            })
            .environment(\.managedObjectContext, viewContext)
            .presentationDetents([.large])
            .presentationCornerRadius(50)
            .presentationBackground(colorScheme == .dark ? .black : .white)
            .presentationDragIndicator(.visible)
        }
    }
    
}

struct CreateShiftForm: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @Environment(\.colorScheme) var colorScheme
    
    private let notificationManager = ShiftNotificationManager.shared
    
    let jobs: FetchedResults<Job>
    var dateSelected: Date?
    
    @State private var selectedJobIndex: Int = 0
    @State private var selectedJob: Job?
    @State private var startDate: Date
    @State private var endDate: Date
    @State var selectedDays = Array(repeating: false, count: 7)
    
    @State private var enableRepeat = false
    
    @State private var selectedRepeatEnd: Date
    
    @State private var selectedIndex: Int = 0
    
    // for notifications
    @State private var notifyMe = true
    @State private var selectedReminderTime: ReminderTime = .fifteenMinutes
    
    
    
    var onShiftCreated: () -> Void
    
    init(jobs: FetchedResults<Job>, dateSelected: Date?, onShiftCreated: @escaping () -> Void) {
        self.jobs = jobs
        self.dateSelected = dateSelected
        self.onShiftCreated = onShiftCreated
        
        let defaultDate = dateSelected ?? Date()
        _startDate = State(initialValue: defaultDate)
        _endDate = State(initialValue: defaultDate)
        _selectedJob = State(initialValue: jobs.first)
        
        let defaultRepeatEnd = Calendar.current.date(byAdding: .month, value: 6, to: defaultDate)!
        _selectedRepeatEnd = State(initialValue: defaultRepeatEnd)
        
    }
    
    
    private func createShift() {
        let newShift = ScheduledShift(context: viewContext)
        newShift.startDate = startDate
        newShift.endDate = endDate
        newShift.job = jobs[selectedJobIndex]
        newShift.id = UUID()
        newShift.notifyMe = notifyMe
        newShift.reminderTime = selectedReminderTime.timeInterval
        
        do {
            try viewContext.save()
            if notifyMe {
                notificationManager.scheduleNotifications()
            }
            onShiftCreated()
            dismiss()
        } catch {
            print("Error creating shift: \(error.localizedDescription)")
        }
    }
    
    
    
    func saveRepeatingShiftSeries(startDate: Date, endDate: Date, repeatEveryWeek: Bool) {
    let repeatID = generateUniqueID()

    let calendar = Calendar.current
    var currentStartDate = startDate
    var currentEndDate = endDate
    
    // Create a dictionary to store the days on which a shift has been scheduled
    var scheduledDays = [String: Bool]()

    while currentStartDate <= selectedRepeatEnd {
        // Format the date to a simple day format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let currentDateString = dateFormatter.string(from: currentStartDate)

        if selectedDays[getDayOfWeek(date: currentStartDate) - 1] && scheduledDays[currentDateString] == nil {
            let shift = ScheduledShift(context: viewContext)
            shift.startDate = currentStartDate
            shift.endDate = currentEndDate
            shift.job = jobs[selectedJobIndex]
            shift.id = UUID()
            shift.isRepeating = repeatEveryWeek
            shift.repeatID = repeatEveryWeek ? repeatID : nil
            shift.notifyMe = notifyMe
            shift.reminderTime = selectedReminderTime.timeInterval
            
            // Mark the current day as scheduled
            scheduledDays[currentDateString] = true
        }

        // Move to the next day
        currentStartDate = calendar.date(byAdding: .day, value: 1, to: currentStartDate)!
        currentEndDate = calendar.date(byAdding: .day, value: 1, to: currentEndDate)!
    }

    // Save the context after creating all the shifts
    do {
        try viewContext.save()
        notificationManager.scheduleNotifications()
        onShiftCreated()
        dismiss()
    } catch {
        print("Error saving repeating shift series: \(error)")
    }
}



    
    @State var startAngle: Double = 0
    @State var toAngle: Double = 180
    
    @State var startProgress: CGFloat = 0
    @State var toProgress: CGFloat = 0.5
    
    var body: some View {
        
        let iconColor: Color = colorScheme == .dark ? .orange : .cyan
        let jobBackground: Color = colorScheme == .dark ? Color(.systemGray5) : .black
        NavigationStack {
            List{
                Section{
                    HStack(spacing: 25){
                        VStack(alignment: .center, spacing: 5){
                         
                            
                            
                            HStack{
                                Image(systemName: "figure.walk.arrival")
                                    .foregroundColor(iconColor)
                                Text("Start")
                                    .bold()
                            }
                            .font(.callout)
                            Text(getTime(angle: startAngle).formatted(date: .omitted, time: .shortened))
                                .font(.title2.bold())
                            
                            Text(getTime(angle: startAngle).formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .bold()
                            
                            
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        VStack(alignment: .center, spacing: 5){
                            HStack{
                                Image(systemName: "figure.walk.departure")
                                    .foregroundColor(iconColor)
                                Text("End")
                                    .bold()
                            }
                            .font(.callout)
                            
                            Text(getTime(angle: toAngle, isEndDate: true).formatted(date: .omitted, time: .shortened))
                                .font(.title2.bold())
                            
                            Text(getTime(angle: toAngle, isEndDate: true).formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .bold()
                            
                            
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        //.padding(.horizontal)
                    }.listRowSeparator(.hidden)
                        .padding(.top, 10)
                    VStack{
                        scheduleSlider()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 30)
                        Spacer()
                    }
                    .frame(minHeight: screenBounds().height / 3)
                }.listRowBackground(Color.clear)
                    
                Section {
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(0..<jobs.count, id: \.self) { index in
                                        Button(action: {
                                            selectedJobIndex = index
                                        }) {
                                            HStack(spacing: 10) {
                                                Image(systemName: jobs[index].icon ?? "briefcase.circle")
                                                    .foregroundColor(Color(red: Double(jobs[index].colorRed),
                                                                           green: Double(jobs[index].colorGreen),
                                                                           blue: Double(jobs[index].colorBlue)))
                                                Text(jobs[index].name ?? "")
                                                    .bold()
                                                    .foregroundColor(selectedJobIndex == index ? .white : .gray)
                                            }
                                            .padding()
                                            .background(selectedJobIndex == index ? jobBackground : Color.primary.opacity(0.04))
                                            .cornerRadius(50)
                                        }
                                    }
                                }.haptics(onChangeOf: selectedJobIndex, type: .light)
                               // .padding(.horizontal)
                            }.mask(
                                HStack(spacing: 0) {
                                    LinearGradient(gradient:
                                       Gradient(
                                        colors: [Color.primary.opacity(0.04), Color.black]),
                                           startPoint: .leading, endPoint: .trailing
                                       )
                                       .frame(width: 7)

                                    Rectangle().fill(Color.black)

                                    LinearGradient(gradient:
                                       Gradient(
                                        colors: [Color.black, Color.primary.opacity(0.04)]),
                                           startPoint: .leading, endPoint: .trailing
                                       )
                                       .frame(width: 7)
                                }
                             )
                    
                    
                        }.listRowBackground(Color.primary.opacity(0.05))
                Section {
                    VStack(spacing: 18){
                        Toggle(isOn: $enableRepeat){
                            Text("Repeat")
                                .bold()
                        }.toggleStyle(OrangeToggleStyle())
                        
                        HStack {
                                    ForEach(0..<7) { i in
                                        Button(action: {
                                            if i == getDayOfWeek(date: startDate) - 1 {
                                                return
                                            }
                                            selectedDays[i].toggle()
                                        }) {
                                            Text(getDayShortName(day: i))
                                                .font(.system(size: 14))
                                                .bold()
                                        }
                                      //  .padding()
                                        .background(selectedDays[i] ? (colorScheme == .dark ? .white : .black) : Color(.systemGray6))
                                        .foregroundColor(colorScheme == .dark ? .black : .white)
                                        .cornerRadius(8)
                                        .buttonStyle(.bordered)
                                        .frame(height: 15)
                                        .disabled(!enableRepeat)
                                    }
                                }.onAppear {
                                    selectedDays[getDayOfWeek(date: startDate) - 1] = true
                                }
                                .haptics(onChangeOf: selectedDays, type: .light)
                        
                        
                        RepeatEndPicker(startDate: getTime(angle: startAngle), selectedRepeatEnd: $selectedRepeatEnd)
                            .disabled(!enableRepeat)
                    }
                }.listRowBackground(Color.primary.opacity(0.05))
                Section {
                    VStack{
                        
                        Toggle(isOn: $notifyMe){
                            Text("Remind Me")
                                .bold()
                        }.toggleStyle(OrangeToggleStyle())
                        
                        Picker("When", selection: $selectedReminderTime) {
                            ForEach(ReminderTime.allCases) { reminderTime in
                                Text(reminderTime.rawValue).tag(reminderTime)
                            }
                        }.disabled(!notifyMe)
                        
                    }
                }.listRowBackground(Color.primary.opacity(0.05))
            }.scrollContentBackground(.hidden)
            
                .toolbar{
                    ToolbarItem(placement: .navigationBarTrailing){
                        Button {
                            startDate = getTime(angle: startAngle)
                            endDate = getTime(angle: toAngle, isEndDate: true)
                            selectedJob = jobs[selectedIndex]
                            
                            if enableRepeat {
                                saveRepeatingShiftSeries(startDate: getTime(angle: startAngle), endDate: getTime(angle: toAngle, isEndDate: true), repeatEveryWeek: true)
                            }
                            else {
                                createShift()
                            }
                        } label: {
                            Text("Save")
                                .bold()
                                
                        }.padding()
                    }
                }
                .navigationBarTitle("Schedule", displayMode: .inline)
        }
    }
    
    @ViewBuilder
    func scheduleSlider() -> some View{
        
        let sliderBackgroundColor: Color = colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)
        let sliderColor: Color = colorScheme == .dark ? .black.opacity(0.8) : .white
        
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
                    
                    let texts = ["12PM","   6PM","12AM","6AM   "]
                    ForEach(texts.indices, id: \.self){ index in
                        
                        Text("\(texts[index])")
                            .font(.caption.bold())
                            
                            .rotationEffect(.init(degrees: Double(index) * -90))
                            .offset(y: (width - 90) / 2)
                            .rotationEffect(.init(degrees: Double(index) * 90))
                    }
                }
                Circle()
                    .stroke(sliderBackgroundColor, lineWidth: 45)
                    .shadow(radius: 5, x: 2, y: 1)
                
                
                let reverseRotation = (startProgress > toProgress) ? -Double((1 - startProgress) * 360) : 0
                Circle()
                    .trim(from: startProgress > toProgress ? 0 : startProgress, to: toProgress + (-reverseRotation / 360))
                    .stroke(sliderColor, style: StrokeStyle(lineWidth: 30, lineCap: .round, lineJoin: .round))
                    .rotationEffect(.init(degrees: -90))
                    .rotationEffect(.init(degrees: reverseRotation))
                
                
                Image(systemName: "figure.walk.arrival")
                    .font(.callout)
                    .foregroundColor(.gray)
                    .frame(width: 30, height: 30)
                    .rotationEffect(.init(degrees: 90))
                    .rotationEffect(.init(degrees: -startAngle))
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
                    .foregroundColor(.gray)
                    .frame(width: 30, height: 30)
                    .rotationEffect(.init(degrees: 90))
                    .rotationEffect(.init(degrees: -toAngle))
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
                        .font(.title.bold())
                    Text("\(getTimeDifference().1) m")
                        .foregroundColor(.gray)
                }
                .scaleEffect(1.1)
                .haptics(onChangeOf: getTimeDifference().0, type: .light)
            }
        }
        .frame(width: screenBounds().width / 1.7)
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

extension View {
    func screenBounds() -> CGRect {
        return UIScreen.main.bounds
    }
}


struct ListViewRow: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
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
    
    func cancelRepeatingShiftSeries(shift: ScheduledShift) {
        guard let repeatID = shift.repeatID else { return }
        
        let request: NSFetchRequest<ScheduledShift> = ScheduledShift.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "repeatID == %@", repeatID),
            NSPredicate(format: "startDate > %@", shift.startDate! as NSDate)
        ])
        
        do {
            let futureShifts = try viewContext.fetch(request)
            for futureShift in futureShifts {
                viewContext.delete(futureShift)
            }
            cancelNotifications(for: futureShifts)
            try viewContext.save()
        } catch {
            print("Error canceling repeating shift series: \(error)")
        }
    }
    
    func cancelNotifications(for shifts: [ScheduledShift]) {
        let identifiers = shifts.map { "ScheduledShift-\($0.objectID)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
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
            
            if shift.isRepeating {
                Button{
                    dismiss()
                    CustomConfirmationAlert(action: {
                        cancelRepeatingShiftSeries(shift: shift)
                    }, title: "End all future repeating shifts for this shift?").present()
                } label: {
                    Text("End Repeat").bold()
                }
            }
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
        ScheduledShiftsView(dateSelected: .constant(dateComponents), showMenu: .constant(false))
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
                    .frame(width: screenBounds().width / 7)
                VStack(alignment: .leading, spacing: 5){
                    Text(job.name ?? "")
                        .font(.title2)
                        .bold()
                    Text(job.title ?? "")
                        .foregroundColor(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
                        .font(.subheadline)
                        .bold()
                  /*  Text("$\(job.hourlyPay, specifier: "%.2f") / hr")
                        .foregroundColor(.gray)
                        .font(.footnote)
                        .bold() */
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
                //.padding()
            
        }
        //.background(Color(.systemGray5),in: RoundedRectangle(cornerRadius: 12))
        //.padding(.horizontal, 20)
        //.padding(.vertical, 10)
    }
}

// used to generate the same ID for scheduledshifts that repeat.

func generateUniqueID() -> String {
    return UUID().uuidString
}

struct RepeatEndPicker: View {
    
    private let options = ["1 month", "3 months", "6 months"]
    private let calendar = Calendar.current
    
    @State private var selectedIndex = 2 // Default to 6 months
    @Binding var selectedRepeatEnd: Date
    let startDate: Date  // Add startDate as a property
    
    init(startDate: Date, selectedRepeatEnd: Binding<Date>) {
        self.startDate = startDate
        self._selectedRepeatEnd = selectedRepeatEnd
        let defaultRepeatEnd = calendar.date(byAdding: .month, value: 6, to: startDate)!
        self._selectedIndex = State(initialValue: self.options.firstIndex(of: "\(6) months")!)
        // set the selectedIndex to the index of the default repeat end option
    }
    
    var body: some View {
        Picker("End Repeat", selection: $selectedIndex) {
            ForEach(0..<options.count) { index in
                Text(options[index]).tag(index)
            }
        }
        .onChange(of: selectedIndex) { value in
            let months = [1, 3, 6][value]
            selectedRepeatEnd = calendar.date(byAdding: .month, value: months, to: startDate)! // Use startDate instead of selectedRepeatEnd
        }
    }
    
}

enum ReminderTime: String, CaseIterable, Identifiable {
    case oneMinute = "1 minute before"
    case fifteenMinutes = "15 minutes before"
    case thirtyMinutes = "30 minutes before"
    case oneHour = "1 hour before"

    var id: String { self.rawValue }
    var timeInterval: TimeInterval {
        switch self {
        case .oneMinute:
            return 60
        case .fifteenMinutes:
            return 15 * 60
        case .thirtyMinutes:
            return 30 * 60
        case .oneHour:
            return 60 * 60
        }
    }
}

