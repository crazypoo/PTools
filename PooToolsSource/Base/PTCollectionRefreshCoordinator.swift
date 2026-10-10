//
//  PTCollectionRefreshCoordinator.swift
//  PooTools
//
// English: Own refresh-control construction so PTCollectionView stays focused on the public list facade.
// Español: Centraliza la construcción de los controles de refresco para que PTCollectionView conserve una fachada pequeña.
// 中文：集中管理刷新控件的创建，让 PTCollectionView 保持为轻量公开列表门面。
//

import UIKit

@MainActor
final class PTCollectionRefreshCoordinator {
    func configure(_ collectionView: PTBaseCollectionView,
                   config: PTCollectionViewConfig,
                   onHeader: @escaping PTActionTask,
                   onFooter: @escaping PTActionTask) {
        // English: The refresh facade is a value wrapper, so mutate it through a local variable.
        // Español: La fachada de refresco es un envoltorio de valor; por eso se muta mediante una variable local.
        // 中文：刷新 facade 是值类型包装器，因此必须通过可变局部变量修改。
        var targetCollectionView = collectionView
        if config.topRefresh {
            targetCollectionView.pt.header = PTRefreshHeader {
                onHeader()
            }
        } else {
            targetCollectionView.pt.header = nil
        }

        guard config.footerRefresh else {
            targetCollectionView.pt.autoFooter = nil
            return
        }
        let footer = PTRefreshAutoFooter {
            onFooter()
        }
        footer.setTitle(config.footerRefreshIdle, for: .idle)
        footer.setTitle(config.footerRefreshPulling, for: .pulling)
        footer.setTitle(config.footerRefreshRefreshing, for: .refreshing)
        footer.setTitle(config.footerRefreshWillRefresh, for: .willRefresh)
        footer.setTitle(config.footerRefreshNoMoreData, for: .noMoreData)
        footer.setFont(config.footerRefreshTextFont)
        footer.setTextColor(config.footerRefreshTextColor)
        footer.triggerAutomaticallyRefreshPercent = config.triggerAutomaticallyRefreshPercent
        footer.setAutomaticallyHidden(config.isAutomaticallyRefresh)
        footer.ignoredContentInsetBottom = config.ignoredScrollViewContentInsetBottom
        targetCollectionView.pt.autoFooter = footer
    }
}
