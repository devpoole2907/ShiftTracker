//
//  BreakInputView.swift
//  ShiftTracker
//
//  Created by James Poole on 4/07/23.
//

import SwiftUI

struct BreakInputView: View {
    
    @EnvironmentObject var viewModel: DetailViewModel
    @EnvironmentObject var themeManager: ThemeDataManager

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
                
            }.padding(.horizontal)
                .padding(.vertical, 10)
                .background(.thinMaterial .opacity(0.5),in:
                                RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            
            
            
            HStack {
                ActionButtonView(title: "Unpaid Break", backgroundColor: themeManager.breaksColor, textColor: .indigo, icon: "bed.double.fill", buttonWidth: UIScreen.main.bounds.width / 2 - 30) {
                    
                    viewModel.isUnpaid = true
                    
                    buttonAction()
                    
                    
                }
                ActionButtonView(title: "Paid Break", backgroundColor: themeManager.breaksColor, textColor: .indigo, icon: "cup.and.saucer.fill", buttonWidth: UIScreen.main.bounds.width / 2 - 30) {
                    
                    viewModel.isUnpaid = false
                    
                    buttonAction()
                    
                }
            }
            
            
            
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
