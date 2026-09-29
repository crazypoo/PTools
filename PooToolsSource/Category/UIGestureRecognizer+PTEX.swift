//
//  UIGestureRecognizer+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 5/5/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import ObjectiveC

public typealias TapedBlock = (_ sender: AnyObject) -> Void

// MARK: - PTProtocolCompatible

extension UIGestureRecognizer: PTProtocolCompatible {}

// MARK: - Action Token

@MainActor
public final class PTGestureActionToken: @MainActor Hashable {

    fileprivate let id: UUID

    fileprivate weak var gestureRecognizer:
        UIGestureRecognizer?

    fileprivate init(id: UUID, gestureRecognizer: UIGestureRecognizer) {
        self.id = id
        self.gestureRecognizer = gestureRecognizer
    }

    /// 主动移除当前 closure action。
    public func cancel() {
        gestureRecognizer?.pt.removeAction(self)
    }

    public static func == (lhs: PTGestureActionToken, rhs: PTGestureActionToken) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Internal Action Box

@MainActor
private final class PTGestureActionBox: NSObject {

    let id: UUID

    private let handler:
        @MainActor (UIGestureRecognizer) -> Void

    init(id: UUID, handler: @escaping @MainActor (UIGestureRecognizer) -> Void) {
        self.id = id
        self.handler = handler
        super.init()
    }

    @objc
    func invoke(_ gestureRecognizer: UIGestureRecognizer) {
        handler(gestureRecognizer)
    }
}

// MARK: - Internal Storage

@MainActor
private final class PTGestureActionStorage: NSObject {
    var actions: [UUID: PTGestureActionBox] = [:]
}

@MainActor
private enum PTGestureAssociatedKeys {
    static var actionStorage: UInt8 = 0
}

@MainActor
private extension UIGestureRecognizer {

    var ptGestureActionStorage:
        PTGestureActionStorage {

        if let storage = objc_getAssociatedObject(self,&PTGestureAssociatedKeys.actionStorage) as? PTGestureActionStorage {
            return storage
        }

        let storage = PTGestureActionStorage()

        objc_setAssociatedObject(self, &PTGestureAssociatedKeys.actionStorage, storage, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        return storage
    }

    var ptExistingGestureActionStorage:
        PTGestureActionStorage? {

        objc_getAssociatedObject(self, &PTGestureAssociatedKeys.actionStorage) as? PTGestureActionStorage
    }
}

// MARK: - New PTools Closure API

public extension PTPOP where Base: UIGestureRecognizer {

    /// 添加一个 Closure Action。
    ///
    /// 支持同一个 UIGestureRecognizer 挂多个 Closure，
    /// 不会覆盖已有 target-action。
    @MainActor
    @discardableResult
    func addAction(_ handler: @escaping @MainActor (Base) -> Void) -> PTGestureActionToken {

        let id = UUID()

        let box = PTGestureActionBox(id: id) { gestureRecognizer in
            guard let typedGesture = gestureRecognizer as? Base else {
                return
            }

            handler(typedGesture)
        }

        let storage = base.ptGestureActionStorage
        storage.actions[id] = box

        base.addTarget(box, action: #selector(PTGestureActionBox.invoke(_:)))

        return PTGestureActionToken(id: id, gestureRecognizer: base)
    }

    /// 删除指定 Closure Action。
    @MainActor
    func removeAction(_ token: PTGestureActionToken) {

        guard token.gestureRecognizer === base,
              let storage = base.ptExistingGestureActionStorage,
              let box = storage.actions.removeValue(forKey: token.id) else {
            return
        }

        base.removeTarget(box, action: #selector(PTGestureActionBox.invoke(_:)))

        token.gestureRecognizer = nil

        clearStorageIfNeeded(storage)
    }

    /// 删除所有通过 PTools 添加的 Closure Action。
    ///
    /// 不影响外部自己通过 addTarget 添加的 target-action。
    @MainActor
    func removeAllActions() {

        guard let storage = base.ptExistingGestureActionStorage else {
            return
        }

        for box in storage.actions.values {
            base.removeTarget(box, action: #selector(PTGestureActionBox.invoke(_:)))
        }

        storage.actions.removeAll()

        objc_setAssociatedObject(base, &PTGestureAssociatedKeys.actionStorage, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /// 当前通过 PTools 添加的 Closure 数量。
    @MainActor
    var actionCount: Int {
        base.ptExistingGestureActionStorage?.actions.count ?? 0
    }

    @MainActor
    private func clearStorageIfNeeded(_ storage: PTGestureActionStorage) {
        guard storage.actions.isEmpty else {
            return
        }

        objc_setAssociatedObject(base, &PTGestureAssociatedKeys.actionStorage, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

// MARK: - Legacy Compatibility

public extension UIGestureRecognizer {

    /// 保留旧 PTools / SwifterSwift 风格初始化方式。
    ///
    /// 旧代码可以继续：
    ///
    ///     let tap = UITapGestureRecognizer { sender in
    ///         ...
    ///     }
    ///
    @MainActor
    convenience init(actionBlock: @escaping TapedBlock) {
        self.init()
        addGesActionHandlers(handler: actionBlock)
    }

    /// 保留旧 API，但内部已经转到新的多 Closure Action Core。
    ///
    /// 与旧实现不同：
    /// 连续调用不会再覆盖前一个 handler。
    @MainActor
    func addGesActionHandlers(handler: @escaping TapedBlock) {
        pt.addAction { gesture in
            handler(gesture)
        }
    }

    /// 从当前宿主 UIView 移除该手势。
    @MainActor
    func removeFromView() {
        view?.removeGestureRecognizer(self)
    }
}
