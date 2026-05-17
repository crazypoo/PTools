//
//  PTHttpDatasource.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import ObjectiveC

@MainActor
final class PTHttpDatasource {
    static let shared = PTHttpDatasource()

    // 🌟 将数据源改为私有存储，杜绝外部绕过锁机制直接操作引发数据竞争
    private var _httpModels: [PTHttpModel] = []
    
    // 🌟 引入高效互斥锁，保障多并发网络回调操作数据源时的绝对线程安全
    private let lock = NSLock()

    private init() {}

    /// 获取当前捕获的所有 HTTP 记录（线程安全只读副本，专供 UI 渲染层读取）
    var httpModels: [PTHttpModel] {
        lock.lock()
        defer { lock.unlock() }
        return _httpModels
    }

    /// 记录新增的网络抓包模型（线程安全写入）
    /// - Returns: 是否成功添加（若 URL 无效或出现重复请求则返回 false）
    func addHttpRequest(_ model: PTHttpModel) -> Bool {
        guard let urlString = model.url?.absoluteString, !urlString.isEmpty else {
            return false
        }

        lock.lock()
        defer { lock.unlock() }

        // 请求防重校验：根据 requestId 判断是否存在相同记录
        guard !_httpModels.contains(where: { $0.requestId == model.requestId }) else {
            return false
        }

        // 🌟 严格内存防护：容量限制策略 (上限 1000 条，超出自动移除最早一条)
        if _httpModels.count >= 1000 {
            if !_httpModels.isEmpty {
                _httpModels.removeFirst()
            }
        }

        // 绑定递增顺序索引
        model.index = _httpModels.count
        _httpModels.append(model)
        return true
    }

    /// 清空所有数据源记录（线程安全）
    func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        _httpModels.removeAll()
    }

    /// 根据指定模型安全移除对应记录（线程安全）
    func remove(_ model: PTHttpModel) {
        lock.lock()
        defer { lock.unlock() }
        // 🌟 终极修复：使用高效、精准的高阶函数按条件移除，彻底根除枚举遍历移除导致的错位误删 Bug
        _httpModels.removeAll { $0.requestId == model.requestId }
    }
}

extension URLRequest {
        
    // 🌟 性能极客优化：使用 nonisolated(unsafe) 告诉编译器我们通过内部的锁/队列来保证这个静态 Key 的安全
     private struct AssociatedKeys {
         nonisolated(unsafe) static var requestId: UInt8 = 0
         nonisolated(unsafe) static var startTime: UInt8 = 0
    }
    
    // 创建一个私有的全局串行队列，用来隔离 Objective-C Runtime 关联对象的并发读写
    private static let runtimeQueue = DispatchQueue(label: "com.custom.http.request.runtimeQueue")
    
    /// 当前请求绑定的唯一生命周期追踪凭证 (🌟 移除 @MainActor，升级为全线程安全访问)
    var requestId: String {
        get {
            // 使用串行队列同步读取，防止多线程同时读写 Runtime 导致崩溃
            Self.runtimeQueue.sync {
                if let id = objc_getAssociatedObject(self, &AssociatedKeys.requestId) as? String {
                    return id
                } else {
                    let newValue = UUID().uuidString
                    objc_setAssociatedObject(
                        self,
                        &AssociatedKeys.requestId,
                        newValue,
                        .OBJC_ASSOCIATION_COPY_NONATOMIC
                    )
                    return newValue
                }
            }
        }
        set {
            Self.runtimeQueue.sync {
                objc_setAssociatedObject(
                    self,
                    &AssociatedKeys.requestId,
                    newValue,
                    .OBJC_ASSOCIATION_COPY_NONATOMIC
                )
            }
        }
    }
    
    /// 记录请求发起的初始时间戳 (🌟 同样移除 @MainActor)
    var startTimeStamp: NSNumber? {
        get {
            Self.runtimeQueue.sync {
                objc_getAssociatedObject(self, &AssociatedKeys.startTime) as? NSNumber
            }
        }
        set {
            Self.runtimeQueue.sync {
                objc_setAssociatedObject(
                    self,
                    &AssociatedKeys.startTime,
                    newValue,
                    .OBJC_ASSOCIATION_RETAIN_NONATOMIC
                )
            }
        }
    }
}
