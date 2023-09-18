//
//  IntroView.swift
//  ShiftTracker
//
//  Created by James Poole on 29/04/23.
//

import SwiftUI
import AuthenticationServices
import PopupView
import CoreLocation

struct IntroMainView: View {
    
    @State private var activeIntro: PageIntro = pageIntros[0]
    
    @EnvironmentObject var jobSelectionViewModel: JobSelectionManager
    @EnvironmentObject var viewModel: ContentViewModel
    
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) var context
    
    @State private var keyboardHeight: CGFloat = 0
    
    @State private var emailID: String = ""
    @State private var password: String = ""
    
    @State private var createAccount: Bool = false
    
    @Binding var isFirstLaunch: Bool
    
    @State private var showAddJobView = false
    
    var body: some View {
        GeometryReader{
            let size = $0.size
            
            IntroView(intro: $activeIntro, size: size){
                VStack(spacing: 10){
                    Button{
                        
                        
                        showAddJobView = true
                        
                       // withAnimation(.easeOut(duration: 0.8)){
                            
                            
                            
                            //isFirstLaunch = false
                        //}
                    } label: {
                        Text("Continue")
                            .fontWeight(.semibold)
                            
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity)
                            .glassModifier(cornerRadius: 20)
                    }
                    
                }.padding(.top, 25)
            }
            .fullScreenCover(isPresented: $showAddJobView){
                JobView(isEditJobPresented: .constant(true), selectedJobForEditing: .constant(nil))
                    .environmentObject(viewModel)
                    .environmentObject(jobSelectionViewModel)
                    .onDisappear{
                        withAnimation {
                            isFirstLaunch = false
                        }
                    }
                
                
                    .presentationBackground(.ultraThinMaterial)
                
            }
            
            
            
            
        }
        .padding(15)
        .background(.ultraThinMaterial)
        
    }
    

    
}

struct IntroMainView_Previews: PreviewProvider {
    static var previews: some View {
        //MainWithSideBarView(currentTab: .constant(.home))
        MainWithSideBarView()
    }
}

struct IntroView<ActionView: View>: View {
    
    @State private var locationManager = CLLocationManager()
    
    @Environment(\.colorScheme) private var colorScheme
    
    @Binding var intro: PageIntro
    
    var size: CGSize
    var actionView: ActionView
    
    init(intro: Binding<PageIntro>, size: CGSize, @ViewBuilder actionView: @escaping () -> ActionView){
        self._intro = intro
        self.size = size
        self.actionView = actionView()
    }
    
    
    @State private var showView: Bool = false
    @State private var hideWholeView: Bool = false
    
