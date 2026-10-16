//
//  PTNumberKeyBoard.swift
//  PooTools_Example
//
//  Created by ken lam on 2021/10/26.
//  Copyright © 2021 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

// English: Import the umbrella Core target explicitly for standalone SwiftPM builds.
// Español: Importa explícitamente el target Core para las compilaciones SwiftPM independientes.
// 中文：独立 SwiftPM 编译时，显式导入 Core 聚合 target。
#if SWIFT_PACKAGE
import ptools
#endif

@objc public enum PTKeyboardType: Int {
    case Normal, Call, Point, InputID
}

public typealias PTNumberKeyBoardBackSpace = (_ keyboard: PTNumberKeyBoard) -> Void
public typealias PTNumberKeyBoardReturnSTH = (_ keyboard: PTNumberKeyBoard, _ result: String) -> Void

public extension PTNumberKeyBoard {
    static var doneButton = "PT Button delete".localized()
    
    static func createKeyboard(type: PTKeyboardType, backSpace: @escaping PTNumberKeyBoardBackSpace, returnSTH: @escaping PTNumberKeyBoardReturnSTH) -> Self {
        return Self(type: type, backSpace: backSpace, returnSTH: returnSTH)
    }
}

@objcMembers
public class PTNumberKeyBoard: UIView {
    private static let kKeyBoardH: CGFloat = 216
    private static let kLineWidth: CGFloat = 1
    private static let kButtonSpaceTop: CGFloat = 5
    private static let kButtonSpaceLeft: CGFloat = 5
    private static let kNumRows = 4
    private static let kNumCols = 3

    private var keyWidth: CGFloat {
        max(1, (bounds.width - CGFloat(Self.kLineWidth * 2) - CGFloat(Self.kButtonSpaceLeft * 4)) / 3)
    }

    required public init(type: PTKeyboardType,
                backSpace: @escaping PTNumberKeyBoardBackSpace,
                returnSTH: @escaping PTNumberKeyBoardReturnSTH) {

        super.init(frame: .zero)

        let colorNormal = UIColor(red: 252/255, green: 252/255, blue: 252/255, alpha: 1)
        let colorHighlighted = UIColor(red: 186/255, green: 189/255, blue: 194/255, alpha: 1)

        for row in 0..<Self.kNumRows {
            for col in 0..<Self.kNumCols {
                let tag = col + Self.kNumCols * row + 1
                let button = UIButton(type: .custom)
                button.tag = tag

                button.addActionHandlers { sender in
                    switch sender.tag {
                    case 12:
                        backSpace(self)
                    case 10:
                        let symbol: String
                        switch type {
                        case .Normal: symbol = ""
                        case .Call: symbol = "+"
                        case .Point: symbol = "."
                        case .InputID: symbol = "X"
                        }
                        returnSTH(self, symbol)
                    case 11:
                        returnSTH(self, "0")
                    default:
                        returnSTH(self, String(sender.tag))
                    }
                }

                addSubview(button)

                button.viewCorner(radius: 5)

                let normalColor = (tag == 10 || tag == 12) ? colorHighlighted : colorNormal
                let highlightedColor = (tag == 10 || tag == 12) ? colorNormal : colorHighlighted

                button.titleLabel?.font = .systemFont(ofSize: 25)
                button.setTitleColor(.black, for: .normal)

                switch tag {
                case 1...9: button.setTitle("\(tag)", for: .normal)
                case 10:
                    let symbol: String
                    switch type {
                    case .Call: symbol = "+"
                    case .Point: symbol = "."
                    case .InputID: symbol = "X"
                    default: symbol = ""
                    }
                    button.setTitle(symbol, for: .normal)
                case 11: button.setTitle("0", for: .normal)
                case 12: button.setTitle(PTNumberKeyBoard.doneButton, for: .normal)
                default: break
                }

                button.setBackgroundImage(normalColor.createImageWithColor(), for: .normal)
                button.setBackgroundImage(highlightedColor.createImageWithColor(), for: .highlighted)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        for row in 0..<Self.kNumRows {
            for col in 0..<Self.kNumCols {
                guard let button = viewWithTag(col + Self.kNumCols * row + 1) else { continue }
                let topOffset = Self.kKeyH * CGFloat(row) + CGFloat(row) * Self.kLineWidth + Self.kButtonSpaceTop * CGFloat(row + 1)
                let leftOffset = self.keyWidth * CGFloat(col) + CGFloat(col) * Self.kLineWidth + Self.kButtonSpaceLeft * CGFloat(col + 1)
                button.frame = CGRect(x: leftOffset,
                                      y: topOffset,
                                      width: keyWidth,
                                      height: Self.kKeyH)
            }
        }
    }

    // English: Let the host view determine width while exposing the keyboard's intrinsic height.
    // Español: Deja que la vista anfitriona determine el ancho y expone solo la altura intrínseca.
    // 中文：宽度交给宿主 View 决定，只提供键盘的固有高度。
    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric,
               height: Self.kKeyBoardH + max(0, safeAreaInsets.bottom))
    }

    public override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        invalidateIntrinsicContentSize()
    }

    private static var kKeyH: CGFloat {
        (Self.kKeyBoardH - CGFloat(Self.kLineWidth * 3) - CGFloat(Self.kButtonSpaceTop * 5)) / 4
    }
}
