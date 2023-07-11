//
//  ContentViewButtonsView.swift
//  ShiftTracker
//
//  Created by James Poole on 11/07/23.
//

import SwiftUI
import Haptics

struct ContentViewButtonsView: View {
    
    @EnvironmentObject var viewModel: ContentViewModel
    @EnvironmentObject var jobSelectionViewModel: JobSelectionViewModel
    @EnvironmentObject var navigationState: NavigationState
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var context
    
    @Binding var jobShakeTimes: CGFloat
    @Binding var payShakeTimes: CGFloat
    
    var body: some View{
    
        let buttonColor: Color = colorScheme == .dark ? Color.white : Color.black
        let disabledButtonColor: Color = Color("SquaresColor")
        let foregroundColor: Color = colorScheme == .dark ? .black : .white
        
    Section{
        HStack{
            if viewModel.shiftState == .notStarted {
                AnimatedButton(
                    isTapped: $viewModel.isStartShiftTapped,
                    activeSheet: $viewModel.activeSheet,
                    activeSheetCase: .startShiftSheet,
                    title: "Start Shift",
                    backgroundColor: buttonColor,
                    isDisabled: viewModel.hourlyPay == 0 || jobSelectionViewModel.selectedJobUUID == nil
                )
                .frame(maxWidth: .infinity)
                .onAppear(perform: viewModel.prepareHaptics)
                .onTapGesture {
                    if jobSelectionViewModel.selectedJobUUID == nil {
                        withAnimation(.linear(duration: 0.4)) {
                            jobShakeTimes += 2
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7){
                            navigationState.showMenu = true
                        }
                    }
                }
                
            } else if viewModel.shiftState == .countdown {
                Button(action: {
                    CustomConfirmationAlert(action: {
                        viewModel.endShift(using: context, endDate: Date(), job: jobSelectionViewModel.fetchJob(in: context)!)
                    }, cancelAction: nil, title: "Cancel your upcoming shift?").showAndStack()
                    withAnimation {
                        viewModel.isEndShiftTapped = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            viewModel.isEndShiftTapped = false
                        }
                    }
                }) {
                    Text("Cancel Shift")
                        .frame(minWidth: UIScreen.main.bounds.width / 3)
                        .bold()
                        .padding()
                        .background((viewModel.shift == nil || (viewModel.shift != nil && viewModel.isOnBreak) || viewModel.isEditing) ? disabledButtonColor : buttonColor)
                        .foregroundColor(foregroundColor)
                        .cornerRadius(18)
                }
                .buttonStyle(.borderless)
                .frame(maxWidth: .infinity)
                .scaleEffect(viewModel.isEndShiftTapped ? 1.1 : 1)
                .animation(.easeInOut(duration: 0.3), value: viewModel.isEndShiftTapped)
                
                
            } else if viewModel.shiftState == .inProgress {
                if !viewModel.isOnBreak{
                    AnimatedButton(
                        isTapped: $viewModel.isBreakTapped,
                        activeSheet: $viewModel.activeSheet,
                        activeSheetCase: .startBreakSheet,
                        title: "Start Break",
                        backgroundColor: !viewModel.isEditing ? buttonColor : disabledButtonColor,
                        isDisabled: viewModel.isEditing
                    )
                }
                else {
                    AnimatedButton(
                        isTapped: $viewModel.isBreakTapped,
                        activeSheet: $viewModel.activeSheet,
                        activeSheetCase: .endBreakSheet,
                        title: "End Break",
                        backgroundColor: buttonColor,
                        isDisabled: false
                    )
                }
                AnimatedButton(
                    isTapped: $viewModel.isEndShiftTapped,
                    activeSheet: $viewModel.activeSheet,
                    activeSheetCase: .endShiftSheet,
                    title: "End Shift",
                    backgroundColor: (viewModel.shift == nil || (viewModel.shift != nil && viewModel.isOnBreak) || viewModel.isEditing) ? disabledButtonColor : buttonColor,
                    isDisabled: viewModel.shift == nil || viewModel.isOnBreak || viewModel.isEditing
                )
            }
            
            
        }.haptics(onChangeOf: payShakeTimes, type: .error)
            .haptics(onChangeOf: viewModel.activeSheet, type: .light)
            .haptics(onChangeOf: jobShakeTimes, type: .error)
        
        
    }
}
}
