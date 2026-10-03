//
//  PTCollectionDataCoordinator.swift
//  PooTools
//
// English: Keep data-source registration and Diffable configuration away from the public facade.
// Español: Mantiene el registro del data source y la configuración Diffable fuera de la fachada pública.
// 中文：将数据源注册和 Diffable 配置从公开门面中拆出。
//

import UIKit

// English: Keep Diffable identity validation and snapshot lookup in one small coordinator.
// Español: Mantiene la validación de identidades Diffable y la búsqueda del snapshot en un coordinador pequeño.
// 中文：将 Diffable 身份校验和快照查找集中到轻量协调器中。
@MainActor
public final class PTCollectionDataCoordinator {
    public init() {}

    public func validationError(for sections: [PTSection],
                                against snapshot: PTSnapshot? = nil) -> PTCollectionViewUpdateError? {
        var sectionIdentifiers = Set(snapshot?.sectionIdentifiers.map(\.identifier) ?? [])
        var rowIdentifiers = Set(snapshot?.itemIdentifiers.map(\.diffId) ?? [])

        for section in sections {
            guard !section.identifier.isEmpty else { return .emptySectionIdentifier }
            guard sectionIdentifiers.insert(section.identifier).inserted else {
                return .duplicateSectionIdentifier(section.identifier)
            }
            for row in section.rows ?? [] {
                guard !row.diffId.isEmpty else { return .emptyRowIdentifier }
                guard rowIdentifiers.insert(row.diffId).inserted else {
                    return .duplicateRowIdentifier(row.diffId)
                }
            }
        }
        return nil
    }

    public func validationError(for rows: [PTRows],
                                against snapshot: PTSnapshot) -> PTCollectionViewUpdateError? {
        var rowIdentifiers = Set(snapshot.itemIdentifiers.map(\.diffId))
        for row in rows {
            guard !row.diffId.isEmpty else { return .emptyRowIdentifier }
            guard rowIdentifiers.insert(row.diffId).inserted else {
                return .duplicateRowIdentifier(row.diffId)
            }
        }
        return nil
    }

    public func section(at index: Int, in snapshot: PTSnapshot) -> PTSection? {
        guard snapshot.sectionIdentifiers.indices.contains(index) else { return nil }
        return snapshot.sectionIdentifiers[index]
    }

    public func row(at indexPath: IndexPath, in snapshot: PTSnapshot) -> PTRows? {
        guard let section = section(at: indexPath.section, in: snapshot) else { return nil }
        let rows = snapshot.itemIdentifiers(inSection: section)
        guard rows.indices.contains(indexPath.item) else { return nil }
        return rows[indexPath.item]
    }
}

extension PTCollectionView {
    
    func setupDiffableDataSource() {
        // 1. 配置 Cell
        diffableDataSource = PTDataSource(collectionView: collectionView) { [weak self] (collectionView, indexPath, rowModel) -> UICollectionViewCell? in
            guard let self = self else { return nil }
            
            let snapshot = self.diffableDataSource.snapshot()
            
            guard indexPath.section < snapshot.sectionIdentifiers.count else {
                return collectionView.dequeueReusableCell(withReuseIdentifier: "CELL", for: indexPath)
            }

            let sectionModel = snapshot.sectionIdentifiers[indexPath.section]
            
            let cell: UICollectionViewCell
            if let configuredCell = self.cellInCollection?(collectionView, sectionModel, indexPath) {
                cell = configuredCell
            } else if let cellClass = rowModel.cellClass,
                      !rowModel.reuseID.isEmpty {
                self.registerCellIfNeeded(cellClass, reuseID: rowModel.reuseID)
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: rowModel.reuseID, for: indexPath)

                if let fusionCell = cell as? PTFusionCellProtocol,
                   let fusionModel = rowModel.dataModel as? PTFusionCellModel {
                    fusionCell.cellModel = fusionModel
                } else if let bindableCell = cell as? PTAnyCellBindable,
                          let dataModel = rowModel.dataModel {
                    bindableCell.pt_bindAny(dataModel)
                }
            } else {
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CELL", for: indexPath)
            }

            self.configureSwipeCell(cell,
                                    collectionView: collectionView,
                                    sectionModel: sectionModel,
                                    indexPath: indexPath)
            return cell
        }
        
