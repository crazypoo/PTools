// English: Configuration contains presentation choices only; manifest semantics stay in Core.
// Español: La configuración contiene solo decisiones de presentación; la semántica vive en Core.
// 中文：配置只负责展示选项，Manifest 语义统一由 Core 负责。

#if canImport(UIKit)
import UIKit

@MainActor
public struct PTAcknowledgementsConfiguration {
    public enum Style: Sendable {
        case plain
        case grouped
        case insetGrouped
        case cards

        var tableStyle: UITableView.Style {
            switch self {
            case .plain, .cards: return .plain
            case .grouped: return .grouped
            case .insetGrouped: return .insetGrouped
            }
        }
    }

    public enum Grouping: Sendable {
        case name
        case sourceManager
        case licenseType
        case none
    }

    public var title: String
    public var style: Style
    public var grouping: Grouping
    public var showsSearchBar: Bool
    public var showsVersions: Bool
    public var showsSourceBadges: Bool
    public var header: String?
    public var footer: String?

    public init(
        title: String = "开源许可",
        style: Style = .insetGrouped,
        grouping: Grouping = .name,
        showsSearchBar: Bool = true,
        showsVersions: Bool = true,
        showsSourceBadges: Bool = true,
        header: String? = nil,
        footer: String? = nil
    ) {
        self.title = title
        self.style = style
        self.grouping = grouping
        self.showsSearchBar = showsSearchBar
        self.showsVersions = showsVersions
        self.showsSourceBadges = showsSourceBadges
        self.header = header
        self.footer = footer
    }
}
#endif
