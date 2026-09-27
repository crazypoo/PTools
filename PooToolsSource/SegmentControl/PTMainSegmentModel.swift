// English: Compatibility value model for the native segmented renderer.
// Español: Modelo de compatibilidad para el renderizador segmentado nativo.
// 中文：原生分段渲染器使用的兼容模型。

import UIKit

public enum PTSegmentControlModelType {
    case OnlyTitle(type: PTSegmentControlModelSubType)
    case ImageTitle(type: PTSegmentControlModelSubType)
    case OnlyImage

    public enum PTSegmentControlModelSubType {
        case Normal
        case OnlyTitle
    }
}

/// English: Legacy-shaped model retained as a migration wrapper, not a third-party subclass.
/// Español: Modelo con forma heredada conservado como adaptador de migración, no como subclase de terceros.
/// 中文：保留旧字段形态作为迁移适配器，不再继承第三方模型。
@MainActor
@available(*, deprecated, message: "Use PTSegmentItem and PTSegmentStyle for new code.")
public class PTMainSegmentModel: NSObject {
    open var title: String = ""
    open var subTitle: String = ""
    open var titleNormalColor: UIColor = .black
    open var titleCurrentColor: UIColor = .black
    open var titleSelectedColor: UIColor = .white
    open var titleNormalFont: UIFont = .systemFont(ofSize: 16)
    open var titleSelectedFont: UIFont = .boldSystemFont(ofSize: 16)
    open var subTitleNormalColor: UIColor = .black
    open var subTitleCurrentColor: UIColor = .black
    open var subTitleSelectedColor: UIColor = .white
    open var subTitleCurrentBGColor: UIColor = .clear
    open var subTitleNormalBGColor: UIColor = .clear
    open var subTitleSelectedBGColor: UIColor = .clear
    open var itemWidthIncrement: CGFloat = 0
    open var onlyShowTitle: PTSegmentControlModelType? = .OnlyTitle(type: .Normal)
    open var subTitleNormalFont: UIFont = .systemFont(ofSize: 12)
    open var subTitleSelectedFont: UIFont = .boldSystemFont(ofSize: 12)
    open var modelIndex: Int = 0
    open var index: Int = 0
    open var itemSpace: CGFloat = 0
    open var itemWidth: CGFloat = 0
    open var imageURL: String = ""
    open var isSelected = false

    public override init() {
        super.init()
    }
}