        // 2. 配置 Header 和 Footer
        diffableDataSource.supplementaryViewProvider = { [weak self] (collectionView, kind, indexPath) -> UICollectionReusableView? in
            guard let self = self else { return nil }
            
            let snapshot = self.diffableDataSource.snapshot()
            
            guard indexPath.section < snapshot.sectionIdentifiers.count else {
                return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NSStringFromClass(PTBaseCollectionReusableView.self), for: indexPath)
            }
            let sectionModel = snapshot.sectionIdentifiers[indexPath.section]
            
            if kind == UICollectionView.elementKindSectionHeader,
               !(sectionModel.headerReuseID ?? "").stringIsEmpty(),
               let headerHeight = sectionModel.headerHeight,
               headerHeight != CGFloat.leastNormalMagnitude,
               let headerReusableView = headerInCollection?(kind,collectionView,sectionModel,indexPath) {
                return headerReusableView
            } else if kind == UICollectionView.elementKindSectionFooter,
                      !(sectionModel.footerReuseID ?? "").stringIsEmpty(),
                      let footerHeight = sectionModel.footerHeight,
                      footerHeight != CGFloat.leastNormalMagnitude,
                      let footerReusableView = footerInCollection?(kind,collectionView,sectionModel,indexPath) {
                return footerReusableView
            }
            
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NSStringFromClass(PTBaseCollectionReusableView.self), for: indexPath)
        }
        
        let initialSnapshot = PTSnapshot()
        diffableDataSource.apply(initialSnapshot, animatingDifferences: false)
    }

    private func configureSwipeCell(_ cell: UICollectionViewCell,
                                    collectionView: UICollectionView,
                                    sectionModel: PTSection,
                                    indexPath: IndexPath) {
        guard let swipeCell = cell as? PTBaseSwipeCell else { return }

        let canSwipe = indexPathSwipe?(sectionModel, indexPath) ?? false
        swipeCell.cellCanSwipe = canSwipe
        swipeCell.resetSwipeActions()
        guard canSwipe else { return }

        if let actions = swipeRightHandler?(collectionView, sectionModel, indexPath) {
            swipeCell.configureRightActions(actions)
        }
        if let actions = swipeLeftHandler?(collectionView, sectionModel, indexPath) {
            swipeCell.configureLeftActions(actions)
        }
    }
}


//MARK: Cell 相关
extension PTCollectionView  {
    func autoRegisterIfNeeded(sections: [PTSection]) {
        for section in sections {
            if let headerClass = section.headerClass as? PTSupplementaryRegisterable.Type {
                registerSupplementaryIfNeeded(headerClass, reuseID: section.headerReuseID)
            }
            if let footerClass = section.footerClass as? PTSupplementaryRegisterable.Type {
                registerSupplementaryIfNeeded(footerClass, reuseID: section.footerReuseID)
            }
            section.rows?.forEach { row in
                if let cellClass = row.cellClass, !row.reuseID.isEmpty {
                    registerCellIfNeeded(cellClass, reuseID: row.reuseID)
                }
            }
        }
    }
    
    private func registerCellIfNeeded(_ cellClass: UICollectionViewCell.Type, reuseID: String) {
        guard !reuseID.isEmpty else { return }
        guard !registeredCells.contains(reuseID) else { return }
        collectionView.register(cellClass, forCellWithReuseIdentifier: reuseID)
        registeredCells.insert(reuseID)
    }
    
    // English: Register the section's effective identifier so custom header and footer IDs can be dequeued safely.
    // Español: Registra el identificador efectivo de cada sección para poder reutilizar de forma segura headers y footers personalizados.
    // 中文：使用 Section 的实际复用标识注册视图，确保自定义 header/footer ID 能够安全出队。
    private func registerSupplementaryIfNeeded(_ viewClass: PTSupplementaryRegisterable.Type,
                                               reuseID: String? = nil) {
        let resolvedReuseID = (reuseID?.isEmpty == false ? reuseID : nil) ?? viewClass.reuseID
        let registrationKey = "\(viewClass.kind)|\(resolvedReuseID)"
        guard !resolvedReuseID.isEmpty, !registeredSupplementary.contains(registrationKey),
              let reusableViewClass = viewClass as? UICollectionReusableView.Type else { return }
        collectionView.register(reusableViewClass,
                                forSupplementaryViewOfKind: viewClass.kind,
                                withReuseIdentifier: resolvedReuseID)
        registeredSupplementary.insert(registrationKey)
    }
}
