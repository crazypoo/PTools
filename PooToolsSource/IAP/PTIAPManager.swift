//
//  PTIAPManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import StoreKit

// Typealiases for completion blocks
public typealias PurchasedProductsChanged = () -> Void
public typealias ProductsCompletionBlock = ([SKProduct]) -> Void
public typealias PurchaseCompletionBlock = (SKPaymentTransaction?) -> Void
public typealias IAPErrorBlock = (Error) -> Void
public typealias RestorePurchasesCompletionBlock = () -> Void

public class PTIAPManager: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    public static let shared = PTIAPManager()
    
    private var purchasedItems: [String]
    private var products: [String: SKProduct]
    private var purchasedItemsChanged = false
    
    private var productRequests: [(SKProductsRequest, (Result<[SKProduct], Error>) -> Void)] = []
    private var payments: [(String, PurchaseCompletionBlock, IAPErrorBlock)] = []
    private var purchasesChangedCallbacks: [(PurchasedProductsChanged, AnyObject)] = []
    
    private var restoreCompletionBlock: RestorePurchasesCompletionBlock?
    private var restoreErrorBlock: IAPErrorBlock?
    
    override init() {
        if let purchasedItems = NSArray(contentsOf: PTIAPManager.purchasesURL()) as? [String] {
            self.purchasedItems = purchasedItems
        } else {
            self.purchasedItems = []
        }
        self.products = [:]
        
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func willResignActive(_ notification: Notification) {
        if purchasedItemsChanged {
            persistPurchasedItems()
        }
    }
    
    private static func purchasesURL() -> URL {
        let appDocDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        return appDocDir.appendingPathComponent(".purchases.plist")
    }
    
    private func persistPurchasedItems() {
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: purchasedItems, format: .binary, options: 0)
            try data.write(to: PTIAPManager.purchasesURL())
        } catch {
            PTNSLogConsole("Saving purchases to \(PTIAPManager.purchasesURL()) failed!")
        }
    }
    
    public func hasPurchased(_ productID: String) -> Bool {
        return purchasedItems.contains(productID)
    }
    
    // Simple reachability check
    private static func checkAppStoreAvailable() -> Bool {
        _ = hostent()
        let hostname = "appstore.com"
        let result = hostname.withCString { gethostbyname($0) }
        return result != nil
    }
    
    // MARK: - Product Information
    
    public func getProducts(forIds productIds: [String], completion: @escaping ProductsCompletionBlock) {
        var result: [SKProduct] = []
        var remainingIds: Set<String> = Set()
        
        for productId in productIds {
            if let product = products[productId] {
                result.append(product)
            } else {
                remainingIds.insert(productId)
            }
        }
        
        if remainingIds.isEmpty {
            completion(result)
            return
        }
        
        let req = SKProductsRequest(productIdentifiers: remainingIds)
        req.delegate = self
        productRequests.append((req, { result in
            switch result {
            case .success(let products):
                for product in products {
                    self.products[product.productIdentifier] = product
                }
                completion(products)
            case .failure(let error):
                PTNSLogConsole("Failed to fetch products: \(error.localizedDescription)")
            }
        }))
        req.start()
    }
    
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        for (i, tuple) in productRequests.enumerated() {
            if tuple.0 == request {
                tuple.1(.success(response.products))
                productRequests.remove(at: i)
                return
            }
        }
    }
    
    // MARK: - Purchase
    
    public func restorePurchases() {
        restorePurchases(completion: nil, error: nil)
    }
    
    public func restorePurchases(completion: RestorePurchasesCompletionBlock?, error: IAPErrorBlock?) {
        restoreCompletionBlock = completion
        restoreErrorBlock = error
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    public func purchase(product: SKProduct, completion: @escaping PurchaseCompletionBlock, error: @escaping IAPErrorBlock) {
        guard PTIAPManager.checkAppStoreAvailable(), SKPaymentQueue.canMakePayments() else {
            error(NSError(domain: "PTIAPManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Can't make payments"]))
            return
        }
        
        let payment = SKPayment(product: product)
        payments.append((payment.productIdentifier, completion, error))
        SKPaymentQueue.default().add(payment)
    }
    
    public func purchase(productId: String, completion: @escaping PurchaseCompletionBlock, error: @escaping IAPErrorBlock) {
        getProducts(forIds: [productId]) { products in
            if products.isEmpty {
                error(NSError(domain: "PTIAPManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Didn't find products with ID \(productId)"]))
            } else {
                self.purchase(product: products[0], completion: completion, error: error)
            }
        }
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        var newPurchases = false
        
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                purchasedItems.append(transaction.payment.productIdentifier)
                newPurchases = true
                queue.finishTransaction(transaction)
            case .failed:
                queue.finishTransaction(transaction)
            case .purchasing:
                PTNSLogConsole("\(transaction.payment.productIdentifier) is being processed by the App Store...")
            case .deferred:
                PTNSLogConsole("\(transaction.payment.productIdentifier) is deferred by the App Store...")
            @unknown default:
                break
            }
        }
        
        if newPurchases {
            persistPurchasedItems()
            purchasedItemsChanged = true
            
            for (callback, _) in purchasesChangedCallbacks {
                callback()
            }
        }
        
        for transaction in transactions {
            if let paymentIndex = payments.firstIndex(where: { $0.0 == transaction.payment.productIdentifier }) {
                let (_, completion, error) = payments[paymentIndex]
                
                switch transaction.transactionState {
                case .purchased, .restored:
                    completion(transaction)
                case .failed:
                    error(transaction.error!)
                default:
                    break
                }
            }
        }
    }
    
    public func canPurchase() -> Bool {
        return SKPaymentQueue.canMakePayments() && PTIAPManager.checkAppStoreAvailable()
    }
    
    // MARK: - Observation
    
    public func addPurchasesChangedCallback(_ callback: @escaping PurchasedProductsChanged, withContext context: AnyObject) {
        purchasesChangedCallbacks.append((callback, context))
    }
    
    public func removePurchasesChangedCallback(withContext context: AnyObject) {
        purchasesChangedCallbacks.removeAll { $0.1 === context }
    }
    
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        restoreCompletionBlock?()
        restoreCompletionBlock = nil
        restoreErrorBlock = nil
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        restoreErrorBlock?(error)
        restoreCompletionBlock = nil
        restoreErrorBlock = nil
    }
}

