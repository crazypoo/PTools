//
//  PTCallMessageMailFunction.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/8.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import WebKit
import MessageUI

public typealias MessageResultBlock = (_ sendResult: MessageComposeResult)->Void
public typealias MailResultBlock = (_ sendResult: MFMailComposeResult)->Void

@objcMembers
public class PTCallMessageMailFunction: NSObject {
    public static let share = PTCallMessageMailFunction()
    
    var messageResultBlock:MessageResultBlock?
    var mailResultBlock:MailResultBlock?
    
    lazy var webView:WKWebView = {
        let webView = WKWebView.init(frame: .zero)
        return webView
    }()
    
    open class func telpromptByWebView(phone:String)
    {
        PTCallMessageMailFunction.share.webView.navigationDelegate = PTCallMessageMailFunction.share
        
        let urlPhoneString = "tel://\(phone)"
        PTCallMessageMailFunction.share.webView.load(URLRequest.init(url: URL(string: urlPhoneString)!))
    }
    
    open class func sendMessage(content:String,users:[String],resultBlock:MessageResultBlock?)
    {
        let vc = MFMessageComposeViewController()
        vc.body = content
        vc.recipients = users
        vc.messageComposeDelegate = PTCallMessageMailFunction.share
        vc.modalPresentationStyle = .fullScreen
        PTUtils.getCurrentVC().present(vc, animated: true)
        PTCallMessageMailFunction.share.messageResultBlock = resultBlock
    }
    
    open class func sendMail(title:String,content:String,recipients:[String]?,ccRecipients:[String]?,bccRecipients:[String]?,image:UIImage?,resultBlock:MailResultBlock?)
    {
        let vc = MFMailComposeViewController()
        vc.setSubject(title)
        vc.setMessageBody(content, isHTML: false)
        vc.setToRecipients(recipients)
        vc.setCcRecipients(ccRecipients)
        vc.setBccRecipients(bccRecipients)
        if image != nil
        {
            let imageData = image!.pngData()
            vc.addAttachmentData(imageData!, mimeType: "image/png", fileName: "SendImage.png")
        }
        vc.mailComposeDelegate = PTCallMessageMailFunction.share
        PTUtils.getCurrentVC().present(vc, animated: true)
        PTCallMessageMailFunction.share.mailResultBlock = resultBlock
    }
}

extension PTCallMessageMailFunction:WKNavigationDelegate
{
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url
        let scheme = url!.scheme
        let app = UIApplication.shared
        if scheme == "tel"
        {
            if app.canOpenURL(url!)
            {
                app.open(url!)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }
}

extension PTCallMessageMailFunction:MFMessageComposeViewControllerDelegate
{
    public func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
        if self.messageResultBlock != nil
        {
            self.messageResultBlock!(result)
        }
    }
}

extension PTCallMessageMailFunction:MFMailComposeViewControllerDelegate
{
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) {
            if self.mailResultBlock != nil
            {
                self.mailResultBlock!(result)
            }
        }
    }
}


