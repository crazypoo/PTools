//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension HierarchyInspectorViewModel {
    final class SnapshotViewModel: NSObject, HierarchyInspectorSectionViewModelProtocol {
        let shouldAnimateKeyboard: Bool = true

        private struct Details: HierarchyInspectorReferenceSummaryCellViewModelProtocol {
            let title: String?
            var isEnabled: Bool
            let subtitle: String?
            let image: UIImage?
            let depth: Int
            let element: ViewHierarchyElementReference

            init(with element: ViewHierarchyElementReference, isEnabled: Bool) {
                title = element.displayName
                self.isEnabled = isEnabled
                subtitle = element.shortElementDescription
                depth = element.depth
                self.element = element
                image = element.cachedIconImage?
                    .resized(Inspector.sharedInstance.appearance.actionIconSize)
            }
        }

        private struct SearchQueryItem: ExpirableProtocol {
            let query: String
            let expirationDate: Date = .init().addingTimeInterval(5)
            let results: [Details]
        }

        var searchQuery: String? {
            didSet {
                if oldValue != searchQuery {
                    loadData()
                }
            }
        }

        private var queryStore: [String: SearchQueryItem] = [:]

        let snapshot: ViewHierarchySnapshot

        private var currentSearchResults = [Details]()

        init(snapshot: ViewHierarchySnapshot) {
            self.snapshot = snapshot
        }

        var isEmpty: Bool { currentSearchResults.isEmpty }

        let numberOfSections = 1

        func selectRow(at indexPath: IndexPath) -> InspectorCommand? {
            guard (0 ..< currentSearchResults.count).contains(indexPath.row) else {
                return nil
            }
            let element = currentSearchResults[indexPath.row].element

            return .inspect(element)
        }

        func isRowEnabled(at indexPath: IndexPath) -> Bool {
            currentSearchResults[indexPath.row].isEnabled
        }

        func numberOfRows(in section: Int) -> Int {
            currentSearchResults.count
        }

        func titleForHeader(in section: Int) -> String? {
            Texts.allResults(count: currentSearchResults.count, in: snapshot.root.displayName)
        }

        func cellViewModelForRow(at indexPath: IndexPath) -> HierarchyInspectorCellViewModel {
            .element(currentSearchResults[indexPath.row])
        }

        @objc func loadData() {
            currentSearchResults = {
                guard let key = searchQuery else {
                    return []
                }

                if let searchQueryItem = queryStore[key], searchQueryItem.isValid {
                    return searchQueryItem.results
                }

                if key == Inspector.sharedInstance.configuration.showAllViewSearchQuery {
                    let results = snapshot.root.viewHierarchy.map {
                        Details(with: $0, isEnabled: true)
                    }

                    let queryItem = SearchQueryItem(
                        query: key,
                        results: results
                    )

                    queryStore[key] = queryItem

                    return queryItem.results
                }

                let results: [Details] = snapshot.root.viewHierarchy.compactMap { element in
                    guard (element.displayName + element.className).localizedCaseInsensitiveContains(key) else { return nil }
                    return Details(with: element, isEnabled: true)
                }

                let queryItem = SearchQueryItem(
                    query: key,
                    results: results
                )

                queryStore[key] = queryItem

                return queryItem.results
            }()
        }
    }
}
