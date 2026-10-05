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

public enum PTStorePurchaseResult: Sendable, Equatable {
    case purchased(PTStoreEntitlement)
    case pending
    case cancelled
}

public enum PTStoreVerificationResult: Sendable, Equatable {
    case verified(PTStoreTransactionSnapshot)
    case unverified(productID: String, reason: String)
}

public enum PTStoreTransactionEvent: Sendable, Equatable {
    case verified(PTStoreTransactionSnapshot)
    case unverified(productID: String, reason: String)
}

public struct PTStoreVerificationPolicy: Sendable, Equatable {
    public let finishVerifiedTransactions: Bool
    public init(finishVerifiedTransactions: Bool = true) {
        self.finishVerifiedTransactions = finishVerifiedTransactions
    }
}

public struct PTStoreTransactionSnapshot: Sendable, Equatable {
    public let productID: String
    public let transactionID: UInt64
    public let purchaseDate: Date
    public let expirationDate: Date?
    public let revocationDate: Date?
    public let isUpgraded: Bool
    public let ownershipType: String

    public init(productID: String,
                transactionID: UInt64,
                purchaseDate: Date,
                expirationDate: Date?,
                revocationDate: Date?,
                isUpgraded: Bool,
                ownershipType: String = "unknown") {
        self.productID = productID
        self.transactionID = transactionID
        self.purchaseDate = purchaseDate
        self.expirationDate = expirationDate
        self.revocationDate = revocationDate
        self.isUpgraded = isUpgraded
        self.ownershipType = ownershipType
    }
}

public enum PTStoreSubscriptionState: Sendable, Equatable {
    case active(expirationDate: Date?)
    case inGracePeriod(expirationDate: Date?)
    case inBillingRetryPeriod
    case expired
    case revoked(Date?)
    case unavailable
}

public enum PTStoreError: Error, Sendable, Equatable {
    case productNotFound
    case unverified
    case pending
    case userCancelled
    case failed(String)
}

