//
//  PTPasswordInputCoordinator.swift
//  PooTools
//
//  Created by 邓杰豪 on 20/10/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit

@MainActor
public final class PTPasswordInputCoordinator: NSObject {

    public enum FieldRole: Sendable {
        case password
        case confirmation
    }

    public typealias CommittedChangeHandler = @MainActor @Sendable (_ role: FieldRole, _ text: String, _ isReady: Bool) -> Void

    public typealias ReadyChangeHandler = @MainActor @Sendable (_ isReady: Bool) -> Void

    /// 文本真正改变后的回调
    public var onCommittedChange: CommittedChangeHandler?

    /// 整个密码表单可提交状态变化的回调
    public var onReadyChange: ReadyChangeHandler?

    private weak var passwordField: UITextField?
    private weak var confirmationField: UITextField?

    private let validate: @MainActor @Sendable (String) -> Bool
    private var lastReadyState = false

    /// 当前表单是否满足提交条件
    public var isReady: Bool {
        guard let password = passwordField?.text, !password.isEmpty, validate(password) else {
            return false
        }

        if let confirmationField {
            return confirmationField.text == password
        }

        return true
    }

    public init(passwordField: UITextField, confirmationField: UITextField? = nil, validate: @escaping @MainActor @Sendable (String) -> Bool = { !$0.isEmpty }) {
        self.passwordField = passwordField
        self.confirmationField = confirmationField === passwordField ? nil : confirmationField
        self.validate = validate

        super.init()

        lastReadyState = isReady

        NotificationCenter.default.addObserver(self, selector: #selector(handleTextDidChange(_:)), name: UITextField.textDidChangeNotification, object: passwordField)

        if let confirmationField = self.confirmationField {
            NotificationCenter.default.addObserver(self, selector: #selector(handleTextDidChange(_:)), name: UITextField.textDidChangeNotification, object: confirmationField)
        }
    }

    @objc
    private func handleTextDidChange(_ notification: Notification) {
        guard let field = notification.object as? UITextField else {
            return
        }

        if field === passwordField {
            commitChange(.password, field: field)
        } else if field === confirmationField {
            commitChange(.confirmation, field: field)
        }
    }

    private func commitChange(_ role: FieldRole, field: UITextField) {
        let ready = isReady

        onCommittedChange?(role, field.text ?? "", ready)

        publishReadyIfNeeded()
    }

    private func publishReadyIfNeeded() {
        let ready = isReady

        guard ready != lastReadyState else {
            return
        }

        lastReadyState = ready
        onReadyChange?(ready)
    }

    /// 程序化修改文本后主动同步状态。
    /// 指定 changedField 时也会发送文本提交回调。
    public func refresh(changedField: FieldRole? = nil) {
        switch changedField {
        case .password:
            if let passwordField {
                commitChange(.password, field: passwordField)
            }

        case .confirmation:
            if let confirmationField {
                commitChange(.confirmation, field: confirmationField)
            }

        case nil:
            publishReadyIfNeeded()
        }
    }

    /// 提前停止观察，例如表单被复用或替换时
    public func invalidate() {
        NotificationCenter.default.removeObserver(self)
        onCommittedChange = nil
        onReadyChange = nil
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
