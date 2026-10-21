//
//  PTMediaGridCommitState.swift
//  PooTools
//
//  English: Track desired and committed media rows without treating a scheduled update as visible.
//  Español: Rastrea las filas deseadas y confirmadas sin tratar una actualización programada como visible.
//  中文：跟踪期望和已提交的媒体 Row，不把已排队更新误认为已经显示。
//

import Foundation

struct PTMediaGridCommitState: Equatable {
    private(set) var committedRowIDs: [String] = []
    private(set) var desiredRowIDs: [String] = []
    private(set) var inFlightTransactionID: String?

    var hasInFlightTransaction: Bool { inFlightTransactionID != nil }

    mutating func enqueue(rowIDs: [String]) {
        desiredRowIDs = rowIDs
    }

    mutating func begin(transactionID: String) -> Bool {
        guard inFlightTransactionID == nil else { return false }
        inFlightTransactionID = transactionID
        return true
    }

    @discardableResult
    mutating func commit(transactionID: String, rowIDs: [String]) -> Bool {
        guard inFlightTransactionID == transactionID ||
                (inFlightTransactionID == nil && desiredRowIDs == rowIDs) else {
            return false
        }
        committedRowIDs = rowIDs
        desiredRowIDs = rowIDs
        inFlightTransactionID = nil
        return true
    }

    mutating func supersede(transactionID: String) {
        guard inFlightTransactionID == transactionID else { return }
        inFlightTransactionID = nil
    }

    mutating func reset() {
        committedRowIDs = []
        desiredRowIDs = []
        inFlightTransactionID = nil
    }
}
