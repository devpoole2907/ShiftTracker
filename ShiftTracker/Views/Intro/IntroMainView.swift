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

    @EnvironmentObject var navigationState: NavigationState
    
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
                       
                        navigationState.activeCover = .jobView
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8){
                            withAnimation {
                                isFirstLaunch = false
                                
                            }
                        }
                    } label: {
                        Text("Continue")
                            .fontWeight(.semibold)
                            
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity)
                            .glassModifier(cornerRadius: 20)
                    }
                    
                }.padding(.top, 25)
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
                
                
                if intro.customView != nil {
                    
                    VStack {
                        
                        intro.customView.frame(maxWidth: .infinity)
                            .padding(.top, 80)
                        
                        
                    }
                    
                }/*else {
                    Image(intro.introAssetImage ?? "")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    //.padding(15)
                        .frame(width: size.width, height: size.height)
                        .cornerRadius(12)
                    
                }*/
                
            }.offset(y: showView ? 0 : -size.height / 2)
                .opacity(showView ? 1 : 0)
            
            VStack(alignment: .leading, spacing: 10){
                
                Spacer(minLength: 0)
                
                
                    Text(intro.title)
                    .font((getRect().height == 667 || getRect().height == 736) ? .title2 : .largeTitle)
                        .fontWeight(.black)
               
                        .allowsTightening(true)
                    
                    
                    
                    Text(intro.subTitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .roundedFontDesign()
         
                        .allowsTightening(true)
                  
               
                
                if !intro.displaysAction{
                    Group{
                        Spacer(minLength: 25)
                        
                        
                        CustomIndicatorView(totalPages: filteredPages.count, currentPage: filteredPages.firstIndex(of: intro) ?? 0)
                            .frame(maxWidth: .infinity)
                        
                        Spacer(minLength: 10)
                        
                        AnimatedButton(action: {
                            
                            if filteredPages.firstIndex(of: intro) == 4 {
                                locationManager.requestAlwaysAuthorization()
                            } else if filteredPages.firstIndex(of: intro) == 5 {
                                requestNotificationPerms()
                            }
                            changeIntro()
                            
                            
                        }, title: "Next", backgroundColor: colorScheme == .dark ? .black : .white, isDisabled: false)
                        
                       .frame(maxWidth: .infinity)
                        
                
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
                        .contentShape(Rectangle())
                }
                .padding(10)
                .padding(.horizontal, 4)
                .glassModifier(cornerRadius: 50)
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

