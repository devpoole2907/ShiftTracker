//
//  SideMenu.swift
//  ShiftTracker
//
//  Created by James Poole on 28/04/23.
//

import SwiftUI
import PopupView

struct SideMenu: View {
    
    
    @Binding var showMenu: Bool
    
    @EnvironmentObject var authModel: FirebaseAuthModel
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 0){
            
            VStack(alignment: .leading, spacing: 14){
                Image(systemName: "person.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 65, height: 65)
                    .clipShape(Circle())
                Text("James")
                    .font(.title2)
                    .bold()
                
            /*    Text("@jp4938")
                    .font(.callout) */
                   
                
                
                
                    
            }
            .padding(.horizontal)
            .padding(.leading)
            
            ScrollView(.vertical, showsIndicators: false){
                VStack{
                    VStack(alignment: .leading, spacing: 45) {
                        TabButton(title: "Profile", image: "person.fill", destination: { AnyView(SettingsView()) })
                        TabButton(title: "Jobs", image: "briefcase.fill", destination: { AnyView(JobsView().navigationBarTitle("Jobs", displayMode: .inline)) })
                        TabButton(title: "Upgrade", image: "plus.diamond.fill", destination: { AnyView(ProView()) })
                    }
                    .padding()
                    .padding(.leading)
                    .padding(.top, 35)

                    
                   
                    
                  
                }
            }
            VStack{
                Divider()
                
                TabButton(title: "Settings", image: "gearshape.fill", destination: { AnyView(SettingsView()) })
                        .padding()
                        .padding(.leading)

                    Button(action: {
                        //
                        
                        LogOutPopUp(logoutAction: authModel.signOut).present()
                        
                    }) {
                        Text("Logout")
                            .bold()
                            .padding()
                            .padding(.leading)
                        
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                
            }
            
        }
        .padding(.top)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(width: getRect().width-90)
        .frame(maxHeight: .infinity)
        .background(
            Color.primary
                .opacity(0.04)
                .ignoresSafeArea(.container, edges: .vertical))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    func TabButton(title: String, image: String, destination: @escaping () -> AnyView) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 25) {
                Image(systemName: image)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 30, height: 30)
                Text(title)
                    .font(.largeTitle)
                    .bold()
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    
}

struct SideMenu_Previews: PreviewProvider {
    static var previews: some View {
        MainWithSideBarView()
    }
}

extension View {
    func getRect()->CGRect {
        return UIScreen.main.bounds
    }
}

struct LogOutPopUp: CentrePopup {
    let logoutAction: () -> Void
    func configurePopup(popup: CentrePopupConfig) -> CentrePopupConfig {
        popup.horizontalPadding(28)
    }
    func createContent() -> some View {
        VStack(spacing: 5) {
      
            createTitle()
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

private extension LogOutPopUp {

    func createTitle() -> some View {
        Text("Are you sure you want to log out?")
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

private extension LogOutPopUp {
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
            logoutAction()
            dismiss()
        }) {
            Text("Logout")
                .bold()
                .foregroundColor(.white)
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(.black)
                .cornerRadius(8)
        }
    }
}
