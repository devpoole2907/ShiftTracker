//
//  ShiftsView.swift
//  ShiftTracker
//
//  Created by James Poole on 19/03/23.
//

import SwiftUI
import CoreData
import Haptics
import PopupView

struct ShiftsView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @AppStorage("isProVersion", store: UserDefaults(suiteName: "group.com.poole.james.ShiftTracker")) var isProVersion = false
    
    @FetchRequest(
        entity: OldShift.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)])
    var latestShifts: FetchedResults<OldShift>
    
    @FetchRequest(entity: OldShift.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.taxedPay, ascending: false)])
    var highPayShifts: FetchedResults<OldShift>
    
    @FetchRequest(entity: OldShift.entity(), sortDescriptors: [NSSortDescriptor(key: "duration", ascending: false)])
    var longestShifts: FetchedResults<OldShift>
    
    
    // shitty workaround test
    @FetchRequest(entity: OldShift.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)])
    var latestShiftsDuctTapeFix: FetchedResults<OldShift>
    
    @FetchRequest(entity: OldShift.entity(), sortDescriptors: []) var oldShifts: FetchedResults<OldShift>
    
    @FetchRequest(entity: Job.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Job.title, ascending: true)]) private var jobs: FetchedResults<Job>
    
    @State private var isTotalShiftsTapped: Bool = false
    @State private var isTotalPayTapped: Bool = false
    @State private var isTaxedPayTapped: Bool = false
    @State private var isTotalHoursTapped: Bool = false
    @State private var isToggled = false
    @State private var isShareSheetShowing = false
    @State private var isEditing = false
    @State private var showAlert = false
    @State private var showingAddShiftSheet = false
    
    @State private var showProView = false
    
    @State private var searchBarOpacity: Double = 0.0
    @State private var searchBarScale: CGFloat = 0.9
    
    
    @State private var refreshingID = UUID()
    
    @State private var totalShiftsPay: Double = 0.0
    
    @Binding var showMenu: Bool
    
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
    
    
    
    var body: some View {
        
        
        let backgroundColor: Color = colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : .white
        let countColor: Color = colorScheme == .dark ? Color.blue.opacity(0.5) : .blue.opacity(0.8)
        let hourColor: Color = colorScheme == .dark ? Color.orange.opacity(0.5) : .orange.opacity(0.8)
        let taxedColor: Color = colorScheme == .dark ? Color.green.opacity(0.5) : .green.opacity(0.8)
        let totalColor: Color = colorScheme == .dark ? Color.pink.opacity(0.5) : .pink.opacity(0.8)
        
        let squareColor: Color = colorScheme == .dark ? Color(.systemGray6) : Color.white
        
        
        NavigationStack{
            VStack(spacing: 1){
                List {
                    Section{
                        VStack(spacing: 15) {
                            HStack(spacing: 15) {
                                RoundedSquareView(text: "Shifts", count: "\(oldShifts.count)", color: Color.primary.opacity(0.03), imageColor: .blue, systemImageName: "briefcase.circle.fill")
                                    .frame(maxWidth: .infinity)
                                
                                RoundedSquareView(text: "Taxed", count: "\(currencyFormatter.currencySymbol ?? "")\(addAllTaxedPay())", color: Color.primary.opacity(0.03), imageColor: .green, systemImageName: "dollarsign.circle.fill")
                                    .frame(maxWidth: .infinity)
                                
                            }
                            HStack(spacing: 15) {
                                
                                RoundedSquareView(text: "Hours", count: "\(addAllHours())", color: Color.primary.opacity(0.03), imageColor: .orange, systemImageName: "stopwatch.fill")
                                
                                    .frame(maxWidth: .infinity)
                                
                                
                                RoundedSquareView(text: "Total", count: "\(currencyFormatter.currencySymbol ?? "")\(addAllPay())", color: Color.primary.opacity(0.03), imageColor: .pink, systemImageName: "chart.line.downtrend.xyaxis.circle.fill")
                                
                                    .frame(maxWidth: .infinity)
                                
                                
                            }
                        }.padding(.horizontal, -15)
                        
                        
                    }.dynamicTypeSize(.small)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .padding(.top, 20)
                    
                    ForEach(jobs.indices, id: \.self) { index in
                                        let job = jobs[index]
                                        Section /*(header: index == 0 ? summaryHeader() : nil)*/ {
                                            NavigationLink(destination: StatsView(statsMode: .earnings, jobId: job.objectID)) {
                                                summaryContent(for: job)
                                            }
                                        }
                    }.listRowBackground(Color.primary.opacity(0.03))
                    
                }
                .scrollContentBackground(.hidden)
                
            }
            .navigationBarTitle("Summary")
            
            .toolbar{
                ToolbarItem(placement: .navigationBarLeading){
                    Button{
                        withAnimation{
                            showMenu.toggle()
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .bold()
                     
                    }
                    //.foregroundColor(.black)
                }
            }
            
        }
        
        
    }
    
    private func summaryContent(for job: Job) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            
            HStack{
                Image(systemName: job.icon ?? "briefcase.circle")
                    .foregroundColor(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
                    .bold()
                    .font(.system(size: 12))
                Text(job.name ?? "")
                    // .foregroundColor(Color(red: Double(job.colorRed), green: Double(job.colorGreen), blue: Double(job.colorBlue)))
                   // .foregroundColor(.black)
                    .bold()
                    .font(.title3)
            }
            VStack(alignment: .leading, spacing: 3){
                Text("Earnings")
                    .foregroundColor(.green)
                    .font(.subheadline)
                    .bold()
                
                if let earnings = calculateEarningsForLastWeek(for: job) {
                    HStack {
                        Text("$\(earnings, specifier: "%.2f")")
                          //  .foregroundColor(.black)
                            .font(.title)
                            .bold()
                        
                      /*  Text("earned this week")
                            .foregroundColor(.gray)
                            .bold()
                            .font(.caption) */
                    }
                }
            }
            VStack(alignment: .leading, spacing: 3){
            Text("Hours")
                .foregroundColor(.orange)
                .font(.subheadline)
                .bold()
            if let hours = calculateHoursForLastWeek(for: job) {
                HStack {
                    Text("\(hours, specifier: "%.1f")")
                       // .foregroundColor(.black)
                        .font(.title2)
                        .bold()
                   
                }
            }
                
        }
            Text(lastWeekDateRange())
                .foregroundColor(.gray)
                .bold()
                .font(.caption)
            }
        }
    
    // old summary header
    private func summaryHeader() -> some View {
        let textColor: Color = colorScheme == .dark ? .white : .black
        return HStack {
                Text("Summary")
                    .font(.title)
                    .foregroundColor(textColor)
                    .bold()
                    .textCase(nil)
                    .padding(.leading, -8)
            }
        }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM"
        return formatter
    }
    
    private func addAllTaxedPay() -> String {
        let total = oldShifts.reduce(0) { $0 + $1.taxedPay }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: total)) ?? "0.00"
    }
    
    private func addAllPay() -> String {
        let total = oldShifts.reduce(0) { $0 + $1.totalPay }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: total)) ?? "0.00"
    }
    
    private func addAllHours() -> String {
        let total = oldShifts.reduce(0) { $0 + $1.duration }
        let totalHours = total / 3600.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: totalHours)) ?? "0.00"
    }
    

    private func calculateEarningsForLastWeek(for job: Job) -> Double? {
           guard let oldShifts = job.oldShifts as? Set<OldShift> else { return nil }
           
           let now = Date()
           let calendar = Calendar.current
           
           guard let lastMonday = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now, matchingPolicy: .nextTimePreservingSmallerComponents, repeatedTimePolicy: .first, direction: .backward) else { return nil }
           
           let lastWeekShifts = oldShifts.filter { shift in
               if let shiftDate = shift.shiftStartDate, calendar.isDate(shiftDate, equalTo: lastMonday, toGranularity: .day) || calendar.isDate(shiftDate, inSameDayAs: lastMonday) {
                   return true
               }
               return false
           }
           
           let totalEarnings = lastWeekShifts.reduce(0) { result, shift in
               result + shift.totalPay
           }
           
           return totalEarnings
       }
    
    private func calculateHoursForLastWeek(for job: Job) -> Double? {
           guard let oldShifts = job.oldShifts as? Set<OldShift> else { return nil }
           
           let now = Date()
           let calendar = Calendar.current
           
           guard let lastMonday = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now, matchingPolicy: .nextTimePreservingSmallerComponents, repeatedTimePolicy: .first, direction: .backward) else { return nil }
           
           let lastWeekShifts = oldShifts.filter { shift in
               if let shiftDate = shift.shiftStartDate, calendar.isDate(shiftDate, equalTo: lastMonday, toGranularity: .day) || calendar.isDate(shiftDate, inSameDayAs: lastMonday) {
                   return true
               }
               return false
           }
           
           let totalHours = lastWeekShifts.reduce(0) { result, shift in
               result + shift.duration
           }
           
            return totalHours / 3600.0
       }
    
    private func lastWeekDateRange() -> String {
        let now = Date()
        let calendar = Calendar.current

        guard let lastMonday = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now, matchingPolicy: .nextTimePreservingSmallerComponents, repeatedTimePolicy: .first, direction: .backward) else { return "" }
        guard let previousSunday = calendar.date(byAdding: .day, value: -6, to: lastMonday) else { return "" }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy"

        let startDate = dateFormatter.string(from: previousSunday)
        let endDate = dateFormatter.string(from: lastMonday)

        return "\(startDate) - \(endDate)"
    }

    
    
}

