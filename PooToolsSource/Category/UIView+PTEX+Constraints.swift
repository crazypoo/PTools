//
//  UIView+PTEX+Constraints.swift
//  PooTools
//
//  English: Safe UIView constraint helpers with common-ancestor validation.
//  Español: Ayudantes seguros de restricciones UIView con validación del ancestro común.
//  中文：带最近公共祖先校验的 UIView 安全约束辅助方法。
//

#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit
import SnapKit

//MARK: 視頻剪輯
public extension UIView {
    var imageWithView: UIImage? {
        guard !bounds.isEmpty else { return nil }
        let renderer = UIGraphicsImageRenderer(bounds: self.bounds)
        return renderer.image { rendererContext in
            self.layer.render(in: rendererContext.cgContext)
        }
    }
    
    func edgesConstraint(subView: UIView, constant: CGFloat = 0) {
        self.leadingConstraint(subView: subView, constant: constant)
        self.trailingConstraint(subView: subView, constant: constant)
        self.topConstraint(subView: subView, constant: constant)
        self.bottomConstraint(subView: subView, constant: constant)
    }
    
    func sizeConstraint(subView: UIView, constant: CGFloat = 0) {
        self.widthConstraint(subView: subView, constant: constant)
        self.heightConstraint(subView: subView, constant: constant)
    }
    
    func sizeConstraint(constant: CGFloat = 0) {
        self.widthConstraint(constant: constant)
        self.heightConstraint(constant: constant)
    }

    private func pt_commonAncestor(of first: UIView, and second: UIView?) -> UIView? {
        guard let second else { return first }
        var candidate: UIView? = first
        while let current = candidate {
            if current === second || second.isDescendant(of: current) {
                return current
            }
            candidate = current.superview
        }
        return nil
    }

    private enum PTConstraintAttribute {
        case leading
        case trailing
        case top
        case bottom
        case centerX
        case centerY
        case width
        case height

        // English: Map the compatibility API to one SnapKit attribute while preserving its public signatures.
        // Español: Mapea la API de compatibilidad a un atributo de SnapKit y conserva sus firmas públicas.
        // 中文：将兼容 API 映射到单个 SnapKit 属性，同时保留公开方法签名。
        func maker(from maker: ConstraintMaker) -> ConstraintMakerExtendable {
            switch self {
            case .leading: return maker.leading
            case .trailing: return maker.trailing
            case .top: return maker.top
            case .bottom: return maker.bottom
            case .centerX: return maker.centerX
            case .centerY: return maker.centerY
            case .width: return maker.width
            case .height: return maker.height
            }
        }

        @MainActor func item(from view: UIView) -> ConstraintItem {
            switch self {
            case .leading: return view.snp.leading
            case .trailing: return view.snp.trailing
            case .top: return view.snp.top
            case .bottom: return view.snp.bottom
            case .centerX: return view.snp.centerX
            case .centerY: return view.snp.centerY
            case .width: return view.snp.width
            case .height: return view.snp.height
            }
        }
    }

    private func pt_relation(_ lhs: ConstraintMakerExtendable,
                             rhs: ConstraintRelatableTarget,
                             relation: NSLayoutConstraint.Relation) -> ConstraintMakerEditable {
        switch relation {
        case .lessThanOrEqual:
            return lhs.lessThanOrEqualTo(rhs)
        case .greaterThanOrEqual:
            return lhs.greaterThanOrEqualTo(rhs)
        case .equal:
            return lhs.equalTo(rhs)
        @unknown default:
            return lhs.equalTo(rhs)
        }
    }

    private func pt_makeConstraint(first: UIView,
                                   second: UIView?,
                                   attribute: PTConstraintAttribute,
                                   constant: CGFloat,
                                   multiplier: CGFloat,
                                   relatedBy: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
        let prepared = first.snp.prepareConstraints { make in
            let lhs = attribute.maker(from: make)
            if let second {
                let rhs: ConstraintRelatableTarget = attribute.item(from: second)
                pt_relation(lhs, rhs: rhs, relation: relatedBy)
                    .multipliedBy(multiplier)
                    .offset(constant)
            } else {
                let rhs: ConstraintRelatableTarget = constant
                pt_relation(lhs, rhs: rhs, relation: relatedBy)
            }
        }

        guard let snapConstraint = prepared.first,
              let layoutConstraint = snapConstraint.layoutConstraints.first else {
            preconditionFailure("SnapKit did not create the compatibility constraint")
        }

        // English: Do not activate constraints between unrelated view trees; UIKit would raise an exception.
        // Español: No activa restricciones entre árboles de vistas no relacionados; UIKit lanzaría una excepción.
        // 中文：不激活不属于同一视图树的约束，否则 UIKit 会直接抛出异常。
        if pt_commonAncestor(of: first, and: second) != nil {
            snapConstraint.activate()
        }
        return layoutConstraint
    }
    
