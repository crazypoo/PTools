//
//  WeekObject.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public final class Weak<Object: AnyObject>: Hashable {
    private let objectIdentifier: ObjectIdentifier
    public weak var weakReference: Object?

    public init(_ object: Object) {
        objectIdentifier = ObjectIdentifier(object)
        weakReference = object
    }

    public convenience init?(_ object: Object?) {
        guard let object = object else { return nil }
        self.init(object)
    }

    public static func == (lhs: Weak<Object>, rhs: Weak<Object>) -> Bool {
        lhs.objectIdentifier == rhs.objectIdentifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(objectIdentifier)
    }
}
