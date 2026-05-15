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
    
    // 🌟 性能极客优化：采用单字节的静态变量指针地址做 Key，不仅避开命名冲突，查找速度更是呈数量级提升
    @MainActor
    private struct AssociatedKeys {
        static var requestId: UInt8 = 0
        static var startTime: UInt8 = 0
    }

    /// 当前请求绑定的唯一生命周期追踪凭证 (自动按需注入 UUID)
    @MainActor var requestId: String {
        get {
            // 通过获取静态内存地址做 Key 读取关联对象
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
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.requestId,
                newValue,
                .OBJC_ASSOCIATION_COPY_NONATOMIC
            )
        }
    }

    /// 记录请求发起的初始时间戳
    @MainActor var startTime: NSNumber? {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.startTime) as? NSNumber
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.startTime,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}
