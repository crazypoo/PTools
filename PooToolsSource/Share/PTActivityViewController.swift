//
//  PTShareItem.swift
//  PTNetworkTesting
//
//  Created by 邓杰豪 on 7/3/23.
//

import UIKit
import SnapKit

open class PTShareItem: NSObject,UIActivityItemSource {
    let title: String
    let content: String
    let url: URL?
    
    public init(title: String, content: String, url: URL? = nil) {
        self.title = title
        self.content = content
        self.url = url
    }
    
    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        ""
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        switch activityType {
        case .postToFacebook?:
            if url != nil {
                return "\(title)\n\(content)\n\(url!)"
            } else {
                return "\(title)\n\(content)"
            }
        case .postToTwitter?:
            if url != nil {
                return "\(title) \(url!)"
            } else {
                return "\(title)"
            }
        case .message?:
            if url != nil {
                return "\(title)\n\(content)\n\(url!)"
            } else {
                return "\(title)\n\(content)"
            }
        default:
            return url
        }
    }
}

public class PTShareCustomActivity: UIActivity {
    //用于保存传递过来的要分享的数据
    open var text:String!
    open var url:URL!
    open var image:UIImage!
     
    open var customActivityTitle:String!
    open var customActivityImage:UIImage!

    //显示在分享框里的名称
    public override var activityTitle: String?  {
        customActivityTitle
    }
     
    //分享框的图片
    public override var activityImage: UIImage? {
        customActivityImage
    }
     
    //分享类型，在UIActivityViewController.completionHandler回调里可以用于判断，一般取当前类名
    public override var activityType: UIActivity.ActivityType? {
        UIActivity.ActivityType(rawValue: PTShareCustomActivity.self.description())
    }
     
    //按钮类型（分享按钮：在第一行，彩色，动作按钮：在第二行，黑白）
    public override class var activityCategory: UIActivity.Category {
        .share
    }
     
    //是否显示分享按钮，这里一般根据用户是否授权,或分享内容是否正确等来决定是否要隐藏分享按钮
    public override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for item in activityItems {
            if item is UIImage {
                return true
            }
            if item is String {
                return true
            }
            if item is URL {
                return true
            }
        }
        return false
    }
     
    //解析分享数据时调用，可以进行一定的处理
    public override func prepare(withActivityItems activityItems: [Any]) {
        for item in activityItems {
            if item is UIImage {
                image = (item as! UIImage)
            }
            if item is String {
                text = (item as! String)
            }
            if item is URL {
                url = (item as! URL)
            }
        }
    }
     
    //执行分享行为
    //这里根据自己的应用做相应的处理
    //例如你可以分享到另外的app例如微信分享，也可以保存数据到照片或其他地方，甚至分享到网络
    public override func perform() {        //具体的执行代码这边先省略
        //......
        activityDidFinish(true)
    }
     
    //分享时调用
    public override var activityViewController: UIViewController? {
        nil
    }
     
    //完成分享后调用
    public override func activityDidFinish(_ completed: Bool) {
    }
}

@objcMembers
open class PTActivityViewController:UIActivityViewController {
    
    /// 毛玻璃
    private lazy var preview: UIVisualEffectView = {
        let preview = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        preview.translatesAutoresizingMaskIntoConstraints = false
        preview.layer.cornerRadius = previewCornerRadius
        preview.clipsToBounds = true
        preview.alpha = 0
        return preview
    }()

    private lazy var previewLabel:PTActiveLabel = {
        let label = PTActiveLabel()
        
        label.urlMaximumLength = 31
        label.customize { label in
            label.attributedText = self.contentAtt
            label.font = previewFont
            label.numberOfLines = previewNumberOfLines
            label.lineSpacing = 2
            label.textColor = .black
            label.hashtagColor = UIColor(red: 85.0/255, green: 172.0/255, blue: 238.0/255, alpha: 1)
            label.mentionColor = UIColor(red: 238.0/255, green: 85.0/255, blue: 96.0/255, alpha: 1)
            label.URLColor = previewLinkColor
            label.configureLinkAttribute = { (type, attributes, isSelected) in
                var atts = attributes
                switch type {
                case PTActiveType.hashtag,PTActiveType.url,PTActiveType.mention,PTActiveType.email:
                    atts[NSAttributedString.Key.font] = isSelected ? self.previewFont : self.previewFont
                default:
                    break
                }
                return atts
            }
        }
        return label
    }()
    
