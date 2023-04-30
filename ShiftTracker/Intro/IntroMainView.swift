//
//  IntroView.swift
//  ShiftTracker
//
//  Created by James Poole on 29/04/23.
//

import SwiftUI
import Firebase
import AuthenticationServices
import PopupView

struct IntroMainView: View {
    
    @State private var activeIntro: PageIntro = pageIntros[0]
    
    @State private var keyboardHeight: CGFloat = 0
    
    @State private var emailID: String = ""
    @State private var password: String = ""
    
    @EnvironmentObject var authModel: FirebaseAuthModel
    
    var body: some View {
        GeometryReader{
            let size = $0.size
            
            IntroView(intro: $activeIntro, size: size){
                VStack(spacing: 10){
                    CustomTextField(text: $emailID, hint: "Email Address", leadingIcon: Image(systemName: "at.circle.fill"))
                    
                    CustomTextField(text: $password, hint: "Password", leadingIcon: Image(systemName: "lock.fill"), isPassword: true)
                    
                    Spacer(minLength: 10)
                    
                    HStack{
                        Text("Don't have an account?")
                        Button{
                            register()
                        } label: {
                            Text("Sign up")
                                .bold()
                        }
                    }.padding()
                    
                    Button{
                        login()
                    } label: {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity)
                            .background{
                                Capsule()
                                    .fill(.black)
                            }
                    }
                    Divider()
                    Text("OR")
                    Divider()
                    
                    HStack{
                        Image(systemName: "applelogo")
                            .foregroundColor(.white)
                        Text("Sign in with Apple")
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity)
                    .background{
                        Capsule()
                            .fill(.black)
                    }
                    .overlay(
                        SignInWithAppleButton { request in
                            authModel.handleSignInWithAppleRequest(request)
                        } onCompletion: { result in
                            authModel.handleSignInWithAppleCompletion(result)
                        }
                        .signInWithAppleButtonStyle(.white)
                        .blendMode(.overlay)
                    )
                    
                    HStack{
                        Button{
                            SkipLogInPopup(action: authModel.signInAnonymously).present()
                        } label: {
                            Text("Skip sign in")
                                .bold()
                        }
                    }.padding()
                    
                    
                    
                   /* Button{
                        register()
                    } label: {
                        HStack{
                            Image(systemName: "applelogo")
                                .foregroundColor(.white)
                            Text("Sign in with Apple")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.vertical, 15)
                        }
                            .frame(maxWidth: .infinity)
                            .background{
                                Capsule()
                                    .fill(.black)
                            }
                    } */
                    
                }.padding(.top, 25)
                  /*  .onAppear{
                        Auth.auth().addStateDidChangeListener{ auth, user in
                            if user != nil{
                                userIsLoggedIn.toggle()
                            }
                        }
                    } */
            }
            
            
            
        }
        .padding(15)
       // .ignoresSafeArea(.keyboard)
        // when adding login view, implement keyboard push view from kavsoft app intro animations video
    }
    
    func login(){
        Auth.auth().signIn(withEmail: emailID, password: password) { result, error in
            if error != nil{
                print(error!.localizedDescription)
                LoginFailedPopup().present()
            }
          
        }
    }
    
    func register() {
        Auth.auth().createUser(withEmail: emailID, password: password) { result, error in
            if error != nil {
                print(error!.localizedDescription)
            }
           
        }
    }
    
}

struct IntroMainView_Previews: PreviewProvider {
    static var previews: some View {
        MainWithSideBarView()
    }
}

struct IntroView<ActionView: View>: View {
    
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
                    //.padding(15)
                    .frame(width: size.width, height: size.height)
                
            }.offset(y: showView ? 0 : -size.height / 2)
                .opacity(showView ? 1 : 0)
            
            VStack(alignment: .leading, spacing: 10){
                
                Spacer(minLength: 0)
                
                Text(intro.title)
                    .font(.system(size: 40))
                    .fontWeight(.black)
                
                Text(intro.subTitle)
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding(.top, 15)
                
                if !intro.displaysAction{
                    Group{
                        Spacer(minLength: 25)
                        
                        
                        CustomIndicatorView(totalPages: filteredPages.count, currentPage: filteredPages.firstIndex(of: intro) ?? 0)
                            .frame(maxWidth: .infinity)
                        
                        Spacer(minLength: 10)
                        
                        Button{
                            changeIntro()
                        } label: {
                            Text("Next")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: size.width * 0.4)
                            .padding(.vertical, 15)
                            .background{
                                Capsule()
                                    .fill(.black)
                            }
                        }.frame(maxWidth: .infinity)
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
                        .foregroundColor(.black)
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
    
    func changeIntro(_ isPrevious: Bool = false){
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0)){
            hideWholeView = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
            if let index = pageIntros.firstIndex(of: intro), (isPrevious ? index != 0 : index != pageIntros.count - 1) {
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
        .background(.primary.opacity(0.05))
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
        .background(.primary.opacity(0.05))
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
                    //.foregroundColor(.onBackgroundSecondary)
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
