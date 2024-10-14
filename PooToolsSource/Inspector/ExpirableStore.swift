//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

struct ExpirableStore<Value>: ExpirableProtocol {
    private let lifespan: TimeInterval

    private(set) var expirationDate: Date

    private var _wrappedValue: Value?

    var wrappedValue: Value? {
        get {
            isValid ? _wrappedValue : .none
        }
        set {
            _wrappedValue = newValue
            expirationDate = Self.makeExpirationDate(lifespan)
        }
    }

    init(_ value: Value? = .none, lifespan: TimeInterval) {
        expirationDate = Self.makeExpirationDate(lifespan)
        _wrappedValue = value
        self.lifespan = lifespan
    }

    private static func makeExpirationDate(_ lifespan: TimeInterval) -> Date {
        Date().addingTimeInterval(lifespan)
    }
}
