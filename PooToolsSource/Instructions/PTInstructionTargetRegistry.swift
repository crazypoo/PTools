// English: Weak target registration keeps instruction tours independent from view-controller ownership.
// Español: El registro débil mantiene los tutoriales independientes de la propiedad de los controladores.
// 中文：弱引用目标注册让引导流程不依赖控制器的生命周期管理。

import UIKit
#if SWIFT_PACKAGE
import PToolsOverlay
#endif

@MainActor
public final class PTInstructionTargetRegistry {
    public static let shared = PTInstructionTargetRegistry()

    private init() {}

    public func register(_ id: PTInstructionID,
                         view: UIView,
                         businessID: AnyHashable? = nil) {
        PTAnchorRegistry.shared.register(PTAnchorID(id.rawValue), view: view, businessID: businessID)
    }

    public func unregister(_ id: PTInstructionID) {
        PTAnchorRegistry.shared.unregister(PTAnchorID(id.rawValue))
    }

    public func target(_ id: PTInstructionID) -> PTInstructionTarget {
        .registered(id)
    }
}

@MainActor
public extension UIView {
    func pt_registerInstructionTarget(_ id: PTInstructionID,
                                      businessID: AnyHashable? = nil) {
        PTInstructionTargetRegistry.shared.register(id, view: self, businessID: businessID)
    }

    func pt_unregisterInstructionTarget(_ id: PTInstructionID) {
        PTInstructionTargetRegistry.shared.unregister(id)
    }
}