    private lazy var previewImageView : UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = previewImageCornerRadius
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.accessibilityIgnoresInvertColors = true
        return view
    }()
    
    private let activityItems: [Any]
    
    /// 渐入动画时间
    open var fadeInDuration: TimeInterval = 0.3
    
    /// 渐出动画时间
    open var fadeOutDuration: TimeInterval = 0.3
    
    /// 内容Content默认圆角
    open var previewCornerRadius: CGFloat = 12
    
    /// 内容图片圆角
    open var previewImageCornerRadius: CGFloat = 3
    
    /// 内容图片大小
    open var previewImageSideLength: CGFloat = 80
    
    /// 内容间隔
    open var previewPadding: CGFloat = 12
    
    /// 内容行数
    open var previewNumberOfLines: Int = 5
    
    /// URL的颜色
    open var previewLinkColor: UIColor = UIColor(red: 0, green: 0.47, blue: 1, alpha: 1)
    
    /// 字体的颜色
    open var previewFont: UIFont = .appfont(size: 16,bold:true)
    
    /// Content的间隔(top)
    open var previewTopMargin: CGFloat = 8
    
    /// Content的间隔(bottom)
    open var previewBottomMargin: CGFloat = 8
        
    private var haveImage:Bool = false
    private lazy var fullContentHeight:CGFloat = {
        let value:CGFloat = (CGFloat.kSCREEN_HEIGHT / 2) - previewBottomMargin * 5 - (CGFloat.kNavBarHeight_Total + previewTopMargin)
        return value
    }()
    private lazy var contentAtt:NSMutableAttributedString = {
        let attributedString = NSMutableAttributedString()
        
        var urlString = ""
        var contentString = ""
        for (index, item) in activityItems.enumerated() {
            if let url = item as? URL {
                urlString = url.absoluteString
            } else if let text = item as? String {
                contentString = text
            }
        }
        
        var urlLines = 0
        if !urlString.stringIsEmpty() {
            urlLines = numberOfLines(urlString)
        }
        
        let contentLines = numberOfLines(contentString)
        let textMaxLines = (previewNumberOfLines - urlLines)

        let contentText = contentString.truncatedText(maxLineNumber: (textMaxLines - (urlLines + 1)), font: self.previewFont, labelShowWidth: labelContentWidth(), lineSpacing: 2)
        attributedString.append(NSAttributedString(string: contentText + (contentLines > textMaxLines ? "...." : "") + "\n\(urlString)"))
        return attributedString
    }()
    
    public convenience init(activityItems: [Any]) {
        self.init(activityItems: activityItems, applicationActivities: nil)
    }
    
    public convenience init(text: String, activities: [UIActivity]? = nil) {
        self.init(activityItems: [text], applicationActivities: activities)
    }
    
    public convenience init(image: UIImage, activities: [UIActivity]? = nil) {
        self.init(activityItems: [image], applicationActivities: activities)
    }
    
    public convenience init(url: URL, activities: [UIActivity]? = nil) {
        self.init(activityItems: [url], applicationActivities: activities)
    }
    
    //MARK: 初始化分享控件
    ///初始化分享控件
    /// - Parameters:
    ///   - activityItems: 可以是文本,图片data,其他文件....... Sample:["123",someImage.pngData()]
    ///   - applicationActivities:
    public override init(activityItems: [Any], applicationActivities: [UIActivity]?) {
        self.activityItems = activityItems
        
        super.init(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
            
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
                
        UIView.animate(withDuration: fadeInDuration) {
            self.preview.alpha = 1
        }
                
        AppWindows!.addSubview(preview)
        
        preview.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            if #available(iOS 17.0, *) {
                make.bottom.equalTo(AppWindows!.snp.centerY).offset(-(previewBottomMargin * 5))
            } else {
                make.bottom.equalTo(self.view.snp.top).offset(-previewBottomMargin)
            }
            make.height.equalTo(self.fullContentHeight)
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIView.animate(withDuration: fadeOutDuration, animations: {
            self.preview.alpha = 0
        }) { _ in
            self.preview.removeFromSuperview()
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        if let previewImage = activityItems.first(where: { $0 is UIImage }) as? UIImage {
            haveImage = true
            preview.contentView.addSubviews([previewImageView,previewLabel])
            previewImageView.image = previewImage
            previewImageView.snp.makeConstraints { make in
                make.left.top.equalToSuperview().inset(previewPadding)
                make.width.equalTo(previewImageSideLength)
                make.height.equalTo(previewImageSideLength)
            }
            
            previewLabel.snp.makeConstraints { make in
                make.right.equalToSuperview().inset(previewPadding)
                make.top.equalToSuperview().inset(previewPadding)
                make.bottom.lessThanOrEqualToSuperview().inset(previewPadding)
                make.left.equalTo(self.previewImageView.snp.right).offset(previewPadding)
            }

        } else {
            haveImage = false
            
            preview.contentView.addSubviews([previewLabel])
            previewLabel.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(previewPadding)
                make.top.equalToSuperview().inset(previewPadding)
                make.bottom.lessThanOrEqualToSuperview().inset(previewPadding)
            }
        }
        
        let swipeGesture = UISwipeGestureRecognizer { sender in
            self.dismiss(animated: true, completion: nil)
        }
        swipeGesture.direction = .down
        preview.addGestureRecognizer(swipeGesture)
        
        var showContentHeight:CGFloat = fullContentHeight
        let contentHeight = UIView.sizeFor(string: contentAtt.string, font: previewFont,lineSpacing: 2, width: labelContentWidth()).height + previewPadding * 2
        if contentHeight < fullContentHeight {
            showContentHeight = contentHeight
        }
        preview.snp.updateConstraints { make in
            make.height.equalTo(showContentHeight)
        }
    }
        
    public func presentActionSheet(_ vc: UIViewController, from view: UIView,completion:PTActionTask? = nil) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            popoverPresentationController?.sourceView = view
            popoverPresentationController?.sourceRect = view.bounds
            popoverPresentationController?.permittedArrowDirections = [.right, .left]
        }
        vc.present(self, animated: true, completion: completion)
    }
    
    func labelContentWidth() -> CGFloat {
        var labelW:CGFloat = CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 2
        if haveImage {
            labelW = (labelW - previewImageSideLength - previewPadding * 3)
        } else {
            labelW = (labelW - previewPadding * 2)
        }
        return labelW
    }
    
    func numberOfLines(_ string: String) -> Int {
        string.numberOfLines(font: previewFont, labelShowWidth: labelContentWidth(), lineSpacing: 2)
   }
}
