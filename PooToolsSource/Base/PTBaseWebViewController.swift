//
//  PTBaseWebViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 9/21/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import WebKit
import SnapKit

public extension String {
    func joinHtml(lang:String = "zh-CN") -> String {
        return "<!DOCTYPE html><html lang=\"\(lang)\"><head><meta name=\"viewport\" content=\"width=device-width,initial-scale=1,minimum-scale=1,maximum-scale=1,user-scalable=no\"><style>body{padding:0;margin:0;}img{display:block;width:100%;}</style></head><body>\(self)</body></html>"
    }
}

open class PTBaseWebViewController: PTBaseViewController {

    public var vcDismiss:PTActionTask?
    
    public var webHeight: ((CGFloat) -> Void)?
    public var backImage:UIImage = UIColor.random.createImageWithColor().transformImage(size: CGSizeMake(24, 24))
    
    public var hiddenNav = false {
        didSet {
            navigationController?.navigationBar.isHidden = true
            webView.snp.updateConstraints { make in
                make.top.equalTo(hiddenNav ? 0 : CGFloat.kNavBarHeight_Total)
            }
        }
    }
    
    fileprivate var showString:String = ""
    
    fileprivate lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        //允许视频播放
        config.allowsAirPlayForMediaPlayback = true
        // 允许在线播放
        config.allowsInlineMediaPlayback = true
#if DEBUG
        config.websiteDataStore = WKWebsiteDataStore.nonPersistent()
#else
        config.websiteDataStore = WKWebsiteDataStore.default()
#endif
        //自定义配置,一般用于 js调用oc方法(OC拦截URL中的数据做自定义操作)
        let userContentController = WKUserContentController()
        // 是否支持记忆读取
        config.suppressesIncrementalRendering = true
        // 允许用户更改网页的设置
        config.userContentController = userContentController
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        config.preferences = preferences
        
        let view = WKWebView()
        view.navigationDelegate = self
        view.uiDelegate = self
        view.scrollView.delegate = self
        view.backgroundColor = .white
        view.scrollView.showsHorizontalScrollIndicator = false
        view.scrollView.bounces = false
        
        return view
    }()
    
    lazy var backButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(backImage, for: .normal)
        view.addActionHandlers { _ in
            if self.checkVCIsPresenting() {
                self.dismissAnimated()
            } else {
                self.navigationController?.popViewController()
            }
        }
        return view
    }()
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setCustomBackButtonView(backButton)
    }
    
    public init(showString:String = "") {
        self.showString = showString
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        vcDismiss?()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        
        var topSpace:CGFloat = 0
        navigationItem.largeTitleDisplayMode = .never
        topSpace = (navigationController?.navigationBar.isHidden ?? false) ? -CGFloat.kNavBarHeight_Total : 0
        view.addSubviews([webView])
        webView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(topSpace)
        }
        self.loadWeb()
    }
    
    func loadWeb() {
        if !showString.stringIsEmpty(),let url = URL(string: showString) {
            let request = URLRequest(url: url)
            self.webView.load(request)
        } else if !showString.stringIsEmpty(),showString.containsHTMLTags() {
            self.webView.loadHTMLString(self.showString.joinHtml(), baseURL: nil)
        } else {
            fatalError("Not load url or html")
        }
    }
}

extension PTBaseWebViewController: WKNavigationDelegate,WKUIDelegate,UIScrollViewDelegate {
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        return .allow
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
        return .allow
    }
    
    /// 页面开始加载
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        PTNSLogConsole("页面开始加载")
    }
    /// 页面内容返回
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        PTNSLogConsole("页面内容返回")
    }
    
    /// 页面加载完成
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        PTNSLogConsole("页面加载完成>>>>>>\(webView)")
        self.title = webView.title ?? ""
    }
    
    /// 提交发生错误
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        PTNSLogConsole("提交发生错误  \(error)")
    }
    
    /// 页面加载失败
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        PTNSLogConsole("页面加载失败  \(error)")
    }
}
