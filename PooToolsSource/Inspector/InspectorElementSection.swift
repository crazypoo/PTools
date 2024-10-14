//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

/// An array of element inspector sections.
public typealias InspectorElementSections = [InspectorElementSection]

/// An object that represents an inspector section.
public struct InspectorElementSection {
    public var title: String?
    public private(set) var dataSources: [InspectorElementSectionDataSource]

    public init(title: String? = nil, rows: [InspectorElementSectionDataSource] = []) {
        self.title = title
        dataSources = rows
    }

    public init(title: String? = nil, rows: InspectorElementSectionDataSource...) {
        self.title = title
        dataSources = rows
    }

    public init(title: String? = nil, rows: [InspectorElementSectionDataSource?]) {
        self.title = title
        dataSources = rows.compactMap { $0 }
    }

    public init(title: String? = nil, rows: InspectorElementSectionDataSource?...) {
        self.title = title
        dataSources = rows.compactMap { $0 }
    }

    public mutating func append(_ dataSource: InspectorElementSectionDataSource?) {
        guard let dataSource = dataSource else {
            return
        }

        dataSources.append(dataSource)
    }
}

// MARK: - Array Extensions

public extension InspectorElementSections {
    static let empty = InspectorElementSections()

    init(with dataSources: InspectorElementSectionDataSource?...) {
        self.init(dataSources: dataSources)
    }

    init(dataSources: [InspectorElementSectionDataSource?]) {
        let rows = dataSources.compactMap { $0 }

        self = [InspectorElementSection(rows: rows)]
    }
}
