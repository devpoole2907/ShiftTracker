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
    
    @EnvironmentObject var shiftStore: ShiftStore
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    
    @Environment(\.colorScheme) var colorScheme
    
    private let notificationManager = ShiftNotificationManager.shared
    
    //  let jobs: FetchedResults<Job>
    @Binding var dateSelected: DateComponents?
    
    @State private var selectedJob: Job?
    @State private var startDate: Date
    @State private var endDate: Date
    @State var selectedDays = Array(repeating: false, count: 7)
    
    @State private var enableRepeat = false
    
    @State private var selectedRepeatEnd: Date
    
    @State private var selectedIndex: Int = 0
    
    @State private var selectedTags: Set<Tag> = []
    
    // for notifications
    @State private var notifyMe = true
    @State private var selectedReminderTime: ReminderTime = .fifteenMinutes
    
    
    init(dateSelected: Binding<DateComponents?>) {
        _dateSelected = dateSelected

        let defaultDate: Date = Calendar.current.date(from: dateSelected.wrappedValue ?? DateComponents()) ?? Date()
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
            notifyMe: notifyMe,
            tags: selectedTags)
        
        
        
        let newShift = ScheduledShift(context: viewContext)
        newShift.startDate = startDate
        newShift.endDate = endDate
        newShift.id = shiftID
        newShift.newRepeatID = repeatID
        newShift.isRepeating = enableRepeat
        newShift.reminderTime = selectedReminderTime.timeInterval
        newShift.notifyMe = notifyMe
        newShift.job = jobSelectionViewModel.fetchJob(in: viewContext)
        newShift.tags = NSSet(array: Array(selectedTags))
        
        do {
            try viewContext.save()
            if notifyMe {
                notificationManager.scheduleNotifications()
            }
            
            shiftStore.add(shiftToAdd)
            
            if newShift.isRepeating {
                        saveRepeatingShiftSeries(startDate: startDate, endDate: endDate, repeatEveryWeek: enableRepeat, repeatID: repeatID)
                    }
            
            //  onShiftCreated()
            dismiss()
        } catch {
            print("Error creating shift: \(error.localizedDescription)")
        }
    }
    
    
    
    func saveRepeatingShiftSeries(startDate: Date, endDate: Date, repeatEveryWeek: Bool, repeatID: UUID) {
        
        let calendar = Calendar.current
        var currentStartDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
            var currentEndDate = calendar.date(byAdding: .day, value: 1, to: endDate)!
        

        
        while currentStartDate <= selectedRepeatEnd {
            if selectedDays[getDayOfWeek(date: currentStartDate) - 1] {
                
                let shiftID = UUID()
                
                let shift = ScheduledShift(context: viewContext)
                shift.startDate = currentStartDate
                shift.endDate = currentEndDate
                shift.job = jobSelectionViewModel.fetchJob(in: viewContext)
                shift.id = shiftID
                shift.isRepeating = repeatEveryWeek
                shift.newRepeatID = repeatEveryWeek ? repeatID : UUID() //  check this code
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
                    notifyMe: notifyMe,
                    tags: selectedTags)
                
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
        NavigationStack {
            ScrollView{
                
                VStack(spacing: 15){
                 
                    VStack(spacing: 5){
                        
                        HStack(spacing: 5){
                            
                            Toggle(isOn: $enableRepeat){
                                Text("Repeat")
                                    .bold()
                            }.toggleStyle(CustomToggleStyle())
                                .frame(height: 40)
                            //  .padding(.vertical)
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity)
                                .background(Color("SquaresColor"))
                                .cornerRadius(12)
                            //  .padding()
                            
                            
                            RepeatEndPicker(dateSelected: $dateSelected, selectedRepeatEnd: $selectedRepeatEnd)
                                .frame(height: 40)
                            //  .padding(.vertical)
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity)
                                .disabled(!enableRepeat)
                            
                                .background(Color("SquaresColor"))
                                .cornerRadius(12)
                            
                            // .padding()
                        }.padding(.horizontal)
                        
                        
                        
                        
                            .onAppear {
                                selectedDays[getDayOfWeek(date: (dateSelected?.date ?? Date())) - 1] = true
                                
                                print("start date is : \(startDate)")
                            }
                            .haptics(onChangeOf: selectedDays, type: .light)
                        
                        HStack {
                            ForEach(0..<7) { i in
                                Button(action: {
                                    if i == getDayOfWeek(date: startDate) - 1 {
                                        return
                                    }
                                    selectedDays[i].toggle()
                                }) {
                                    Text(getDayShortName(day: i))
                                        .font((UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? .caption : .callout)
                                        .bold()
                                }
                                //  .padding()
                                .background(selectedDays[i] ? (colorScheme == .dark ? .white : .black) : Color(.systemGray6))
                                .foregroundColor(colorScheme == .dark ? .black : .white)
                                .cornerRadius(8)
                                .clipShape(Circle())
                                .buttonStyle(.bordered)
                                .frame(height: 15)
                                .frame(maxWidth: .infinity)
                                .disabled(!enableRepeat)
                            }
                        }
                        
                        .padding()
                        
                        .background(Color("SquaresColor"))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                    }
                    
                    VStack(spacing: 10){
                    
                    HStack(spacing: 10){
                        VStack(alignment: .center, spacing: 2){
                            
                            
                            
                            HStack{
                                Image(systemName: "figure.walk.arrival")
                                    .foregroundColor(iconColor)
                                Text("START")
                                    .foregroundStyle(.gray)
                                    .bold()
                            }
                            .font(.system(.caption, design: .rounded))
                            Text(getTime(angle: startAngle).formatted(date: .omitted, time: .shortened))
                              
                            
                                .font(.system(.title3, design: .rounded))
                                .bold()
                            
                            Text(getTime(angle: startAngle).formatted(date: .abbreviated, time: .omitted))
                                .font(.system(.caption2, design: .rounded))
                                .foregroundColor(.gray)
                                .bold()
                            
                            
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        VStack(alignment: .center, spacing: 2){
                            HStack{
                                Image(systemName: "figure.walk.departure")
                                    .foregroundColor(iconColor)
                                Text("END")
                                    .bold()
                                    .foregroundStyle(.gray)
                            }
                            .font(.system(.caption, design: .rounded))
                            
                            Text(getTime(angle: toAngle, isEndDate: true).formatted(date: .omitted, time: .shortened))
                                .font(.system(.title3, design: .rounded))
                                .bold()
                            
                            Text(getTime(angle: toAngle, isEndDate: true).formatted(date: .abbreviated, time: .omitted))
                                .font(.system(.caption2, design: .rounded))
                                .foregroundColor(.gray)
                                .bold()
                            
                            
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        //.padding(.horizontal)
                    }.listRowSeparator(.hidden)
                        .padding(.top)
                    
                    scheduleSlider()
                    //  .frame(maxWidth: .infinity, alignment: .center)
                        .frame(minHeight: (UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? screenBounds().height / 2 : screenBounds().height / 3)
                    // .frame(minWidth: screenBounds().width - 40)
                        .padding(.top, (UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? 20 : 30)
                        .padding(.bottom, (UIScreen.main.bounds.height) == 667 || (UIScreen.main.bounds.height) == 736 ? -85 : -10)
                        
                        
                        HStack(spacing: 5){
                            Text("\(getTimeDifference().0) hr")
                                
                            Text("\(getTimeDifference().1) m")
                               
                        }.font(.title.bold())
                            .fontDesign(.rounded)
                                .padding(.bottom)
                                .padding(.top, -10)
                    
                }
                    
                    .background(Color("SquaresColor"))
                    .cornerRadius(12)
                    .padding(.horizontal)
                
                    
                    VStack(spacing: 10){
                        
                        
                        
                        HStack(spacing: 5){
                            
                            Toggle(isOn: $notifyMe){
                                Text("Reminder")
                                    .bold()
                            }.toggleStyle(CustomToggleStyle())
                                .frame(height: 40)
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity)
                                .background(Color("SquaresColor"))
                                .cornerRadius(12)
                            
                            
                            
                            Picker("When", selection: $selectedReminderTime) {
                                ForEach(ReminderTime.allCases) { reminderTime in
                                    Text(reminderTime.rawValue).tag(reminderTime)
                                }
                            }.disabled(!notifyMe)
                            
                                .frame(height: 40)
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity)
                      
                            
                                .background(Color("SquaresColor"))
                                .cornerRadius(12)
                            
                        }.padding(.horizontal)
                        
                        HStack{
                            TagPicker($selectedTags)
                        }.padding(.horizontal)
                           
                        
                    }
                    
                }
          
            }.scrollContentBackground(.hidden)
            
                .toolbar{
                    ToolbarItem(placement: .navigationBarTrailing){
                        Button {
                            startDate = getTime(angle: startAngle)
                            endDate = getTime(angle: toAngle, isEndDate: true)
                            selectedJob = jobSelectionViewModel.fetchJob(in: viewContext)
                            
                            
                            createShift()
                            
                           
                        } label: {
                            Image(systemName: "folder.badge.plus")
                                .bold()
                            
                        }.padding()
                    }
                    ToolbarItem(placement: .navigationBarLeading){
                        CloseButton{
                            dismiss()
                        }
                    }
                }
                .navigationTitle("Schedule")
    
                .toolbarBackground(colorScheme == .dark ? .black : .white, for: .navigationBar)
        }.onAppear {
            
            print("start date is \(startDate)")
            
            
        }
    }
    
    @ViewBuilder
    func scheduleSlider() -> some View{
        
        let sliderBackgroundColor: Color = colorScheme == .dark ? Color(.black) : Color(.systemGray5)
        let sliderColor: Color = colorScheme == .dark ? Color(.systemGray6) : .white
        
        GeometryReader{ proxy in
            
            let width = proxy.size.width
            
            ZStack{
                
                ZStack {
                    
                    Circle()
                        .foregroundStyle(colorScheme == .dark ? Color("SquaresColor") : .white)
                    
                    ForEach(1...60, id: \.self) { index in
                        Rectangle()
                            .fill(index % 5 == 0 ? .gray : .black)
                        
                        
                        
                            .frame(width: 2, height: index % 5 == 0 ? 10 : 5)
                        
                            .offset(y: (width - 60) / 2)
                            .rotationEffect(.init(degrees: Double(index) * 6))
                    }
                    
                    let texts = ["12","6","12","6"]
                    let textsTimes = ["PM","PM","AM","AM"]
                    ForEach(texts.indices, id: \.self){ index in
                        VStack(spacing: 2){
                            
                            if texts[index] == "12" && textsTimes[index] == "PM" {
                             
                                Image(systemName: "sun.max.fill")
                                    .foregroundStyle(.yellow)
                                    .bold()
                                    .font(.caption2)
                                
                            }
                            
                            HStack(alignment: .lastTextBaseline, spacing: 0){
                                Text("\(texts[index])")
                                    .font(.system(.footnote, design: .rounded))
                                    .bold()
                                Text("\(textsTimes[index])")
                                    .font(.system(.caption2, design: .rounded))
                                    .bold()
                                
                            }
                            
                           
                            
                            if texts[index] == "12" && textsTimes[index] == "AM" {
                                
                                Image(systemName: "moon.stars.fill")
                                    .foregroundStyle(.cyan)
                                    .bold()
                                    .font(.caption2)
                            
                                
                            }
                            
                        }.padding(.bottom, (texts[index] == "12" && textsTimes[index] == "PM") ? 20 : 0)
                            .padding(.top, (texts[index] == "12" && textsTimes[index] == "AM") ? 20 : 0)
                            .padding(.trailing, (texts[index] == "6" && textsTimes[index] == "AM") ? 20 : 0)
                            .padding(.leading, (texts[index] == "6" && textsTimes[index] == "PM") ? 20 : 0)
                        
                            .rotationEffect(.init(degrees: Double(index) * -90))
                            .offset(y: (width - 90) / 2)
                            .rotationEffect(.init(degrees: Double(index) * 90))
                    }
                }
                    
                Circle()
                    .stroke(sliderBackgroundColor, lineWidth: 45)
               
                   // .shadow(radius: 5, x: 2, y: 1)
                
                
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
                
                
               // .scaleEffect(1.1)
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
        
        
        if let dateSelected = dateSelected {
            
            let dateComponents = dateSelected
            
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
