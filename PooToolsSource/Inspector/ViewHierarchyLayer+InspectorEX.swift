//
//  ViewHierarchyLayer+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import Foundation

extension ViewHierarchyLayer: Actionable {
    var title: String {
        description
    }

    var emptyActionTitle: String {
        Texts.emptyLayer(with: description)
    }
}

extension ViewHierarchyLayer: AdditiveArithmetic {
    public static func - (lhs: Inspector.ViewHierarchyLayer, rhs: Inspector.ViewHierarchyLayer) -> Inspector.ViewHierarchyLayer {
        ViewHierarchyLayer(
            name: [lhs.name, rhs.name].joined(separator: ",-"),
            showLabels: lhs.showLabels,
            allowsInternalViews: lhs.allowsInternalViews
        ) {
            lhs.filter($0) && rhs.filter($0) == false
        }
    }

    public static func + (lhs: Inspector.ViewHierarchyLayer, rhs: Inspector.ViewHierarchyLayer) -> Inspector.ViewHierarchyLayer {
        ViewHierarchyLayer(
            name: [lhs.name, rhs.name].joined(separator: ",+"),
            showLabels: lhs.showLabels,
            allowsInternalViews: lhs.allowsInternalViews
        ) {
            lhs.filter($0) || rhs.filter($0)
        }
    }

    public static var zero: Inspector.ViewHierarchyLayer {
        ViewHierarchyLayer(name: "zero", showLabels: false) { _ in false }
    }
}

extension ViewHierarchyLayer: CustomStringConvertible {
    var description: String {
        guard name.contains(",+") || name.contains(",-") else {
            return name
        }

        let components = name.components(separatedBy: ",")

        var additions = [String]()
        var exclusions = [String]()

        components.forEach {
            if $0 == components.first {
                additions.append($0)
            }

            if $0.first == "+" {
                additions.append(String($0.dropFirst()))
            }

            if $0.first == "-" {
                exclusions.append(String($0.dropFirst()))
            }
        }

        var displayName = String()

        additions.enumerated().forEach { index, name in
            if index == 0 {
                displayName = name
                return
            }

            if index == additions.count - 1 {
                displayName += " and \(name)"
            }
            else {
                displayName += ", \(name)"
            }
        }

        guard exclusions.isEmpty == false else {
            return displayName
        }

        exclusions.enumerated().forEach { index, name in
            if index == 0 {
                displayName += " excl․ \(name)"
                return
            }

            if index == additions.count - 1 {
                displayName += " and \(name)"
            }
            else {
                displayName += ", \(name)"
            }
        }

        return displayName
    }
}
