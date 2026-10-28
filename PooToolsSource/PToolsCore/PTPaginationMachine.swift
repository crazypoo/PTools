//
//  PTPaginationMachine.swift
//  PToolsCore
//
// English: A Foundation-only pagination state machine with generation-safe request tokens.
// Español: Una máquina de estados de paginación basada solo en Foundation con tokens seguros por generación.
// 中文：仅依赖 Foundation 的分页状态机，并使用带代次校验的请求令牌。
//

import Foundation

// English: Keep page configuration explicit so zero-based and one-based APIs can coexist.
// Español: Mantiene explícita la configuración para que convivan APIs basadas en cero y en uno.
// 中文：显式保存页码配置，让 0 起始和 1 起始接口可以共存。
public struct PTPaginationConfiguration: Sendable, Equatable {
    public let firstPage: Int
    public let pageSize: Int
    public let serializesRequests: Bool

    public init(firstPage: Int = 1,
                pageSize: Int = 20,
                serializesRequests: Bool = true) {
        self.firstPage = max(0, firstPage)
        self.pageSize = max(1, pageSize)
        self.serializesRequests = serializesRequests
    }
}

// English: A token identifies both the request generation and its page.
// Español: Un token identifica tanto la generación de la solicitud como su página.
// 中文：令牌同时标识请求代次和请求页码。
public struct PTPaginationRequestToken: Sendable, Hashable {
    public let generation: UInt64
    public let requestedPage: Int
    public let id: UUID

    fileprivate init(generation: UInt64, requestedPage: Int, id: UUID = UUID()) {
        self.generation = generation
        self.requestedPage = requestedPage
        self.id = id
    }
}

// English: Keep pagination state value-typed so a caller can own it on any actor.
// Español: Mantiene el estado de paginación como tipo de valor para que el llamador pueda poseerlo en cualquier actor.
// 中文：分页状态使用值类型，让调用方可以在任意 actor 中安全持有。
public struct PTPaginationMachine: Sendable {
    public let configuration: PTPaginationConfiguration

    public private(set) var currentPage: Int
    public private(set) var hasMore: Bool

    private var generation: UInt64 = 0
    private var nextPage: Int
    private var inFlight: [UUID: PTPaginationRequestToken] = [:]
    private var completedPages: Set<Int> = []

    public init(configuration: PTPaginationConfiguration = .init()) {
        self.configuration = configuration
        self.currentPage = configuration.firstPage - 1
        self.nextPage = configuration.firstPage
        self.hasMore = true
    }

    public var isLoading: Bool {
        !inFlight.isEmpty
    }

    public var inFlightPages: Set<Int> {
        Set(inFlight.values.map(\.requestedPage))
    }

    // English: Refresh always starts a new generation and invalidates every older response.
    // Español: La actualización siempre inicia una nueva generación e invalida todas las respuestas anteriores.
    // 中文：刷新始终开启新代次，并让之前所有回包失效。
    @discardableResult
    public mutating func beginRefresh() -> PTPaginationRequestToken {
        generation &+= 1
        inFlight.removeAll(keepingCapacity: true)
        completedPages.removeAll(keepingCapacity: true)
        currentPage = configuration.firstPage - 1
        nextPage = configuration.firstPage
        hasMore = true
        return reserve(page: configuration.firstPage)
    }

    // English: A serialized machine rejects re-entry while a page is in flight.
    // Español: Una máquina serializada rechaza la reentrada mientras haya una página en vuelo.
    // 中文：串行模式下有请求进行时拒绝再次加载，避免重复请求。
    @discardableResult
    public mutating func beginNextPage() -> PTPaginationRequestToken? {
        guard hasMore else { return nil }
        if configuration.serializesRequests, isLoading { return nil }
        return reserve(page: max(configuration.firstPage, nextPage))
    }

    public func isCurrent(_ token: PTPaginationRequestToken) -> Bool {
        inFlight[token.id] == token && token.generation == generation
    }

