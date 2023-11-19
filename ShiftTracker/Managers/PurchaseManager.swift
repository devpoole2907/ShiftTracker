//
//  PurchaseManager.swift
//  ShiftTracker
//
//  Created by James Poole on 17/07/23.
//

import Foundation
import StoreKit
import CoreData

@MainActor
class PurchaseManager: ObservableObject {
    
    
    private let productIds = ["pro_lifetime"]
    
    @Published
    private(set) var products: [Product] = []
    private var productsLoaded = false
    
    @Published private(set) var purchasedProductIDs = Set<String>()
    
    @Published var showSuccessSheet = false
    
    private var updates: Task<Void, Never>? = nil
    
    var subscriptionExpiryDate: Date?
    
    var hasUnlockedPro: Bool {
        
    //    return true // temporary for testflight
    
        if self.purchasedProductIDs.contains("pro_lifetime") {
                    return true
                }
        
        return (subscriptionExpiryDate ?? Date()) > Date()
        
     
        
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
        var latestTransaction: Transaction?

        // loop through all transactions to get the latest one
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            if transaction.productID == "pro_lifetime" {
                            self.purchasedProductIDs.insert(transaction.productID)
                            return
                        }

  
            if let latest = latestTransaction,
               let transactionExpirationDate = transaction.expirationDate,
               let latestExpirationDate = latest.expirationDate {
                if transactionExpirationDate > latestExpirationDate {
                    latestTransaction = transaction
                }
            } else if latestTransaction == nil {
       
                latestTransaction = transaction
            }
        }

       
        if let transaction = latestTransaction {
                if let revocationDate = transaction.revocationDate,
                   revocationDate < Date() {
                    self.purchasedProductIDs.remove(transaction.productID)
                    self.subscriptionExpiryDate = nil
                 
                } else {
                    self.purchasedProductIDs.insert(transaction.productID)
                    self.subscriptionExpiryDate = transaction.expirationDate
                }
            }
    }



    
    func purchase(_ product: Product) async throws {
        
        let result = try await product.purchase()
        
        switch result {
            
        case let .success(.verified(transaction)):
            
            await transaction.finish()
            await self.updatePurchasedProducts()
            
            DispatchQueue.main.async {
                            self.showSuccessSheet = true
                        }
            
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
    
    func handleSubscriptionExpiry(in viewContext: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Job> = Job.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "autoClockIn == YES || autoClockOut == YES")
        
        do {
            let jobs = try viewContext.fetch(fetchRequest)
            for job in jobs {
                job.autoClockIn = false
                job.autoClockOut = false
            }
            try viewContext.save()
        } catch {
            // Handle the error
            print("Unable to fetch jobs: \(error)")
        }
    }

    
    
    
    
}
