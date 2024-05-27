//
//  PTHttpDatasource.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class PTHttpDatasource {
    static let shared = PTHttpDatasource()

    var httpModels: [PTHttpModel] = []

    func addHttpRequest(_ model: PTHttpModel) -> Bool {
        if model.url?.absoluteString.isEmpty == true {
            return false
        }

        // Maximum number limit
        if httpModels.count >= 1000 {
            if !httpModels.isEmpty {
                httpModels.remove(at: 0)
            }
        }

        // Detect repeated
        guard !httpModels.contains(where: { $0.requestId == model.requestId }) else {
            return false
        }
        model.index = httpModels.count
        httpModels.append(model)
        return true
    }

    func removeAll() {
        httpModels.removeAll()
    }

    func remove(_ model: PTHttpModel) {
        for (index, obj) in httpModels.reversed().enumerated() {
            if obj.requestId == model.requestId {
                httpModels.remove(at: index)
            }
        }
    }
}

extension URLRequest {
    private enum AssociatedKeys {
        static var requestId = "requestId"
        static var startTime = "startTime"
    }

    var requestId: String {
        get {
            if let id = objc_getAssociatedObject(self, AssociatedKeys.requestId) as? String {
                return id
            } else {
                let newValue = UUID().uuidString
                objc_setAssociatedObject(self, AssociatedKeys.requestId, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
                return newValue
            }
        }
        set {
            objc_setAssociatedObject(self, AssociatedKeys.requestId, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }

    var startTime: NSNumber? {
        get {
            objc_getAssociatedObject(self, AssociatedKeys.startTime) as? NSNumber
        }
        set {
            objc_setAssociatedObject(self, AssociatedKeys.startTime, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
