//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public extension Inspector {
    /// Evaluates objects of a given type.
    typealias Handler<Type> = Provider<Type, Void>

    /// Transforms objects from a given type to another object from a different type.
    struct Provider<From, To>: Hashable {
        private let identifier = UUID()

        private let closure: (From) -> To

        public init(closure: @escaping (From) -> To) {
            self.closure = closure
        }

        public static func == (lhs: Provider<From, To>, rhs: Provider<From, To>) -> Bool {
            lhs.identifier == rhs.identifier
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
        }
    }
}

extension Inspector.Provider where To == Void {
    /// Call when you need the handler to evaluate the object.
    func handle(_ sender: From) {
        closure(sender)
    }
}

extension Inspector.Provider where From: Any, To: Any {
    /// Call when you need to resolve the current value for the given object.
    func value(for sender: From) -> To {
        closure(sender)
    }
}

extension Inspector.Provider where From == Void {
    /// Call when you need to resolve the current value.
    var value: To {
        closure(())
    }
}

// MARK: - Typealiases

typealias ViewHierarchyColorScheme = Inspector.Provider<UIView, UIColor>

public extension Inspector {
    typealias ElementIconProvider = Provider<UIView, UIImage?>
    typealias ElementColorProvider = Provider<UIView, UIColor?>
}
