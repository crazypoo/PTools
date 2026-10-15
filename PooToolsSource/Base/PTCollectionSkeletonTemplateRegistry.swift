//
//  PTCollectionSkeletonTemplateRegistry.swift
//  PooTools
//
// English: Register static skeleton descriptors without creating business cells.
// Español: Registra descriptores estáticos sin crear celdas de negocio.
// 中文：注册静态骨架描述，不创建业务 Cell。
//

import UIKit

@MainActor
public final class PTCollectionSkeletonTemplateRegistry {
    public static let shared = PTCollectionSkeletonTemplateRegistry()

    private var providers: [String: any PTSkeletonTemplateProviding.Type] = [:]

    private init() {}

    public func register(_ provider: any PTSkeletonTemplateProviding.Type, forReuseIdentifier identifier: String) {
        let key = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }
        providers[key] = provider
    }

    public func unregister(forReuseIdentifier identifier: String) {
        providers.removeValue(forKey: identifier)
    }

    public func descriptor(forReuseIdentifier identifier: String,
                           context: PTSkeletonTemplateContext) -> PTSkeletonItemDescriptor? {
        providers[identifier]?.skeletonTemplate(for: context)
    }

    public func removeAll() {
        providers.removeAll(keepingCapacity: true)
    }
}

extension PTCollectionView {
    public func registerSkeletonTemplate(_ provider: any PTSkeletonTemplateProviding.Type,
                                         forReuseIdentifier identifier: String) {
        PTCollectionSkeletonTemplateRegistry.shared.register(provider, forReuseIdentifier: identifier)
    }
}