    var body: some View{
        VStack{
            GeometryReader{
                let size = $0.size
                
                Image(intro.introAssetImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    //.padding(15)
                    .frame(width: size.width, height: size.height)
                    .cornerRadius(12)
                
                  
                
            }.offset(y: showView ? 0 : -size.height / 2)
                .opacity(showView ? 1 : 0)
            
            VStack(alignment: .leading, spacing: 10){
                
                Spacer(minLength: 0)
                
                
                    Text(intro.title)
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .lineLimit(2, reservesSpace: true)
                        .allowsTightening(true)
                    
                    
                    
                    Text(intro.subTitle)
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.top, 15)
                        .lineLimit(3, reservesSpace: true)
                        .allowsTightening(true)
                  
               
                
                if !intro.displaysAction{
                    Group{
                        Spacer(minLength: 25)
                        
                        
                        CustomIndicatorView(totalPages: filteredPages.count, currentPage: filteredPages.firstIndex(of: intro) ?? 0)
                            .frame(maxWidth: .infinity)
                        
                        Spacer(minLength: 10)
                        
                        Button{
                            
                            if filteredPages.firstIndex(of: intro) == 4 {
                                locationManager.requestAlwaysAuthorization()
                            } else if filteredPages.firstIndex(of: intro) == 5 {
                                requestNotificationPerms()
                            }
                            changeIntro()
                                
                                
                        } label: {
                            Text("Next")
                            .fontWeight(.semibold)
                           // .foregroundColor(colorScheme == .dark ? .black : .white)
                            .frame(width: size.width * 0.4)
                            .padding(.vertical, 15)
                            .glassModifier()
                        }.frame(maxWidth: .infinity)
                        
                
                            Button{
                                changeIntro(isSkip: true)
                                locationManager.requestAlwaysAuthorization()
                                requestNotificationPerms()
                            } label: {
                                Text("Skip")
                                    .bold()
                            }.padding()
                            .frame(maxWidth: .infinity)
                        
                    }
                
                } else {
                    actionView
                }
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .offset(y: showView ? 0 : size.height / 2)
                .opacity(showView ? 1 : 0)
            
            
            
        }
        .offset(y: hideWholeView ? size.height / 2 : 0)
        .opacity(hideWholeView ? 0 : 1)
        .overlay(alignment: .topLeading){
            if intro != pageIntros.first {
                Button{
                    changeIntro(true)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                        .contentShape(Rectangle())
                }
                .padding(10)
                .offset(y: showView ? 0 : -200)
                .offset(y: hideWholeView ? -200 : 0)
                
            }
        }
        
        

        
        .onAppear{
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0).delay(0.1)){
                showView = true
            }
        }
    }
    
    func changeIntro(_ isPrevious: Bool = false, isSkip: Bool = false){
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0)){
            hideWholeView = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
            
            
            if isSkip {
                intro = pageIntros[pageIntros.count - 1]
            }
            else if let index = pageIntros.firstIndex(of: intro), (isPrevious ? index != 0 : index != pageIntros.count - 1) {
                intro = isPrevious ? pageIntros[index - 1] : pageIntros[index + 1]
            }
            else {
                intro = isPrevious ? pageIntros[0] : pageIntros[pageIntros.count - 1]
            }
            
            hideWholeView = false
            showView = false
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0)){
                showView = true
            }
            
        }
        
        
    }
    
    func requestNotificationPerms() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("All set!")
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }

    
    var filteredPages: [PageIntro] {
        return pageIntros.filter { !$0.displaysAction }
    }
    
}

struct SkipLogInPopup: CentrePopup {
    let action: () -> Void
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup.horizontalPadding(28)
    }
    func createContent() -> some View {
        VStack(spacing: 5) {
      
            createTitle()
                .padding(.vertical)
            
            createDescription()
                .padding(.vertical)
            //Spacer(minLength: 32)
          //  Spacer.height(32)
            createButtons()
               // .padding()
        }
        .padding(.top, 12)
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        .background(Color("SquaresColor"))
    }
}

private extension SkipLogInPopup {

    func createTitle() -> some View {
        Text("Are you sure you want to skip signing in?")
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    func createDescription() -> some View {
        Text("You can always sign in later.")
                    //.foregroundColor(.onBackgroundSecondary)
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

private extension SkipLogInPopup {
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
            Text("Skip")
                .bold()
                .foregroundColor(.white)
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(.black)
                .cornerRadius(8)
        }
    }
}

struct LoginFailedPopup: CentrePopup {
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup.horizontalPadding(28)
    }
    func createContent() -> some View {
        VStack(spacing: 5) {
      
            createTitle()
                .padding(.vertical)
            
            createDescription()
                .padding(.vertical)
            //Spacer(minLength: 32)
          //  Spacer.height(32)
            createButtons()
               // .padding()
        }
        .padding(.top, 12)
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        .background(Color("SquaresColor"))
    }
}

private extension LoginFailedPopup {

    func createTitle() -> some View {
        Text("Login failed.")
            .bold()
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    func createDescription() -> some View {
        Text("Check your email and password.")
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
    }
    
    func createButtons() -> some View {
        HStack(spacing: 4) {
            createCancelButton()
        }
    }
}

private extension LoginFailedPopup {
    func createCancelButton() -> some View {
        Button(action: dismiss) {
            Text("OK")

                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(.primary.opacity(0.1))
                .cornerRadius(8)
        }
    }

}
