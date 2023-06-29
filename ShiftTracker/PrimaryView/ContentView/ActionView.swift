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
    @State private var isRounded = false
    
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
                            .disabled(isRounded)
                    }
                } else {
                    
                    switch actionType {
                    case .startShift:
                        
                        
                        
                        DatePicker("", selection: $actionDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .disabled(isRounded)
                    case .endShift:
                        if let limitStartDate = pickerStartDate {
                            DatePicker("", selection: $actionDate, in: limitStartDate... , displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .disabled(isRounded)
                        }
                    case .endBreak:
                        
                        if let limitStartDate = pickerStartDate {
                            DatePicker("", selection: $actionDate, in: limitStartDate... , displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .disabled(isRounded)
                        }
                    default:
                        fatalError("Unsupported action type")
                    }
                    
                }
                
                
                Toggle(isOn: $isRounded){
                    Text("Auto Round")
                        .bold()
                }.toggleStyle(OrangeToggleStyle())
                    
                    .onChange(of: isRounded) { value in
                        
                        if isRounded == true {
                            actionDate = roundDate(actionDate)
                        } else {
                            actionDate = Date()
                        }
                    }
            .padding(.horizontal)
                .frame(maxWidth: UIScreen.main.bounds.width - 100)
                .padding(.vertical, 10)
                .background(Color.primary.opacity(0.04),in:
                                RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.bottom, 10)
                
                
                if actionType == .startBreak {
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
                        ActionButtonView(title: "Start Shift", backgroundColor: buttonColor, textColor: textColor, icon: "figure.walk.arrival", buttonWidth: UIScreen.main.bounds.width - 80) {
                            viewModel.startShiftButtonAction(using: context, startDate: actionDate, job: jobSelectionViewModel.fetchJob(in: context)!)
                            dismiss()
                        }
                    case .endShift:
                        ActionButtonView(title: "End Shift", backgroundColor: buttonColor, textColor: textColor, icon: "figure.walk.departure", buttonWidth: UIScreen.main.bounds.width - 80) {
                            
                            self.viewModel.lastEndedShift = viewModel.endShift(using: context, endDate: actionDate, job: jobSelectionViewModel.fetchJob(in: context)!)
                            dismiss()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                activeSheet = .detailSheet
                            }
                            
                        }
                    case .endBreak:
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
