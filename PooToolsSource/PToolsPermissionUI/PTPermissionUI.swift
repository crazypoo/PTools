//
//  PTPermissionUI.swift
//  PToolsPermissionUI
//
//  Optional UIKit bridge for permission settings and presentation state.
//  Puente UIKit opcional para los ajustes y el estado de presentación de permisos.
//  可选的 UIKit 权限设置页桥接与展示状态。
//

import Foundation
import PToolsPermissionCore

public enum PTPermissionUIState: Equatable, Sendable {
    case loading
    case status(PTPermissionStatus)
    case failure(String)
}

public struct PTPermissionUIItem: Equatable, Identifiable, Sendable {
    public let id: String
    public let kind: PTPermissionKind
    public let title: String
    public let detail: String
    public let state: PTPermissionUIState

    public init(id: String? = nil,
                kind: PTPermissionKind,
                title: String? = nil,
                detail: String = "",
                state: PTPermissionUIState = .loading) {
        self.id = id ?? kind.name
        self.kind = kind
        self.title = title ?? kind.name
        self.detail = detail
        self.state = state
    }
}

#if canImport(UIKit)
import UIKit
import PToolsUIFoundation

// English: UIKit owns settings presentation; the permission core remains usable in non-UI processes and tests.
// Español: UIKit posee la presentación de ajustes; el núcleo de permisos sigue siendo utilizable en procesos y pruebas sin UI.
// 中文：设置页展示由 UIKit 负责，权限 Core 仍可用于无 UI 进程和测试。
@MainActor
public enum PTPermissionUISettingsBridge {
    public static func installDefaultSettingsHandler() {
        PTPermissionSettingsRouter.install { url in
            guard let url else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    public static func prepareContainer(_ view: ConstraintView) {
        view.backgroundColor = .clear
        view.isAccessibilityElement = false
    }
}
#else
// English: Keep the optional UI module importable by host-side tooling without inventing a non-UIKit presentation path.
// Español: Mantiene importable el módulo UI opcional en herramientas del host sin inventar una ruta de presentación no UIKit.
// 中文：让宿主工具可以导入可选 UI 模块，但不伪造非 UIKit 展示路径。
@MainActor
public enum PTPermissionUISettingsBridge {
    public static func installDefaultSettingsHandler() {}
}
#endif
