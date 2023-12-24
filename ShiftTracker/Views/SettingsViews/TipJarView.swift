//
//  TipView.swift
//  ShiftTracker
//
//  Created by James Poole on 20/03/23.
//

import SwiftUI
import StoreKit




struct TipJarView: View {
    let productIDs = ["ShiftTracker_Small_Tip", "ShiftTracker_Medium_Tip", "ShiftTracker_Large_Tip"]
    @State private var showingProView = false
    
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var themeManager: ThemeDataManager
    
    @State private var products: [Product] = []
    
    var body: some View {
            VStack {
                List{
                    if !purchaseManager.hasUnlockedPro {
                        Section{
                        Button(action: {
                            showingProView = true // set the state variable to true to show the sheet
                        }) {
                            Group{
                                ZStack {
                                    Color.black
                                        .cornerRadius(20)
                                        .frame(height: 80)
                                    VStack(spacing: 2) {
                                        HStack{
                                            Text("ShiftTracker")
                                                .font(.title2)
                                                .bold()
                                                .foregroundColor(Color.white)
                                            Text("PRO")
                                                .font(.title)
                                                .bold()
                                                .foregroundColor(Color.orange)
                                        }
                                        //.padding(.top, 3)
                                   
                                        Text("Upgrade Now")
                                            .font(.subheadline)
                                            .bold()
                                            .foregroundColor(.white)
                                    }
                                }.shadow(radius: 5, x: 0, y: 4)
                                .frame(maxWidth: UIScreen.main.bounds.width - 20)
                                .shadow(radius: 2, x: 0, y: 1)//maxHeight: 100)
                            }//.padding(.bottom, 75)
                        }
                        }.listRowBackground(Color.clear)
                }
                ForEach(self.products) { product in
                    Button {
                        Task {
                                    do {
                                        try await self.purchase(product)
                                    } catch {
                                        print(error)
                                    }
                                }
                    } label: {
                        Text("\(product.displayPrice) - \(product.displayName)")
                            .foregroundColor(.orange)
                    }
                }

                .listRowSeparator(.hidden)
                }.scrollContentBackground(.hidden)
                    .background(themeManager.settingsGradient)
                .task {
                    do {
                        try await self.loadProducts()
                    } catch {
                        print(error)
                    }
                }
                
            }
            
        .navigationTitle("Support Us")
            .sheet(isPresented: $showingProView) { // present the sheet with ProView
                if #available(iOS 16.4, *) {
                    ProView()
                        .presentationDetents([.large])
                        .presentationBackground(.ultraThinMaterial)
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(12)
                }
                else {
                    ProView()
                }
            }
       }
    private func loadProducts() async throws {
            self.products = try await Product.products(for: productIDs)
        }
    
    private func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case let .success(.verified(transaction)):
            // Successful purhcase
            await transaction.finish()
        case let .success(.unverified(_, error)):
            // Successful purchase but transaction/receipt can't be verified
            // Could be a jailbroken phone
            break
        case .pending:
            // Transaction waiting on SCA (Strong Customer Authentication) or
            // approval from Ask to Buy
            break
        case .userCancelled:
            // ^^^
            break
        @unknown default:
            break
        }
    }

    
}

struct TipView_Previews: PreviewProvider {
    static var previews: some View {
        TipJarView()
    }
}
