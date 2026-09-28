// English: Form snapshots and the MainActor collection adapter bridge semantic data to PTCollectionView.
// Español: Los snapshots y el adaptador de colección de Form traducen datos semánticos a PTCollectionView en MainActor.
// 中文：Form 快照和 MainActor 集合适配器负责把语义数据转换为 PTCollectionView。

import Foundation

public struct PTFormSupplementaryText: Sendable, Hashable {
    public var title: String?
    public var subtitle: String?

    public init(title: String? = nil, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
}

public enum PTFormSupplementaryContent: Sendable, Hashable {
    case text(PTFormSupplementaryText)
    case custom(identifier: String)
}

public struct PTFormSectionSnapshot: Sendable {
    public let section: PTFormSection
    public let fields: [PTFormField]

    public init(section: PTFormSection, fields: [PTFormField]) {
        self.section = section
        self.fields = fields
    }
}

public struct PTFormSnapshot: Sendable {
    public let revision: UInt64
    public let sections: [PTFormSectionSnapshot]

    public init(revision: UInt64 = 0, sections: [PTFormSectionSnapshot]) {
        self.revision = revision
        self.sections = sections
    }

    public var fields: [PTFormField] {
        sections.flatMap(\.fields)
    }
}

public enum PTFormDefinitionIssue: Sendable, Hashable {
    case duplicateFieldID(PTFormFieldID)
    case duplicateSectionID(String)
    case missingField(sectionID: String, fieldID: PTFormFieldID)
    case duplicatedFieldReference(fieldID: PTFormFieldID, sectionID: String)
    case unsectionedField(PTFormFieldID)
}

#if canImport(UIKit)
import UIKit
#if SWIFT_PACKAGE
import ptools
#endif

@MainActor
final class PTFormFieldBox: NSObject {
    let field: PTFormField

    init(field: PTFormField) {
        self.field = field
    }
}

@MainActor
final class PTFormSupplementaryBox: NSObject {
    let sectionID: String
    let content: PTFormSupplementaryContent

    init(sectionID: String, content: PTFormSupplementaryContent) {
        self.sectionID = sectionID
        self.content = content
    }
}

@MainActor
public final class PTFormCollectionAdapter {
    public init() {}

    public func makeSections(from snapshot: PTFormSnapshot,
                             configuration: PTFormConfiguration,
                             themeAdapter: PTFormThemeAdapter,
                             validationIssues: [PTFormFieldID: String] = [:]) -> [PTSection] {
        snapshot.sections.map { sectionSnapshot in
            let section = sectionSnapshot.section
            let resolvedConfiguration = configuration.defaultSectionConfiguration.merging(section.configuration)
            let model = PTSection(identifier: section.id,
                                   headerTitle: section.title ?? "",
                                   rows: sectionSnapshot.fields.map { field in
                let issue = validationIssues[field.id]
                let rowHash = Self.diffHash(for: field, issue: issue)
                return PTRows(title: field.title,
                              ID: PTFormFieldCell.reuseID,
                              diffId: field.id.rawValue,
                              diffHash: rowHash,
                              dataModel: PTFormFieldBox(field: field))
            })

            let hasHeader = section.header != nil || section.title != nil || section.subtitle != nil
            if hasHeader {
                let content = section.header ?? .text(.init(title: section.title,
                                                             subtitle: section.subtitle))
                model.headerID = Self.headerReuseID(for: content)
                model.headerHeight = resolvedConfiguration.headerHeight?.fallback ?? 44
                model.headerDataModel = PTFormSupplementaryBox(sectionID: section.id, content: content)
            }

            if let footer = section.footer {
                model.footerID = Self.footerReuseID(for: footer)
                model.footerHeight = resolvedConfiguration.footerHeight?.fallback ?? 36
                model.footerDataModel = PTFormSupplementaryBox(sectionID: section.id, content: footer)
            }

            let appearance = resolvedConfiguration.appearance
            switch appearance?.backgroundStyle {
            case .card, .grouped:
                model.decorationBackgroundColor = themeAdapter.fieldColor()
                model.decorationCornerRadius = appearance?.cornerRadius ?? themeAdapter.cornerRadius()
                model.decorationShadowOpacity = appearance?.shadow?.opacity ?? 0.08
            case .none:
                model.decorationBackgroundColor = .clear
            case nil:
                break
            }

            let insets = resolvedConfiguration.contentInsets ?? .zero
            model.layoutConfiguration = PTSectionLayoutConfiguration(
                contentInsets: insets.directional,
                interGroupSpacing: resolvedConfiguration.rowSpacing ?? 0,
                topSpacing: resolvedConfiguration.topSpacing,
                bottomSpacing: resolvedConfiguration.bottomSpacing,
                headerSpacing: resolvedConfiguration.headerSpacing,
                footerSpacing: resolvedConfiguration.footerSpacing,
                itemHeight: .estimated(configuration.defaultFieldConfiguration.minimumHeight ?? 44))
            return model
        }
    }

    public func locations(for snapshot: PTFormSnapshot) -> [PTFormFieldLocation] {
        snapshot.sections.enumerated().flatMap { sectionIndex, sectionSnapshot in
            sectionSnapshot.fields.enumerated().map { itemIndex, field in
                PTFormFieldLocation(fieldID: field.id,
                                    sectionID: sectionSnapshot.section.id,
                                    sectionIndex: sectionIndex,
                                    itemIndex: itemIndex)
            }
        }
    }

    static func headerReuseID(for content: PTFormSupplementaryContent) -> String {
        switch content {
        case .text: return PTFormDefaultSectionHeader.reuseID
        case .custom(let identifier): return "PTFormHeader.\(identifier)"
        }
    }

    static func footerReuseID(for content: PTFormSupplementaryContent) -> String {
        switch content {
        case .text: return PTFormDefaultSectionFooter.reuseID
        case .custom(let identifier): return "PTFormFooter.\(identifier)"
        }
    }

    private static func diffHash(for field: PTFormField, issue: String?) -> Int {
        var hasher = Hasher()
        hasher.combine(field.id)
        hasher.combine(field.value)
        hasher.combine(field.isEnabled)
        hasher.combine(field.isReadOnly)
        hasher.combine(issue)
        hasher.combine(field.configuration)
        return hasher.finalize()
    }
}

public struct PTFormFieldLocation: Sendable, Hashable {
    public let fieldID: PTFormFieldID
    public let sectionID: String
    public let sectionIndex: Int
    public let itemIndex: Int

    public init(fieldID: PTFormFieldID,
                sectionID: String,
                sectionIndex: Int,
                itemIndex: Int) {
        self.fieldID = fieldID
        self.sectionID = sectionID
        self.sectionIndex = sectionIndex
        self.itemIndex = itemIndex
    }
}

private extension PTFormInsets {
    var directional: NSDirectionalEdgeInsets {
        NSDirectionalEdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
    }
}

private extension PTFormSectionConfiguration {
    func merging(_ override: PTFormSectionConfiguration?) -> PTFormSectionConfiguration {
        guard let override else { return self }
        return .init(contentInsets: override.contentInsets ?? contentInsets,
                     rowSpacing: override.rowSpacing ?? rowSpacing,
                     topSpacing: override.topSpacing ?? topSpacing,
                     bottomSpacing: override.bottomSpacing ?? bottomSpacing,
                     headerSpacing: override.headerSpacing ?? headerSpacing,
                     footerSpacing: override.footerSpacing ?? footerSpacing,
                     headerHeight: override.headerHeight ?? headerHeight,
                     footerHeight: override.footerHeight ?? footerHeight,
                     appearance: override.appearance ?? appearance)
    }
}
#endif
