//
//  PTHTMLHeightCalculator.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 1/29/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit
import WebKit

// ✅ Swift 6 优化：标记 @MainActor 确保所有 WKWebView 的操作严格在 UI 线程执行
@MainActor
public final class PTHTMLHeightCalculator: NSObject {
    
    // 放弃有状态的全局单例共享回调，改为每次实例化独立的计算任务，彻底解决并发列表计算冲突
    private let webView: WKWebView
    // 使用 Continuation 桥接传统 Delegate 到 async/await 体系
    private var activeContinuation: CheckedContinuation<CGFloat, Never>?
    private var activeNavigation: WKNavigation?

    // English: Ignore callbacks from a navigation that was replaced by a newer calculation.
    // Español: Ignora callbacks de una navegación reemplazada por un cálculo más reciente.
    // 中文：忽略已被新计算替换的旧导航回调。

    // ✅ 在初始化时直接构建 WebView，消除 initWebView() 样板代码和强制解包(!)
    public override init() {
        let configuration = WKWebViewConfiguration()
        // 使用 UIScreen 的替代安全方案或传入确定宽度，避免强制依赖隐式全局变量
        let screenWidth = UIScreen.main.bounds.width
        self.webView = WKWebView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 1), configuration: configuration)
        self.webView.scrollView.isScrollEnabled = false
        super.init()
        // 设置代理
        self.webView.navigationDelegate = self
    }

    // English: Finish a suspended calculation safely before releasing the WebKit view.
    // Español: Finaliza de forma segura un cálculo suspendido antes de liberar la vista WebKit.
    // 中文：释放 WebKit 视图前安全结束挂起的计算。
    deinit {
        activeContinuation?.resume(returning: 0)
        webView.stopLoading()
        webView.navigationDelegate = nil
        activeNavigation = nil
    }

    /// 现代化的 Swift 6 异步计算接口
    /// - Parameter html: 原始 HTML 字符串
    /// - Returns: 计算出的实际渲染高度
    public func calculateHeight(for html: String) async -> CGFloat {
        webView.stopLoading()
        // 确保上一个未完成的任务安全释放（防止重复调用挂起）
        activeContinuation?.resume(returning: 0)
        activeContinuation = nil
        
        let processedHTML = Self.resetHtmlTag(rawHTML: html)
        
        return await withCheckedContinuation { continuation in
            self.activeContinuation = continuation
            self.activeNavigation = self.webView.loadHTMLString(processedHTML, baseURL: nil)
        }
    }
    
    // ✅ 遵循 Sendable 的静态纯函数，安全且无副作用
    public static func resetHtmlTag(rawHTML: String) -> String {
        // Step 1: 替换懒加载图片的 src
        let processedHTML = rawHTML
            .replacingOccurrences(of: #"(?i)<img([^>]+)(?:data-src|data-lazy|data-original)=["']([^"']+)["']([^>]*)>"#,
                                  with: "<img$1src=\"$2\"$3>",
                                  options: .regularExpression)

        // Step 2: 构造完整 HTML 页面 (加入 CSS 样式，宽度设为 100% 避免撑爆屏幕)
        let completeHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                body {
                    margin: 0;
                    padding: 0;
                }
                img {
                    width: 100%;
                    max-width: 100%;
                    height: auto;
                    display: block;
                }
                div {
                    width: 100%;
                    max-width: 100%;
                }
            </style>
        </head>
        <body>
        \(processedHTML)
        </body>
        </html>
        """
        return completeHTML
    }
}

// MARK: - WKNavigationDelegate
extension PTHTMLHeightCalculator: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard isCurrentNavigation(navigation) else { return }
        // 使用 Task 包装与 WebView 交互的 JS 评估，对齐 Actor 隔离
        Task { @MainActor [weak self, weak webView] in
            guard let self, let webView, self.isCurrentNavigation(navigation) else { return }
            do {
                // 推荐获取 document.documentElement.scrollHeight 往往比 body 更加精准
                let result = try await webView.evaluateJavaScript("document.documentElement.scrollHeight")
                guard self.isCurrentNavigation(navigation) else { return }
                let height = (result as? NSNumber)?.decimalValue.description.cgFloat ?? 0
                finishCalculation(with: height)
            } catch {
                finishCalculation(with: 0)
            }
        }
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard isCurrentNavigation(navigation) else { return }
        finishCalculation(with: 0)
    }

    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        guard activeContinuation != nil else { return }
        activeNavigation = webView.reload()
    }
    
    private func finishCalculation(with height: CGFloat) {
        activeContinuation?.resume(returning: height)
        activeContinuation = nil
        activeNavigation = nil
    }

    private func isCurrentNavigation(_ navigation: WKNavigation?) -> Bool {
        guard let navigation, let activeNavigation else { return false }
        return navigation === activeNavigation
    }
}

// 辅助转换代码 (支持 String 转 CGFloat，确保编译顺畅)
private extension String {
    var cgFloat: CGFloat {
        if let doubleValue = Double(self) {
            return CGFloat(doubleValue)
        }
        return 0
    }
}
