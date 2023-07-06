//
//  JobOverview.swift
//  ShiftTracker
//
//  Created by James Poole on 30/06/23.
//

import SwiftUI
import CoreData
import Haptics



struct JobOverview: View {
    
    @StateObject var shiftManager = ShiftDataManager()
    
    @State private var showingAddShiftSheet = false
    
    @State private var isChartViewPrimary: Bool = false
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var navigationState: NavigationState
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject var jobSelectionViewModel: JobSelectionViewModel
    
    @FetchRequest var shifts: FetchedResults<OldShift>
    
    init(){
        
        let fetchRequest: NSFetchRequest<OldShift> = OldShift.fetchRequest()
        fetchRequest.predicate = nil
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \OldShift.shiftStartDate, ascending: false)]
        _shifts = FetchRequest(fetchRequest: fetchRequest)
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
    
    
    
    @State private var selectedView: String? = nil
    
    
    @State private var showSquare1 = false
    
    @State var animate = false
    
    var body: some View {
        
        let backgroundColor: Color = colorScheme == .dark ? Color(red: 28/255, green: 28/255, blue: 30/255) : .white
        let textColor: Color = colorScheme == .dark ? .white : .black
        NavigationStack{
        List{
            Section{
                GeometryReader { geometry in
                    VStack(alignment: .leading){
                    HStack(spacing: 5){
                        VStack(spacing: 5) {
                            if !isChartViewPrimary {
                                StatsSquare()
                                    .environmentObject(shiftManager)
                                    .frame(width: geometry.size.width / 2)
                                    .frame(height: geometry.size.height / 2)
                                
                            }
                            ChartSquare(isChartViewPrimary: $isChartViewPrimary)
                                .environmentObject(shiftManager)
                                .frame(width: isChartViewPrimary ? geometry.size.width : geometry.size.width / 2)
                                .frame(height: isChartViewPrimary ? geometry.size.height : geometry.size.height / 2)
                                .animation(.easeInOut, value: isChartViewPrimary)
                               /* .onTapGesture {
                                    withAnimation {
                                        if !isChartViewPrimary {
                                            isChartViewPrimary = true
                                        }
                                    }
                                }*/
                        }
                        if !isChartViewPrimary {
                        
                                RoundedRectangle(cornerRadius: 12)
                                    .foregroundStyle(Color("SquaresColor"))
                            
                        }
                        
                    }
                }
                }
                    .padding(.trailing, 2)
                    .padding(.bottom, 5)
            }.frame(minHeight: isChartViewPrimary ? 400 : 200)
            
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                .haptics(onChangeOf: isChartViewPrimary, type: .light)
            
            
            Section{
                ForEach(shifts.filter({ shiftManager.shouldIncludeShift($0, jobModel: jobSelectionViewModel) }).prefix(10), id: \.objectID) { shift in
                    NavigationLink(destination: DetailView(shift: shift, presentedAsSheet: false).navigationBarTitle(Text("Shift Details")), label: {
                        ShiftDetailRow(shift: shift)
                    })
                    
                    
                }
            } header: {
                NavigationLink(destination: ShiftsList().environmentObject(shiftManager)) {
                    
                        Text("Latest Shifts")
                            .textCase(nil)
                            .foregroundColor(textColor)
                            .padding(.leading, -12)
                            .font(.title2)
                            .bold()
                        Spacer()
                        Image(systemName: "chevron.right")
                        .bold()
                  
                    }
            }
            .listRowBackground(Color("SquaresColor"))
        }.scrollContentBackground(.hidden)
            
        .fullScreenCover(isPresented: $showingAddShiftSheet) {
            if let job = jobSelectionViewModel.fetchJob(in: viewContext){
                AddShiftView(job: job).environment(\.managedObjectContext, viewContext).environmentObject(shiftManager)
                    .presentationDetents([.large])
                    .presentationBackground(opaqueVersion(of: .primary, withOpacity: 0.04, in: colorScheme))
            } else {
                Text("Error")
            }
        }
            
        .onAppear {
            navigationState.gestureEnabled = true
        }

            
        .navigationBarTitle(jobSelectionViewModel.fetchJob(in: viewContext)?.name ?? "Summary")
            
        .toolbar{
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("\(Image(systemName: "plus"))") {
                    showingAddShiftSheet.toggle()
                }.disabled(jobSelectionViewModel.selectedJobUUID == nil)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(0..<shiftManager.statsModes.count) { index in
                        Button(action: {
                            shiftManager.statsMode = StatsMode(rawValue: index) ?? .earnings
                        }) {
                            HStack {
                                Text(shiftManager.statsModes[index])
                                    .textCase(nil)
                                if index == shiftManager.statsMode.rawValue {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor) // Customize the color if needed
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                }
                .haptics(onChangeOf: shiftManager.statsMode, type: .soft)
            }
            
            ToolbarItem(placement: .navigationBarLeading){
                Button{
                    withAnimation{
                        navigationState.showMenu.toggle()
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .bold()
                    
                }
            }
        }
            
    }
        
        
        
        
        
    }
    
}





//  .padding(.top, 20)

/*  HStack(spacing: 15) {

RoundedSquareView(text: "Shifts", count: "\(shifts.filter({ shouldIncludeShift($0) }).count)", color: Color.primary.opacity(0.04), imageColor: .blue, systemImageName: "briefcase.circle.fill")
.frame(maxWidth: .infinity)

// .frame(width: self.animate ? 100 : .infinity, height: self.animate ? 60 : 90)
//   if !showSquare1{
RoundedSquareView(text: "Taxed", count: "\(currencyFormatter.currencySymbol ?? "")\(addAllTaxedPay())", color: Color.primary.opacity(0.04), imageColor: .green, systemImageName: "dollarsign.circle.fill")
.frame(maxWidth: .infinity)

//   }


}
HStack(spacing: 15) {
// if !showSquare1 {
RoundedSquareView(text: "Hours", count: "\(addAllHours())", color: Color.primary.opacity(0.04), imageColor: .orange, systemImageName: "stopwatch.fill")

.frame(maxWidth: .infinity)

RoundedSquareView(text: "Total", count: "\(currencyFormatter.currencySymbol ?? "")\(addAllPay())", color: Color.primary.opacity(0.04), imageColor: .pink, systemImageName: "chart.line.downtrend.xyaxis.circle.fill")

.frame(maxWidth: .infinity)

// }
}

}.padding(.horizontal, -15) */