    // English: Apply only a token from the active generation; stale callbacks are ignored.
    // Español: Solo aplica tokens de la generación activa; los callbacks obsoletos se ignoran.
    // 中文：只应用当前代次的令牌，旧回调会被忽略。
    @discardableResult
    public mutating func applySuccess(_ token: PTPaginationRequestToken,
                                      itemCount: Int,
                                      hasMore explicitHasMore: Bool? = nil,
                                      totalPages: Int? = nil) -> Bool {
        guard consume(token) else { return false }

        let page = token.requestedPage
        completedPages.insert(page)
        if itemCount == 0 {
            completedPages.remove(page)
        }
        currentPage = contiguousCompletedPage()
        nextPage = max(nextPage, page + 1)

        if let totalPages {
            let lastPage = max(configuration.firstPage, totalPages)
            currentPage = min(currentPage, lastPage)
            hasMore = page < lastPage
        } else if let explicitHasMore {
            hasMore = explicitHasMore
        } else {
            hasMore = itemCount > 0
        }

        if itemCount == 0 {
            // Empty pages roll back one page without changing the generation.
            // Las páginas vacías retroceden una página sin cambiar la generación.
            // 空页回退一页，但不会改变当前代次。
            currentPage = min(contiguousCompletedPage(), max(configuration.firstPage - 1, page - 1))
            if hasMore {
                nextPage = min(nextPage, max(configuration.firstPage, page))
            }
        }
        return true
    }

    // English: A failed current request can be retried without changing its generation.
    // Español: Una solicitud actual fallida puede reintentarse sin cambiar su generación.
    // 中文：当前请求失败后可以在不改变代次的情况下重试。
    @discardableResult
    public mutating func applyFailure(_ token: PTPaginationRequestToken) -> Bool {
        guard consume(token) else { return false }
        nextPage = min(nextPage, max(configuration.firstPage, token.requestedPage))
        currentPage = contiguousCompletedPage()
        return true
    }

    // English: Cancellation removes only the matching request and makes no UI decision.
    // Español: La cancelación elimina solo la solicitud correspondiente y no decide el estado de UI.
    // 中文：取消只移除对应请求，不替调用方决定 UI 状态。
    @discardableResult
    public mutating func cancel(_ token: PTPaginationRequestToken) -> Bool {
        guard consume(token) else { return false }
        nextPage = min(nextPage, max(configuration.firstPage, token.requestedPage))
        currentPage = contiguousCompletedPage()
        return true
    }

    // English: Invalidate all requests while keeping the machine reusable.
    // Español: Invalida todas las solicitudes manteniendo reutilizable la máquina.
    // 中文：让所有请求失效，同时保留状态机的可复用性。
    public mutating func invalidate() {
        generation &+= 1
        inFlight.removeAll(keepingCapacity: true)
        completedPages.removeAll(keepingCapacity: true)
        currentPage = configuration.firstPage - 1
        nextPage = configuration.firstPage
        hasMore = true
    }

    // English: Mark the current sequence as complete without fabricating a page response.
    // Español: Marca la secuencia actual como completa sin inventar una respuesta de página.
    // 中文：直接标记当前序列结束，不伪造分页回包。
    public mutating func markEnd() {
        hasMore = false
    }

    private mutating func reserve(page: Int) -> PTPaginationRequestToken {
        let token = PTPaginationRequestToken(generation: generation,
                                              requestedPage: page)
        inFlight[token.id] = token
        nextPage = max(nextPage, page + 1)
        return token
    }

    private func contiguousCompletedPage() -> Int {
        var page = configuration.firstPage - 1
        while completedPages.contains(page + 1) {
            page += 1
        }
        return page
    }

    private mutating func consume(_ token: PTPaginationRequestToken) -> Bool {
        guard token.generation == generation,
              inFlight[token.id] == token else {
            return false
        }
        inFlight.removeValue(forKey: token.id)
        return true
    }
}
