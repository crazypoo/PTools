//
//  PTVideoEditorLens.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

public struct PTVideoEditorLens <Whole,Part> {
    public let from: (Whole) -> Part
    public let to: (Part, Whole) -> Whole

    public init(from: @escaping (Whole) -> Part,
                to: @escaping (Part, Whole) -> Whole) {
        self.from = from
        self.to = to
    }
}

public func compose<A,B,C>(_ lhs: PTVideoEditorLens<A, B>,
                           _ rhs: PTVideoEditorLens<B,C>) -> PTVideoEditorLens<A, C> {
    PTVideoEditorLens<A, C>(
        from: { a in rhs.from(lhs.from(a)) },
        to: { (c, a) in lhs.to(rhs.to(c, lhs.from(a)),a)}
    )
}

public func * <A, B, C>(_ lhs: PTVideoEditorLens<A, B>,
                        _ rhs: PTVideoEditorLens<B,C>) -> PTVideoEditorLens<A, C> {
    compose(lhs, rhs)
}