public actor PTStore {
    public let verificationPolicy: PTStoreVerificationPolicy

    public init(verificationPolicy: PTStoreVerificationPolicy = .init()) {
        self.verificationPolicy = verificationPolicy
    }

    public func products(for identifiers: Set<String>) async throws -> [PTStoreProduct] {
        try await Product.products(for: identifiers).map {
            PTStoreProduct(id: $0.id, displayName: $0.displayName, displayPrice: $0.displayPrice, type: String(describing: $0.type))
        }
    }

    public func purchase(productID: String) async throws -> PTStoreEntitlement {
        switch try await purchaseResult(productID: productID) {
        case .purchased(let entitlement): return entitlement
        case .pending: throw PTStoreError.pending
        case .cancelled: throw PTStoreError.userCancelled
        }
    }

    // English: Preserve pending and cancellation as typed outcomes instead of treating them as failures.
    // Español: Conserva pending y cancelación como resultados tipados en lugar de tratarlos como fallos.
    // 中文：将 pending 和取消保留为类型化结果，不再全部当作错误。
    public func purchaseResult(productID: String) async throws -> PTStorePurchaseResult {
        guard let product = try await Product.products(for: [productID]).first else { throw PTStoreError.productNotFound }
        switch try await product.purchase() {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { throw PTStoreError.unverified }
            if verificationPolicy.finishVerifiedTransactions { await transaction.finish() }
            return .purchased(PTStoreEntitlement(productID: transaction.productID,
                                                  transactionID: transaction.id,
                                                  expirationDate: transaction.expirationDate))
        case .userCancelled: return .cancelled
        case .pending: return .pending
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

    public func currentEntitlementSnapshots() async -> [PTStoreTransactionSnapshot] {
        var result: [PTStoreTransactionSnapshot] = []
        for await verification in Transaction.currentEntitlements {
            if case .verified(let transaction) = verification {
                result.append(snapshot(for: transaction))
            }
        }
        return result
    }

    public func sync() async throws {
        try await AppStore.sync()
    }

    public func latestTransaction(productID: String) async -> PTStoreTransactionSnapshot? {
        guard let verification = await Transaction.latest(for: productID),
              case .verified(let transaction) = verification else { return nil }
        return snapshot(for: transaction)
    }

    public func subscriptionState(productID: String, now: Date = .now) async -> PTStoreSubscriptionState {
        guard let transaction = await latestTransaction(productID: productID) else { return .unavailable }
        if let revocationDate = transaction.revocationDate { return .revoked(revocationDate) }
        if let expirationDate = transaction.expirationDate, expirationDate <= now { return .expired }
        return .active(expirationDate: transaction.expirationDate)
    }

    // English: Read StoreKit's subscription state so grace and billing-retry periods are not mistaken for expiry.
    // Español: Lee el estado de StoreKit para no confundir gracia o reintento de cobro con expiración.
    // 中文：读取 StoreKit 订阅状态，避免把宽限期或扣费重试误判为过期。
    public func subscriptionStatus(productID: String,
                                   now: Date = .now) async throws -> PTStoreSubscriptionState {
        guard let product = try await Product.products(for: [productID]).first,
              let subscription = product.subscription else { return .unavailable }
        let statuses = try await subscription.status
        guard let status = statuses.first else { return .unavailable }
        switch status.state {
        case .subscribed:
            let expirationDate = await latestTransaction(productID: productID)?.expirationDate
            return .active(expirationDate: expirationDate)
        case .inGracePeriod:
            let expirationDate = await latestTransaction(productID: productID)?.expirationDate
            return .inGracePeriod(expirationDate: expirationDate)
        case .inBillingRetryPeriod:
            return .inBillingRetryPeriod
        case .expired:
            return .expired
        case .revoked:
            return .revoked(await latestTransaction(productID: productID)?.revocationDate)
        default:
            return .unavailable
        }
    }

    private func snapshot(for transaction: Transaction) -> PTStoreTransactionSnapshot {
        PTStoreTransactionSnapshot(productID: transaction.productID,
                                   transactionID: transaction.id,
                                   purchaseDate: transaction.purchaseDate,
                                   expirationDate: transaction.expirationDate,
                                   revocationDate: transaction.revocationDate,
                                   isUpgraded: transaction.isUpgraded,
                                   ownershipType: String(describing: transaction.ownershipType))
    }
}

public actor PTTransactionMonitor {
    private let verificationPolicy: PTStoreVerificationPolicy
    private var continuation: AsyncStream<PTStoreEntitlement>.Continuation?
    private var task: Task<Void, Never>?
    private var stream: AsyncStream<PTStoreEntitlement>?
    private var eventContinuation: AsyncStream<PTStoreTransactionEvent>.Continuation?
    private var eventStream: AsyncStream<PTStoreTransactionEvent>?
    private var seenTransactionIDs: Set<UInt64> = []

    public init(verificationPolicy: PTStoreVerificationPolicy = .init()) {
        self.verificationPolicy = verificationPolicy
    }

    public func start() -> AsyncStream<PTStoreEntitlement> {
        if let stream { return stream }
        let stream = AsyncStream<PTStoreEntitlement> { continuation in self.continuation = continuation }
        self.stream = stream
        startTaskIfNeeded()
        return stream
    }

    public func startEvents() -> AsyncStream<PTStoreTransactionEvent> {
        if let eventStream { return eventStream }
        let stream = AsyncStream<PTStoreTransactionEvent> { continuation in self.eventContinuation = continuation }
        eventStream = stream
        startTaskIfNeeded()
        return stream
    }

    public func stop() {
        task?.cancel()
        task = nil
        continuation?.finish()
        continuation = nil
        stream = nil
        eventContinuation?.finish()
        eventContinuation = nil
        eventStream = nil
        seenTransactionIDs.removeAll(keepingCapacity: false)
    }

    private func startTaskIfNeeded() {
        guard task == nil else { return }
        let shouldFinishVerifiedTransactions = verificationPolicy.finishVerifiedTransactions
        task = Task { [weak self] in
            for await verification in Transaction.updates {
                guard let self else { return }
                switch verification {
                case .verified(let transaction):
                    guard await self.accept(transaction.id) else { continue }
                    if shouldFinishVerifiedTransactions { await transaction.finish() }
                    let snapshot = await self.snapshot(for: transaction)
                    await self.yield(.verified(snapshot))
                    await self.yieldEntitlement(PTStoreEntitlement(productID: transaction.productID,
                                                                    transactionID: transaction.id,
                                                                    expirationDate: transaction.expirationDate))
                case .unverified(let transaction, let error):
                    await self.yield(.unverified(productID: transaction.productID,
                                                 reason: String(describing: error)))
                @unknown default:
                    continue
                }
            }
        }
    }

    private func accept(_ transactionID: UInt64) -> Bool {
        guard seenTransactionIDs.insert(transactionID).inserted else { return false }
        return true
    }

    private func yield(_ event: PTStoreTransactionEvent) { eventContinuation?.yield(event) }
    private func yieldEntitlement(_ entitlement: PTStoreEntitlement) { continuation?.yield(entitlement) }

    private func snapshot(for transaction: Transaction) -> PTStoreTransactionSnapshot {
        PTStoreTransactionSnapshot(productID: transaction.productID,
                                   transactionID: transaction.id,
                                   purchaseDate: transaction.purchaseDate,
                                   expirationDate: transaction.expirationDate,
                                   revocationDate: transaction.revocationDate,
                                   isUpgraded: transaction.isUpgraded,
                                   ownershipType: String(describing: transaction.ownershipType))
    }
}
