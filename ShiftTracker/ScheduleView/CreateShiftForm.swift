//
//  CreateShiftForm.swift
//  ShiftTracker
//
//  Created by James Poole on 9/07/23.
//

import SwiftUI

struct CreateShiftForm: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var shiftStore: ScheduledShiftStore
    @EnvironmentObject var jobSelectionViewModel: JobSelectionViewModel
    
    @Environment(\.colorScheme) var colorScheme
    
    private let notificationManager = ShiftNotificationManager.shared
    
    //  let jobs: FetchedResults<Job>
    var dateSelected: Date?
    
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
    
    
    init(dateSelected: Date?) {
        self.dateSelected = dateSelected
        
        let defaultDate = dateSelected ?? Date()
        _startDate = State(initialValue: defaultDate)
        _endDate = State(initialValue: defaultDate)
        
        let defaultRepeatEnd = Calendar.current.date(byAdding: .month, value: 2, to: defaultDate)!
        _selectedRepeatEnd = State(initialValue: defaultRepeatEnd)
        
    }
    
    
    private func createShift() {
        
        let shiftID = UUID()
        let repeatID = UUID()
        
        let shiftToAdd = SingleScheduledShift(
            startDate: startDate,
            endDate: endDate,
            id: shiftID,
            job: jobSelectionViewModel.fetchJob(in: viewContext)!,
            isRepeating: enableRepeat,
            repeatID: repeatID,
            reminderTime: selectedReminderTime.timeInterval,
            notifyMe: notifyMe)
        
        
        
        let newShift = ScheduledShift(context: viewContext)
        newShift.startDate = startDate
        newShift.endDate = endDate
        newShift.id = shiftID
        newShift.newRepeatID = repeatID
        newShift.reminderTime = selectedReminderTime.timeInterval
        newShift.notifyMe = notifyMe
        newShift.job = jobSelectionViewModel.fetchJob(in: viewContext)
        
        
        do {
            try viewContext.save()
            if notifyMe {
                notificationManager.scheduleNotifications()
            }
            
            shiftStore.add(shiftToAdd)
            
            
            //  onShiftCreated()
            dismiss()
        } catch {
            print("Error creating shift: \(error.localizedDescription)")
        }
    }
    
    
    
    func saveRepeatingShiftSeries(startDate: Date, endDate: Date, repeatEveryWeek: Bool, repeatID: UUID) {
        
        let calendar = Calendar.current
        var currentStartDate = startDate
        var currentEndDate = endDate
        

        
        while currentStartDate <= selectedRepeatEnd {
            if selectedDays[getDayOfWeek(date: currentStartDate) - 1] {
                
                let shiftID = UUID()
                
                let shift = ScheduledShift(context: viewContext)
                shift.startDate = currentStartDate
                shift.endDate = currentEndDate
                shift.job = jobSelectionViewModel.fetchJob(in: viewContext)
                shift.id = shiftID
                shift.isRepeating = repeatEveryWeek
                shift.newRepeatID = repeatEveryWeek ? repeatID : UUID()
                shift.notifyMe = notifyMe
                shift.reminderTime = selectedReminderTime.timeInterval
                
                let shiftToAdd = SingleScheduledShift(
                    startDate: currentStartDate,
                    endDate: currentEndDate,
                    id: shiftID,
                    job: jobSelectionViewModel.fetchJob(in: viewContext)!,
                    isRepeating: enableRepeat,
                    repeatID: repeatID,
                    reminderTime: selectedReminderTime.timeInterval,
                    notifyMe: notifyMe)
                
                shiftStore.add(shiftToAdd)
                
            }
            
            // Move to the next day, whether a shift was scheduled or not.
            currentStartDate = calendar.date(byAdding: .day, value: 1, to: currentStartDate)!
            currentEndDate = calendar.date(byAdding: .day, value: 1, to: currentEndDate)!
        }
        
        // Save the context after creating all the shifts
        do {
            try viewContext.save()
            notificationManager.scheduleNotifications()
            //  onShiftCreated()
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
                    VStack(spacing: 18){
                        Toggle(isOn: $enableRepeat){
                            Text("Repeat")
                                .bold()
                        }.toggleStyle(CustomToggleStyle())
                        
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
                }.listRowBackground(Color("SquaresColor"))
                Section {
                    VStack{
                        
                        Toggle(isOn: $notifyMe){
                            Text("Remind Me")
                                .bold()
                        }.toggleStyle(CustomToggleStyle())
                        
                        Picker("When", selection: $selectedReminderTime) {
                            ForEach(ReminderTime.allCases) { reminderTime in
                                Text(reminderTime.rawValue).tag(reminderTime)
                            }
                        }.disabled(!notifyMe)
                        
                    }
                }.listRowBackground(Color("SquaresColor"))
            }.scrollContentBackground(.hidden)
            
                .toolbar{
                    ToolbarItem(placement: .navigationBarTrailing){
                        Button {
                            startDate = getTime(angle: startAngle)
                            endDate = getTime(angle: toAngle, isEndDate: true)
                            selectedJob = jobSelectionViewModel.fetchJob(in: viewContext)
                            
                            if enableRepeat {
                                
                                
                                saveRepeatingShiftSeries(startDate: getTime(angle: startAngle), endDate: getTime(angle: toAngle, isEndDate: true), repeatEveryWeek: true, repeatID: UUID())
                                 
                            }
                            else {
                                createShift()
                            }
                        } label: {
                            Text("Save")
                                .bold()
                            
                        }.padding()
                    }
                    ToolbarItem(placement: .navigationBarLeading){
                        CloseButton{
                            dismiss()
                        }
                    }
                }
                .navigationBarTitle("Schedule", displayMode: .inline)
                .toolbarBackground(colorScheme == .dark ? .black : .white, for: .navigationBar)
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
