//
//  PTCollectionPrefetchCoordinator.swift
//  PooTools
//
// English: Keep PhotoKit prefetch callbacks separate from collection interactions.
// Español: Mantiene las devoluciones de precarga de PhotoKit separadas de las interacciones de colección.
// 中文：将 PhotoKit 预取回调与列表交互逻辑分离。
//

import UIKit
import Photos

// English: Centralize photo prefetching so duplicate batches and stale cancellations do not reach PhotoKit.
// Español: Centraliza la precarga de fotos para que los lotes duplicados y las cancelaciones obsoletas no lleguen a PhotoKit.
// 中文：集中管理图片预取，避免重复批次和过期取消请求直接进入 PhotoKit。
@MainActor
final class PTCollectionPhotoPrefetchCoordinator {
    private struct CachedAsset {
        let asset: PHAsset
        var requestCount: Int
    }

    private let imageManager = PHCachingImageManager()
    private var cachedAssets: [String: CachedAsset] = [:]
    private var cachedTargetSize: CGSize = .zero

    func prefetch(assets: [PHAsset], targetSize: CGSize) {
        let normalizedSize = CGSize(width: max(targetSize.width, 1),
                                    height: max(targetSize.height, 1))
        if cachedTargetSize != .zero, cachedTargetSize != normalizedSize {
            removeAll()
        }
        cachedTargetSize = normalizedSize

        let uniqueAssets = assets.reduce(into: [PHAsset]()) { result, asset in
            let identifier = asset.localIdentifier
            guard !identifier.isEmpty else { return }
            if var cachedAsset = cachedAssets[identifier] {
                cachedAsset.requestCount += 1
                cachedAssets[identifier] = cachedAsset
            } else {
                cachedAssets[identifier] = CachedAsset(asset: asset, requestCount: 1)
                result.append(asset)
            }
        }
        guard !uniqueAssets.isEmpty else { return }
        imageManager.startCachingImages(for: uniqueAssets,
                                        targetSize: normalizedSize,
                                        contentMode: .aspectFill,
                                        options: nil)
    }

    func cancel(assets: [PHAsset], targetSize: CGSize) {
        let normalizedSize = CGSize(width: max(targetSize.width, 1),
                                    height: max(targetSize.height, 1))
        guard cachedTargetSize == .zero || cachedTargetSize == normalizedSize else {
            removeAll()
            return
        }
        var cancelCounts: [String: Int] = [:]
        for asset in assets {
            let identifier = asset.localIdentifier
            guard !identifier.isEmpty else { continue }
            cancelCounts[identifier, default: 0] += 1
        }
        let cached = cancelCounts.compactMap { identifier, cancelCount -> PHAsset? in
            guard var cachedAsset = cachedAssets[identifier] else { return nil }
            cachedAsset.requestCount -= cancelCount
            if cachedAsset.requestCount <= 0 {
                cachedAssets.removeValue(forKey: identifier)
                return cachedAsset.asset
            }
            cachedAssets[identifier] = cachedAsset
            return nil
        }
        guard !cached.isEmpty else { return }
        imageManager.stopCachingImages(for: cached,
                                       targetSize: normalizedSize,
                                       contentMode: .aspectFill,
                                       options: nil)
    }

    func removeAll() {
        guard !cachedAssets.isEmpty else {
            cachedTargetSize = .zero
            return
        }
        let assets = cachedAssets.values.map(\.asset)
        let targetSize = cachedTargetSize
        cachedAssets.removeAll(keepingCapacity: false)
        cachedTargetSize = .zero
        imageManager.stopCachingImages(for: assets,
                                       targetSize: targetSize,
                                       contentMode: .aspectFill,
                                       options: nil)
    }
}

//MARK: For Photos
extension PTCollectionView:UICollectionViewDataSourcePrefetching {
    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let assets = photoAssets(for: indexPaths)
        if !assets.isEmpty {
            photoPrefetchCoordinator.prefetch(assets: assets,
                                              targetSize: viewConfig.previewImageSize)
        }
    }
        
    public func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let assets = photoAssets(for: indexPaths)
        if !assets.isEmpty {
            photoPrefetchCoordinator.cancel(assets: assets,
                                             targetSize: viewConfig.previewImageSize)
        }
    }
}

private extension PTCollectionView {
    func photoAssets(for indexPaths: [IndexPath]) -> [PHAsset] {
        guard let config = viewConfig,
              config.viewForPhoto,
              !photoAssets.isEmpty else { return [] }

        let dataSource = diffableDataSource
        let snapshot = dataSource?.snapshot()
        var identifiers = Set<String>()

        return indexPaths.compactMap { indexPath in
            let fallbackIndex = indexPath.item
            let snapshotIndex: Int?
            if let dataSource,
               let row = dataSource.itemIdentifier(for: indexPath) {
                snapshotIndex = snapshot?.indexOfItem(row)
            } else {
                snapshotIndex = nil
            }

            let assetIndex = snapshotIndex ?? fallbackIndex
            guard photoAssets.indices.contains(assetIndex) else { return nil }

            let asset = photoAssets[assetIndex]
            guard identifiers.insert(asset.localIdentifier).inserted else { return nil }
            return asset
        }
    }
}
