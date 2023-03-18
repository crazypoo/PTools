//
//  PTShareItem.swift
//  PTNetworkTesting
//
//  Created by 邓杰豪 on 7/3/23.
//

import UIKit

public class PTShareItem: NSObject,UIActivityItemSource {
    let title: String
    let content: String
    let url: URL
    
    init(title: String, content: String, url: URL) {
        self.title = title
        self.content = content
        self.url = url
    }
    
    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ""
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        switch activityType {
        case .postToFacebook?:
            return "\(title)\n\(content)\n\(url)"
        case .postToTwitter?:
            return "\(title) \(url)"
        case .message?:
            return "\(title)\n\(content)\n\(url)"
        default:
            return url
        }
    }
}

public class PTShare {
    static let share = PTShare()
    
    public func share(shareItems items:[Any]) {
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        PTUtils.getCurrentVC().present(activityViewController, animated: true)
    }
}
