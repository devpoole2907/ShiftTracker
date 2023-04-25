//
//  DetailView.swift
//  ShiftTracker
//
//  Created by James Poole on 20/03/23.
//

import SwiftUI
import CoreData
import Foundation
import Charts

struct DetailView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(\.managedObjectContext) private var context
    
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var notes: String
    @FocusState private var noteIsFocused: Bool
    @State private var isEditing: Bool = false
    
    @State private var showingDeleteAlert = false
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
    
    @State private var selectedStartDate: Date
    @State private var selectedEndDate: Date
    @State private var selectedBreakStartDate: Date
    @State private var selectedBreakEndDate: Date
    @State private var selectedTaxPercentage: Double
    @State private var selectedHourlyPay: Double
    @State private var shiftDuration: TimeInterval
    @State private var selectedTotalTips: Double
    @State private var addTipsToTotal: Bool = false
    
    //tags stuff
    
    @AppStorage("tagList") private var tagsList: Data = Data()
    @State private var tags: [Tag] = []
    @State private var selectedTag: Tag? = nil
    
    @AppStorage("TipsEnabled") private var tipsEnabled: Bool = true
    @AppStorage("TaxEnabled") private var taxEnabled: Bool = true
    
    @FocusState private var payIsFocused: Bool
    
    @FetchRequest(entity: OldShift.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)])
    var shifts: FetchedResults<OldShift>
    
    @ObservedObject var shift: OldShift
    
    init(shift: OldShift) {
        self.shift = shift
        _notes = State(wrappedValue: shift.shiftNote ?? "")
        _selectedStartDate = State(wrappedValue: shift.shiftStartDate ?? Date())
        _selectedEndDate = State(wrappedValue: shift.shiftEndDate ?? Date())
        _selectedBreakStartDate = State(wrappedValue: shift.breakStartDate ?? Date())
        _selectedBreakEndDate = State(wrappedValue: shift.breakEndDate ?? Date())
        _selectedTaxPercentage = State(wrappedValue: shift.tax )
        _selectedHourlyPay = State(wrappedValue: shift.hourlyPay)
        //_selectedTag = State(wrappedValue: shift.tag)
        _shiftDuration = State(wrappedValue: shift.duration)
        _selectedTotalTips = State(wrappedValue: shift.totalTips)
    }
    
    func totalBreakDuration(for breaks: Set<Break>) -> TimeInterval {
        let paidBreaks = breaks.filter { $0.isUnpaid == true }
        let totalDuration = paidBreaks.reduce(0) { (sum, breakItem) -> TimeInterval in
            let breakDuration = breakItem.endDate?.timeIntervalSince(breakItem.startDate ?? Date())
            return sum + (breakDuration ?? 0.0)
        }
        return totalDuration
    }
    
    let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    
    var shiftData: [ShiftProfitCategory] {
        [
            ShiftProfitCategory(profit: shift.taxedPay, payCategory: "After Tax"),
            ShiftProfitCategory(profit: shift.totalPay - shift.taxedPay, payCategory: "Tax"),
            ShiftProfitCategory(profit: shift.totalTips, payCategory: "Tips")
        ]
    }
    
    @State private var offsetX = 0.0
    @State private var offsetY = 150.0
    
    @State private var showSelectionBar = false
    
    @State private var selectedDay = ""
    @State private var selectedValue: Double = 0
    @State private var selectedMins = 0.0
    
    var body: some View {
        
        let taxedBackgroundColor: Color = colorScheme == .dark ? Color.green.opacity(0.7) : Color.green.opacity(0.8)
        let totalBackgroundColor: Color = colorScheme == .dark ? Color.pink.opacity(0.7) : Color.pink.opacity(0.8)
        let tipsBackgroundColor: Color = colorScheme == .dark ? Color.teal.opacity(0.7) : Color.teal.opacity(0.8)
        let timerBackgroundColor: Color = colorScheme == .dark ? Color.orange.opacity(0.7) : Color.orange.opacity(0.8)
        let indigoBackgroundColor: Color = colorScheme == .dark ? Color.indigo.opacity(0.7) : Color.indigo.opacity(0.8)
        
        
        List{
            Section{
                HStack{
                    VStack(alignment: .center){
                        Chart {
                            ForEach(shiftData) { data in
                                BarMark(
                                    y: .value("Profit", data.profit)
                                )
                                .foregroundStyle(by: .value("Pay Category", data.payCategory))
                                
                            }
                        }//.chartYScale(domain: 0...shift.totalPay)
                        
                        //.fixedSize()
                        .frame(width: 80)
                        .padding()
                        
                        .chartLegend(.hidden)
                        .chartForegroundStyleScale(["After Tax": LinearGradient(gradient: Gradient(colors: [taxedBackgroundColor]), startPoint: .top, endPoint: .bottom), "Tax": LinearGradient(gradient: Gradient(colors: [totalBackgroundColor]), startPoint: .top, endPoint: .bottom), "Tips": LinearGradient(gradient: Gradient(colors: [tipsBackgroundColor]), startPoint: .top, endPoint: .bottom)])
                        
                        
                        
                    }
                    VStack(alignment: .trailing, spacing: 10) {
                        
                        
                        
                        
                        //Spacer()
                        if shift.overtimeDuration > 0 {
                            Text("OVERTIME")
                                .foregroundColor(.white)
                                .font(.system(size: 25, weight: .bold).monospacedDigit())
                                .frame(width: 200, height: 40)
                                .background(.red)
                                .cornerRadius(12)
                                .fixedSize()
                        }
                        VStack(alignment: .trailing, spacing: 8){
                            Text("Taxed Pay ")
                                .font(.title)
                                .bold()
                        Text("\(currencyFormatter.currencySymbol ?? "")\(shift.taxedPay, specifier: "%.2f")")
                        
                                .font(.system(size: 40))
                            .fontWeight(.black)
                            .foregroundColor(taxedBackgroundColor)
                            //.frame(maxWidth: 200, minHeight: 75)
                            //.background(taxedBackgroundColor)
                        
                        //.fixedSize()
                            .cornerRadius(20)
                            .padding(.bottom, 10)
                    }
                        if shift.tax > 0 {
                            VStack(alignment: .trailing, spacing: 8){
                                Divider()
                                Text("Before Tax ")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("\(currencyFormatter.currencySymbol ?? "")\(shift.totalPay, specifier: "%.2f")")
                                    //.padding(.horizontal, 20)
                                    .font(.title3)
                                    .fontWeight(.heavy)
                                    .foregroundColor(totalBackgroundColor)

                                    .cornerRadius(20)
                                    .padding(.bottom, 10)
                            }
                        }
                        if shift.totalTips > 0 {
                            VStack(alignment: .trailing, spacing: 8){
                                Divider()
                                Text("Tips ")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("\(currencyFormatter.currencySymbol ?? "")\(shift.totalTips, specifier: "%.2f")")
                                    //.padding(.horizontal, 20)
                                    .font(.system(size: 30))
                                    .fontWeight(.heavy)
                                    .foregroundColor(tipsBackgroundColor)
                              
                            }
                        }
                        VStack(alignment: .trailing, spacing: 8){
                            Divider()
                            Text("Duration ")
                                .font(.body)
                                .bold()
                            Text(shiftLengthString(shiftLength: shift.duration))
                                .foregroundColor(.orange)
                                .font(.largeTitle)
                                .bold()
                                //.frame(width: 250, height: 70)
                            // .background(timerBackgroundColor)
                                //.cornerRadius(20)
                                //.fixedSize()
                                //.padding()
                        }
                        VStack(alignment: .trailing, spacing: 8){
                            if let breaks = shift.breaks as? Set<Break> {
                                let duration = totalBreakDuration(for: breaks)
                                if duration > 0 {
                                    Divider()
                                    Text("Unpaid Breaks ")
                                        .font(.subheadline)
                                        .bold()
                                    Text("\(durationFormatter.string(from: duration) ?? "")")
                                        .foregroundColor(.indigo)
                                        .font(.headline)
                                            .bold()
                                        //.frame(width: 100, height: 30)
                                        //.background(.indigo)
                                        //.cornerRadius(12)
                                       // .fixedSize()
                                    // .padding(.bottom, 10)
                                }
                            }
                        }
                        
                        
                        
                        /*   HStack(spacing: 20) { // increased spacing between squares
                         RoundedSquareView(text: "Duration", count: "\(shiftLengthString())", color: timerBackgroundColor, imageColor: .white, systemImageName: "stopwatch") // added opacity to background color
                         .frame(maxWidth: .infinity) // increased width of the square
                         RoundedSquareView(text: "Hourly Pay", count: "\(currencyFormatter.currencySymbol ?? "")\(shift.hourlyPay)", color: .indigo.opacity(0.5), imageColor: .white, systemImageName: "dollarsign.circle")
                         .frame(maxWidth: .infinity)
                         }*/
                    }.listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .frame(maxWidth: .infinity)
                }.padding()
                
                //VStack(alignment: .leading, spacing: 10){
            }
            /*   Section {
             NavigationLink(destination: ShiftTipsView(shift: shift)) {
             HStack {
             Text("View Tips")
             //  Spacer()
             //Image(systemName: "chevron.right")
             //   .foregroundColor(Color.gray)
             }
             }
             }
             .listRowSeparator(.hidden)
             .listRowBackground(Color.clear) */
            
            
            Section{
                VStack{
                    DatePicker("Start: ", selection: $selectedStartDate)
                        .onChange(of: selectedStartDate) { _ in
                            if selectedStartDate > selectedEndDate {
                                selectedStartDate = selectedEndDate
                            }
                            //shift.shiftStartDate = selectedStartDate
                            //saveContext() // Save the value of tax percent whenever it changes
                        }
                        .disabled(!isEditing)
                        .onAppear {
                            noteIsFocused = false // Dismiss the text editor when the picker appears
                        }
                        .scaleEffect(isEditing ? 1.01 : 1.0) // Add a scale effect that pulses the picker
                        .animation(.easeInOut(duration: 0.2))
                    
                    DatePicker("End: ", selection: $selectedEndDate)
                        .onChange(of: selectedEndDate) { _ in
                            if selectedEndDate < selectedStartDate {
                                selectedEndDate = selectedStartDate
                            }
                            //shift.shiftEndDate = selectedEndDate
                            //saveContext() // Save the value of tax percent whenever it changes
                        }.disabled(!isEditing)
                        .onAppear {
                            noteIsFocused = false // Dismiss the text editor when the picker appears
                        }
                        .scaleEffect(isEditing ? 1.01 : 1.0) // Add a scale effect that pulses the picker
                        .animation(.easeInOut(duration: 0.2)) // Add an animation modifier to create the pulse effect
                    
                    
                    
                }
            }.listRowSeparator(.hidden)
            Section{
                HStack {
                    
                    Text("Hourly pay:")
                    //.foregroundColor(isEditing ? Color.black.opacity(0.8) : Color.white.opacity(0.5))
                    
                    TextField("", value: $selectedHourlyPay, format: .currency(code: Locale.current.currency?.identifier ?? "NZD"))
                        .disabled(!isEditing)
                        .keyboardType(.decimalPad)
                        .focused($payIsFocused)
                    //.foregroundColor(isEditing ? Color.white.opacity(0.8) : Color.white.opacity(0.5))
                    
                    
                    
                }
                if shift.tax > 0 || taxEnabled {
                    Picker("Estimated tax: ", selection: $selectedTaxPercentage){
                        ForEach(Array(stride(from: 0, to: 50, by: 0.5)), id: \.self){ index in
                            Text(index/100, format: .percent)
                        }
                    }.disabled(!isEditing)
                }
                
                if tipsEnabled || shift.totalTips > 0 {
                    HStack {
                        
                        Text("Total tips:")
                        //.foregroundColor(isEditing ? Color.black.opacity(0.8) : Color.white.opacity(0.5))
                        
                        TextField("", value: $selectedTotalTips, format: .currency(code: Locale.current.currency?.identifier ?? "NZD"))
                            .disabled(!isEditing)
                            .keyboardType(.decimalPad)
                            .focused($payIsFocused)
                        //.foregroundColor(isEditing ? Color.white.opacity(0.8) : Color.white.opacity(0.5))
                        
                        
                    }
                    /*  Toggle(isOn: $addTipsToTotal) {
                     HStack {
                     Image(systemName: "chart.line.downtrend.xyaxis")
                     Spacer().frame(width: 10)
                     Text("Add tips to total pay")
                     }
                     }.toggleStyle(OrangeToggleStyle()) */
                    
                }
                
            }.listRowSeparator(.hidden)
            /*.frame(height: (isEditing) ? nil : 0)
             .clipped() // <-- Clip the content when the frame height is reduced
             .animation(.easeInOut(duration: 0.3))*/
            
            // Inside your existing view body
            
            
            
            //.listRowBackground(Color.clear)
            Section{
                if let breaks = shift.breaks as? Set<Break> {
                    let sortedBreaks = breaks.sorted { $0.startDate ?? Date() < $1.startDate ?? Date() }
                    NavigationLink(destination: BreaksListView(breaks: sortedBreaks, shift: shift)){
                        Text("Breaks")
                    }
                }
            }.listRowSeparator(.hidden)
            Section(header: Text("Notes").font(.title3).bold()){
                TextEditor(text: $notes)
                
                //.textFieldStyle(PlainTextFieldStyle())
                    .focused($noteIsFocused)
                //.padding()
                
                    .cornerRadius(20)
                
                    .frame(minHeight: 200, maxHeight: .infinity)
                
            }
            Spacer()
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .toolbar{
                    ToolbarItemGroup(placement: .keyboard){
                        Spacer()
                        
                        Button("Done"){
                            noteIsFocused = false
                            payIsFocused = false
                            shift.shiftNote = notes
                            //shift.tag = selectedTag
                            saveContext()
                        }
                    }
                }
            // }
            
        }.onAppear(perform: loadData)
        //.padding(.horizontal, 30)
        
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Done" : "\(Image(systemName: "pencil"))") {
                        isEditing.toggle()
                        shift.shiftStartDate = selectedStartDate
                        shift.shiftEndDate = selectedEndDate
                        shift.breakStartDate = selectedBreakStartDate
                        shift.breakEndDate = selectedBreakEndDate
                        shift.tax = selectedTaxPercentage
                        shift.hourlyPay = selectedHourlyPay
                        //shift.tag = selectedTag
                        shift.totalTips = selectedTotalTips
                        let newBreakElapsed = selectedBreakEndDate.timeIntervalSince(selectedBreakStartDate)
                        shift.duration = selectedEndDate.timeIntervalSince(selectedStartDate) - newBreakElapsed
                        
                        
                        shift.totalPay = (shift.duration / 3600.0) * shift.hourlyPay
                        shift.taxedPay = shift.totalPay - (shift.totalPay * shift.tax / 100.0)
                        saveContext()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing){
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                    }
                    .foregroundColor(.red)
                    .alert(isPresented: $showingDeleteAlert) {
                        Alert(
                            title: Text("Delete shift?"),
                            message: Text("Are you sure you want to delete this shift?"),
                            primaryButton: .destructive(Text("Delete")) {
                                deleteShift()
                                presentationMode.wrappedValue.dismiss()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    
                }
            }
        
        
        
    }
    
    private func deleteShift() {
        context.delete(shift)
        saveContext()
        
    }
    
    // A date formatter to display the shift dates in a more readable format
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    
    private func shiftLengthString(shiftLength: TimeInterval) -> String {
        
        let hours = Int(shiftLength) / 3600
        let minutes = (Int(shiftLength) % 3600) / 60
        return String(format: "%1ih %02im", hours, minutes)
    }
    
    private func shiftDurationDouble() -> TimeInterval {
        guard let startDate = shift.shiftStartDate, let endDate = shift.shiftEndDate else {
            return 0.0
        }
        return endDate.timeIntervalSince(startDate)
    }
    
    private func saveContext() {
        do {
            try shift.managedObjectContext?.save()
        } catch let error {
            print("Error saving notes: \(error.localizedDescription)")
        }
    }
    
    func loadData() {
        if let decodedData = try? JSONDecoder().decode([Tag].self, from: tagsList) {
            tags = decodedData
        }
    }
    
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        let shift = OldShift(context: PersistenceController.preview.container.viewContext)
        shift.shiftNote = "Some notes"
        shift.taxedPay = 120.0
        shift.totalPay = 200.0
        shift.hourlyPay = 20.0
        shift.shiftStartDate = Date().addingTimeInterval(-3600)
        shift.shiftEndDate = Date()
        shift.duration = 53434.0
        shift.totalTips = 50.0
        
        return NavigationStack {
            DetailView(shift: shift)
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}


struct ShiftTipsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let shift: OldShift
    
    @FetchRequest(entity: Tip.entity(), sortDescriptors: [])
    private var allTips: FetchedResults<Tip>
    
    private var shiftTips: [Tip] {
        allTips.filter { $0.oldShift == shift }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Tips")) {
                    ForEach(shiftTips, id: \.objectID) { tip in
                        Text("$\(tip.value, specifier: "%.2f")")
                    }
                    .onDelete(perform: deleteTip)
                }
            }
            
        }.toolbar{
            ToolbarItem(){
                Button(action: {
                    addTip()
                }) {
                    Image(systemName: "plus")
                }
                
            }
        }
        .navigationTitle("Tips")
    }
    
    private func addTip() {
        withAnimation {
            let newTip = Tip(context: viewContext)
            newTip.value = Double.random(in: 1...100)
            newTip.oldShift = shift
            
            saveContext()
        }
    }
    
    private func deleteTip(at offsets: IndexSet) {
        withAnimation {
            offsets.forEach { index in
                let tip = shiftTips[index]
                viewContext.delete(tip)
            }
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}


struct ShiftProfitCategory: Identifiable {
    let id = UUID()
    let profit: Double
    let payCategory: String
}


