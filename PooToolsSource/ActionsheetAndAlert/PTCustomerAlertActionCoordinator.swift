//
//  PTCustomerAlertActionCoordinator.swift
//  PooTools
//
// English: Guard one-shot alert actions and disable buttons during dismissal.
// Español: Protege las acciones de una sola ejecución y desactiva botones durante el cierre.
// 中文：保证 Alert 操作只执行一次，并在消失动画期间禁用按钮。
//

import UIKit

@MainActor
final class PTCustomerAlertActionCoordinator {
    private var isHandling = false

    func begin(_ buttons: [UIButton]) -> Bool {
        guard !isHandling else { return false }
        isHandling = true
        buttons.forEach { $0.isEnabled = false }
        return true
    }

    func reset() {
        isHandling = false
    }
}
