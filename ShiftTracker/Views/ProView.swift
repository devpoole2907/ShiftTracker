//
//  ProView.swift
//  ShiftTracker
//
//  Created by James Poole on 26/03/23.
//

import SwiftUI
import StoreKit

struct ProView: View {
    
    @Environment(\.dismiss) var dismiss
    
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    @State private var hasAppeared = false // used to animate the background fading out when appearing as a fullscreencover due to a system glitch with black/white backgrounds no transparency
    
    
    var body: some View {
        
        let proButtonColor: Color = colorScheme == .dark ? Color.orange : Color.cyan
        let textColor: Color = colorScheme == .dark ? Color.white.opacity(0.9) : Color.white
        let upgradeButtonTextColor: Color = colorScheme == .dark ? .white : Color.black
        
        let backgroundColor = colorScheme == .dark ? Color(.systemGray6) : Color.white
        
        NavigationStack {
            
            ZStack{
                backgroundColor.opacity(hasAppeared ? 0 : 1)
                
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack{
                        HStack{
                            Text("ShiftTracker")
                                .font(.title)
                                .bold()
                            Text("PRO")
                                .font(.largeTitle)
                                .fontWeight(.heavy)
                                .foregroundStyle(proButtonColor.gradient)
                        }
                        
                        VStack(alignment: .leading){
                            
                            ForEach(proFeatures, id: \.self) { feature in
                                
                                FeatureRow(image: feature.image, text: feature.text)
                                
                            }
                            
                        }.padding(.horizontal, 30)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            HStack{
                                Text("UNLOCK")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(upgradeButtonTextColor)
                                Text("PRO")
                                    .font(.largeTitle)
                                    .fontWeight(.heavy)
                                    .foregroundStyle(proButtonColor.gradient)
                                Text("FEATURES")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(upgradeButtonTextColor)
                            }
                            
                            .foregroundColor(textColor)
                        }
                        .padding()
                        .cornerRadius(20)
                        .frame(maxWidth: .infinity)
                        
                        
                        HStack(spacing: 10){
                            ForEach(purchaseManager.products, id: \.subscription) { product in
                                
                                PurchaseButton(product: product)
                                
                                
                            }
                            
                        }.padding(.horizontal, 30)
                        
                        Button(action: {
                            
                            Task {
                                
                                do {
                                    try await AppStore.sync()
                                } catch {
                                    print(error)
                                }
                                
                                
                            }
                            
                        }) {
                            Text("Restore")
                                .bold()
                                .roundedFontDesign()
                        }.padding()
                        
                    }
                    
                }
                
            }
            
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        hasAppeared = true
                    }
                }
            }
            
            .sheet(isPresented: $purchaseManager.showSuccessSheet, onDismiss: {dismiss()}) {
                
                PurchaseSuccessView()
                
                    .customSheetBackground()
                    .customSheetRadius()
                
            }
            
            .toolbar {
                
                ToolbarItem(placement: .navigationBarLeading) {
                    
                    CloseButton(action: {dismiss()})
                    
                    
                }
                
                
            }
            
            
        }
        
        
        .onAppear{
            
            Task{
                
                await purchaseManager.updatePurchasedProducts()
                
                
            }
            
        }
    }
}


struct FeatureRow: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let image: String
    let text: String
    
    var body: some View {
        let proButtonColor: Color = colorScheme == .dark ? Color.orange : Color.cyan
        HStack {
            Image(systemName: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .foregroundColor(proButtonColor)
            Spacer().frame(width: 15)
            Text(text)
                .font(.title2)
                .bold()
        }.listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .padding(.vertical, 5)
    }
}

struct PurchaseButton: View {
    
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    @Environment(\.colorScheme) var colorScheme
    
    let product: Product
    
    
    var body: some View {
        
        let proButtonColor: Color = colorScheme == .dark ? Color.orange : Color.cyan
        let upgradeButtonTextColor: Color = colorScheme == .dark ? .white : Color.black
        
        Button(action: {
            
            Task {
                do {
                    try await purchaseManager.purchase(product)
                } catch {
                    print("Purchase failed with error: \(error)")
                }
            }
            
        }){
            
            VStack{
                // says upgrade instead of lifetime for now, maybe return and introduce monthly sub again later
                Text(product.id == "pro_month" ? "MONTHLY" : "UPGRADE")
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundColor(upgradeButtonTextColor)
                    .lineLimit(1)
                    .allowsTightening(true)
                
                
                Text(product.displayPrice)
                    .foregroundColor(proButtonColor)
                
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .padding()
            .glassModifier(cornerRadius: 20)
            
            
            
        }
        
        
    }
    
}



struct ProView_Previews: PreviewProvider {
    static var previews: some View {
        ProView()
    }
}
