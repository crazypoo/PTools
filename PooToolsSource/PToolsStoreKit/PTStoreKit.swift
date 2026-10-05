// English: StoreKit 2 first typed facade for products, purchases, and entitlements.
// Español: Fachada tipada basada primero en StoreKit 2 para productos, compras y derechos.
// 中文：基于 StoreKit 2 的类型化商品、购买和权益门面。

import Foundation
import StoreKit

public struct PTStoreProduct: Sendable, Equatable {
    public let id: String
    public let displayName: String
    public let displayPrice: String
    public let type: String
    public init(id: String, displayName: String, displayPrice: String, type: String) {
        self.id = id; self.displayName = displayName; self.displayPrice = displayPrice; self.type = type
    }
}

public struct PTStoreEntitlement: Sendable, Equatable {
    public let productID: String
    public let transactionID: UInt64
    public let expirationDate: Date?
    public init(productID: String, transactionID: UInt64, expirationDate: Date?) {
        self.productID = productID; self.transactionID = transactionID; self.expirationDate = expirationDate
    }
}

public enum PTStoreError: Error, Sendable, Equatable {
    case productNotFound
    case unverified
    case pending
    case userCancelled
    case failed(String)
}

public actor PTStore {
    public init() {}

    public func products(for identifiers: Set<String>) async throws -> [PTStoreProduct] {
        try await Product.products(for: identifiers).map {
            PTStoreProduct(id: $0.id, displayName: $0.displayName, displayPrice: $0.displayPrice, type: String(describing: $0.type))
        }
    }

    public func purchase(productID: String) async throws -> PTStoreEntitlement {
        guard let product = try await Product.products(for: [productID]).first else { throw PTStoreError.productNotFound }
        switch try await product.purchase() {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { throw PTStoreError.unverified }
            await transaction.finish()
            return PTStoreEntitlement(productID: transaction.productID, transactionID: transaction.id, expirationDate: transaction.expirationDate)
        case .userCancelled: throw PTStoreError.userCancelled
        case .pending: throw PTStoreError.pending
        @unknown default: throw PTStoreError.failed("Unknown StoreKit purchase result")
        }
    }

    public func currentEntitlements() async -> [PTStoreEntitlement] {
        var result: [PTStoreEntitlement] = []
        for await verification in Transaction.currentEntitlements {
            if case .verified(let transaction) = verification {
                result.append(PTStoreEntitlement(productID: transaction.productID, transactionID: transaction.id, expirationDate: transaction.expirationDate))
            }
        }
        return result
    }
}

public actor PTTransactionMonitor {
    private var continuation: AsyncStream<PTStoreEntitlement>.Continuation?
    private var task: Task<Void, Never>?

    public init() {}

    public func start() -> AsyncStream<PTStoreEntitlement> {
        let stream = AsyncStream<PTStoreEntitlement> { continuation in self.continuation = continuation }
        task?.cancel()
        task = Task { [weak self] in
            for await verification in Transaction.updates {
                guard case .verified(let transaction) = verification else { continue }
                await transaction.finish()
                let entitlement = PTStoreEntitlement(productID: transaction.productID, transactionID: transaction.id, expirationDate: transaction.expirationDate)
                await self?.yield(entitlement)
            }
        }
        return stream
    }

    public func stop() {
        task?.cancel(); task = nil; continuation?.finish(); continuation = nil
    }

    private func yield(_ entitlement: PTStoreEntitlement) { continuation?.yield(entitlement) }
}