    @discardableResult
    func leadingConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        pt_makeConstraint(first: self, second: subView, attribute: .leading, constant: constant, multiplier: multiplier, relatedBy: relatedBy)
    }
    
    @discardableResult
    func trailingConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        pt_makeConstraint(first: self, second: subView, attribute: .trailing, constant: constant, multiplier: multiplier, relatedBy: relatedBy)
    }
    
    @discardableResult
    func topConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        pt_makeConstraint(first: self, second: subView, attribute: .top, constant: constant, multiplier: multiplier, relatedBy: relatedBy)
    }
    
    @discardableResult
    func bottomConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        pt_makeConstraint(first: self, second: subView, attribute: .bottom, constant: constant, multiplier: multiplier, relatedBy: relatedBy)
    }
    
    @discardableResult
    func centerXConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        pt_makeConstraint(first: self, second: subView, attribute: .centerX, constant: constant, multiplier: multiplier, relatedBy: relatedBy)
    }
    
    @discardableResult
    func centerYConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        pt_makeConstraint(first: self, second: subView, attribute: .centerY, constant: constant, multiplier: multiplier, relatedBy: relatedBy)
    }
    
    @discardableResult
    func leadingConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        pt_makeConstraint(first: item, second: subView, attribute: .leading, constant: constant, multiplier: multiplier, relatedBy: relatedBy)
    }
    
    @discardableResult
    func trailingConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        pt_makeConstraint(first: item, second: subView, attribute: .trailing, constant: constant, multiplier: multiplier, relatedBy: relatedBy)
    }
    
    @discardableResult
    func topConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        pt_makeConstraint(first: item, second: subView, attribute: .top, constant: constant, multiplier: multiplier, relatedBy: relatedBy)
    }
    
    @discardableResult
    func bottomConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        pt_makeConstraint(first: item, second: subView, attribute: .bottom, constant: constant, multiplier: multiplier, relatedBy: relatedBy)
    }
    
    @discardableResult
    func centerXConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        pt_makeConstraint(first: item, second: subView, attribute: .centerX, constant: constant, multiplier: multiplier, relatedBy: relatedBy)
    }
    
    @discardableResult
    func centerYConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        pt_makeConstraint(first: item, second: subView, attribute: .centerY, constant: constant, multiplier: multiplier, relatedBy: relatedBy)
    }
    
    @discardableResult
    func widthConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        pt_makeConstraint(first: item, second: subView, attribute: .width, constant: constant, multiplier: multiplier, relatedBy: relatedBy)
    }
    
    @discardableResult
    func heightConstraint(item: UIView, subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        pt_makeConstraint(first: item, second: subView, attribute: .height, constant: constant, multiplier: multiplier, relatedBy: relatedBy)
    }
    
    @discardableResult
    func widthConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        pt_makeConstraint(first: self, second: subView, attribute: .width, constant: constant, multiplier: multiplier, relatedBy: relatedBy)
    }
    
    @discardableResult
    func heightConstraint(subView: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        pt_makeConstraint(first: self, second: subView, attribute: .height, constant: constant, multiplier: multiplier, relatedBy: relatedBy)
    }
    
    @discardableResult
    func widthConstraint(constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        pt_makeConstraint(first: self, second: nil, attribute: .width, constant: constant, multiplier: multiplier, relatedBy: relatedBy)
    }
    
    @discardableResult
    func heightConstraint(constant: CGFloat = 0, multiplier: CGFloat = 1, relatedBy: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        pt_makeConstraint(first: self, second: nil, attribute: .height, constant: constant, multiplier: multiplier, relatedBy: relatedBy)
    }
}
#endif
