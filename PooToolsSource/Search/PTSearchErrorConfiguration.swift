//
//  PTSearchErrorConfiguration.swift
//  PooTools
//
// English: Error presentation is typed while the underlying provider error remains available to the hook.
// Español: La presentación del error está tipada y el error original sigue disponible para el hook.
// 中文：错误展示使用类型化配置，同时通过 hook 保留原始错误。
//

import UIKit

#if SWIFT_PACKAGE
import ptools
#endif

public enum PTSearchErrorKind: Sendable, Equatable {
    case network
    case offline
    case server
    case authorization
    case unknown
}

@MainActor
public struct PTSearchErrorConfiguration {
    public var kind: PTSearchErrorKind
    public var image: UIImage?
    public var title: String
    public var message: String
    public var retryTitle: String
    public var retryAction: (@MainActor () -> Void)?

    public init(kind: PTSearchErrorKind = .unknown,
                image: UIImage? = UIImage(systemName: "exclamationmark.triangle"),
                title: String = "Search Failed".localized(),
                message: String = "Please try again".localized(),
                retryTitle: String = "Retry".localized(),
                retryAction: (@MainActor () -> Void)? = nil) {
        self.kind = kind
        self.image = image
        self.title = title
        self.message = message
        self.retryTitle = retryTitle
        self.retryAction = retryAction
    }
}
