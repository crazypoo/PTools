//
//  PTSearchSnapshot.swift
//  PooTools
//
// English: A value snapshot prevents an older async request from updating newer results.
// Español: Una instantánea de valor evita que una solicitud antigua sobrescriba resultados nuevos.
// 中文：值快照用于阻止旧异步请求覆盖新结果。
//

import Foundation

public struct PTSearchSnapshot: Sendable, Equatable {
    public let id: UUID
    public let keyword: String

    public init(id: UUID = UUID(), keyword: String) {
        self.id = id
        self.keyword = keyword
    }
}
