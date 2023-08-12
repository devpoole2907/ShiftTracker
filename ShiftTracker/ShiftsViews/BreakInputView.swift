//
//  BreakInputView.swift
//  ShiftTracker
//
//  Created by James Poole on 4/07/23.
//

import SwiftUI

struct BreakInputView: View {
    
    @EnvironmentObject var viewModel: DetailViewModel

    var startDate: Date
    var endDate: Date
    var buttonAction: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    init(startDate: Date, endDate: Date, buttonAction: @escaping () -> Void){

        self.startDate = startDate
        self.endDate = endDate
        self.buttonAction = buttonAction
        
    }

    var body: some View {
        NavigationStack{
        VStack(alignment: .leading, spacing: 15){
            VStack(alignment: .leading){
                HStack{
                    Text("Start:")
                        .bold()
                        .frame(width: 50, alignment: .leading)
                        .padding(.vertical, 5)
                    DatePicker("Start:", selection: $viewModel.selectedBreakStartDate, in: startDate...endDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .onChange(of: viewModel.selectedBreakStartDate) { newValue in
                            if viewModel.selectedBreakStartDate < newValue || viewModel.selectedBreakEndDate > endDate {
                                viewModel.selectedBreakEndDate = newValue.addingTimeInterval(10 * 60)
                            }
                        }
                }
                HStack{
                    Text("End:")
                        .bold()
                        .frame(width: 50, alignment: .leading)
                    DatePicker("End:", selection: $viewModel.selectedBreakEndDate, in: ...endDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .onChange(of: viewModel.selectedBreakEndDate) { newValue in
                            if newValue < viewModel.selectedBreakStartDate || newValue > endDate {
                                viewModel.selectedBreakEndDate = viewModel.selectedBreakStartDate.addingTimeInterval(10 * 60)
                            }
                        }
                }
                Picker(selection: $viewModel.isUnpaid, label: Text("Break Type")) {
                    Text("Paid").tag(false)
                    Text("Unpaid").tag(true)
                }.pickerStyle(SegmentedPickerStyle())
                
            }.padding()
                .background(Color("SquaresColor"),in:
                                RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            Button(action: buttonAction) {
                Text("Add Break")
                    .bold()
            }.listRowSeparator(.hidden)
                .padding()
                .frame(maxWidth: .infinity)
                .background(colorScheme == .dark ? .white : .black)
                .foregroundColor(colorScheme == .dark ? .black : .white)
                .cornerRadius(20)
        }
        .padding(20)
        
        
        .navigationBarTitle("Add Break", displayMode: .inline)
    
        .toolbar{
            ToolbarItem(placement: .navigationBarTrailing) {
                CloseButton {
                    dismiss()
                }
            }
        }
            
    }
        
    }
}
