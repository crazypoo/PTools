//
//  UIKeyCommandTableView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public protocol UITableViewKeyCommandsDelegate: AnyObject {
    func tableViewDidBecomeFirstResponder(_ tableView: UIKeyCommandTableView)
    func tableViewDidResignFirstResponder(_ tableView: UIKeyCommandTableView)
    func tableViewKeyCommandSelectionBelowBounds(_ tableView: UIKeyCommandTableView) -> UIKeyCommandTableView.OutOfBoundsBehavior
    func tableViewKeyCommandSelectionAboveBounds(_ tableView: UIKeyCommandTableView) -> UIKeyCommandTableView.OutOfBoundsBehavior
}

/// A table view that allows navigation and selection using a hardware keyboard.
public class UIKeyCommandTableView: UITableView {
    
    public enum OutOfBoundsBehavior {
        case resignFirstResponder, wrapAround, doNothing
    }
    
    public weak var keyCommandsDelegate: UITableViewKeyCommandsDelegate?
    
    public override var canBecomeFirstResponder: Bool {
        !isHidden && totalNumberOfRows > 0
    }
    
    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        let hasBecomeFirstResponder = super.becomeFirstResponder()
        
        if hasBecomeFirstResponder {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                
                self.keyCommandsDelegate?.tableViewDidBecomeFirstResponder(self)
            }
        }
        
        return hasBecomeFirstResponder
    }
    
    @discardableResult
    public override func resignFirstResponder() -> Bool {
        let hasResignedFirstResponder = super.resignFirstResponder()
        
        if hasResignedFirstResponder {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                
                self.keyCommandsDelegate?.tableViewDidResignFirstResponder(self)
            }
        }
        
        return hasResignedFirstResponder
    }
    
    public var selectPreviousKeyCommandOptions: [UIKeyCommand.Options] = [.arrowUp]
    
    public var selectNextKeyCommandOptions: [UIKeyCommand.Options] = [.arrowDown]
    
    public var activateSelectionKeyCommandOptions: [UIKeyCommand.Options] = [.spaceBar, .return]
    
    public var activateAccessoryButtonKeyCommandOptions: [UIKeyCommand.Options] = []
    
    public var clearSelectionKeyCommandOptions: [UIKeyCommand.Options] = []
    
    public override var keyCommands: [UIKeyCommand]? {
        var keyCommands = [UIKeyCommand]()
        
        selectPreviousKeyCommandOptions.forEach {
            keyCommands.append(UIKeyCommand($0, action: #selector(selectPreviousRow)))
        }
        
        selectNextKeyCommandOptions.forEach {
            keyCommands.append(UIKeyCommand($0, action: #selector(selectNextRow)))
        }
        
        activateSelectionKeyCommandOptions.forEach {
            keyCommands.append(UIKeyCommand($0, action: #selector(activateSelection)))
        }
        
        activateAccessoryButtonKeyCommandOptions.forEach {
            keyCommands.append(UIKeyCommand($0, action: #selector(activateAccessorySelection)))
        }
        
        clearSelectionKeyCommandOptions.forEach {
            keyCommands.append(UIKeyCommand($0, action: #selector(clearSelection)))
        }
        
        return keyCommands
    }
    
    public var totalNumberOfRows: Int {
        (0 ..< numberOfSections).map { numberOfRows(inSection: $0) }.reduce(0, +)
    }
    
    public var indexPathForLastRowInLastSection: IndexPath {
        let lastSection = numberOfSections - 1
        let lastRow     = numberOfRows(inSection: lastSection) - 1
        
        return IndexPath(row: lastRow, section: lastSection)
    }
    
    /// Tries to select and scroll to the row at the given index in section 0.
    /// Does not require the index to be in bounds. Does nothing if out of bounds.
    public func selectRowIfPossible(at indexPath: IndexPath?) {
        guard
            allowsSelection,
            let indexPath = indexPath
        else {
            return
        }
        
        switch validate(indexPath) {
            
        case .success:
            handleSelectionSuccess(at: indexPath)
            
        case let .failure(reason):
            handleSelectionFailure(at: indexPath, reason: reason)
        }
    }
    
    @objc
    public func selectPreviousRow() {
        selectRowIfPossible(at: indexPathForSelectedRow?.previousRow() ?? indexPathForLastVisibleRow)
    }

    @objc
    public func selectNextRow() {
        selectRowIfPossible(at: indexPathForSelectedRow?.nextRow() ?? indexPathForFirstVisibleRow)
    }
    
}

// MARK: - Selection

private extension UIKeyCommandTableView {
    
    func lastRow(in section: Int) -> Int? {
        switch validate(IndexPath(row: .zero, section: section)) {
        case .failure:
            return nil
            
        case .success:
            return numberOfRows(inSection: section) - 1
        }
    }
    
    func handleSelectionSuccess(at indexPath: IndexPath) {
        var selectedIndexPath: IndexPath? {
            guard
                let delegate = delegate,
                delegate.responds(to: #selector(UITableViewDelegate.tableView(_:willSelectRowAt:)))
            else {
                return indexPath
            }
            
            return delegate.tableView?(self, willSelectRowAt: indexPath)
        }
        
        if let validIndexPath = selectedIndexPath {
            return performRowSelection(at: validIndexPath)
        }
        
        switch indexPathForSelectedRow?.compare(indexPath) {
        case .orderedSame:
            return
        
        case .orderedDescending:
            selectRowIfPossible(at: indexPath.previousRow())
            
        case .none, .orderedAscending:
            selectRowIfPossible(at: indexPath.nextRow())
        }
    }
    
    func handleSelectionFailure(at indexPath: IndexPath, reason: IndexPath.InvalidReason) {
        switch reason {
        case .sectionBelowBounds:
            switch keyCommandsDelegate?.tableViewKeyCommandSelectionBelowBounds(self) {
            case .none, .doNothing:
                break
                
            case .resignFirstResponder:
                resignFirstResponder()
                
            case .wrapAround:
                selectRowIfPossible(at: indexPathForLastRowInLastSection)
            }
            
        case .sectionAboveBounds:
            switch keyCommandsDelegate?.tableViewKeyCommandSelectionAboveBounds(self) {
            case .none, .doNothing:
                break
                
            case .resignFirstResponder:
                resignFirstResponder()
                
            case .wrapAround:
                selectRowIfPossible(at: .first)
            }
            
        case .rowAboveBounds:
            selectRowIfPossible(at: indexPath.nextSection())
            
        case .rowBelowBounds:
            let section = indexPath.section - 1
            
            if let row = lastRow(in: section) {
                selectRowIfPossible(at: IndexPath(row: row, section: section))
            }
            else {
                selectRowIfPossible(at: IndexPath(row: .zero, section: section))
            }
        }
    }
    
    func performRowSelection(at indexPath: IndexPath) {
        switch isRowVisible(at: indexPath) {
        case .fullyVisible:
            selectRow(at: indexPath, animated: false, scrollPosition: .none)
            
        case let .notFullyVisible(scrollPosition):
            selectRow(at: indexPath, animated: false, scrollPosition: .none)
            scrollToRow(at: indexPath, at: scrollPosition, animated: true)
            
            debounce(#selector(flashScrollIndicators), after: 0.2)
        }
    }
    
    func validate(_ indexPath: IndexPath) -> Result<IndexPath, IndexPath.InvalidReason> {
        guard indexPath.section >= 0 else {
            return .failure(.sectionBelowBounds)
        }
        
        guard indexPath.section < numberOfSections else {
            return .failure(.sectionAboveBounds)
        }
        
        guard indexPath.row >= 0 else {
            return .failure(.rowBelowBounds)
        }
        
        guard indexPath.row < numberOfRows(inSection: indexPath.section) else {
            return .failure(.rowAboveBounds)
        }
        
        return .success(indexPath)
    }
}

// MARK: - Key Command Handlers

@objc
private extension UIKeyCommandTableView {
    
    func clearSelection() {
        selectRow(at: nil, animated: false, scrollPosition: .none)
    }

    func activateSelection() {
        guard let selectedIndexPath = selectableIndexPath else {
            return
        }
        
        delegate?.tableView?(self, didSelectRowAt: selectedIndexPath)
    }
    
    func activateAccessorySelection() {
        guard let selectedIndexPath = selectableIndexPath else {
            return
        }
        
        delegate?.tableView?(self, accessoryButtonTappedForRowWith: selectedIndexPath)
    }
    
    var indexPathForFirstVisibleRow: IndexPath? {
        for indexPath in indexPathsForVisibleRows ?? [] where isRowVisible(at: indexPath) == .fullyVisible {
            return indexPath
        }
        return .none
    }
    
    var indexPathForLastVisibleRow: IndexPath? {
        for indexPath in (indexPathsForVisibleRows ?? []).reversed() where isRowVisible(at: indexPath) == .fullyVisible {
            return indexPath
        }
        return .none
    }
    
    var selectableIndexPath: IndexPath? {
        guard let indexPathForSelectedRow = indexPathForSelectedRow else {
            return nil
        }
        
        guard
            let delegate = delegate,
            delegate.responds(to: #selector(UITableViewDelegate.tableView(_:willSelectRowAt:)))
        else {
            return indexPathForSelectedRow
        }
        
        return delegate.tableView?(self, willSelectRowAt: indexPathForSelectedRow)
    }
}

// MARK: - Row Visibility

private extension UIKeyCommandTableView {
    
    /// Whether a row is fully visible, or if not if it’s above or below the viewport.
    enum RowVisibility: Hashable {
        case fullyVisible
        case notFullyVisible(ScrollPosition)
    }

    /// Whether the given row is fully visible, or if not if it’s above or below the viewport.
    func isRowVisible(at indexPath: IndexPath) -> RowVisibility {
        let rowRect = rectForRow(at: indexPath)
        
        if bounds.inset(by: adjustedContentInset).contains(rowRect) {
            return .fullyVisible
        }

        let position: ScrollPosition = rowRect.midY < bounds.midY ? .top : .bottom
        
        return .notFullyVisible(position)
    }
    
}
