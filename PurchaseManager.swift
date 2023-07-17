//
//  PurchaseManager.swift
//  ShiftTracker
//
//  Created by James Poole on 17/07/23.
//

import Foundation
import StoreKit

@MainActor
class PurchaseManager: ObservableObject {
    
    
    private let productIds = ["pro_month", "pro_yearly"]
    
    @Published
    private(set) var products: [Product] = []
    private var productsLoaded = false
    
    @Published private(set) var purchasedProductIDs = Set<String>()
    
    private var updates: Task<Void, Never>? = nil
    
    var hasUnlockedPro: Bool {
        
        return !self.purchasedProductIDs.isEmpty
        
    }
    
    init() {
        
        updates = observeTransactionUpdates()
        
    }
    
    deinit {
        
        updates?.cancel()
        
    }
   
    private func observeTransactionUpdates() -> Task<Void, Never> {
        
        Task(priority: .background) { [unowned self] in
            
            for await verificationResult in Transaction.updates {
                
                await self.updatePurchasedProducts()
                
            }
            
        }
        
        
    }
    
    
    
    func loadProducts() async throws {
        
        guard !self.productsLoaded else { return }
        
        self.products = try await Product.products(for: productIds)
        self.productsLoaded = true
        
        
    }
    
    func updatePurchasedProducts() async {
        
        
        for await result in Transaction.currentEntitlements {
            
            guard case .verified(let transaction) = result else {
                
                continue
                
            }
            
            if transaction.revocationDate == nil {
                
                
                self.purchasedProductIDs.insert(transaction.productID)
                
            } else {
                
                self.purchasedProductIDs.remove(transaction.productID)
                
            }
            
            
        }
        
        
    }
    
    func purchase(_ product: Product) async throws {
        
        let result = try await product.purchase()
        
        switch result {
            
        case let .success(.verified(transaction)):
            
            await transaction.finish()
            await self.updatePurchasedProducts()
            
        case let .success(.unverified(_, error)):
            
            break
            
            
        case .pending:
            
            break
            
        case .userCancelled:
            
            break
            
            
        @unknown default:
            break
        }
        
        
        
    }
    
    
    
    
}
