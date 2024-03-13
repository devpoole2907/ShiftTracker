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
    @EnvironmentObject var selectedJobManager: JobSelectionManager
    @EnvironmentObject var navigationState: NavigationState
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @Binding var jobShakeTimes: CGFloat
    @Binding var payShakeTimes: CGFloat
    @State var breakCanceled: Bool = false
    
    var body: some View{
    
        let buttonColor: Color = colorScheme == .dark ? Color.white : Color.black
        let disabledButtonColor: Color = Color("SquaresColor")
        
    Section{
        HStack(spacing: 0){
            if viewModel.shiftState == .notStarted {
                AnimatedButton(
                    action: { navigationState.activeSheet = .startShiftSheet }, title: "Start Shift",
                    backgroundColor: buttonColor,
                    isDisabled:  selectedJobManager.selectedJobUUID == nil
                )
                .frame(maxWidth: .infinity)
                .onAppear(perform: viewModel.prepareHaptics)
                .onTapGesture {
                    if selectedJobManager.selectedJobUUID == nil {
                        withAnimation(.linear(duration: 0.4)) {
                            jobShakeTimes += 2
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7){
                            navigationState.showMenu = true
                        }
                    }
                }
                
            } else if viewModel.shiftState == .countdown {
                
                
                AnimatedButton(
                    action: {
                        CustomConfirmationAlert(action: {
                            viewModel.uncompleteCancelledScheduledShift(viewContext: viewContext)
                            viewModel.cancelShift(using: viewContext) { result in
                                            switch result {
                                            case .success():
                                                print("Successfully canceled and deleted all active shifts.")
                                           
                                            case .failure(let error):
                                                print("Failed to cancel shifts: \(error.localizedDescription)")
                                               
                                            }
                                        }
                        }, cancelAction: nil, title: "Cancel your upcoming shift?").showAndStack()
                        
                    },
                    title: "Cancel Shift",
                    backgroundColor: !viewModel.isEditing ? buttonColor : disabledButtonColor,
                    isDisabled: viewModel.isEditing
                )
        
                
                
            } else if viewModel.shiftState == .inProgress {
                if !viewModel.isOnBreak{
                    AnimatedButton(
                        action: { navigationState.activeSheet = .startBreakSheet },
                        title: "Start Break",
                        backgroundColor: !viewModel.isEditing ? buttonColor : disabledButtonColor,
                        isDisabled: viewModel.isEditing
                    )
                    
                    AnimatedButton(
                        action: { navigationState.activeSheet = .endShiftSheet },
                        title: "End Shift",
                        backgroundColor: (viewModel.currentShift == nil || (viewModel.currentShift != nil && viewModel.isOnBreak) || viewModel.isEditing) ? disabledButtonColor : buttonColor,
                        isDisabled: viewModel.currentShift == nil || viewModel.isOnBreak || viewModel.isEditing
                    )
                    
                }
                else {
                    AnimatedButton(
                        action:  viewModel.breakTimeElapsed <= 60 ? { viewModel.cancelBreak()
                            breakCanceled.toggle() } : { navigationState.activeSheet = .endBreakSheet } ,
                        title: viewModel.breakTimeElapsed <= 60 ? "Cancel Break" : "End Break",
                        backgroundColor: buttonColor,
                        isDisabled: viewModel.isEditing
                    )
                }
               
            }
            
            
        }.haptics(onChangeOf: payShakeTimes, type: .error)
            .haptics(onChangeOf: navigationState.activeSheet, type: .light)
            .haptics(onChangeOf: jobShakeTimes, type: .error)
            .haptics(onChangeOf: breakCanceled, type: .error)
        
           
    }.padding()
            
}
}
