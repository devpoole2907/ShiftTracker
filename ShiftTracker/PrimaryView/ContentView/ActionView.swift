//
//  ActionView.swift
//  ShiftTracker
//
//  Created by James Poole on 20/05/23.
//

import SwiftUI
import Haptics

struct ActionView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(\.dismiss) var dismiss
    @State private var actionDate = Date()
    
    
    @ObservedObject var viewModel: ContentViewModel
    @ObservedObject var jobSelectionViewModel: JobSelectionViewModel
    @Environment(\.managedObjectContext) private var context
    @Binding var activeSheet: ActiveSheet?
    let navTitle: String
    var pickerStartDate: Date?
    
    var actionType: ActionType
    
    var body: some View {
        
        let buttonColor: Color = colorScheme == .dark ? .white : .black
        let textColor: Color = colorScheme == .dark ? .black : .white
        
        NavigationStack {
            VStack {
                
                
                
                if actionType == .startBreak {
                    if let limitStartDate = pickerStartDate {
                        DatePicker("", selection: $actionDate, in: limitStartDate...Date(), displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    HStack {
                        ActionButtonView(title: "Unpaid Break", backgroundColor: Color.indigo, textColor: .white, icon: "bed.double.fill", buttonWidth: UIScreen.main.bounds.width / 2 - 30) {
                            viewModel.startBreak(startDate: actionDate, isUnpaid: true)
                            dismiss()
                        }
                        ActionButtonView(title: "Paid Break", backgroundColor: Color.indigo, textColor: .white, icon: "cup.and.saucer.fill", buttonWidth: UIScreen.main.bounds.width / 2 - 30) {
                            viewModel.startBreak(startDate: actionDate, isUnpaid: false)
                            dismiss()
                        }
                    }
                } else {
                    
                    switch actionType {
                    case .startShift:
                        
                        
                        
                        DatePicker("", selection: $actionDate, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        ActionButtonView(title: "Start Shift", backgroundColor: buttonColor, textColor: textColor, icon: "figure.walk.arrival", buttonWidth: UIScreen.main.bounds.width - 80) {
                            viewModel.startShiftButtonAction(using: context, startDate: actionDate, job: jobSelectionViewModel.fetchJob(in: context)!)
                            dismiss()
                        }
                    case .endShift:
                        if let limitStartDate = pickerStartDate {
                            DatePicker("", selection: $actionDate, in: limitStartDate... , displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        ActionButtonView(title: "End Shift", backgroundColor: buttonColor, textColor: textColor, icon: "figure.walk.departure", buttonWidth: UIScreen.main.bounds.width - 80) {
                            self.viewModel.lastEndedShift = viewModel.endShift(using: context, endDate: actionDate, job: jobSelectionViewModel.fetchJob(in: context)!)
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                activeSheet = .sheet1
                            }
                        }
                    case .endBreak:
                        
                        if let limitStartDate = pickerStartDate {
                            DatePicker("", selection: $actionDate, in: limitStartDate... , displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        ActionButtonView(title: "End Break", backgroundColor: buttonColor, textColor: textColor, icon: "deskclock.fill", buttonWidth: UIScreen.main.bounds.width - 80) {
                            viewModel.endBreak(endDate: actionDate)
                            dismiss()
                        }
                    default:
                        fatalError("Unsupported action type")
                    }
                    
                }
                
            }
            .navigationBarTitle(navTitle, displayMode: .inline)
        }
        
    }
}
