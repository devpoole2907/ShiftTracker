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
    
    
    var body: some View {
        
        let proButtonColor: Color = colorScheme == .dark ? Color.orange : Color.cyan
        let textColor: Color = colorScheme == .dark ? Color.white.opacity(0.9) : Color.white
        let upgradeButtonTextColor: Color = colorScheme == .dark ? .white : Color.black
        
        
        NavigationStack {
            
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
                    HStack {
                        Image(systemName: "clipboard")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundColor(proButtonColor)
                        Spacer().frame(width: 15)
                        Text("Multiple Jobs")
                            .font(.title2)
                            .bold()
                    }.listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 5)
                    HStack {
                        Image(systemName: "play.rectangle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundColor(proButtonColor)
                        Spacer().frame(width: 15)
                        Text("Live Activities")
                            .font(.title2)
                            .bold()
                        //.foregroundColor(textColor)
                    }.listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 5)
                    HStack {
                        Image(systemName: "location")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundColor(proButtonColor)
                        Spacer().frame(width: 15)
                        Text("Location based clock in & clock out")
                            .font(.title2)
                            .bold()
                        //.foregroundColor(textColor)
                    }.listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 5)
                    HStack {
                        Image(systemName: "paintpalette")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundColor(proButtonColor)
                        Spacer().frame(width: 15)
                        Text("Custom Themes")
                            .font(.title2)
                            .bold()
                    }.listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 5)
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundColor(proButtonColor)
                        Spacer().frame(width: 15)
                        Text("Data Exporting")
                            .font(.title2)
                            .bold()
                    }.listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 5)
                    
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundColor(proButtonColor)
                        Spacer().frame(width: 15)
                        Text("Custom App Icons")
                            .font(.title2)
                            .bold()
                    }.listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 5)
                    
                    
                    /*  HStack {
                     Image(systemName: "timer")
                     .resizable()
                     .aspectRatio(contentMode: .fit)
                     .frame(width: 40, height: 40)
                     .foregroundColor(proButtonColor)
                     Spacer().frame(width: 15)
                     Text("Automatic Breaks")
                     .font(.title2)
                     .bold()
                     }.listRowSeparator(.hidden)
                     .listRowBackground(Color.clear)
                     .padding(.vertical, 5)
                     HStack {
                     Image(systemName: "paperclip")
                     .resizable()
                     .aspectRatio(contentMode: .fit)
                     .frame(width: 40, height: 40)
                     .foregroundColor(proButtonColor)
                     Spacer().frame(width: 15)
                     Text("Invoice Generation")
                     .font(.title2)
                     .bold()
                     }.listRowSeparator(.hidden)
                     .listRowBackground(Color.clear)
                     .padding(.vertical, 5)*/
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
                        .fontDesign(.rounded)
                }.padding()
                
            }
            
            .sheet(isPresented: $purchaseManager.showSuccessSheet, onDismiss: {dismiss()}) {
                
                PurchaseSuccessView()
                
                    .presentationBackground(Color("allSheetBackground"))
                    .presentationCornerRadius(25)
                
            }
            
            .toolbar {
                
                ToolbarItem(placement: .navigationBarLeading) {
                    
                    CloseButton(action: {dismiss()})
                    
                    
                }
                
                
            }
            
            
        } .onAppear{
            
            Task{
                
                await purchaseManager.updatePurchasedProducts()
                
                
            }
            
        }
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
                Text(product.id == "pro_month" ? "MONTHLY" : "YEARLY")
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
            .cornerRadius(20)
            .padding()
            .background(Color("SquaresColor"),in:
                            RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            
            
        }
        
        
    }
    
}


struct ProView_Previews: PreviewProvider {
    static var previews: some View {
        ProView()
    }
}
