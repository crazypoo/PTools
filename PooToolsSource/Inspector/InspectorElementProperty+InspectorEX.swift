//
//  InspectorElementProperty+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public extension InspectorElementProperty {
    static func cgColorPicker(title: String, color: @escaping CGColorProvider, handler: @escaping CGColorHandler) -> InspectorElementProperty {
        .colorPicker(
            title: title,
            color: { UIColor(cgColor: color()) },
            handler: { handler($0?.cgColor) }
        )
    }
}

public extension InspectorElementProperty {
    static func fontNamePicker(
        title: String,
        emptyTitle: String = .systemFontFamilyName,
        fontProvider: @escaping FontProvider,
        handler: @escaping FontHandler
    ) -> InspectorElementProperty {
        .optionsList(
            title: title,
            emptyTitle: emptyTitle,
            axis: .vertical,
            options: FontReference.allCases.map { (title: $0.description, icon: $0.icon) },
            selectedIndex: {
                guard let fontName = fontProvider()?.fontName else { return nil }
                return FontReference.firstIndex(of: fontName)
            },
            handler: {
                guard
                    let newIndex = $0,
                    let pointSize = fontProvider()?.pointSize,
                    let newFont = FontReference.font(at: newIndex, size: pointSize)
                else {
                    return handler(nil)
                }

                handler(newFont)
            }
        )
    }

    static func fontSizeStepper(
        title: String,
        fontProvider: @escaping FontProvider,
        handler: @escaping FontHandler
    ) -> InspectorElementProperty {
        .cgFloatStepper(
            title: title,
            value: { fontProvider()?.pointSize ?? 0 },
            range: { 0...256 },
            stepValue: { 1 }
        ) { fontSize in

            let newFont = fontProvider()?.withSize(fontSize)

            handler(newFont)
        }
    }
}

extension InspectorElementProperty: Hashable {
    private var idenfitifer: String {
        String(describing: self)
    }

    public static func == (
        lhs: InspectorElementProperty,
        rhs: InspectorElementProperty
    ) -> Bool {
        lhs.idenfitifer == rhs.idenfitifer
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(idenfitifer)
    }
}

public extension InspectorElementProperty {
    static func segmentPicker(for segmentedControl: UISegmentedControl, handler: SelectionHandler?) -> InspectorElementProperty {
        .optionsList(
            title: "Segment",
            emptyTitle: "No Segments",
            options: segmentedControl.segmentsOptions,
            selectedIndex: { segmentedControl.selectedSegmentIndex == UISegmentedControl.noSegment ? nil : segmentedControl.selectedSegmentIndex },
            handler: handler
        )
    }
}

private extension UISegmentedControl {
    var segmentsOptions: [String] {
        var options = [String]()

        for index in 0 ..< numberOfSegments {
            var title: String {
                let segmentIndex = "Segment \(index)"

                guard let titleForSegment = titleForSegment(at: index) else {
                    return segmentIndex
                }

                return segmentIndex + " – " + titleForSegment
            }

            options.append(title)
        }

        return options
    }
}

public extension InspectorElementProperty {
    static func integerStepper(
        title: String,
        value: @escaping IntProvider,
        range: @escaping IntClosedRangeProvider,
        stepValue: @escaping IntProvider,
        handler: IntHandler?
    ) -> InspectorElementProperty {
        .stepper(
            title: title,
            value: { Double(value()) },
            range: { Double(range().lowerBound)...Double(range().upperBound) },
            stepValue: { Double(stepValue()) },
            isDecimalValue: false,
            handler: handler == nil ? nil : { handler?(Int($0)) }
        )
    }

    static func cgFloatStepper(
        title: String,
        value: @escaping CGFloatProvider,
        range: @escaping CGFloatClosedRangeProvider,
        stepValue: @escaping CGFloatProvider,
        handler: CGFloatHandler?
    ) -> InspectorElementProperty {
        .stepper(
            title: title,
            value: { Double(value()) },
            range: { Double(range().lowerBound)...Double(range().upperBound) },
            stepValue: { Double(stepValue()) },
            isDecimalValue: true,
            handler: handler == nil ? nil : { handler?(CGFloat($0)) }
        )
    }

    static func floatStepper(
        title: String,
        value: @escaping (() -> Float),
        range: @escaping (() -> ClosedRange<Float>),
        stepValue: @escaping (() -> Float),
        handler: ((Float) -> Void)?
    ) -> InspectorElementProperty {
        .stepper(
            title: title,
            value: { Double(value()) },
            range: { Double(range().lowerBound)...Double(range().upperBound) },
            stepValue: { Double(stepValue()) },
            isDecimalValue: true,
            handler: handler == nil ? nil : { handler?(Float($0)) }
        )
    }
}

public extension InspectorElementProperty {
    static func dataDetectorType(
        textView: UITextView,
        dataDetectorType: UIDataDetectorTypes
    ) -> InspectorElementProperty {
        .switch(
            title: dataDetectorType.description,
            isOn: { textView.dataDetectorTypes.contains(dataDetectorType) }
        ) { isOn in

            var dataDetectorTypes: UIDataDetectorTypes? {
                var dataDetectors = textView.dataDetectorTypes

                switch isOn {
                case true:
                    _ = dataDetectors.insert(dataDetectorType).memberAfterInsert

                case false:
                    dataDetectors.remove(dataDetectorType)
                }

                return dataDetectors
            }

            let newDataDetectorTypes = dataDetectorTypes ?? []

            textView.dataDetectorTypes = newDataDetectorTypes
        }
    }
}
