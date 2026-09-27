// English: Small main-actor compatibility model used by the legacy data source wrapper.
// Español: Pequeño modelo de compatibilidad en MainActor usado por el adaptador antiguo.
// 中文：旧数据源适配器使用的 MainActor 兼容模型。

import Foundation

@MainActor
public final class PTSegmentControlBaseModel: NSObject {
    public var categoryName: String = ""
    public var subTitle: String = ""
    public var imageURL: String = ""

    public override init() {
        super.init()
    }
}