struct ShiftsView_Previews: PreviewProvider {
    static var previews: some View {
        ShiftsView(showMenu: .constant(false))
    }
}


// old search bar view:

/*  SearchBarView(text: $searchText)
 
 .disabled(isEditing || sortOption == 0)
 //.padding(.horizontal, 50)
 //.padding(.top, 10)
 .frame(maxWidth: .infinity)
 .frame(height: (isEditing || sortOption == 0) ? 0 : nil)
 .clipped() // <-- Clip the content when the frame height is reduced
 .animation(.easeInOut(duration: 0.3)) */
struct ShiftRow: View {
    var oldShift: OldShift
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(oldShift.shiftStartDate ?? Date(), formatter: dateFormatter)")
                    .font(.headline)
                
            }
            Spacer()
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

struct PayPeriodView: View {
    var body: some View{
        VStack(spacing: 50){
            Text("You have entered the backrooms!")
            
            Text("Invoice generation etc and pay period to go here")
        }
    }
}


struct DeleteShiftAlert: CentrePopup {
    let action: () -> Void
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup.horizontalPadding(28)
    }
    func createContent() -> some View {
        VStack(spacing: 5) {
            
            createTitle()
                .padding(.vertical)
            //Spacer(minLength: 32)
            //  Spacer.height(32)
            createButtons()
            // .padding()
        }
        .padding(.top, 12)
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        .background(.primary.opacity(0.05))
    }
}

private extension DeleteShiftAlert {
    
    func createTitle() -> some View {
        Text("Are you sure you want to delete these shifts?")
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    func createButtons() -> some View {
        HStack(spacing: 4) {
            createCancelButton()
            createUnlockButton()
        }
    }
}

private extension DeleteShiftAlert {
    func createCancelButton() -> some View {
        Button(action: dismiss) {
            Text("Cancel")
            
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(.primary.opacity(0.1))
                .cornerRadius(8)
        }
    }
    func createUnlockButton() -> some View {
        Button(action: {
            action()
            dismiss()
        }) {
            Text("Confirm")
                .bold()
                .foregroundColor(.white)
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(.black)
                .cornerRadius(8)
        }
    }
}
