//
//  MockupSideMenu.swift
//  ShiftTracker
//
//  Created by James Poole on 25/09/23.
//

import SwiftUI

struct MockupSideMenu: View {
    
    @State private var switchView: Bool = true
    
    enum ActiveJob {
        case jobone, jobtwo, jobthree
    }
    
    @State private var activeJob: ActiveJob = .jobone
    
    var body: some View {
        
        let foregroundColor = Color.white.opacity(0.5)
        
        
        VStack {
            HStack{
                Image(systemName: "photo").foregroundStyle(activeJob == .jobone ? .white : foregroundColor)
                RoundedRectangle(cornerRadius: 6).frame(width: 50, height: 10).foregroundStyle(foregroundColor)
                    Spacer()
            }.padding().background{
                Capsule().foregroundStyle(.thinMaterial)
            }.opacity(activeJob == .jobone ? 1.0 : 0.5)
            
            HStack{
                Image(systemName: "photo").foregroundStyle(activeJob == .jobtwo ? .white : foregroundColor)
                RoundedRectangle(cornerRadius: 6).frame(width: 90, height: 10).foregroundStyle(foregroundColor)
                    Spacer()
            }.padding().background{
                Capsule().foregroundStyle(.thinMaterial)
            }.opacity(activeJob == .jobtwo ? 1.0 : 0.5)
            
            HStack{
                Image(systemName: "photo").foregroundStyle(activeJob == .jobthree ? .white : foregroundColor)
                RoundedRectangle(cornerRadius: 6).frame(width: 75, height: 10).foregroundStyle(foregroundColor)
                    Spacer()
            }.padding().background{
                Capsule().foregroundStyle(.thinMaterial)
            }.opacity(activeJob == .jobthree ? 1.0 : 0.5)
            
            
        }.foregroundStyle(.gray)
            .frame(maxWidth: 200)
            .shadow(color: Color.black.opacity(0.5), radius: 10, x: 5, y: 5)
        
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
                            withAnimation {
                                switch activeJob {
                                case .jobone:
                                    activeJob = .jobtwo
                                case .jobtwo:
                                    activeJob = .jobthree
                                case .jobthree:
                                    activeJob = .jobone
                                }
                            }
                        }
                    }
        
    }
}

#Preview {
    MockupSideMenu()
}
