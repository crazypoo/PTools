//
//  PTHTMLHeightCalculator.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 1/29/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit
import WebKit

public class PTHTMLHeightCalculator: NSObject {
    public static let share = PTHTMLHeightCalculator()
    
    private var webView: WKWebView!
    private var completionHandler: ((CGFloat) -> Void)?

    public override init() {
        super.init()
    }

    public func initWebView() {
        let configuration = WKWebViewConfiguration()
        webView = WKWebView(frame: CGRectMake(0, 0, CGFloat.kSCREEN_WIDTH, 1), configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = self
    }
    
    public func calculateHeight(for html: String,
                                completion: @escaping (CGFloat) -> Void) {
        completionHandler = completion
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    public static func resetHtmlTag(rawHTML:String) -> String {
        // Step 1: 替换懒加载图片的 src
        let processedHTML = rawHTML
            .replacingOccurrences(of: #"(?i)<img([^>]+)(?:data-src|data-lazy|data-original)=["']([^"']+)["']([^>]*)>"#,
                                  with: "<img$1src=\"$2\"$3>",
                                  options: .regularExpression)

        // Step 2: 构造完整 HTML 页面
        let completeHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
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

extension PTHTMLHeightCalculator: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] result, error in
            guard let self = self, let height = result as? CGFloat, error == nil else {
                self?.completionHandler?(0)
                return
            }
            self.completionHandler?(height)
        }
    }
}
