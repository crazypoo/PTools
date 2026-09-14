# PTools 5.9.x 公开 API 基线

本报告由 Scripts/report_public_api_5_9.rb 生成，记录源码级声明，不宣称 ABI 稳定。

| 位置 | 类型 | 访问级别 | 声明 |
| --- | --- | --- | --- |
| PooToolsSource/AESAndDES/PTDataEncryption.swift:16 | enum | public | public enum PTEncryptionError: LocalizedError { |
| PooToolsSource/AESAndDES/PTDataEncryption.swift:24 | var | public | public var errorDescription: String? { |
| PooToolsSource/AESAndDES/PTDataEncryption.swift:37 | class | public | public class PTDataEncryption { |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:14 | typealias | public | public typealias PTActionSheetCallback = (_ sheet:PTActionSheetController) -> Void |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:15 | typealias | public | public typealias PTActionSheetIndexCallback = (_ sheet:PTActionSheetController, _ index:Int,_ title:String) -> Void |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:17 | class | public | public class PTActionCell:UIView { |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:54 | enum | public | @objc public enum PTSheetButtonStyle: Int { |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:59 | class | public | public class PTActionSheetItem: NSObject { |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:60 | var | public | public var title:String = "" |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:61 | var | public | public var titleColor:UIColor = .systemBlue |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:62 | var | public | public var titleFont:UIFont = .systemFont(ofSize: 20) |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:63 | var | public | public var image:Any? |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:64 | var | public | public var imageSize:CGSize = CGSizeMake(34, 34) |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:65 | var | public | public var iCloudDocumentName:String = "" |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:66 | var | public | public var highlightColor:UIColor = .systemGray4 |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:69 | var | public | public var heightlightColor:UIColor { |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:73 | var | public | public var itemAlignment:UIControl.ContentHorizontalAlignment = .center |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:74 | var | public | public var itemLayout:PTSheetButtonStyle = .leftImageRightTitle |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:75 | var | public | public var contentEdgeValue:CGFloat = 20 |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:76 | var | public | public var contentImageSpace:CGFloat = 15 |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:78 | init | public | public init(title: String, |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:104 | class | public | public class PTActionSheetTitleItem: PTActionSheetItem { |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:105 | var | public | public var subTitle:String = "" |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:107 | init | public | public init(title: String = "", |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:124 | struct | public | public struct PTActionSheetViewConfigSnapshot: Sendable { |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:125 | let | public | public let lineHeight: CGFloat |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:126 | let | public | public let rowHeight: CGFloat |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:127 | let | public | public let separatorHeight: CGFloat |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:128 | let | public | public let viewSpace: CGFloat |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:129 | let | public | public let cornerRadii: CGFloat |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:131 | init | public | public init(lineHeight: CGFloat, |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:144 | class | public | public class PTActionSheetViewConfig:NSObject { |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:151 | init | public | public init(@PTClampedPropertyWrapper(range:0.1...0.5) lineHeight: CGFloat = 0.5, |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:166 | func | public | public func snapshot() -> PTActionSheetViewConfigSnapshot { |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:175 | class | public | public class PTActionSheetController: PTAlertController { |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:177 | var | public | public var actionSheetCancelSelectBlock: PTActionSheetCallback? |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:178 | var | public | public var actionSheetDestructiveSelectBlock: PTActionSheetIndexCallback? |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:179 | var | public | public var actionSheetSelectBlock: PTActionSheetIndexCallback? |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:180 | var | public | public var tapBackgroundBlock: PTActionSheetCallback? |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:245 | init | public | public init(viewConfig:PTActionSheetViewConfig = PTActionSheetViewConfig(), |
| PooToolsSource/ActionsheetAndAlert/PTActionSheetController.swift:528 | func | public | public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, |
| PooToolsSource/ActionsheetAndAlert/PTAlertConfig.swift:14 | class | public | public class PTAlertConfig: NSObject { |
| PooToolsSource/ActionsheetAndAlert/PTAlertConfig.swift:17 | enum | public | public enum PTUserInterfaceStyle: Int { |
| PooToolsSource/ActionsheetAndAlert/PTAlertConfig.swift:23 | enum | public | public enum PTAlertPriority { |
| PooToolsSource/ActionsheetAndAlert/PTAlertConfig.swift:72 | enum | public | public enum PTMode { |
| PooToolsSource/ActionsheetAndAlert/PTAlertConfig.swift:84 | var | public | public var popoverMode: PTMode = .queue |
| PooToolsSource/ActionsheetAndAlert/PTAlertConfig.swift:86 | var | public | public var popoverPriority: PTAlertPriority = .medium |
| PooToolsSource/ActionsheetAndAlert/PTAlertConfig.swift:88 | var | public | public var allowsEventPenetration = false |
| PooToolsSource/ActionsheetAndAlert/PTAlertConfig.swift:90 | var | public | public var autoHideWhenPenetrated = false |
| PooToolsSource/ActionsheetAndAlert/PTAlertConfig.swift:92 | var | public | public var shouldAutorotate = false |
| PooToolsSource/ActionsheetAndAlert/PTAlertConfig.swift:94 | var | public | public var supportedInterfaceOrientations = UIInterfaceOrientationMask.portrait |
| PooToolsSource/ActionsheetAndAlert/PTAlertConfig.swift:96 | var | public | public var userInterfaceStyleOverride = PTUserInterfaceStyle.unspecified |
| PooToolsSource/ActionsheetAndAlert/PTAlertConfig.swift:98 | var | public | public var identifier: String? |
| PooToolsSource/ActionsheetAndAlert/PTAlertConfig.swift:100 | var | public | public var showAlertDuration: TimeInterval = 0.35 |
| PooToolsSource/ActionsheetAndAlert/PTAlertConfig.swift:101 | var | public | public var hideAlertDuration: TimeInterval = 0.35 |
| PooToolsSource/ActionsheetAndAlert/PTAlertConfig.swift:105 | var | public | public var showALertDuration: TimeInterval { |
| PooToolsSource/ActionsheetAndAlert/PTAlertConfig.swift:112 | var | public | public var hideALertDuration: TimeInterval { |
| PooToolsSource/ActionsheetAndAlert/PTAlertController.swift:13 | class | open | open class PTAlertController: PTBaseViewController { |
| PooToolsSource/ActionsheetAndAlert/PTAlertController.swift:16 | var | open | open var config = PTAlertConfig() |
| PooToolsSource/ActionsheetAndAlert/PTAlertController.swift:107 | func | public | public func dismissSelf(completion: PTActionTask? = nil) { |
| PooToolsSource/ActionsheetAndAlert/PTAlertController.swift:115 | func | open | open func showAnimation(completion: PTActionTask? = nil) { |
| PooToolsSource/ActionsheetAndAlert/PTAlertController.swift:119 | func | open | open func dismissAnimation(completion: PTActionTask? = nil) { |
| PooToolsSource/ActionsheetAndAlert/PTAlertManager.swift:13 | struct | public | public struct PTAlertDebugSnapshot { |
| PooToolsSource/ActionsheetAndAlert/PTAlertManager.swift:14 | let | public | public let sceneCount: Int |
| PooToolsSource/ActionsheetAndAlert/PTAlertManager.swift:15 | let | public | public let scenes: [SceneInfo] |
| PooToolsSource/ActionsheetAndAlert/PTAlertManager.swift:17 | struct | public | public struct SceneInfo { |
| PooToolsSource/ActionsheetAndAlert/PTAlertManager.swift:18 | let | public | public let id: String |
| PooToolsSource/ActionsheetAndAlert/PTAlertManager.swift:19 | let | public | public let showingKeys: [String] |
| PooToolsSource/ActionsheetAndAlert/PTAlertManager.swift:20 | let | public | public let queueKeys: [String] |
| PooToolsSource/ActionsheetAndAlert/PTAlertManager.swift:155 | init | public | public init(sceneContextProvider: any PTSceneContextProviding = PTDefaultSceneContextProvider()) { |
| PooToolsSource/ActionsheetAndAlert/PTAlertManager.swift:217 | func | public | public func debugSnapshot() -> PTAlertDebugSnapshot { |
| PooToolsSource/ActionsheetAndAlert/PTAlertProtocol.swift:12 | protocol | public | public protocol PTAlertProtocol where Self: PTAlertController { |
| PooToolsSource/ActionsheetAndAlert/PTAlertTips.swift:12 | enum | public | public enum PTAlertTipsStyle { |
| PooToolsSource/ActionsheetAndAlert/PTAlertTips.swift:61 | class | public | public class PTAlertTipsLow: UIView { |
| PooToolsSource/ActionsheetAndAlert/PTAlertTips.swift:62 | var | open | open var dismissByTap: Bool = true |
| PooToolsSource/ActionsheetAndAlert/PTAlertTips.swift:63 | var | open | open var dismissInTime: Bool = true |
| PooToolsSource/ActionsheetAndAlert/PTAlertTips.swift:64 | var | open | open var duration: TimeInterval = 1.5 |
| PooToolsSource/ActionsheetAndAlert/PTAlertTips.swift:65 | var | open | open var haptic: PTAlertTipsHaptic? = nil |
| PooToolsSource/ActionsheetAndAlert/PTAlertTips.swift:67 | let | public | public let titleLabel: UILabel? |
| PooToolsSource/ActionsheetAndAlert/PTAlertTips.swift:68 | let | public | public let subtitleLabel: UILabel? |
| PooToolsSource/ActionsheetAndAlert/PTAlertTips.swift:69 | let | public | public let iconView: UIView? |
| PooToolsSource/ActionsheetAndAlert/PTAlertTips.swift:96 | init | public | public init(title: String?, subtitle: String?, icon: PTAlertTipsIcon?) { |
| PooToolsSource/ActionsheetAndAlert/PTAlertTips.swift:179 | func | open | open func present(on view: UIView, completion: PTActionTask? = nil) { |
| PooToolsSource/ActionsheetAndAlert/PTAlertTips.swift:224 | func | open | @objc open func dismiss(completion: PTActionTask? = nil) { |
| PooToolsSource/ActionsheetAndAlert/PTAlertTips.swift:280 | init | public | public init(iconSize: CGSize, margins: UIEdgeInsets, spaceBetweenIconAndTitle: CGFloat) { |
| PooToolsSource/ActionsheetAndAlert/PTAlertTips.swift:318 | class | public | public class PTAlertTipsHight: UIView { |
| PooToolsSource/ActionsheetAndAlert/PTAlertTips.swift:320 | var | open | open var dismissByTap: Bool = true |
| PooToolsSource/ActionsheetAndAlert/PTAlertTips.swift:321 | var | open | open var dismissInTime: Bool = true |
| PooToolsSource/ActionsheetAndAlert/PTAlertTips.swift:322 | var | open | open var duration: TimeInterval = 1.5 |
| PooToolsSource/ActionsheetAndAlert/PTAlertTips.swift:323 | var | open | open var haptic: PTAlertTipsHaptic? = nil |
| PooToolsSource/ActionsheetAndAlert/PTAlertTips.swift:325 | let | public | public let titleLabel: UILabel? |
| PooToolsSource/ActionsheetAndAlert/PTAlertTips.swift:326 | let | public | public let subtitleLabel: UILabel? |
| PooToolsSource/ActionsheetAndAlert/PTAlertTips.swift:327 | let | public | public let iconView: UIView? |
| PooToolsSource/ActionsheetAndAlert/PTAlertTips.swift:360 | init | public | public init(title: String?, subtitle: String?, icon: PTAlertTipsIcon?) { |
| PooToolsSource/ActionsheetAndAlert/PTAlertTips.swift:442 | func | open | open func present(on view: UIView, completion: PTActionTask? = nil) { |
| PooToolsSource/ActionsheetAndAlert/PTAlertTips.swift:493 | func | open | @objc open func dismiss(completion: PTActionTask? = nil) { |
| PooToolsSource/ActionsheetAndAlert/PTAlertTipsHaptic.swift:11 | enum | public | public enum PTAlertTipsHaptic { |
| PooToolsSource/ActionsheetAndAlert/PTAlertTipsIcon.swift:11 | enum | public | public enum PTAlertTipsIcon:Equatable { |
| PooToolsSource/ActionsheetAndAlert/PTAlertTipsIcon.swift:19 | func | public | @MainActor public func createView(lineThick:CGFloat) -> UIView { |
| PooToolsSource/ActionsheetAndAlert/PTAlertTipsIcon.swift:40 | protocol | public | public protocol PTAlertTipsAnimation { |
| PooToolsSource/ActionsheetAndAlert/PTAlertTipsIcon.swift:44 | class | public | public class PTAlertTipsDone:UIView, @MainActor PTAlertTipsAnimation { |
| PooToolsSource/ActionsheetAndAlert/PTAlertTipsIcon.swift:56 | func | public | public func animation() { |
| PooToolsSource/ActionsheetAndAlert/PTAlertTipsIcon.swift:90 | class | public | public class PTAlertTipsError:UIView, @MainActor PTAlertTipsAnimation { |
| PooToolsSource/ActionsheetAndAlert/PTAlertTipsIcon.swift:102 | func | public | public func animation() { |
| PooToolsSource/ActionsheetAndAlert/PTAlertTipsIcon.swift:173 | class | public | public class PTAlertTipsHeart: UIView { |
| PooToolsSource/ActionsheetAndAlert/PTAlertTipsIcon.swift:214 | enum | public | public enum ResizingBehavior: Int { |
| PooToolsSource/ActionsheetAndAlert/PTAlertTipsIcon.swift:221 | func | public | public func apply(rect: CGRect, target: CGRect) -> CGRect { |
| PooToolsSource/ActionsheetAndAlert/PTAlertTipsIcon.swift:255 | class | public | public class PTAlertTipsSpinner: UIView { |
| PooToolsSource/ActionsheetAndAlert/PTAlertTipsViewController.swift:13 | class | public | public class PTAlertTipsViewController: PTAlertController { |
| PooToolsSource/ActionsheetAndAlert/PTAlertTipsViewController.swift:25 | var | public | public var dismissCallback: PTActionTask? |
| PooToolsSource/ActionsheetAndAlert/PTAlertTipsViewController.swift:51 | init | public | public init(title: String? = nil, |
| PooToolsSource/ActionsheetAndAlert/PTAlertWindow.swift:12 | class | public | public class PTAlertWindow: UIWindow { |
| PooToolsSource/ActionsheetAndAlert/PTAlertWindow.swift:13 | var | public | public var allowsEventPenetration = false |
| PooToolsSource/ActionsheetAndAlert/PTAlertWindow.swift:15 | var | public | public var autoHideWhenPenetrated = false |
| PooToolsSource/ActionsheetAndAlert/PTAlertWindow.swift:17 | var | public | public var rootPopoverController: PTAlertProtocol? { |
| PooToolsSource/ActionsheetAndAlert/PTCustomerAlertController.swift:13 | typealias | public | public typealias PTCustomerCustomerBlock = (_ alertCustomerView:UIView) -> Void |
| PooToolsSource/ActionsheetAndAlert/PTCustomerAlertController.swift:15 | enum | public | @objc public enum PTAlertAnimationType:Int { |
| PooToolsSource/ActionsheetAndAlert/PTCustomerAlertController.swift:24 | class | public | public class PTCustomBottomButtonModel: NSObject { |
| PooToolsSource/ActionsheetAndAlert/PTCustomerAlertController.swift:25 | var | public | public var titleName:String? = "" |
| PooToolsSource/ActionsheetAndAlert/PTCustomerAlertController.swift:26 | var | public | public var titleColor:UIColor? = UIColor.systemBlue |
| PooToolsSource/ActionsheetAndAlert/PTCustomerAlertController.swift:29 | class | public | public class PTCustomerAlertController: PTAlertController { |
| PooToolsSource/ActionsheetAndAlert/PTCustomerAlertController.swift:61 | var | public | public var bottomButtonTapCallback:((_ title:String,_ index:Int) -> Void)? = nil |
| PooToolsSource/ActionsheetAndAlert/PTCustomerAlertController.swift:62 | var | public | public var backgroundTapCallback:((PTCustomerAlertController) -> Void)? = nil |
| PooToolsSource/ActionsheetAndAlert/PTCustomerAlertController.swift:67 | var | public | public var maximumContentWidth: CGFloat = 340 { |
| PooToolsSource/ActionsheetAndAlert/PTCustomerAlertController.swift:77 | var | public | public var contentBackgroundColor: UIColor? { |
| PooToolsSource/ActionsheetAndAlert/PTCustomerAlertController.swift:86 | var | public | public var visualStyle: PTVisualStyle = .automatic { |
| PooToolsSource/ActionsheetAndAlert/PTCustomerAlertController.swift:236 | init | public | public init(title:String = "", |
| PooToolsSource/ActionsheetAndAlert/PTCustomerAlertController.swift:709 | func | public | public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, |
| PooToolsSource/ActionsheetAndAlert/PTDynamicNotificationView.swift:14 | class | public | public class PTDynamicNotificationView: UIView { |
| PooToolsSource/ActionsheetAndAlert/PTDynamicNotificationView.swift:16 | var | public | public var hideHandler: PTActionTask? |
| PooToolsSource/ActionsheetAndAlert/PTDynamicNotificationView.swift:27 | init | public | public init(showTimes: TimeInterval = 3, |
| PooToolsSource/ActionsheetAndAlert/PTDynamicNotificationView.swift:69 | func | public | public func showNotification() { |
| PooToolsSource/ActionsheetAndAlert/PTDynamicNotificationView.swift:74 | func | public | public func showNotification(in containerView: UIView) { |
| PooToolsSource/ActionsheetAndAlert/PTDynamicNotificationView.swift:98 | func | public | public func hideNotification() { |
| PooToolsSource/ActionsheetAndAlert/PTEditMenuKit.swift:13 | struct | public | public struct PTEditMenuAction { |
| PooToolsSource/ActionsheetAndAlert/PTEditMenuKit.swift:14 | let | public | public let title: String |
| PooToolsSource/ActionsheetAndAlert/PTEditMenuKit.swift:15 | let | public | public let image: UIImage? |
| PooToolsSource/ActionsheetAndAlert/PTEditMenuKit.swift:16 | let | public | public let identifier: String |
| PooToolsSource/ActionsheetAndAlert/PTEditMenuKit.swift:17 | let | public | public let attributes: UIMenuElement.Attributes |
| PooToolsSource/ActionsheetAndAlert/PTEditMenuKit.swift:18 | let | public | public let handler: PTActionTask |
| PooToolsSource/ActionsheetAndAlert/PTEditMenuKit.swift:20 | init | public | public init(title: String, |
| PooToolsSource/ActionsheetAndAlert/PTEditMenuKit.swift:45 | var | public | public var actions: [PTEditMenuAction] { |
| PooToolsSource/ActionsheetAndAlert/PTEditMenuKit.swift:51 | init | public | public init(view: UIView, actions: [PTEditMenuAction]) { |
| PooToolsSource/ActionsheetAndAlert/PTEditMenuKit.swift:58 | func | public | public func present(from rect: CGRect) { |
| PooToolsSource/ActionsheetAndAlert/PTMapActionSheet.swift:30 | class | open | open class PTMapActionSheet: NSObject { |
| PooToolsSource/ActionsheetAndAlert/PTMapActionSheet.swift:33 | class | open | open class func mapNavAlert(currentAppScheme: String, |
| PooToolsSource/ActionsheetAndAlert/PTPopoverMenuContent.swift:14 | class | public | public class PTPopoverItem:NSObject { |
| PooToolsSource/ActionsheetAndAlert/PTPopoverMenuContent.swift:15 | var | public | public var name:String = "" |
| PooToolsSource/ActionsheetAndAlert/PTPopoverMenuContent.swift:16 | var | public | public var icon:Any? |
| PooToolsSource/ActionsheetAndAlert/PTPopoverMenuContent.swift:21 | class | public | public class PTPopoverConfig:NSObject { |
| PooToolsSource/ActionsheetAndAlert/PTPopoverMenuContent.swift:22 | var | public | public var textFont:UIFont = .appfont(size: 16) |
| PooToolsSource/ActionsheetAndAlert/PTPopoverMenuContent.swift:23 | var | public | public var textColor:UIColor = PTAppBaseConfig.share.viewDefaultTextColor |
| PooToolsSource/ActionsheetAndAlert/PTPopoverMenuContent.swift:24 | var | public | public var backgroundColor:UIColor = PTDarkModeOption.colorLightDark(lightColor: .white, darkColor: .black) |
| PooToolsSource/ActionsheetAndAlert/PTPopoverMenuContent.swift:25 | var | public | public var rowHeight:CGFloat = 44 |
| PooToolsSource/ActionsheetAndAlert/PTPopoverMenuContent.swift:28 | typealias | public | public typealias PTPopoverHandler = (String,Int) -> Void |
| PooToolsSource/Animation/PTAnimationFunction.swift:11 | let | public | public let PTAnimationDuration = 0.35 |
| PooToolsSource/Animation/PTAnimationFunction.swift:16 | typealias | public | public typealias PTNativeAnimationCompletion = @MainActor @Sendable (_ finished: Bool) -> Void |
| PooToolsSource/Animation/PTAnimationFunction.swift:18 | class | public | public class PTAnimationFunction: NSObject { |
| PooToolsSource/Animation/PTAnimationFunction.swift:27 | class | public | @MainActor public class func animationIn(animationView:UIView, |
| PooToolsSource/Animation/PTAnimationFunction.swift:67 | class | public | @MainActor public class func animationOut(animationView:UIView, |
| PooToolsSource/Animation/PTCoinAnimation.swift:14 | class | public | public class PTCoinAnimation: UIView { |
| PooToolsSource/Animation/PTCoinAnimation.swift:16 | var | public | public var animationBlock:AnimationFinishBlock? |
| PooToolsSource/Animation/PTCoinAnimation.swift:18 | var | public | public var iconImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44)) |
| PooToolsSource/Animation/PTCoinAnimation.swift:78 | func | public | public func beginAnimationFunction() { |
| PooToolsSource/Animation/PTCoinAnimation.swift:126 | func | public | public func animationDidStop(_ anim: CAAnimation, |
| PooToolsSource/Animation/PTGroupBuyAvatarView.swift:11 | class | public | public class PTGroupBuyAvatarView: UIView { |
| PooToolsSource/Animation/PTGroupBuyAvatarView.swift:32 | init | public | public init(avatarImages: [Any], |
| PooToolsSource/Animation/PTGroupBuyAvatarView.swift:154 | func | public | public func startAnimation() { |
| PooToolsSource/Animation/PTListAnimation.swift:12 | protocol | public | public protocol PTListAnimationProtocol { |
| PooToolsSource/Animation/PTListAnimation.swift:18 | enum | public | public enum PTListAnimationConfig { |
| PooToolsSource/Animation/PTListAnimation.swift:35 | enum | public | public enum PTListAnimationDirection: Int, CaseIterable { |
| PooToolsSource/Animation/PTListAnimation.swift:60 | enum | public | public enum PTListAnimationType: PTListAnimationProtocol { |
| PooToolsSource/Animation/PTListAnimation.swift:70 | var | public | public var initialTransform: CGAffineTransform { |
| PooToolsSource/Animation/PTPurchaseCarAnimationTool.swift:11 | typealias | public | public typealias AnimationFinishBlock = (_ finish: Bool) -> Void |
| PooToolsSource/Animation/PTPurchaseCarAnimationTool.swift:14 | enum | public | public enum PTPurchaseCarAnimationTool { |
| PooToolsSource/Animation/PTWaterWaveView.swift:13 | class | public | public class PTWaterWaveView: UIView { |
| PooToolsSource/Animation/PTWaterWaveView.swift:53 | var | open | open var waveWidth:CGFloat = 0 |
| PooToolsSource/Animation/PTWaterWaveView.swift:54 | var | open | open var waveheight:CGFloat = 10 |
| PooToolsSource/Animation/PTWaterWaveView.swift:57 | var | open | open var waveColor:UIColor = .white |
| PooToolsSource/Animation/PTWaterWaveView.swift:60 | var | open | open var waveSpeed:CGFloat = 2.5 |
| PooToolsSource/Animation/PTWaterWaveView.swift:63 | var | open | open var waveOffsetX:CGFloat = 0 |
| PooToolsSource/Animation/PTWaterWaveView.swift:64 | var | open | open var wavePointY:CGFloat = 208 |
| PooToolsSource/Animation/PTWaterWaveView.swift:67 | var | open | open var waveAmplitude:CGFloat = 10 |
| PooToolsSource/Animation/PTWaterWaveView.swift:70 | var | open | open var waveCycle:CGFloat = 0 |
| PooToolsSource/Animation/PTWaterWaveView.swift:72 | init | public | public init(startColor:UIColor, |
| PooToolsSource/AppDelegate/PTAppDelegate.swift:11 | class | open | open class PTAppDelegate: UIResponder,UIApplicationDelegate { |
| PooToolsSource/AppDelegate/PTAppDelegate.swift:12 | var | open | open var window: UIWindow? |
| PooToolsSource/AppDelegate/PTAppScenesDelegate.swift:12 | class | open | open class PTAppScenesDelegate: PTAppDelegate {} |
| PooToolsSource/AppDelegate/PTAppWindowsDelegate.swift:14 | var | public | @MainActor public var serivceHost = "scheme://services?" |
| PooToolsSource/AppDelegate/PTAppWindowsDelegate.swift:17 | var | public | @MainActor public var webRouterUrl = "scheme://webview/home" |
| PooToolsSource/AppDelegate/PTAppWindowsDelegate.swift:20 | class | open | open class PTAppWindowsDelegate: PTAppDelegate { |
| PooToolsSource/AppDelegate/PTAppWindowsDelegate.swift:22 | var | open | open var isFullScreen:Bool = false |
| PooToolsSource/AppDelegate/PTAppWindowsDelegate.swift:29 | func | public | public func makeKeyAndVisible(in scene: UIWindowScene, |
| PooToolsSource/AppDelegate/PTAppWindowsDelegate.swift:55 | func | public | public func makeKeyAndVisible(in scene: UIWindowScene, |
| PooToolsSource/AppDelegate/PTAppWindowsDelegate.swift:63 | func | public | public func makeKeyAndVisible(createViewControllerHandler: () -> UIViewController, tint: UIColor) { |
| PooToolsSource/AppDelegate/PTAppWindowsDelegate.swift:82 | func | public | public func makeKeyAndVisible(viewController: UIViewController, tint: UIColor) { |
| PooToolsSource/AppDelegate/PTAppWindowsDelegate.swift:89 | func | public | public func createDevFunction() { |
| PooToolsSource/AppDelegate/PTAppWindowsDelegate.swift:101 | func | public | public func registerRotation(changeCallBack:((_ orientationMask: UIInterfaceOrientationMask) -> ())? = nil) { |
| PooToolsSource/AppDelegate/PTAppWindowsDelegate.swift:108 | func | public | public func registerRouter(PrifxArray:[String]? = [".Jax"]) { |
| PooToolsSource/AppDelegate/PTAppWindowsDelegate.swift:143 | func | public | public func createSettingBundle() { |
| PooToolsSource/AppDelegate/PTAppWindowsDelegate.swift:155 | func | public | public func faceOrientationMask(app:UIApplication, |
| PooToolsSource/AppDelegate/PTAppWindowsDelegate.swift:173 | func | open | open func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask { |
| PooToolsSource/AppDelegate/PTWindowSceneDelegate.swift:12 | class | open | open class PTWindowSceneDelegate: UIResponder,UIWindowSceneDelegate { |
| PooToolsSource/AppDelegate/PTWindowSceneDelegate.swift:14 | var | open | open var window: UIWindow? |
| PooToolsSource/AppDelegate/PTWindowSceneDelegate.swift:16 | func | open | open func makeKeyAndVisible(in scene: UIWindowScene, createViewControllerHandler: () -> UIViewController, tint: UIColor) { |
| PooToolsSource/AppDelegate/PTWindowSceneDelegate.swift:25 | func | open | open func makeKeyAndVisible(in scene: UIWindowScene, viewController: UIViewController, tint: UIColor) { |
| PooToolsSource/AppStore/PTAppStoreFunction.swift:13 | class | public | public class PTAppStoreFunction: NSObject { |
| PooToolsSource/ApplicationFunction/PCleanCache.swift:16 | class | public | public class PCleanCache: NSObject { |
| PooToolsSource/ApplicationFunction/PCleanCache.swift:22 | class | public | public class func getCacheSize() async -> String { |
| PooToolsSource/ApplicationFunction/PCleanCache.swift:56 | class | public | public class func clearCaches() async -> Bool { |
| PooToolsSource/ApplicationFunction/PTLaunchAdMonitor.swift:15 | let | public | public let PLaunchAdDetailDisplayNotification = "PShowLaunchAdDetailNotification" |
| PooToolsSource/ApplicationFunction/PTLaunchAdMonitor.swift:16 | let | public | public let PLaunchAdSkipNotification = "PLaunchAdSkipNotification" |
| PooToolsSource/ApplicationFunction/PTLaunchAdMonitor.swift:18 | class | public | public class PTLaunchADModel: NSObject { |
| PooToolsSource/ApplicationFunction/PTLaunchAdMonitor.swift:19 | var | public | public var image: Any? |
| PooToolsSource/ApplicationFunction/PTLaunchAdMonitor.swift:20 | var | public | public var time: TimeInterval = 0 |
| PooToolsSource/ApplicationFunction/PTLaunchAdMonitor.swift:21 | var | public | public var tapURL: [AnyHashable: Any]? |
| PooToolsSource/ApplicationFunction/PTLaunchAdMonitor.swift:27 | struct | public | public struct PTLaunchADSnapshot: Sendable { |
| PooToolsSource/ApplicationFunction/PTLaunchAdMonitor.swift:28 | let | public | public let time: TimeInterval |
| PooToolsSource/ApplicationFunction/PTLaunchAdMonitor.swift:29 | let | public | public let imageURL: URL? |
| PooToolsSource/ApplicationFunction/PTLaunchAdMonitor.swift:30 | let | public | public let imageData: Data? |
| PooToolsSource/ApplicationFunction/PTLaunchAdMonitor.swift:31 | let | public | public let imageIdentifier: String? |
| PooToolsSource/ApplicationFunction/PTLaunchAdMonitor.swift:32 | let | public | public let tapURL: [String: String] |
| PooToolsSource/ApplicationFunction/PTLaunchAdMonitor.swift:33 | let | public | public let hasTapURL: Bool |
| PooToolsSource/ApplicationFunction/PTLaunchAdMonitor.swift:36 | init | public | public init(model: PTLaunchADModel) { |
| PooToolsSource/ApplicationFunction/PTLaunchAdMonitor.swift:77 | struct | public | public struct CountdownItem<T: Sendable> : Sendable{ |
| PooToolsSource/ApplicationFunction/PTLaunchAdMonitor.swift:90 | class | public | public class PTLaunchAdMonitor: NSObject { |
| PooToolsSource/ApplicationFunction/PTLaunchAdMonitor.swift:93 | var | public | public var imageContentMode: UIView.ContentMode = .scaleAspectFill |
| PooToolsSource/ApplicationFunction/PTLaunchAdMonitor.swift:94 | var | public | public var adShowed: Bool = false |
| PooToolsSource/ApplicationFunction/PTLaunchAdMonitor.swift:95 | var | public | public var skipName: String = "Skip" |
| PooToolsSource/ApplicationFunction/PTLaunchAdMonitor.swift:168 | func | public | @MainActor public func showAd(adModels: [PTLaunchADModel], |
| PooToolsSource/ApplicationFunction/PTOpenSystemFunction.swift:12 | enum | public | @objc public enum SystemFunctionType : Int { |
| PooToolsSource/ApplicationFunction/PTOpenSystemFunction.swift:20 | class | public | public class PTOpenSystemConfig:NSObject { |
| PooToolsSource/ApplicationFunction/PTOpenSystemFunction.swift:21 | var | public | public var types : SystemFunctionType = .Setting |
| PooToolsSource/ApplicationFunction/PTOpenSystemFunction.swift:22 | var | public | public var content : String = "" |
| PooToolsSource/ApplicationFunction/PTOpenSystemFunction.swift:23 | var | public | public var scheme : String = "" |
| PooToolsSource/ApplicationFunction/PTOpenSystemFunction.swift:31 | class | public | public class PTOpenSystemFunction: NSObject { |
| PooToolsSource/ApplicationFunction/PTOpenSystemFunction.swift:52 | class | public | public class func openSystemFunction(config:PTOpenSystemConfig) { |
| PooToolsSource/ApplicationFunction/PTOpenSystemFunction.swift:129 | class | public | public class func jumpCurrentAppSetting() { |
| PooToolsSource/Badge/CAAnimation+BadgeEX.swift:14 | enum | public | public enum PTAxisType { |
| PooToolsSource/Badge/CAAnimation+BadgeEX.swift:48 | class | public | public class func opacityForeverAnimation(time: CFTimeInterval) -> CABasicAnimation { |
| PooToolsSource/Badge/CAAnimation+BadgeEX.swift:62 | class | public | public class func opacityTimesAnimation(repeatTimes: Float, time: CFTimeInterval) -> CABasicAnimation { |
| PooToolsSource/Badge/CAAnimation+BadgeEX.swift:76 | class | public | public class func rotation(duration: CFTimeInterval, degree: Float, direction: PTAxisType, repeatCount: Float) -> CABasicAnimation { |
| PooToolsSource/Badge/CAAnimation+BadgeEX.swift:91 | class | public | public class func scale(fromScale: Float, toScale: Float, duration: CFTimeInterval, repeatCount: Float) -> CABasicAnimation { |
| PooToolsSource/Badge/CAAnimation+BadgeEX.swift:106 | class | public | public class func shakeAnimation(repeatTimes: Float, duration: CFTimeInterval, offset: CGFloat = 5.0) -> CAKeyframeAnimation { |
| PooToolsSource/Badge/CAAnimation+BadgeEX.swift:121 | class | public | public class func bounceAnimation(repeatTimes: Float, duration: CFTimeInterval, offset: CGFloat = 5.0) -> CAKeyframeAnimation { |
| PooToolsSource/Badge/PTBadgeProtocol.swift:15 | enum | public | public enum PTBadgeStyle: Int, Sendable { |
| PooToolsSource/Badge/PTBadgeProtocol.swift:22 | enum | public | public enum PTBadgeAnimType: Sendable { |
| PooToolsSource/Badge/PTBadgeProtocol.swift:41 | enum | public | public enum PTBadgeContent: Sendable, Equatable { |
| PooToolsSource/Badge/PTBadgeProtocol.swift:51 | struct | public | public struct PTBadgeConfiguration { |
| PooToolsSource/Badge/PTBadgeProtocol.swift:52 | var | public | public var font: UIFont = PTAppBaseConfig.share.tabBadgeFont |
| PooToolsSource/Badge/PTBadgeProtocol.swift:53 | var | public | public var bgColor: UIColor = .red |
| PooToolsSource/Badge/PTBadgeProtocol.swift:54 | var | public | public var textColor: UIColor = .white |
| PooToolsSource/Badge/PTBadgeProtocol.swift:55 | var | public | public var frame: CGRect = .zero |
| PooToolsSource/Badge/PTBadgeProtocol.swift:57 | var | public | public var centerOffset: CGPoint = .zero |
| PooToolsSource/Badge/PTBadgeProtocol.swift:58 | var | public | public var maximumNumber: Int = 99 |
| PooToolsSource/Badge/PTBadgeProtocol.swift:60 | var | public | public var radius: CGFloat { |
| PooToolsSource/Badge/PTBadgeProtocol.swift:64 | var | public | public var borderColor: UIColor = PTAppBaseConfig.share.tabBadgeBorderColor |
| PooToolsSource/Badge/PTBadgeProtocol.swift:65 | var | public | public var borderWidth: CGFloat = PTAppBaseConfig.share.tabBadgeBorderHeight |
| PooToolsSource/Badge/PTBadgeProtocol.swift:66 | var | public | public var animType: PTBadgeAnimType = .none |
| PooToolsSource/Badge/PTBadgeProtocol.swift:67 | var | public | public var canDragToDelete: Bool = false |
| PooToolsSource/Badge/PTBadgeProtocol.swift:68 | var | public | public var longPressTime: TimeInterval = 0.5 |
| PooToolsSource/Badge/PTBadgeProtocol.swift:72 | init | public | public init() { |
| PooToolsSource/Badge/PTBadgeProtocol.swift:303 | protocol | public | public protocol PTBadgeProtocol { |
| PooToolsSource/Badge/UIBarButtonItem+BadgeEX.swift:21 | var | public | public var badge: UILabel? { |
| PooToolsSource/Badge/UIBarButtonItem+BadgeEX.swift:43 | var | public | public var badgeConfig: PTBadgeConfiguration { |
| PooToolsSource/Badge/UIBarButtonItem+BadgeEX.swift:52 | var | public | public var badgeRemoveCallback: (() -> Void)? { |
| PooToolsSource/Badge/UIBarButtonItem+BadgeEX.swift:61 | func | public | public func showBadge() { |
| PooToolsSource/Badge/UIBarButtonItem+BadgeEX.swift:65 | func | public | public func showBadge(style: PTBadgeStyle, value: Any, aniType: PTBadgeAnimType) { |
| PooToolsSource/Badge/UIBarButtonItem+BadgeEX.swift:69 | func | public | public func showBadge(_ content: PTBadgeContent, animation: PTBadgeAnimType = .none) { |
| PooToolsSource/Badge/UIBarButtonItem+BadgeEX.swift:79 | func | public | public func clearBadge() { |
| PooToolsSource/Badge/UIBarButtonItem+BadgeEX.swift:86 | func | public | public func resumeBadge() { |
| PooToolsSource/Badge/UIBarButtonItem+BadgeEX.swift:97 | func | public | public func refreshBadge() { |
| PooToolsSource/Badge/UITabBarItem+BadgeEX.swift:21 | var | public | public var badge: UILabel? { |
| PooToolsSource/Badge/UITabBarItem+BadgeEX.swift:44 | var | public | public var badgeConfig: PTBadgeConfiguration { |
| PooToolsSource/Badge/UITabBarItem+BadgeEX.swift:53 | var | public | public var badgeRemoveCallback: (() -> Void)? { |
| PooToolsSource/Badge/UITabBarItem+BadgeEX.swift:62 | func | public | public func showBadge() { |
| PooToolsSource/Badge/UITabBarItem+BadgeEX.swift:66 | func | public | public func showBadge(style: PTBadgeStyle, value: Any, aniType: PTBadgeAnimType) { |
| PooToolsSource/Badge/UITabBarItem+BadgeEX.swift:70 | func | public | public func showBadge(_ content: PTBadgeContent, animation: PTBadgeAnimType = .none) { |
| PooToolsSource/Badge/UITabBarItem+BadgeEX.swift:86 | func | public | public func clearBadge() { |
| PooToolsSource/Badge/UITabBarItem+BadgeEX.swift:94 | func | public | public func resumeBadge() { |
| PooToolsSource/Badge/UITabBarItem+BadgeEX.swift:111 | func | public | public func refreshBadge() { |
| PooToolsSource/Badge/UIView+BadgeEX.swift:67 | var | public | public var badge: UILabel? { |
| PooToolsSource/Badge/UIView+BadgeEX.swift:99 | var | public | public var badgeConfig: PTBadgeConfiguration { |
| PooToolsSource/Badge/UIView+BadgeEX.swift:113 | var | public | public var badgeRemoveCallback: (() -> Void)? { |
| PooToolsSource/Badge/UIView+BadgeEX.swift:148 | func | public | public func showBadge() { |
| PooToolsSource/Badge/UIView+BadgeEX.swift:152 | func | public | public func showBadge(style: PTBadgeStyle, value: Any, aniType: PTBadgeAnimType) { |
| PooToolsSource/Badge/UIView+BadgeEX.swift:156 | func | public | public func showBadge(_ content: PTBadgeContent, animation: PTBadgeAnimType = .none) { |
| PooToolsSource/Badge/UIView+BadgeEX.swift:174 | func | public | public func clearBadge() { |
| PooToolsSource/Badge/UIView+BadgeEX.swift:184 | func | public | public func resumeBadge() { |
| PooToolsSource/Badge/UIView+BadgeEX.swift:199 | func | public | public func refreshBadge() { |
| PooToolsSource/BankCard/PTBankCardSearch.swift:12 | typealias | public | public typealias PTBankBlock = (_ success:Bool,_ result:NSString) -> Void |
| PooToolsSource/BankCard/PTBankCardSearch.swift:15 | class | public | public class PTBankCardSearch: NSObject { |
| PooToolsSource/Base/PTAppBaseConfig.swift:15 | class | public | public class PTAppBaseConfig: NSObject { |
| PooToolsSource/Base/PTAppBaseConfig.swift:20 | var | public | public var defaultPlaceholderImage:UIImage = UIImage() |
| PooToolsSource/Base/PTAppBaseConfig.swift:22 | var | public | public var defaultEmptyImage:UIImage = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "icon_placeholder") |
| PooToolsSource/Base/PTAppBaseConfig.swift:24 | var | public | public var loadImageProgressBorderColor:UIColor = .purple |
| PooToolsSource/Base/PTAppBaseConfig.swift:25 | var | public | public var loadImageProgressBorderWidth:CGFloat = 1.5 |
| PooToolsSource/Base/PTAppBaseConfig.swift:26 | var | public | public var loadImageShowValueLabel:Bool = false |
| PooToolsSource/Base/PTAppBaseConfig.swift:27 | var | public | public var loadImageShowValueFont:UIFont = .appfont(size: 16) |
| PooToolsSource/Base/PTAppBaseConfig.swift:28 | var | public | public var loadImageShowValueColor:UIColor = .white |
| PooToolsSource/Base/PTAppBaseConfig.swift:29 | var | public | public var loadImageShowValueUniCount:Int = 0 |
| PooToolsSource/Base/PTAppBaseConfig.swift:33 | var | public | public var defaultViewSpace:CGFloat = CGFloat.ScaleW(w: 10) |
| PooToolsSource/Base/PTAppBaseConfig.swift:35 | var | public | public var navContainerSpacing:CGFloat = CGFloat.ScaleW(w: 8) |
| PooToolsSource/Base/PTAppBaseConfig.swift:36 | var | public | public var navBarButtonSpacing:CGFloat = CGFloat.ScaleW(w: 8) |
| PooToolsSource/Base/PTAppBaseConfig.swift:40 | var | public | public var viewControllerBaseBackgroundColor:UIColor = PTDarkModeOption.colorLightDark(lightColor: UIColor(hexString:"#eeeff4") ?? UIColor(white: 0.933, alpha: 1), darkColor: .black) |
| PooToolsSource/Base/PTAppBaseConfig.swift:41 | var | public | public var viewDefaultTextColor:UIColor = PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white) |
| PooToolsSource/Base/PTAppBaseConfig.swift:45 | var | public | public var navGradientBack26Image:UIImage = UIImage() |
| PooToolsSource/Base/PTAppBaseConfig.swift:46 | var | public | public var navGradientBackImage:UIImage = UIImage() |
| PooToolsSource/Base/PTAppBaseConfig.swift:47 | var | public | public var viewControllerBackItemImage:UIImage = UIImage(.chevron.left) |
| PooToolsSource/Base/PTAppBaseConfig.swift:48 | var | public | public var viewControllerBackDarkItemImage:UIImage = UIImage(.chevron.left) |
| PooToolsSource/Base/PTAppBaseConfig.swift:49 | var | public | public var navTitleFont:UIFont = .appfont(size: 24) |
| PooToolsSource/Base/PTAppBaseConfig.swift:50 | var | public | public var navLargeTitleFont:UIFont = .appfont(size: 34) |
| PooToolsSource/Base/PTAppBaseConfig.swift:51 | var | public | public var navLargeTitleProgress:CGFloat = 120 |
| PooToolsSource/Base/PTAppBaseConfig.swift:52 | var | public | public var navLargeTitleBarHeight:CGFloat = 52 |
| PooToolsSource/Base/PTAppBaseConfig.swift:53 | var | public | public var navTitleTextColor:UIColor = PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white) |
| PooToolsSource/Base/PTAppBaseConfig.swift:54 | var | public | public var navBackgroundColor:UIColor = PTDarkModeOption.colorLightDark(lightColor: UIColor(hexString:"#eeeff4") ?? UIColor(white: 0.933, alpha: 1), darkColor: .black) |
| PooToolsSource/Base/PTAppBaseConfig.swift:55 | var | public | public var hidesBarsOnSwipe:Bool = false |
| PooToolsSource/Base/PTAppBaseConfig.swift:56 | var | public | public var navGradientColors:[UIColor] = [] |
| PooToolsSource/Base/PTAppBaseConfig.swift:57 | var | public | public var bavTitleContainerHeight:CGFloat = 32 |
| PooToolsSource/Base/PTAppBaseConfig.swift:58 | var | public | @PTClampedPropertyWrapper(range:0...CGFloat.kNavBarHeight) public var navBarButtonSize:CGFloat = 40 |
| PooToolsSource/Base/PTAppBaseConfig.swift:59 | var | public | public var navBarButton26Mode:Bool = true |
| PooToolsSource/Base/PTAppBaseConfig.swift:62 | var | public | public var permissionTitleFont:UIFont = .appfont(size: 16,bold:true) |
| PooToolsSource/Base/PTAppBaseConfig.swift:63 | var | public | public var permissionTitleColor:UIColor = .black |
| PooToolsSource/Base/PTAppBaseConfig.swift:64 | var | public | public var permissionSubtitleFont:UIFont = .appfont(size: 14) |
| PooToolsSource/Base/PTAppBaseConfig.swift:65 | var | public | public var permissionSubtitleColor:UIColor = .black |
| PooToolsSource/Base/PTAppBaseConfig.swift:66 | var | public | public var permissionDeniedColor:UIColor = .red |
| PooToolsSource/Base/PTAppBaseConfig.swift:67 | var | public | public var permissionNotSupportColor:UIColor = .lightGray |
| PooToolsSource/Base/PTAppBaseConfig.swift:68 | var | public | public var permissionAuthorizedButtonFont:UIFont = .appfont(size: 14) |
| PooToolsSource/Base/PTAppBaseConfig.swift:69 | var | public | public var permissionCellTitleFont:UIFont = .appfont(size: 14) |
| PooToolsSource/Base/PTAppBaseConfig.swift:70 | var | public | public var permissionCellTitleTextColor:UIColor = .black |
| PooToolsSource/Base/PTAppBaseConfig.swift:71 | var | public | public var permissionCellSubtitleFont:UIFont = .appfont(size: 12) |
| PooToolsSource/Base/PTAppBaseConfig.swift:72 | var | public | public var permissionCellSubtitleTextColor:UIColor = .black |
| PooToolsSource/Base/PTAppBaseConfig.swift:75 | var | public | public var decorationBackgroundColor:UIColor = UIColor.white |
| PooToolsSource/Base/PTAppBaseConfig.swift:76 | var | public | public var decorationBackgroundCornerRadius:CGFloat = CGFloat.ScaleW(w: 10) |
| PooToolsSource/Base/PTAppBaseConfig.swift:77 | var | public | public var baseCellHeight:CGFloat = CGFloat.ScaleW(w: 54) |
| PooToolsSource/Base/PTAppBaseConfig.swift:78 | var | public | public var baseCellBackgroundColor:UIColor = PTDarkModeOption.colorLightDark(lightColor: .white, darkColor: .Black25PercentColor) |
| PooToolsSource/Base/PTAppBaseConfig.swift:80 | var | public | public var screenShotShare:Any = UIImage(.square.andPencil) as Any |
| PooToolsSource/Base/PTAppBaseConfig.swift:81 | var | public | public var screenShotFeedback:Any = UIImage(.square.andArrowUp) as Any |
| PooToolsSource/Base/PTAppBaseConfig.swift:84 | var | public | public var privacyURL:String = "https://www.qq.com" |
| PooToolsSource/Base/PTAppBaseConfig.swift:85 | var | public | public var privacyNameFont:UIFont = .appfont(size: 13) |
| PooToolsSource/Base/PTAppBaseConfig.swift:90 | var | public | public var loadImageRetryMaxCount:Int = 3 |
| PooToolsSource/Base/PTAppBaseConfig.swift:91 | var | public | public var loadImageRetryInerval:TimeInterval = 2 |
| PooToolsSource/Base/PTAppBaseConfig.swift:95 | func | public | public func webImageLoadOptions(maxCount:Int? = nil, |
| PooToolsSource/Base/PTAppBaseConfig.swift:107 | func | public | public func gobalWebImageLoadOption(maxCount:Int? = nil, |
| PooToolsSource/Base/PTAppBaseConfig.swift:113 | var | public | public var appID:String = "" |
| PooToolsSource/Base/PTAppBaseConfig.swift:116 | var | public | public var MXMetricKitUploadAddress = "" |
| PooToolsSource/Base/PTAppBaseConfig.swift:118 | var | public | public var playerBackItemImage:UIImage = UIImage(.chevron.left) |
| PooToolsSource/Base/PTAppBaseConfig.swift:119 | var | public | public var playerPlayItemPlayImage:UIImage = UIImage(.play) |
| PooToolsSource/Base/PTAppBaseConfig.swift:120 | var | public | public var playerPlayItemPauseImage:UIImage = UIImage(.pause) |
| PooToolsSource/Base/PTAppBaseConfig.swift:122 | var | public | public var videoCache:Bool = false |
| PooToolsSource/Base/PTAppBaseConfig.swift:124 | var | public | public var tabNormalFont:UIFont = .systemFont(ofSize: 11) |
| PooToolsSource/Base/PTAppBaseConfig.swift:125 | var | public | public var tabSelectedFont:UIFont = .systemFont(ofSize: 11) |
| PooToolsSource/Base/PTAppBaseConfig.swift:126 | var | public | public var tabNormalColor:UIColor = .gray |
| PooToolsSource/Base/PTAppBaseConfig.swift:127 | var | public | public var tabSelectedColor:UIColor = .systemBlue |
| PooToolsSource/Base/PTAppBaseConfig.swift:128 | var | public | public var tabBadgeFont:UIFont = .systemFont(ofSize: 10) |
| PooToolsSource/Base/PTAppBaseConfig.swift:129 | var | public | public var tabBadgeBorderHeight:CGFloat = 1 |
| PooToolsSource/Base/PTAppBaseConfig.swift:130 | var | public | public var tabBadgeBorderColor:UIColor = .white |
| PooToolsSource/Base/PTAppBaseConfig.swift:131 | var | public | public var tabTopSpacing:CGFloat = 5 |
| PooToolsSource/Base/PTAppBaseConfig.swift:132 | var | public | public var tabBottomSpacing:CGFloat = 5 |
| PooToolsSource/Base/PTAppBaseConfig.swift:133 | var | public | public var tabContentSpacing:CGFloat = 2 |
| PooToolsSource/Base/PTAppBaseConfig.swift:134 | var | public | public var tab26BottomSpacing:CGFloat = 15 |
| PooToolsSource/Base/PTAppBaseConfig.swift:135 | var | public | public var tab26Mode:Bool = false |
| PooToolsSource/Base/PTAppBaseConfig.swift:136 | var | public | public var tabSelectedMetail:Bool = false |
| PooToolsSource/Base/PTAppBaseConfig.swift:140 | var | public | @nonobjc public var tabBarVisualStyle: PTVisualStyle = .automatic |
| PooToolsSource/Base/PTAppBaseConfig.swift:141 | var | public | public var tabSelectedMetailColor:UIColor = .lightGray |
| PooToolsSource/Base/PTAppBaseConfig.swift:142 | var | public | public var tabSelectedMetailLRSpacing:CGFloat = 5 |
| PooToolsSource/Base/PTAppBaseConfig.swift:143 | var | public | public var tabbarMetailMode:Bool = false |
| PooToolsSource/Base/PTAppBaseConfig.swift:144 | var | public | public var tabbarCenterMetail:Bool = false |
| PooToolsSource/Base/PTAppBaseConfig.swift:145 | var | public | public var tabbarCenterBGColor:UIColor = .clear |
| PooToolsSource/Base/PTAppBaseConfig.swift:146 | var | public | public var tabbarCenterInsideOffset:CGFloat = 0 |
| PooToolsSource/Base/PTAppBaseConfig.swift:147 | var | public | public var tabbarCenterName:String = "" |
| PooToolsSource/Base/PTAppBaseConfig.swift:148 | var | public | public var tabbarCenterNameFont:UIFont = .appfont(size: 10) |
| PooToolsSource/Base/PTAppBaseConfig.swift:149 | var | public | public var tabbarCenterNameColor:UIColor = .black |
| PooToolsSource/Base/PTAppBaseConfig.swift:150 | var | public | public var tabbarCenterNameContentSpacing:CGFloat = 2 |
| PooToolsSource/Base/PTAppBaseConfig.swift:151 | var | public | public var tabbarMiniSize:CGFloat = 56 |
| PooToolsSource/Base/PTAppBaseConfig.swift:152 | var | public | public var tabbarScrollEnabled:Bool = false |
| PooToolsSource/Base/PTAppBaseConfig.swift:153 | var | public | public var tabbarScrollOffset:CGFloat = 20 |
| PooToolsSource/Base/PTAppBaseConfig.swift:154 | var | public | public var tabbarCenterButtonSize: CGFloat = 64 |
| PooToolsSource/Base/PTAppBaseConfig.swift:155 | var | public | public var tabbarBar26LRSpacing:CGFloat = 24.adapter |
| PooToolsSource/Base/PTAppBaseConfig.swift:157 | var | public | public var tabbarRadius: CGFloat = 0 |
| PooToolsSource/Base/PTAppBaseConfig.swift:158 | var | public | public var tabbarTopLeft: CGFloat = 0 |
| PooToolsSource/Base/PTAppBaseConfig.swift:159 | var | public | public var tabbarTopRight: CGFloat = 0 |
| PooToolsSource/Base/PTAppBaseConfig.swift:160 | var | public | public var tabbarBottomLeft: CGFloat = 0 |
| PooToolsSource/Base/PTAppBaseConfig.swift:161 | var | public | public var tabbarBottomRight: CGFloat = 0 |
| PooToolsSource/Base/PTAppBaseConfig.swift:162 | var | public | public var tabbarCorner: UIRectCorner = .allCorners |
| PooToolsSource/Base/PTAppBaseConfig.swift:163 | var | public | public var tabbarCapsule: Bool = false |
| PooToolsSource/Base/PTAppBaseConfig.swift:164 | var | public | public var tabbarBorderWidth: CGFloat = 0 |
| PooToolsSource/Base/PTAppBaseConfig.swift:165 | var | public | public var tabbarBorderColor: UIColor = .clear |
| PooToolsSource/Base/PTAppBaseConfig.swift:166 | var | public | public var tabbarShowValueLabel: Bool = false |
| PooToolsSource/Base/PTAppBaseConfig.swift:167 | var | public | public var tabbarValueLabelFont: UIFont = .appfont(size: 10) |
| PooToolsSource/Base/PTAppBaseConfig.swift:168 | var | public | public var tabbarValueLabelColor: UIColor = .systemBlue |
| PooToolsSource/Base/PTAppBaseConfig.swift:170 | var | public | public var tabBarAccessoryHeight: CGFloat = 44 |
| PooToolsSource/Base/PTAppBaseConfig.swift:171 | var | public | public var tabBarAccessoryBottomSpacing: CGFloat = 10 |
| PooToolsSource/Base/PTAudioCache.swift:15 | typealias | public | public typealias FileDownloadProgress = @MainActor @Sendable (Int64, Int64, Double) -> Void |
| PooToolsSource/Base/PTAudioCache.swift:110 | func | public | public func cacheFileURL(for url: URL) -> URL { |
| PooToolsSource/Base/PTAudioCache.swift:122 | func | public | public func prepareLocalFile(for url: URL, progress: FileDownloadProgress? = nil, completion: @escaping @MainActor (URL?) -> Void) { |
| PooToolsSource/Base/PTAudioCache.swift:183 | func | public | public func fetchDuration(for url: URL,progress:FileDownloadProgress? = nil,completion: @escaping (Float, URL?) -> Void) { |
| PooToolsSource/Base/PTAudioCache.swift:223 | func | public | public func playerItem(for url: URL,progress:FileDownloadProgress? = nil,completion: @escaping (AVPlayerItem?) -> Void) { |
| PooToolsSource/Base/PTAudioCache.swift:234 | enum | public | public enum PTAudioTranscoder { |
| PooToolsSource/Base/PTBaseButton.swift:15 | class | open | open class PTBaseButton: UIButton { |
| PooToolsSource/Base/PTBaseButton.swift:45 | func | public | public func startLoading(indicatorColor: UIColor = .white) { |
| PooToolsSource/Base/PTBaseButton.swift:76 | func | public | public func stopLoading() { |
| PooToolsSource/Base/PTBaseCellOption.swift:13 | protocol | public | public protocol PTCellBindable: PTAnyCellBindable { |
| PooToolsSource/Base/PTBaseCellOption.swift:18 | protocol | public | public protocol PTAnyCellBindable { |
| PooToolsSource/Base/PTBaseCellOption.swift:35 | class | open | open class PTBaseNormalCell: UICollectionViewCell,@MainActor PTCellRegisterable { |
| PooToolsSource/Base/PTBaseCellOption.swift:37 | var | public | public var isStaticCell:Bool = false { |
| PooToolsSource/Base/PTBaseCellOption.swift:60 | class | open | open class func cellSize() -> CGSize { |
| PooToolsSource/Base/PTBaseCellOption.swift:65 | class | open | open class var reuseID: String { |
| PooToolsSource/Base/PTBaseCellOption.swift:70 | class | open | open class func cellIdentifier() -> String { |
| PooToolsSource/Base/PTBaseCellOption.swift:74 | class | open | open class func cellSizeByClass() -> NSNumber { |
| PooToolsSource/Base/PTBaseCellOption.swift:78 | class | open | open class func cellSizeValue() -> NSValue { |
| PooToolsSource/Base/PTBaseCellOption.swift:86 | class | public | public class PTSwipeAction:NSObject { |
| PooToolsSource/Base/PTBaseCellOption.swift:87 | var | public | public var name:String = "" |
| PooToolsSource/Base/PTBaseCellOption.swift:88 | var | public | public var nameColor:DynamicColor = .black |
| PooToolsSource/Base/PTBaseCellOption.swift:89 | var | public | public var nameFont:UIFont = .appfont(size: 14) |
| PooToolsSource/Base/PTBaseCellOption.swift:90 | var | public | public var image:Any? = nil |
| PooToolsSource/Base/PTBaseCellOption.swift:91 | var | public | public var imageSize:CGSize = .init(width: 24, height: 24) |
| PooToolsSource/Base/PTBaseCellOption.swift:92 | var | public | public var contentSpacing:CGFloat = 4 |
| PooToolsSource/Base/PTBaseCellOption.swift:93 | var | public | public var backgroundColor:DynamicColor = .clear |
| PooToolsSource/Base/PTBaseCellOption.swift:94 | var | public | public var handler:((PTActionLayoutButton)->Void)? = nil |
| PooToolsSource/Base/PTBaseCellOption.swift:96 | init | public | public init(name: String, |
| PooToolsSource/Base/PTBaseCellOption.swift:115 | class | open | open class PTBaseSwipeCell: PTBaseNormalCell { |
| PooToolsSource/Base/PTBaseCellOption.swift:116 | var | public | public var cellCanSwipe: Bool = false { |
| PooToolsSource/Base/PTBaseCellOption.swift:128 | let | public | public let contentContainer = UIView() |
| PooToolsSource/Base/PTBaseCellOption.swift:162 | func | public | public func configureLeftActions(_ actions: [PTSwipeAction]) { |
| PooToolsSource/Base/PTBaseCellOption.swift:170 | func | public | public func configureRightActions(_ actions: [PTSwipeAction]) { |
| PooToolsSource/Base/PTBaseCellOption.swift:179 | func | public | public func addButtons(_ actions: [PTSwipeAction], isLeft: Bool) { |
| PooToolsSource/Base/PTBaseCellOption.swift:330 | func | public | public func closeActions(animated: Bool) { |
| PooToolsSource/Base/PTBaseCellOption.swift:335 | func | public | public func resetSwipeActions() { |
| PooToolsSource/Base/PTBaseCellOption.swift:364 | func | public | public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, |
| PooToolsSource/Base/PTBaseCollectionReusableView.swift:16 | class | open | open class PTBaseCollectionReusableView: UICollectionReusableView { |
| PooToolsSource/Base/PTBaseCollectionReusableView.swift:32 | class | open | open class func cellSize() -> CGSize { |
| PooToolsSource/Base/PTBaseCollectionReusableView.swift:36 | class | open | open class func cellIdentifier() -> String { |
| PooToolsSource/Base/PTBaseCollectionReusableView.swift:40 | class | open | open class func cellSizeByClass() -> NSNumber { |
| PooToolsSource/Base/PTBaseCollectionReusableView.swift:44 | class | open | open class func cellSizeValue() -> NSValue { |
| PooToolsSource/Base/PTBaseDecorationFunction.swift:13 | class | open | open class PTBaseDecorationView: UICollectionReusableView { |
| PooToolsSource/Base/PTBaseDecorationFunction.swift:70 | func | public | public func configure(backgroundColor: UIColor, |
| PooToolsSource/Base/PTBaseMaskView.swift:16 | class | open | open class PTBaseMaskView: UIView { |
| PooToolsSource/Base/PTBaseMaskView.swift:18 | var | open | open var isMask : Bool = false |
| PooToolsSource/Base/PTBaseNavControl.swift:13 | class | open | open class PTBaseNavControl: UINavigationController { |
| PooToolsSource/Base/PTBaseNavControl.swift:45 | func | open | open func baseTraitCollectionDidChange(style:UIUserInterfaceStyle) { } |
| PooToolsSource/Base/PTBaseNavControl.swift:53 | func | open | @objc open func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask { |
| PooToolsSource/Base/PTBaseNavControl.swift:74 | func | public | @objc public func back() { |
| PooToolsSource/Base/PTBaseNavControl.swift:113 | class | public | public class func globalNavControl(nav:UINavigationController, |
| PooToolsSource/Base/PTBaseNavControl.swift:160 | class | public | public class func GobalNavControl(nav:UINavigationController, |
| PooToolsSource/Base/PTBaseTabBarViewController+Support.swift:16 | protocol | public | public protocol PTTabBarVisibilityProtocol { |
| PooToolsSource/Base/PTBaseTabBarViewController+Support.swift:29 | var | public | public var pt_prefersTabBarHidden: Bool { |
| PooToolsSource/Base/PTBaseTabBarViewController+Support.swift:41 | var | open | @objc open var pt_observedScrollView: UIScrollView? { |
| PooToolsSource/Base/PTBaseTabBarViewController+Support.swift:45 | var | public | public var pt_tabBarAccessoryView: UIView? { |
| PooToolsSource/Base/PTBaseTabBarViewController+Support.swift:77 | class | public | public class PTAccessoryContainerView: UIView { |
| PooToolsSource/Base/PTBaseTabBarViewController+SystemTabs.swift:17 | func | public | public func configTab(_ viewController: UIViewController, |
| PooToolsSource/Base/PTBaseTabBarViewController+SystemTabs.swift:34 | func | public | public func configTabGroup(_ viewController: UIViewController, |
| PooToolsSource/Base/PTBaseTabBarViewController+SystemTabs.swift:57 | func | open | open func tabBarController(_ tabBarController: UITabBarController, shouldSelectTab tab: UITab) -> Bool { |
| PooToolsSource/Base/PTBaseTabBarViewController+SystemTabs.swift:65 | func | open | open func tabBarController(_ tabBarController: UITabBarController, didSelectTab selectedTab: UITab, previousTab: UITab?) { |
| PooToolsSource/Base/PTBaseTabBarViewController+SystemTabs.swift:72 | func | open | open func tabBarControllerWillBeginEditing(_ tabBarController: UITabBarController) { |
| PooToolsSource/Base/PTBaseTabBarViewController+SystemTabs.swift:79 | func | open | open func tabBarControllerDidEndEditing(_ tabBarController: UITabBarController) { |
| PooToolsSource/Base/PTBaseTabBarViewController+SystemTabs.swift:87 | func | open | open func tabBarController(_ tabBarController: UITabBarController, displayOrderDidChangeFor group: UITabGroup) { |
| PooToolsSource/Base/PTBaseTabBarViewController.swift:14 | class | open | open class PTBaseTabBarViewController: UITabBarController { |
| PooToolsSource/Base/PTBaseTabBarViewController.swift:16 | var | public | public var ptCustomBar = PTTabBarView() |
| PooToolsSource/Base/PTBaseTabBarViewController.swift:18 | var | public | public var centerRaisedSet:Bool = false { |
| PooToolsSource/Base/PTBaseTabBarViewController.swift:28 | let | public | public let accessoryContainerView = PTAccessoryContainerView() |
| PooToolsSource/Base/PTBaseTabBarViewController.swift:55 | var | public | public var didScrollStateChange: ((_ isScrolled: Bool, _ offsetY: CGFloat) -> Void)? |
| PooToolsSource/Base/PTBaseTabBarViewController.swift:114 | func | public | public func configViewController(viewController: UIViewController, title: String) -> PTBaseNavControl { |
| PooToolsSource/Base/PTBaseTabBarViewController.swift:200 | func | open | open func configure(items: [PTTabBarItemConfig]) { |
| PooToolsSource/Base/PTBaseTabBarViewController.swift:410 | func | public | public func setTabBar(hidden: Bool, animated: Bool) { |
| PooToolsSource/Base/PTBaseTabBarViewController.swift:648 | func | public | public func refreshCurrentAccessoryViewIfNeeded() { |
| PooToolsSource/Base/PTBaseViewController+Navigation.swift:18 | class | open | open class PTNavTitleContainer: UIView { |
| PooToolsSource/Base/PTBaseViewController+Navigation.swift:32 | class | open | open class PTNavigationBarContainer: UIView { |
| PooToolsSource/Base/PTBaseViewController+Navigation.swift:45 | var | public | public var leftContainerWidth: CGFloat = 0 |
| PooToolsSource/Base/PTBaseViewController+Navigation.swift:46 | var | public | public var rightContainerWidth: CGFloat = 0 |
| PooToolsSource/Base/PTBaseViewController+Navigation.swift:56 | let | public | public let rightContainer:UIStackView = { |
| PooToolsSource/Base/PTBaseViewController+Navigation.swift:64 | let | public | public let titleContainer = UIView() |
| PooToolsSource/Base/PTBaseViewController+Navigation.swift:135 | func | public | public func apply(style: PTNavigationBarStyle) { |
| PooToolsSource/Base/PTBaseViewController+NavigationTypes.swift:29 | enum | public | public enum PTNavigationBarStyle: Equatable { |
| PooToolsSource/Base/PTBaseViewController.swift:16 | typealias | public | public typealias PTScreenShotImageHandle = (PTScreenShotActionType,UIImage) -> Void |
| PooToolsSource/Base/PTBaseViewController.swift:17 | typealias | public | public typealias PTScreenShotOnlyGetImageHandle = (UIImage?) -> Void |
| PooToolsSource/Base/PTBaseViewController.swift:19 | enum | public | public enum PTScreenShotActionType { |
| PooToolsSource/Base/PTBaseViewController.swift:23 | enum | public | @objc public enum VCStatusBarChangeStatusType : Int { |
| PooToolsSource/Base/PTBaseViewController.swift:30 | var | public | public var isConfigured = false // ✅ 新增 |
| PooToolsSource/Base/PTBaseViewController.swift:31 | var | public | public var leftView: [UIView] = [] |
| PooToolsSource/Base/PTBaseViewController.swift:32 | var | public | public var leftItemSpacing:CGFloat = 0 |
| PooToolsSource/Base/PTBaseViewController.swift:33 | var | public | public var rightViews: [UIView] = [] |
| PooToolsSource/Base/PTBaseViewController.swift:34 | var | public | public var rightItemSpacing:CGFloat = 0 |
| PooToolsSource/Base/PTBaseViewController.swift:35 | var | public | public var titleView: UIView? |
| PooToolsSource/Base/PTBaseViewController.swift:37 | var | public | public var titleViewFillSpace: Bool = true |
| PooToolsSource/Base/PTBaseViewController.swift:38 | var | public | public var navTitle:String = "" |
| PooToolsSource/Base/PTBaseViewController.swift:39 | var | public | public var barColorStyle:PTNavigationBarStyle = .transparent |
| PooToolsSource/Base/PTBaseViewController.swift:236 | var | public | public var tabBarHandler: ((UINavigationController, UIViewController, Bool, UIViewControllerTransitionCoordinator?) -> Void)? |
| PooToolsSource/Base/PTBaseViewController.swift:238 | func | public | public func installIfNeeded(in nav: UINavigationController) { |
| PooToolsSource/Base/PTBaseViewController.swift:257 | func | public | public func apply(style: PTNavigationBarStyle, in nav: UINavigationController) { |
| PooToolsSource/Base/PTBaseViewController.swift:284 | func | public | public func currentNavigationController(in scene: UIWindowScene) -> UINavigationController? { |
| PooToolsSource/Base/PTBaseViewController.swift:294 | func | public | public func currentViewController(in scene: UIWindowScene) -> UIViewController? { |
| PooToolsSource/Base/PTBaseViewController.swift:352 | func | public | public func setAlpha(_ alpha: CGFloat) { |
| PooToolsSource/Base/PTBaseViewController.swift:359 | func | public | public func bind(to nav: UINavigationController) { |
| PooToolsSource/Base/PTBaseViewController.swift:385 | func | public | public func item(for vc: UIViewController) -> PTNavBarItem { |
| PooToolsSource/Base/PTBaseViewController.swift:394 | func | public | public func update(item: PTNavBarItem, for vc: UIViewController) { |
| PooToolsSource/Base/PTBaseViewController.swift:412 | func | public | public func currentNavLargeTitleBarHeight() -> CGFloat { |
| PooToolsSource/Base/PTBaseViewController.swift:419 | func | public | public func currentNavBarHeight() -> CGFloat { |
| PooToolsSource/Base/PTBaseViewController.swift:430 | func | public | public func navigationController(_ navigationController: UINavigationController, |
| PooToolsSource/Base/PTBaseViewController.swift:647 | func | public | public func restoreIfNeeded(for vc: UIViewController) { |
| PooToolsSource/Base/PTBaseViewController.swift:665 | func | public | public func refreshCurrentNavBar() { |
| PooToolsSource/Base/PTBaseViewController.swift:767 | func | public | public func setLeftView(_ views: [UIView],spacing:CGFloat = 8) { |
| PooToolsSource/Base/PTBaseViewController.swift:806 | func | public | public func setRightViews(_ views: [UIView], spacing: CGFloat = 8) { |
| PooToolsSource/Base/PTBaseViewController.swift:845 | func | public | public func setTitleView(_ view: UIView?, fillSpace: Bool = false) { |
| PooToolsSource/Base/PTBaseViewController.swift:898 | class | open | open class PTBaseViewController: UIViewController { |
| PooToolsSource/Base/PTBaseViewController.swift:902 | func | open | open func prefersLargeTitle() -> Bool { |
| PooToolsSource/Base/PTBaseViewController.swift:906 | func | open | open func allowControlNavBar() -> Bool { |
| PooToolsSource/Base/PTBaseViewController.swift:910 | var | open | open var pt_Title:String? { |
| PooToolsSource/Base/PTBaseViewController.swift:924 | func | open | open func preferredNavigationBarStyle() -> PTNavigationBarStyle { |
| PooToolsSource/Base/PTBaseViewController.swift:998 | func | open | @MainActor open func prepareDefaultNavigationBarItem() { |
| PooToolsSource/Base/PTBaseViewController.swift:1068 | func | open | open func viewControllerOrientation(_ orientationMask: UIInterfaceOrientationMask) {} |
| PooToolsSource/Base/PTBaseViewController.swift:1074 | func | public | public func parseURLParameters(url: URL) -> [String: String]? { |
| PooToolsSource/Base/PTBaseViewController.swift:1079 | func | open | open func setCustomBackButton(image: UIImage?, |
| PooToolsSource/Base/PTBaseViewController.swift:1104 | func | open | open func setCustomBackButtonView(_ customView: UIView, |
| PooToolsSource/Base/PTBaseViewController.swift:1136 | func | open | open func setLeftButtons(views:[UIView], buttonSpacing: CGFloat = 10) { |
| PooToolsSource/Base/PTBaseViewController.swift:1150 | func | open | open func setCustomRightButtons(buttons: [UIView], buttonSpacing: CGFloat = 10) { |
| PooToolsSource/Base/PTBaseViewController.swift:1164 | func | open | open func setCustomTitleView(_ view: UIView? = nil, fillSpace: Bool = true) { |
| PooToolsSource/Base/PTBaseViewController.swift:1172 | func | open | open func updateNavigationBarBackground(scrollView: UIScrollView, changeOffset: CGFloat = 100, color: UIColor = .white) { |
| PooToolsSource/Base/PTBaseViewController.swift:1179 | func | open | open func setNavigationBarBackgroundAlpha(clear:Bool = false) { |
| PooToolsSource/Base/PTBaseViewController.swift:1204 | func | public | public func safePushViewController(_ vc: UIViewController, animated: Bool = true) { |
| PooToolsSource/Base/PTBaseViewController.swift:1215 | func | open | open func bindScrollView(_ scrollView: UIScrollView) { |
| PooToolsSource/Base/PTBaseViewController.swift:1219 | func | open | open func scrollViewDidScroll(_ scrollView: UIScrollView) { |
| PooToolsSource/Base/PTBaseViewController.swift:1223 | func | open | open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) { |
| PooToolsSource/Base/PTBaseViewController.swift:1314 | func | open | open func changeStatusBar(type:VCStatusBarChangeStatusType) { |
| PooToolsSource/Base/PTBaseViewController.swift:1326 | func | open | open func switchOrientation(isFullScreen:Bool) { |
| PooToolsSource/Base/PTBaseViewController.swift:1340 | func | open | open func baseTraitCollectionDidChange(style:UIUserInterfaceStyle) { } |
| PooToolsSource/Base/PTBaseViewController.swift:1342 | func | public | public func returnFrontVC(completion:PTActionTask? = nil) { |
| PooToolsSource/Base/PTBaseViewController.swift:1377 | func | public | public func registerScreenShotService() { |
| PooToolsSource/Base/PTBaseViewController.swift:1429 | var | public | public var emptyDataViewConfig:PTEmptyDataViewConfig? { |
| PooToolsSource/Base/PTBaseViewController.swift:1445 | func | public | public func showEmptyView(task: PTActionTask? = nil) { |
| PooToolsSource/Base/PTBaseViewController.swift:1454 | func | public | public func hideEmptyView(task: PTActionTask? = nil) { |
| PooToolsSource/Base/PTBaseViewController.swift:1459 | func | public | public func emptyViewLoading() { |
| PooToolsSource/Base/PTBaseViewController.swift:1467 | var | public | public var screenShotHandle:PTScreenShotOnlyGetImageHandle? { |
| PooToolsSource/Base/PTBaseViewController.swift:1479 | var | public | public var screenShotActionHandle:PTScreenShotImageHandle? { |
| PooToolsSource/Base/PTBaseViewController.swift:1527 | func | public | public func currentPresentToSheet(vc:UIViewController,overlayColor:UIColor = UIColor(white: 0, alpha: 0.25), sizes: [PTSheetSize] = [.intrinsic], options: PTSheetOptions? = nil) { |
| PooToolsSource/Base/PTBaseWebViewController.swift:19 | class | open | open class PTBaseWebViewController: PTBaseViewController { |
| PooToolsSource/Base/PTBaseWebViewController.swift:21 | var | public | public var vcDismiss:PTActionTask? |
| PooToolsSource/Base/PTBaseWebViewController.swift:23 | var | public | public var webHeight: ((CGFloat) -> Void)? |
| PooToolsSource/Base/PTBaseWebViewController.swift:24 | var | public | public var backImage:UIImage = UIColor.random.createImageWithColor().transformImage(size: CGSizeMake(24, 24)) |
| PooToolsSource/Base/PTBaseWebViewController.swift:26 | var | public | public var hiddenNav = false { |
| PooToolsSource/Base/PTBaseWebViewController.swift:87 | init | public | public init(showString:String = "") { |
| PooToolsSource/Base/PTBaseWebViewController.swift:130 | func | public | public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy { |
| PooToolsSource/Base/PTBaseWebViewController.swift:134 | func | public | public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy { |
| PooToolsSource/Base/PTBaseWebViewController.swift:139 | func | public | public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { |
| PooToolsSource/Base/PTBaseWebViewController.swift:143 | func | public | public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) { |
| PooToolsSource/Base/PTBaseWebViewController.swift:148 | func | public | public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { |
| PooToolsSource/Base/PTBaseWebViewController.swift:154 | func | public | public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { |
| PooToolsSource/Base/PTBaseWebViewController.swift:159 | func | public | public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { |
| PooToolsSource/Base/PTCollectionView.swift:36 | typealias | public | public typealias PTDataSource = UICollectionViewDiffableDataSource<PTSection, PTRows> |
| PooToolsSource/Base/PTCollectionView.swift:37 | typealias | public | public typealias PTSnapshot = NSDiffableDataSourceSnapshot<PTSection, PTRows> |
| PooToolsSource/Base/PTCollectionView.swift:158 | class | public | public class PTCollectionView: UIView { |
| PooToolsSource/Base/PTCollectionView.swift:329 | var | open | open var headerInCollection: PTReusableViewHandler? |
| PooToolsSource/Base/PTCollectionView.swift:330 | var | open | open var footerInCollection: PTReusableViewHandler? |
| PooToolsSource/Base/PTCollectionView.swift:331 | var | open | open var cellInCollection: PTCellInCollectionHandler? |
| PooToolsSource/Base/PTCollectionView.swift:334 | var | open | open var collectionDidSelect: PTCellDidSelectedHandler? |
| PooToolsSource/Base/PTCollectionView.swift:335 | var | open | open var collectionWillDisplay: PTCellDisplayHandler? |
| PooToolsSource/Base/PTCollectionView.swift:336 | var | open | open var collectionDidEndDisplay: PTCellDisplayHandler? |
| PooToolsSource/Base/PTCollectionView.swift:339 | var | open | open var collectionWillBeginDecelerating: PTCollectionViewScrollHandler? |
| PooToolsSource/Base/PTCollectionView.swift:340 | var | open | open var collectionViewDidScroll: PTCollectionViewScrollHandler? |
| PooToolsSource/Base/PTCollectionView.swift:341 | var | open | open var collectionWillBeginDragging: PTCollectionViewScrollHandler? |
| PooToolsSource/Base/PTCollectionView.swift:342 | var | open | open var collectionDidEndDragging: ((UICollectionView,Bool) -> Void)? |
| PooToolsSource/Base/PTCollectionView.swift:343 | var | open | open var collectionDidEndDecelerating: PTCollectionViewScrollHandler? |
| PooToolsSource/Base/PTCollectionView.swift:344 | var | open | open var collectionDidEndScrollingAnimation: PTCollectionViewScrollHandler? |
| PooToolsSource/Base/PTCollectionView.swift:345 | var | open | open var collectionDidScrolltoTop: PTCollectionViewScrollHandler? |
| PooToolsSource/Base/PTCollectionView.swift:346 | var | open | open var collectionWillEndDraging: ((_ scrollView: UIScrollView, _ velocity: CGPoint, _ targetContentOffset: UnsafeMutablePointer<CGPoint>) -> Void)? |
| PooToolsSource/Base/PTCollectionView.swift:356 | var | open | open var orthogonalDidScroll: ((Int, CGPoint) -> Void)? |
| PooToolsSource/Base/PTCollectionView.swift:358 | var | open | open var orthogonalPageDidChange: ((Int, Int) -> Void)? |
| PooToolsSource/Base/PTCollectionView.swift:363 | var | open | open var collectionWillReachBottomTask: PTActionTask? |
| PooToolsSource/Base/PTCollectionView.swift:366 | var | open | open var headerRefreshTask: PTActionTask? |
| PooToolsSource/Base/PTCollectionView.swift:368 | var | open | open var footRefreshTask: PTActionTask? |
| PooToolsSource/Base/PTCollectionView.swift:371 | var | open | open var waterFallLayout: ((Int, AnyObject) -> CGFloat)? |
| PooToolsSource/Base/PTCollectionView.swift:372 | var | open | open var customerLayout: ((Int,PTSection) -> NSCollectionLayoutGroup)? |
| PooToolsSource/Base/PTCollectionView.swift:373 | var | open | open var customerReuseViews: ((Int,PTSection) -> [NSCollectionLayoutBoundarySupplementaryItem])? |
| PooToolsSource/Base/PTCollectionView.swift:376 | var | open | open var emptyTap: ((UIView?) -> Void)? |
| PooToolsSource/Base/PTCollectionView.swift:377 | var | open | open var emptyButtonTap: ((UIView?) -> Void)? |
| PooToolsSource/Base/PTCollectionView.swift:380 | var | open | open var decorationInCollectionView: PTDecorationInCollectionHandler? |
| PooToolsSource/Base/PTCollectionView.swift:383 | var | open | open var decorationViewReset: PTViewInDecorationResetHandler? |
| PooToolsSource/Base/PTCollectionView.swift:386 | var | open | open var decorationCustomLayoutInsetReset: ((Int,PTSection) -> NSDirectionalEdgeInsets)? |
| PooToolsSource/Base/PTCollectionView.swift:388 | var | public | public var contentCollectionView:UICollectionView { collectionView } |
| PooToolsSource/Base/PTCollectionView.swift:389 | var | public | public var collectionSectionDatas:[PTSection] { diffableDataSource.snapshot().sectionIdentifiers } |
| PooToolsSource/Base/PTCollectionView.swift:392 | var | open | open var indexPathSwipe: PTCollectionViewCanSwipeHandler? |
| PooToolsSource/Base/PTCollectionView.swift:393 | var | open | open var swipeLeftHandler :PTCollectionViewSwipeHandler? |
| PooToolsSource/Base/PTCollectionView.swift:394 | var | open | open var swipeRightHandler: PTCollectionViewSwipeHandler? |
| PooToolsSource/Base/PTCollectionView.swift:396 | var | open | open var itemMoveTo: ((_ cView:UICollectionView,_ move:IndexPath,_ to:IndexPath) -> Void)? |
| PooToolsSource/Base/PTCollectionView.swift:398 | var | open | open var forceController: ((_ collectionView:UICollectionView,_ indexPath:IndexPath,_ sectionModel:PTSection) -> UIViewController?)? |
| PooToolsSource/Base/PTCollectionView.swift:399 | var | open | open var forceActions: ((_ collectionView:UICollectionView,_ indexPath:IndexPath,_ sectionModel:PTSection) -> [UIAction]?)? |
| PooToolsSource/Base/PTCollectionView.swift:401 | var | open | open var collectionUpdateError: PTCollectionViewUpdateErrorHandler? |
| PooToolsSource/Base/PTCollectionView.swift:403 | var | public | public var viewConfig: PTCollectionViewConfig! { |
| PooToolsSource/Base/PTCollectionView.swift:457 | init | public | public init(viewConfig: PTCollectionViewConfig!) { |
| PooToolsSource/Base/PTCollectionView.swift:536 | func | public | public func showSkeleton(itemCount: Int? = nil) { |
| PooToolsSource/Base/PTCollectionView.swift:547 | func | public | public func hideSkeleton() { |
| PooToolsSource/Base/PTCollectionView.swift:757 | func | public | public func segmentScrolView() -> UIScrollView { |
| PooToolsSource/Base/PTCollectionView.swift:762 | func | public | public func visibleCells() -> [UICollectionViewCell] { |
| PooToolsSource/Base/PTCollectionView.swift:769 | func | public | public func scrolToItem(indexPath:IndexPath,position:UICollectionView.ScrollPosition) { |
| PooToolsSource/Base/PTCollectionView.swift:775 | func | public | public func mtSelectItem(indexPath:IndexPath,animated:Bool,scrollPosition:UICollectionView.ScrollPosition) { |
| PooToolsSource/Base/PTCollectionView.swift:783 | func | public | public func cornerPosition(row: Int, count: Int) -> CornerPosition { |
| PooToolsSource/Base/PTCollectionView.swift:790 | func | public | public func hideIndicator() { |
| PooToolsSource/Base/PTCollectionView.swift:796 | func | public | public func clearLayoutCaches() { |
| PooToolsSource/Base/PTCollectionView.swift:811 | func | public | public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) { |
| PooToolsSource/Base/PTCollectionView.swift:816 | func | public | public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) { |
| PooToolsSource/Base/PTCollectionView.swift:821 | func | public | public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) { |
| PooToolsSource/Base/PTCollectionView.swift:846 | func | public | public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) { |
| PooToolsSource/Base/PTCollectionView.swift:865 | func | public | public func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) { |
| PooToolsSource/Base/PTCollectionView.swift:869 | func | public | public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? { |
| PooToolsSource/Base/PTCollectionView.swift:882 | func | public | public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) { |
| PooToolsSource/Base/PTCollectionView.swift:887 | func | public | public func scrollViewDidScroll(_ scrollView: UIScrollView) { |
| PooToolsSource/Base/PTCollectionView.swift:894 | func | public | public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { |
| PooToolsSource/Base/PTCollectionView.swift:899 | func | public | public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) { |
| PooToolsSource/Base/PTCollectionView.swift:905 | func | public | public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) { |
| PooToolsSource/Base/PTCollectionView.swift:910 | func | public | public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { |
| PooToolsSource/Base/PTCollectionView.swift:916 | func | public | public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) { |
| PooToolsSource/Base/PTCollectionView.swift:921 | func | public | public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) { |
| PooToolsSource/Base/PTCollectionView.swift:931 | func | public | public func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] { |
| PooToolsSource/Base/PTCollectionView.swift:949 | func | public | public func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal { |
| PooToolsSource/Base/PTCollectionView.swift:959 | func | public | public func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) { |
| PooToolsSource/Base/PTCollectionView.swift:1040 | func | public | public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) { |
| PooToolsSource/Base/PTCollectionView.swift:1048 | func | public | public func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) { |
| PooToolsSource/Base/PTCollectionView.swift:1364 | func | public | @MainActor public func showCollectionDetail(collectionData:[PTSection], |
| PooToolsSource/Base/PTCollectionView.swift:1409 | func | public | public func clearAllData(finishTask:PTCollectionCallback? = nil) { |
| PooToolsSource/Base/PTCollectionView.swift:1433 | func | public | public func insertRows(_ rows: [PTRows], at indexPath: IndexPath, completion: PTActionTask? = nil) { |
| PooToolsSource/Base/PTCollectionView.swift:1488 | func | public | public func insertRows(_ rows:[PTRows],section:Int,completion:PTActionTask? = nil) { |
| PooToolsSource/Base/PTCollectionView.swift:1518 | func | public | public func insertSection(_ sections:[PTSection], afterIndex:Int? = nil,completion:PTActionTask? = nil) { |
| PooToolsSource/Base/PTCollectionView.swift:1566 | func | public | public func deleteRows(_ rows: [PTRows], from section: Int, completion: PTActionTask? = nil) { |
| PooToolsSource/Base/PTCollectionView.swift:1602 | func | public | public func deleteSectionsRows(_ rowsMap: [Int: [PTRows]], completion: PTActionTask? = nil) { |
| PooToolsSource/Base/PTCollectionView.swift:1652 | func | public | public func deleteSections(_ sections: [PTSection], completion: PTActionTask? = nil) { |
| PooToolsSource/Base/PTCollectionView.swift:2012 | func | public | public func hideEmptyLoading(task: PTActionTask?) { |
| PooToolsSource/Base/PTCollectionView.swift:2016 | func | public | public func showEmptyLoading() { |
| PooToolsSource/Base/PTCollectionView.swift:2066 | func | public | public func reloadEmptyConfig() { |
| PooToolsSource/Base/PTCollectionView.swift:2075 | func | public | public func endRefresh() { |
| PooToolsSource/Base/PTCollectionView.swift:2079 | func | public | public func footerRefreshNoMore () { |
| PooToolsSource/Base/PTCollectionView.swift:2084 | func | public | public func footerRefreshReset() { |
| PooToolsSource/Base/PTCollectionView.swift:2092 | func | public | public func registerHeaderIdsNClasss(ids:[String],viewClass:AnyClass,kind:String) { |
| PooToolsSource/Base/PTCollectionView.swift:2096 | func | public | public func registerClassCells(classs:[String:AnyClass]) { |
| PooToolsSource/Base/PTCollectionView.swift:2100 | func | public | public func registerNibCells(nib:[String:String]) { |
| PooToolsSource/Base/PTCollectionView.swift:2104 | func | public | public func registerSupplementaryView(classs:[String:AnyClass],kind:String) { |
| PooToolsSource/Base/PTCollectionView.swift:2110 | func | public | public func reloadSections(at indexes: [Int], animated: Bool = true, completion: PTActionTask? = nil) { |
| PooToolsSource/Base/PTCollectionView.swift:2136 | func | public | public func reloadRows(_ rows: [PTRows], in section: Int, completion: PTActionTask? = nil) { |
| PooToolsSource/Base/PTCollectionView.swift:2171 | func | public | public func reloadSectionsRows(_ rowsMap: [Int: [PTRows]], completion: PTActionTask? = nil) { |
| PooToolsSource/Base/PTCollectionView.swift:2218 | func | public | public func reloadAllData(animated: Bool = true, completion: PTActionTask? = nil) { |
| PooToolsSource/Base/PTCollectionView.swift:2253 | func | public | public func softReloadAllData(animated: Bool = false, completion: PTActionTask? = nil) { |
| PooToolsSource/Base/PTCollectionView.swift:2271 | func | public | public func getRow(at indexPath: IndexPath) -> PTRows? { |
| PooToolsSource/Base/PTCollectionView.swift:2275 | func | public | public func getRows(at indexPaths: [IndexPath]) -> [PTRows] { |
| PooToolsSource/Base/PTCollectionView.swift:2279 | func | public | public func getRow(by diffId: String) -> PTRows? { |
| PooToolsSource/Base/PTCollectionView.swift:2284 | func | public | public func getAllRows(in section: Int) -> [PTRows] { |
| PooToolsSource/Base/PTCollectionView.swift:2292 | func | public | public func getSectionRowsMap(from indexPaths: [IndexPath]) -> [Int: [PTRows]] { |
| PooToolsSource/Base/PTCollectionView.swift:2302 | func | public | public func getSectionIndex(byHeaderID headerID: String) -> Int? { |
| PooToolsSource/Base/PTCollectionViewTypes.swift:15 | class | public | public class PTLRUCache<Key: Hashable & Sendable, Value: AnyObject> { |
| PooToolsSource/Base/PTCollectionViewTypes.swift:18 | init | public | public init(countLimit: Int = 1000) { |
| PooToolsSource/Base/PTCollectionViewTypes.swift:22 | func | public | public func set(_ value: Value, forKey key: Key) { |
| PooToolsSource/Base/PTCollectionViewTypes.swift:26 | func | public | public func get(forKey key: Key) -> Value? { |
| PooToolsSource/Base/PTCollectionViewTypes.swift:30 | func | public | public func remove(forKey key: Key) { |
| PooToolsSource/Base/PTCollectionViewTypes.swift:34 | func | public | public func removeAll() { |
| PooToolsSource/Base/PTCollectionViewTypes.swift:56 | typealias | public | public typealias PTCollectionCallback = @MainActor (UICollectionView) -> Void |
| PooToolsSource/Base/PTCollectionViewTypes.swift:59 | enum | public | public enum PTCollectionViewUpdateError: Error, Equatable, LocalizedError, Sendable { |
| PooToolsSource/Base/PTCollectionViewTypes.swift:65 | var | public | public var errorDescription: String? { |
| PooToolsSource/Base/PTCollectionViewTypes.swift:79 | typealias | public | public typealias PTCollectionViewUpdateErrorHandler = @MainActor (PTCollectionViewUpdateError) -> Void |
| PooToolsSource/Base/PTCollectionViewTypes.swift:86 | init | public | public init() {} |
| PooToolsSource/Base/PTCollectionViewTypes.swift:88 | func | public | public func validationError(for sections: [PTSection], |
| PooToolsSource/Base/PTCollectionViewTypes.swift:110 | func | public | public func validationError(for rows: [PTRows], |
| PooToolsSource/Base/PTCollectionViewTypes.swift:121 | func | public | public func section(at index: Int, in snapshot: PTSnapshot) -> PTSection? { |
| PooToolsSource/Base/PTCollectionViewTypes.swift:126 | func | public | public func row(at indexPath: IndexPath, in snapshot: PTSnapshot) -> PTRows? { |
| PooToolsSource/Base/PTCollectionViewTypes.swift:222 | enum | public | @objc public enum PTCollectionViewType: Int { |
| PooToolsSource/Base/PTCollectionViewTypes.swift:227 | enum | public | @objc public enum PTCollectionViewDecorationItemsType: Int { |
| PooToolsSource/Base/PTCollectionViewTypes.swift:231 | class | public | @objc public class PTDecorationItemModel: NSObject { |
| PooToolsSource/Base/PTCollectionViewTypes.swift:233 | var | open | open var decorationClass: AnyClass! |
| PooToolsSource/Base/PTCollectionViewTypes.swift:235 | var | open | open var decorationID: String! |
| PooToolsSource/Base/PTCollectionViewTypes.swift:238 | enum | public | @objc public enum PTCollectionEmptyViewSet: Int { |
| PooToolsSource/Base/PTCollectionViewTypes.swift:248 | typealias | public | public typealias PTReusableViewHandler = @MainActor (_ kind: String,_ collectionView:UICollectionView,_ sectionModel:PTSection,_ indexPath: IndexPath) -> UICollectionReusableView? |
| PooToolsSource/Base/PTCollectionViewTypes.swift:251 | typealias | public | public typealias PTCellInCollectionHandler = @MainActor (_ collectionView:UICollectionView,_ sectionModel:PTSection,_ indexPath:IndexPath) -> UICollectionViewCell? |
| PooToolsSource/Base/PTCollectionViewTypes.swift:254 | typealias | public | public typealias PTCellDidSelectedHandler = @MainActor (_ collectionView:UICollectionView,_ sectionModel:PTSection,_ indexPath:IndexPath) -> Void |
| PooToolsSource/Base/PTCollectionViewTypes.swift:257 | typealias | public | public typealias PTCellDisplayHandler = @MainActor (_ collectionView:UICollectionView,_ cell:UICollectionViewCell,_ sectionModel:PTSection,_ indexPath:IndexPath) -> Void |
| PooToolsSource/Base/PTCollectionViewTypes.swift:260 | typealias | public | public typealias PTCollectionViewScrollHandler = @MainActor (_ collectionView:UICollectionView) -> Void |
| PooToolsSource/Base/PTCollectionViewTypes.swift:263 | typealias | public | public typealias PTCollectionViewSwipeHandler = @MainActor (_ collectionView:UICollectionView,_ sectionModel:PTSection,_ indexPath:IndexPath) -> [PTSwipeAction] |
| PooToolsSource/Base/PTCollectionViewTypes.swift:265 | typealias | public | public typealias PTCollectionViewCanSwipeHandler = @MainActor (_ sectionModel:PTSection,_ indexPath:IndexPath) -> Bool |
| PooToolsSource/Base/PTCollectionViewTypes.swift:267 | typealias | public | public typealias PTDecorationInCollectionHandler = @MainActor (_ index:Int,_ sectionModel:PTSection) -> [NSCollectionLayoutDecorationItem] |
| PooToolsSource/Base/PTCollectionViewTypes.swift:269 | typealias | public | public typealias PTViewInDecorationResetHandler = @MainActor (_ collectionView: UICollectionView, _ view: UICollectionReusableView, _ elementKind: String, _ indexPath: IndexPath,_ sectionModel: PTSection) -> Void |
| PooToolsSource/Base/PTCollectionViewTypes.swift:274 | class | public | public class PTCollectionViewConfig: NSObject { |
| PooToolsSource/Base/PTCollectionViewTypes.swift:276 | var | open | open var showsVerticalScrollIndicator: Bool = true |
| PooToolsSource/Base/PTCollectionViewTypes.swift:278 | var | open | open var showsHorizontalScrollIndicator: Bool = true |
| PooToolsSource/Base/PTCollectionViewTypes.swift:280 | var | open | open var viewType: PTCollectionViewType = .Normal |
| PooToolsSource/Base/PTCollectionViewTypes.swift:282 | var | open | open var rowCount: Int = 3 |
| PooToolsSource/Base/PTCollectionViewTypes.swift:284 | var | open | open var itemHeight: CGFloat = PTAppBaseConfig.share.baseCellHeight |
| PooToolsSource/Base/PTCollectionViewTypes.swift:286 | var | open | open var itemWidth: CGFloat = 100 |
| PooToolsSource/Base/PTCollectionViewTypes.swift:288 | var | open | open var itemOriginalX: CGFloat = 0 |
| PooToolsSource/Base/PTCollectionViewTypes.swift:290 | var | open | open var contentTopSpace: CGFloat = 0 |
| PooToolsSource/Base/PTCollectionViewTypes.swift:292 | var | open | open var contentBottomSpace: CGFloat = 0 |
| PooToolsSource/Base/PTCollectionViewTypes.swift:294 | var | open | open var cellLeadingSpace: CGFloat = 0 |
| PooToolsSource/Base/PTCollectionViewTypes.swift:296 | var | open | open var cellTrailingSpace: CGFloat = 0 |
| PooToolsSource/Base/PTCollectionViewTypes.swift:298 | var | open | open var tagCellContentSpace: CGFloat = 20 |
| PooToolsSource/Base/PTCollectionViewTypes.swift:300 | var | open | open var topRefresh: Bool = false |
| PooToolsSource/Base/PTCollectionViewTypes.swift:302 | var | open | open var footerRefresh: Bool = false |
| PooToolsSource/Base/PTCollectionViewTypes.swift:303 | var | open | open var footerRefreshTextColor: UIColor = .white |
| PooToolsSource/Base/PTCollectionViewTypes.swift:304 | var | open | open var footerRefreshTextFont: UIFont = .appfont(size: 14) |
| PooToolsSource/Base/PTCollectionViewTypes.swift:305 | var | open | open var footerRefreshIdle: String = "" |
| PooToolsSource/Base/PTCollectionViewTypes.swift:306 | var | open | open var footerRefreshPulling: String = "鬆開即可刷新" |
| PooToolsSource/Base/PTCollectionViewTypes.swift:307 | var | open | open var footerRefreshRefreshing: String = "正在刷新中" |
| PooToolsSource/Base/PTCollectionViewTypes.swift:308 | var | open | open var footerRefreshWillRefresh: String = "即將刷新" |
| PooToolsSource/Base/PTCollectionViewTypes.swift:309 | var | open | open var footerRefreshNoMoreData: String = "已經全部加載完畢" |
| PooToolsSource/Base/PTCollectionViewTypes.swift:310 | var | open | open var triggerAutomaticallyRefreshPercent: CGFloat = 0.5 |
| PooToolsSource/Base/PTCollectionViewTypes.swift:311 | var | open | open var isAutomaticallyRefresh: Bool = true |
| PooToolsSource/Base/PTCollectionViewTypes.swift:312 | var | open | open var ignoredScrollViewContentInsetBottom:CGFloat = 0 |
| PooToolsSource/Base/PTCollectionViewTypes.swift:314 | var | open | open var sectionEdges: NSDirectionalEdgeInsets = .zero |
| PooToolsSource/Base/PTCollectionViewTypes.swift:316 | var | open | open var headerWidthOffset: CGFloat = 0 |
| PooToolsSource/Base/PTCollectionViewTypes.swift:318 | var | open | open var footerWidthOffset: CGFloat = 0 |
| PooToolsSource/Base/PTCollectionViewTypes.swift:320 | var | open | open var showEmptyAlert: Bool = false |
| PooToolsSource/Base/PTCollectionViewTypes.swift:322 | var | open | open var emptyViewConfig: PTEmptyDataViewConfig? |
| PooToolsSource/Base/PTCollectionViewTypes.swift:324 | var | open | open var emptyShowType: PTCollectionEmptyViewSet = .Auto |
| PooToolsSource/Base/PTCollectionViewTypes.swift:326 | var | open | open var decorationItemsType: PTCollectionViewDecorationItemsType = .NoItems |
| PooToolsSource/Base/PTCollectionViewTypes.swift:328 | var | open | open var decorationItemsEdges: NSDirectionalEdgeInsets = .zero |
| PooToolsSource/Base/PTCollectionViewTypes.swift:330 | var | open | open var decorationModel: [PTDecorationItemModel]? |
| PooToolsSource/Base/PTCollectionViewTypes.swift:332 | var | open | open var collectionViewBehavior: UICollectionLayoutSectionOrthogonalScrollingBehavior = .continuous |
| PooToolsSource/Base/PTCollectionViewTypes.swift:334 | var | open | open var customReuseViews: Bool = false |
| PooToolsSource/Base/PTCollectionViewTypes.swift:336 | var | open | open var refreshWithoutAnimation: Bool = false |
| PooToolsSource/Base/PTCollectionViewTypes.swift:338 | var | open | open var sideIndexTitles: [String]? |
| PooToolsSource/Base/PTCollectionViewTypes.swift:340 | var | open | open var indexConfig: PTCollectionIndexViewConfiguration? |
| PooToolsSource/Base/PTCollectionViewTypes.swift:342 | var | open | open var canMoveItem: Bool = false |
| PooToolsSource/Base/PTCollectionViewTypes.swift:345 | var | open | open var alwaysBounceHorizontal: Bool = false |
| PooToolsSource/Base/PTCollectionViewTypes.swift:346 | var | open | open var alwaysBounceVertical: Bool = true |
| PooToolsSource/Base/PTCollectionViewTypes.swift:347 | var | open | open var contentOffSetZero: Bool = false |
| PooToolsSource/Base/PTCollectionViewTypes.swift:352 | var | open | open var viewForPhoto: Bool = false |
| PooToolsSource/Base/PTCollectionViewTypes.swift:353 | var | open | open var previewImageSize: CGSize = CGSizeMake(105, 105) |
| PooToolsSource/Base/PTCollectionViewTypes.swift:356 | var | open | open var pinHeaderToVisibleBounds: Bool = false |
| PooToolsSource/Base/PTCollectionViewTypes.swift:358 | var | open | open var pinFooterToVisibleBounds: Bool = false |
| PooToolsSource/Base/PTCollectionViewTypes.swift:362 | var | open | open var enableSmartPrefetch: Bool = false |
| PooToolsSource/Base/PTCollectionViewTypes.swift:364 | var | open | open var prefetchThreshold: Int = 5 |
| PooToolsSource/Base/PTCollectionViewTypes.swift:366 | var | open | open var skeletonItemCount: Int = 6 |
| PooToolsSource/Base/PTCollectionViewTypes.swift:368 | var | open | open var skeletonCornerRadius: CGFloat = 8 |
| PooToolsSource/Base/PTCollectionViewTypes.swift:371 | class | public | public class PTCollectionIndexViewConfiguration: NSObject { |
| PooToolsSource/Base/PTCollectionViewTypes.swift:373 | var | open | open var itemSize: CGSize = CGSize(width: 15, height: 15) |
| PooToolsSource/Base/PTCollectionViewTypes.swift:375 | var | open | open var itemSpacing: CGFloat = 0 |
| PooToolsSource/Base/PTCollectionViewTypes.swift:377 | var | open | open var itemBackgroundColor: UIColor = UIColor.clear |
| PooToolsSource/Base/PTCollectionViewTypes.swift:379 | var | open | open var itemTextColor: UIColor = UIColor.darkText |
| PooToolsSource/Base/PTCollectionViewTypes.swift:381 | var | open | open var itemSelectedBackgroundColor: UIColor = UIColor.lightGray |
| PooToolsSource/Base/PTCollectionViewTypes.swift:383 | var | open | open var itemSelectedTextColor: UIColor = UIColor.white |
| PooToolsSource/Base/PTCollectionViewTypes.swift:385 | var | open | open var indicatorRadius: CGFloat = 30 |
| PooToolsSource/Base/PTCollectionViewTypes.swift:387 | var | open | open var indicatorBackgroundColor: UIColor = UIColor.lightGray |
| PooToolsSource/Base/PTCollectionViewTypes.swift:389 | var | open | open var indicatorTextColor: UIColor = UIColor.white |
| PooToolsSource/Base/PTCollectionViewTypes.swift:391 | var | open | open var indexViewBackgroundColor: UIColor = .clear |
| PooToolsSource/Base/PTCollectionViewTypes.swift:393 | var | open | open var indexViewFont: UIFont = .appfont(size: 12) |
| PooToolsSource/Base/PTCollectionViewTypes.swift:395 | var | open | open var indexViewHudFont: UIFont = .appfont(size: 18) |
| PooToolsSource/Base/PTCollectionViewTypes.swift:397 | var | open | open var containerTopOffset:CGFloat = 0 |
| PooToolsSource/Base/PTCollectionViewTypes.swift:399 | var | open | open var containerBottomOffset:CGFloat = 0 |
| PooToolsSource/Base/PTCollectionViewTypes.swift:401 | var | open | open var indexContainerRightOffset:CGFloat = 0 |
| PooToolsSource/Base/PTCollectionViewTypes.swift:404 | class | open | open class PTBaseCollectionView: UICollectionView { |
| PooToolsSource/Base/PTCollectionViewTypes.swift:406 | var | public | public var contentOffSetZero: Bool = false |
| PooToolsSource/Base/PTCollectionViewTypes.swift:439 | enum | public | public enum PTDiffAnimation { |
| PooToolsSource/Base/PTCollectionViewTypes.swift:450 | enum | public | public enum CornerPosition { |
| PooToolsSource/Base/PTColorPickerContainerViewController.swift:13 | class | open | open class PTColorPickerContainerViewController: PTBaseViewController { |
| PooToolsSource/Base/PTColorPickerContainerViewController.swift:19 | let | public | public let picker = UIColorPickerViewController() |
| PooToolsSource/Base/PTColorPickerContainerViewController.swift:21 | var | public | public var selectedColorCallback:((UIColor)->Void)? |
| PooToolsSource/Base/PTColorPickerContainerViewController.swift:22 | var | public | public var viewDismiss:PTActionTask? |
| PooToolsSource/Base/PTColorPickerContainerViewController.swift:76 | func | public | public func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) { |
| PooToolsSource/Base/PTEmptyDataSet.swift:28 | var | public | public var configureEmptyDataSetView: ((PTEmptyDataSetView) -> Void)? { |
| PooToolsSource/Base/PTEmptyDataSet.swift:41 | var | public | public var emptyDataSetSource: PTEmptyDataSetSource? { |
| PooToolsSource/Base/PTEmptyDataSet.swift:53 | var | public | public var emptyDataSetDelegate: PTEmptyDataSetDelegate? { |
| PooToolsSource/Base/PTEmptyDataSet.swift:65 | var | public | public var isEmptyDataSetVisible: Bool { |
| PooToolsSource/Base/PTEmptyDataSet.swift:74 | func | public | public func emptyDataSetView(_ closure: @escaping (PTEmptyDataSetView) -> Void) { |
| PooToolsSource/Base/PTEmptyDataSet.swift:158 | func | public | public func reloadEmptyDataSet() { |
| PooToolsSource/Base/PTEmptyDataSetDelegate.swift:15 | protocol | public | public protocol PTEmptyDataSetDelegate: AnyObject { // 🌟 优化2：必须继承 AnyObject，让遵守者只能是 Class，以便能够使用 weak 关键字防止内存泄漏 |
| PooToolsSource/Base/PTEmptyDataSetSource.swift:15 | protocol | public | public protocol PTEmptyDataSetSource: AnyObject { // 🌟 优化2：必须继承 AnyObject，防止循环引用 |
| PooToolsSource/Base/PTEmptyDataSetView.swift:14 | class | public | public class PTEmptyDataSetView: UIView { |
| PooToolsSource/Base/PTEmptyDataSetView.swift:221 | func | public | public func titleLabelString(_ attributedString: NSAttributedString?) -> Self { |
| PooToolsSource/Base/PTEmptyDataSetView.swift:230 | func | public | public func detailLabelString(_ attributedString: NSAttributedString?) -> Self { |
| PooToolsSource/Base/PTEmptyDataSetView.swift:238 | func | public | public func image(_ image: UIImage?) -> Self { |
| PooToolsSource/Base/PTEmptyDataSetView.swift:246 | func | public | public func imageTintColor(_ imageTintColor: UIColor?) -> Self { |
| PooToolsSource/Base/PTEmptyDataSetView.swift:253 | func | public | public func imageAnimation(_ imageAnimation: CAAnimation?) -> Self { |
| PooToolsSource/Base/PTEmptyDataSetView.swift:262 | func | public | public func buttonTitle(_ buttonTitle: NSAttributedString?, for state: UIControl.State) -> Self { |
| PooToolsSource/Base/PTEmptyDataSetView.swift:270 | func | public | public func buttonImage(_ buttonImage: UIImage?, for state: UIControl.State) -> Self { |
| PooToolsSource/Base/PTEmptyDataSetView.swift:278 | func | public | public func buttonBackgroundImage(_ buttonBackgroundImage: UIImage?, for state: UIControl.State) -> Self { |
| PooToolsSource/Base/PTEmptyDataSetView.swift:292 | func | public | public func dataSetBackgroundColor(_ backgroundColor: UIColor?) -> Self { |
| PooToolsSource/Base/PTEmptyDataSetView.swift:299 | func | public | public func customView(_ customView: UIView?) -> Self { |
| PooToolsSource/Base/PTEmptyDataSetView.swift:308 | func | public | public func verticalOffset(_ offset: CGFloat) -> Self { |
| PooToolsSource/Base/PTEmptyDataSetView.swift:317 | func | public | public func verticalSpace(_ space: CGFloat) -> Self { |
| PooToolsSource/Base/PTEmptyDataSetView.swift:325 | func | public | public func shouldFadeIn(_ bool: Bool) -> Self { |
| PooToolsSource/Base/PTEmptyDataSetView.swift:331 | func | public | public func shouldBeForcedToDisplay(_ bool: Bool) -> Self { |
| PooToolsSource/Base/PTEmptyDataSetView.swift:337 | func | public | public func shouldDisplay(_ bool: Bool) -> Self { |
| PooToolsSource/Base/PTEmptyDataSetView.swift:346 | func | public | public func isTouchAllowed(_ bool: Bool) -> Self { |
| PooToolsSource/Base/PTEmptyDataSetView.swift:352 | func | public | public func isScrollAllowed(_ bool: Bool) -> Self { |
| PooToolsSource/Base/PTEmptyDataSetView.swift:360 | func | public | public func isImageViewAnimateAllowed(_ bool: Bool) -> Self { |
| PooToolsSource/Base/PTEmptyDataSetView.swift:369 | func | public | public func didTapContentView(_ closure: @escaping @MainActor () -> Void) -> Self { |
| PooToolsSource/Base/PTEmptyDataSetView.swift:375 | func | public | public func didTapDataButton(_ closure: @escaping @MainActor () -> Void) -> Self { |
| PooToolsSource/Base/PTEmptyDataSetView.swift:381 | func | public | public func willAppear(_ closure: @escaping @MainActor () -> Void) -> Self { |
| PooToolsSource/Base/PTEmptyDataSetView.swift:387 | func | public | public func didAppear(_ closure: @escaping @MainActor () -> Void) -> Self { |
| PooToolsSource/Base/PTEmptyDataSetView.swift:393 | func | public | public func willDisappear(_ closure: @escaping @MainActor () -> Void) -> Self { |
| PooToolsSource/Base/PTEmptyDataSetView.swift:399 | func | public | public func didDisappear(_ closure: @escaping @MainActor () -> Void) -> Self { |
| PooToolsSource/Base/PTFusionCell.swift:15 | typealias | public | public typealias PTCellSwitchBlock = @MainActor (_ rowText: String, _ sender: UIControl) -> Void |
| PooToolsSource/Base/PTFusionCell.swift:16 | typealias | public | public typealias PTSectionMoreBlock = @MainActor (_ rowText: String, _ sender: PTActionLayoutButton) -> Void |
| PooToolsSource/Base/PTFusionCell.swift:29 | var | public | public var switchValueChangeBlock: PTCellSwitchBlock? |
| PooToolsSource/Base/PTFusionCell.swift:60 | var | public | public var activeSwitch: UIControl? { |
| PooToolsSource/Base/PTFusionCell.swift:66 | let | public | public let moreButton = PTActionLayoutButton() |
| PooToolsSource/Base/PTFusionCell.swift:215 | func | public | public func configure(model: PTFusionCellModel) { |
| PooToolsSource/Base/PTFusionCell.swift:525 | class | open | open class PTFusionCell: PTBaseNormalCell, PTFusionCellProtocol { |
| PooToolsSource/Base/PTFusionCell.swift:528 | var | public | public var switchValueChangeBlock: PTCellSwitchBlock? |
| PooToolsSource/Base/PTFusionCell.swift:529 | var | public | public var moreActionBlock: PTSectionMoreBlock? |
| PooToolsSource/Base/PTFusionCell.swift:531 | var | open | open var switchValue: Bool? { |
| PooToolsSource/Base/PTFusionCell.swift:535 | var | open | open var cellModel: PTFusionCellModel? { |
| PooToolsSource/Base/PTFusionCell.swift:558 | class | open | open class PTFusionSwipeCell: PTBaseSwipeCell, PTFusionCellProtocol { |
| PooToolsSource/Base/PTFusionCell.swift:561 | var | public | public var switchValueChangeBlock: PTCellSwitchBlock? |
| PooToolsSource/Base/PTFusionCell.swift:562 | var | public | public var moreActionBlock: PTSectionMoreBlock? |
| PooToolsSource/Base/PTFusionCell.swift:564 | var | open | open var switchValue: Bool? { |
| PooToolsSource/Base/PTFusionCell.swift:568 | var | open | open var cellModel: PTFusionCellModel? { |
| PooToolsSource/Base/PTFusionCellModel.swift:12 | enum | public | public enum PTFusionShowAccessoryType: Equatable, Hashable { |
| PooToolsSource/Base/PTFusionCellModel.swift:18 | enum | public | public enum SwitchType: Equatable, Hashable { |
| PooToolsSource/Base/PTFusionCellModel.swift:24 | enum | public | @objc public enum PTFusionLineType:Int { |
| PooToolsSource/Base/PTFusionCellModel.swift:30 | struct | public | public struct PTFusionLayoutConfig:Equatable { |
| PooToolsSource/Base/PTFusionCellModel.swift:40 | class | open | open class PTFusionCellModel: NSObject { |
| PooToolsSource/Base/PTFusionCellModel.swift:50 | init | public | public init(diffIdentifier: String) { |
| PooToolsSource/Base/PTFusionCellModel.swift:56 | var | public | public var leftImage:Any? |
| PooToolsSource/Base/PTFusionCellModel.swift:58 | var | public | public var imageTopOffset:CGFloat = 5 |
| PooToolsSource/Base/PTFusionCellModel.swift:59 | var | public | public var imageBottomOffset:CGFloat = 5 |
| PooToolsSource/Base/PTFusionCellModel.swift:60 | var | public | public var labelLineSpace:CGFloat = 2 |
| PooToolsSource/Base/PTFusionCellModel.swift:62 | var | public | public var iconRound:Bool = false |
| PooToolsSource/Base/PTFusionCellModel.swift:64 | var | public | public var name:String = "" |
| PooToolsSource/Base/PTFusionCellModel.swift:66 | var | public | public var nameColor:UIColor = PTAppBaseConfig.share.viewDefaultTextColor |
| PooToolsSource/Base/PTFusionCellModel.swift:68 | var | public | public var desc:String = "" |
| PooToolsSource/Base/PTFusionCellModel.swift:70 | var | public | public var descColor:UIColor = UIColor.lightGray |
| PooToolsSource/Base/PTFusionCellModel.swift:72 | var | public | public var nameAttr:ASAttributedString? |
| PooToolsSource/Base/PTFusionCellModel.swift:74 | var | public | public var content:String = "" |
| PooToolsSource/Base/PTFusionCellModel.swift:76 | var | public | public var contentTextColor:UIColor = PTAppBaseConfig.share.viewDefaultTextColor |
| PooToolsSource/Base/PTFusionCellModel.swift:78 | var | public | public var contentAttr:ASAttributedString? |
| PooToolsSource/Base/PTFusionCellModel.swift:80 | var | public | public var contentFont:UIFont = .appfont(size: 16) |
| PooToolsSource/Base/PTFusionCellModel.swift:82 | var | public | public var contentNumberOfLines:Int = 0 |
| PooToolsSource/Base/PTFusionCellModel.swift:84 | var | public | public var contentLineBreakMode:NSLineBreakMode = .byCharWrapping |
| PooToolsSource/Base/PTFusionCellModel.swift:86 | var | public | public var accessoryType:PTFusionShowAccessoryType = .NoneAccessoryView |
| PooToolsSource/Base/PTFusionCellModel.swift:88 | var | public | public var haveLine:PTFusionLineType = .NO |
| PooToolsSource/Base/PTFusionCellModel.swift:90 | var | public | public var haveTopLine:PTFusionLineType = .NO |
| PooToolsSource/Base/PTFusionCellModel.swift:92 | var | public | public var cellFont:UIFont = .appfont(size: 16) |
| PooToolsSource/Base/PTFusionCellModel.swift:94 | var | public | public var cellDescFont:UIFont = .appfont(size: 14) |
| PooToolsSource/Base/PTFusionCellModel.swift:96 | var | public | public var cellID:String? = "" |
| PooToolsSource/Base/PTFusionCellModel.swift:98 | var | public | public var cellClass: AnyClass? = nil |
| PooToolsSource/Base/PTFusionCellModel.swift:101 | var | public | public var cellSelect:Bool? = false |
| PooToolsSource/Base/PTFusionCellModel.swift:103 | var | public | public var cellIndexPath:IndexPath? |
| PooToolsSource/Base/PTFusionCellModel.swift:105 | var | public | public var disclosureIndicatorImage :Any? |
| PooToolsSource/Base/PTFusionCellModel.swift:107 | var | public | public var conrner:UIRectCorner = [] |
| PooToolsSource/Base/PTFusionCellModel.swift:109 | var | public | public var contentIcon:Any? |
| PooToolsSource/Base/PTFusionCellModel.swift:111 | var | public | public var rightSpace:CGFloat = 10 |
| PooToolsSource/Base/PTFusionCellModel.swift:113 | var | public | public var contentRightSpace:CGFloat = 10 |
| PooToolsSource/Base/PTFusionCellModel.swift:114 | var | public | public var contentToRightImageSpacing:CGFloat = 0 |
| PooToolsSource/Base/PTFusionCellModel.swift:116 | var | public | public var leftSpace:CGFloat = 10 |
| PooToolsSource/Base/PTFusionCellModel.swift:118 | var | public | public var contentLeftSpace:CGFloat = 10 |
| PooToolsSource/Base/PTFusionCellModel.swift:120 | var | public | public var cellCorner:CGFloat = 10 |
| PooToolsSource/Base/PTFusionCellModel.swift:122 | var | public | public var switchOnTinColor:UIColor = .systemGreen |
| PooToolsSource/Base/PTFusionCellModel.swift:124 | var | public | public var switchThumbTintColor:UIColor = .white |
| PooToolsSource/Base/PTFusionCellModel.swift:126 | var | public | public var switchTintColor:UIColor = .clear |
| PooToolsSource/Base/PTFusionCellModel.swift:128 | var | public | public var switchBackgroundColor:UIColor = .clear |
| PooToolsSource/Base/PTFusionCellModel.swift:130 | var | public | public var moreString:String = "PT More".localized() |
| PooToolsSource/Base/PTFusionCellModel.swift:132 | var | public | public var moreColor:UIColor = .lightGray |
| PooToolsSource/Base/PTFusionCellModel.swift:134 | var | public | public var moreFont:UIFont = .appfont(size: 13) |
| PooToolsSource/Base/PTFusionCellModel.swift:136 | var | public | public var moreDisclosureIndicatorSpace:CGFloat = 5 |
| PooToolsSource/Base/PTFusionCellModel.swift:138 | var | public | public var moreDisclosureIndicatorSize:CGSize = CGSizeMake(14, 14) |
| PooToolsSource/Base/PTFusionCellModel.swift:140 | var | public | public var moreLayoutStyle: PTLayoutButtonStyle = .leftTitleRightImage |
| PooToolsSource/Base/PTFusionCellModel.swift:142 | var | public | public var moreDisclosureIndicator :Any? = "▶️".emojiToImage(emojiFont: .appfont(size: 14)) |
| PooToolsSource/Base/PTFusionCellModel.swift:144 | var | public | public var iCloudDocument:String = "" |
| PooToolsSource/Base/PTFusionCellModel.swift:146 | var | public | public var topLineHeight:CGFloat = 1 |
| PooToolsSource/Base/PTFusionCellModel.swift:148 | var | public | public var bottomLineHeight:CGFloat = 1 |
| PooToolsSource/Base/PTFusionCellModel.swift:150 | var | public | public var topLineColor:UIColor = DynamicColor(hexString: "E8E8E8") ?? .lightGray |
| PooToolsSource/Base/PTFusionCellModel.swift:152 | var | public | public var bottomLineColor:UIColor = DynamicColor(hexString: "E8E8E8") ?? .lightGray |
| PooToolsSource/Base/PTFusionCellModel.swift:154 | var | public | @PTClampedPropertyWrapper(range:20...88) public var switchControlWidth: CGFloat = 51 |
| PooToolsSource/Base/PTFusionCellModel.swift:157 | var | public | public var cachedTitleAttr: ASAttributedString { |
| PooToolsSource/Base/PTFusionCellModel.swift:162 | func | public | public func titleLabelAtt() -> ASAttributedString { |
| PooToolsSource/Base/PTFusionCellModel.swift:199 | var | public | public var cachedContentAttr: ASAttributedString { |
| PooToolsSource/Base/PTFusionCellModel.swift:204 | func | public | public func contentLabelAtt() -> ASAttributedString { |
| PooToolsSource/Base/PTFusionCellModel.swift:263 | var | public | public var diffId: String { |
| PooToolsSource/Base/PTFusionCellModel.swift:267 | var | public | public var diffHash: Int { |
| PooToolsSource/Base/PTFusionCellModel.swift:291 | class | open | open class PTTagLayoutModel:NSObject { |
| PooToolsSource/Base/PTFusionCellModel.swift:292 | var | public | public var name:String = "" { |
| PooToolsSource/Base/PTFusionCellModel.swift:295 | var | public | public var haveImage:Bool = false { |
| PooToolsSource/Base/PTFusionCellModel.swift:298 | var | public | public var imageWidth:CGFloat = 16 { |
| PooToolsSource/Base/PTFusionCellModel.swift:301 | var | public | public var contentSpace:CGFloat = 4 { |
| PooToolsSource/Base/PTFusionCellModel.swift:304 | var | public | public var contentFont:UIFont = .appfont(size: 14) { |
| PooToolsSource/Base/PTFusionCellModel.swift:307 | var | public | public var contentTextColor:UIColor = .black |
| PooToolsSource/Base/PTFusionCellModel.swift:308 | var | public | public var cachedWidth: CGFloat? { |
| PooToolsSource/Base/PTFusionCellModel.swift:327 | var | public | public var diffId: String { |
| PooToolsSource/Base/PTFusionCellModel.swift:331 | var | public | public var diffHash: Int { |
| PooToolsSource/Base/PTFusionCellModel.swift:338 | protocol | public | public protocol PTDiffableModel { |
| PooToolsSource/Base/PTGAnimationImageView.swift:12 | class | open | open class PTGAnimationImageView: UIView { |
| PooToolsSource/Base/PTGAnimationImageView.swift:13 | var | public | public var imageSet:Any? { |
| PooToolsSource/Base/PTGradientBorderView.swift:11 | class | open | open class PTGradientBorderView: UIView { |
| PooToolsSource/Base/PTGradientBorderView.swift:15 | var | open | open var cornerRadius: CGFloat = 8 { |
| PooToolsSource/Base/PTGradientBorderView.swift:21 | var | open | open var lineWidth: CGFloat = 5 { |
| PooToolsSource/Base/PTGradientBorderView.swift:27 | var | open | open var gradientColors: [UIColor] = [UIColor.red, UIColor.blue] { |
| PooToolsSource/Base/PTGradientBorderView.swift:34 | var | open | open var gradientDirection: Imagegradien = .LeftToRight { |
| PooToolsSource/Base/PTHeaderAndFooter.swift:14 | class | public | public class PTFusionHeader: PTBaseCollectionReusableView,@MainActor PTSupplementaryRegisterable { |
| PooToolsSource/Base/PTHeaderAndFooter.swift:20 | var | public | public var switchValueChangeBlock:PTCellSwitchBlock? |
| PooToolsSource/Base/PTHeaderAndFooter.swift:21 | var | public | public var moreActionBlock:PTSectionMoreBlock? |
| PooToolsSource/Base/PTHeaderAndFooter.swift:22 | var | public | public var switchValue:Bool? { |
| PooToolsSource/Base/PTHeaderAndFooter.swift:36 | var | public | public var sectionModel:PTFusionCellModel? { |
| PooToolsSource/Base/PTHeaderAndFooter.swift:85 | class | public | public class PTVersionFooter: PTBaseCollectionReusableView,@MainActor PTSupplementaryRegisterable { |
| PooToolsSource/Base/PTImageCell.swift:13 | class | open | open class PTImageCell: PTBaseNormalCell { |
| PooToolsSource/Base/PTImageCell.swift:16 | var | public | public var showAnimator: Bool = false { |
| PooToolsSource/Base/PTImageCell.swift:27 | var | public | public var imageData: Any? { |
| PooToolsSource/Base/PTImageCell.swift:119 | func | public | public func removeAnimator() { |
| PooToolsSource/Base/PTImageCell.swift:130 | func | public | public func resetAnimator() { |
| PooToolsSource/Base/PTLazyViewContainer.swift:22 | init | public | public init(createView: @escaping @MainActor () -> T = { T() }) { |
| PooToolsSource/Base/PTLazyViewContainer.swift:34 | func | public | public func ensureView(in parent: UIView, |
| PooToolsSource/Base/PTLazyViewContainer.swift:72 | func | public | public func removeView(using customRemove: (@MainActor (T) -> Void)? = nil) { |
| PooToolsSource/Base/PTLazyViewContainer.swift:89 | var | public | public var isHidden: Bool { |
| PooToolsSource/Base/PTLazyViewContainer.swift:95 | var | public | public var isCreated: Bool { |
| PooToolsSource/Base/PTListViewController.swift:14 | class | open | open class PTListViewController: PTBaseViewController { |
| PooToolsSource/Base/PTListViewController.swift:22 | func | open | open func makeListViewConfiguration() -> PTCollectionViewConfig { |
| PooToolsSource/Base/PTListViewController.swift:31 | func | open | open func configureListView(_ listView: PTCollectionView) { } |
| PooToolsSource/Base/PTListViewController.swift:36 | func | open | open func prepareListViewLayout(_ listView: PTCollectionView) { } |
| PooToolsSource/Base/PTListViewController.swift:41 | func | open | open func installListViewConstraints(_ listView: PTCollectionView) { |
| PooToolsSource/Base/PTListViewController.swift:54 | func | open | open func listViewDidScroll(_ collectionView: UICollectionView) { } |
| PooToolsSource/Base/PTListViewController.swift:59 | func | open | open func listViewDidEndDragging(_ collectionView: UICollectionView, willDecelerate: Bool) { } |
| PooToolsSource/Base/PTNavBar.swift:14 | class | open | open class PTNavBar: PTNavigationBarContainer { |
| PooToolsSource/Base/PTNavBar.swift:22 | var | public | public var isFakeNav: Bool = false { |
| PooToolsSource/Base/PTNavBar.swift:73 | enum | public | public enum PTTitleViewMode: Sendable { |
| PooToolsSource/Base/PTNavBar.swift:79 | var | public | public var titleViewMode: PTTitleViewMode = .fill { |
| PooToolsSource/Base/PTNavBar.swift:85 | var | public | public var titleView: UIView? { |
| PooToolsSource/Base/PTNavBar.swift:232 | func | public | public func setLeftButtons(_ buttons: [UIView]) { |
| PooToolsSource/Base/PTNavBar.swift:261 | func | public | public func setRightButtons(_ buttons: [UIView]) { |
| PooToolsSource/Base/PTPlayerViewController.swift:14 | class | open | open class PTPlayerViewController: PTBaseViewController { |
| PooToolsSource/Base/PTPlayerViewController.swift:35 | var | public | public var videoPlayer: AVPlayer? |
| PooToolsSource/Base/PTPlayerViewController.swift:36 | var | public | public var onCloseTapped: PTActionTask? // 🔹 你可以拦截返回逻辑 |
| PooToolsSource/Base/PTSnapKitEX.swift:14 | typealias | public | public typealias ConstraintView = UIView |
| PooToolsSource/Base/PTSnapKitEX.swift:15 | typealias | public | public typealias ConstraintEdgeInsets = UIEdgeInsets |
| PooToolsSource/Base/PTSnapKitEX.swift:18 | typealias | public | public typealias ConstraintView = NSView |
| PooToolsSource/Base/PTSnapKitEX.swift:19 | typealias | public | public typealias ConstraintEdgeInsets = NSEdgeInsets |
| PooToolsSource/Base/PTSnapKitEX.swift:26 | enum | public | public enum ConstraintAxis: Int { |
| PooToolsSource/Base/PTSnapKitEX.swift:32 | enum | public | public enum ConstraintCrossAxisAlignment { |
| PooToolsSource/Base/PTSnapKitEX.swift:41 | struct | public | public struct ConstraintGroup { |
| PooToolsSource/Base/PTSnapKitEX.swift:50 | func | public | public func prepareConstraints(_ closure: (_ make: ConstraintMaker) -> Void) -> [Constraint] { |
| PooToolsSource/Base/PTSnapKitEX.swift:55 | func | public | public func makeConstraints(_ closure: (_ make: ConstraintMaker) -> Void) { |
| PooToolsSource/Base/PTSnapKitEX.swift:59 | func | public | public func remakeConstraints(_ closure: (_ make: ConstraintMaker) -> Void) { |
| PooToolsSource/Base/PTSnapKitEX.swift:63 | func | public | public func updateConstraints(_ closure: (_ make: ConstraintMaker) -> Void) { |
| PooToolsSource/Base/PTSnapKitEX.swift:67 | func | public | public func removeConstraints() { |
| PooToolsSource/Base/PTSnapKitEX.swift:75 | func | public | public func distributeViewsAlong(axisType: ConstraintAxis, |
| PooToolsSource/Base/PTSnapKitEX.swift:115 | func | public | public func distributeViewsAlong(axisType: ConstraintAxis, |
| PooToolsSource/Base/PTSnapKitEX.swift:155 | func | public | public func distributeSudokuViews(fixedItemWidth: CGFloat, |
| PooToolsSource/Base/PTSnapKitEX.swift:191 | func | public | public func distributeSudokuViews(fixedLineSpacing: CGFloat, |
| PooToolsSource/Base/PTTabBarView.swift:16 | enum | public | public enum PTTabBarLayoutStyle { |
| PooToolsSource/Base/PTTabBarView.swift:22 | protocol | public | public protocol PTTabBarItemContent { |
| PooToolsSource/Base/PTTabBarView.swift:28 | struct | public | public struct PTTabBarItemConfig { |
| PooToolsSource/Base/PTTabBarView.swift:33 | init | public | public init(title: String, |
| PooToolsSource/Base/PTTabBarView.swift:52 | init | public | public init(normal: Any, selected: Any? = nil) { |
| PooToolsSource/Base/PTTabBarView.swift:77 | var | public | public var view: UIView { container } |
| PooToolsSource/Base/PTTabBarView.swift:79 | func | public | @MainActor public func setSelected(_ selected: Bool, animated: Bool) { |
| PooToolsSource/Base/PTTabBarView.swift:155 | class | public | public class func itemImageSize() -> CGFloat { |
| PooToolsSource/Base/PTTabBarView.swift:163 | var | public | public var imageContent: UIView { |
| PooToolsSource/Base/PTTabBarView.swift:169 | var | public | public var isSelectedItem = false { |
| PooToolsSource/Base/PTTabBarView.swift:178 | init | public | public init(content: PTTabBarItemContent, title: String) { |
| PooToolsSource/Base/PTTabBarView.swift:188 | init | public | public init(content: PTTabBarItemContent, |
| PooToolsSource/Base/PTTabBarView.swift:255 | func | public | public func restoreIconLayout() { |
| PooToolsSource/Base/PTTabBarView.swift:310 | var | public | public var shouldSelectIndex: ((Int) -> Bool)? |
| PooToolsSource/Base/PTTabBarView.swift:312 | var | public | public var willSelectIndex: ((Int) -> Void)? |
| PooToolsSource/Base/PTTabBarView.swift:314 | var | public | public var didSelectIndex: ((Int) -> Void)? |
| PooToolsSource/Base/PTTabBarView.swift:318 | var | public | public var didDoubleTapIndex: ((Int) -> Void)? |
| PooToolsSource/Base/PTTabBarView.swift:320 | var | public | public var didTapCenter: PTActionTask? |
| PooToolsSource/Base/PTTabBarView.swift:322 | var | public | public var badgeDragRemoveIndex: ((Int) -> Void)? |
| PooToolsSource/Base/PTTabBarView.swift:324 | var | public | public var items: [PTTabBarItemView] = [] |
| PooToolsSource/Base/PTTabBarView.swift:337 | var | public | public var centerTitle:String { |
| PooToolsSource/Base/PTTabBarView.swift:360 | var | public | public var currentBarLayoutStyle : PTTabBarLayoutStyle { |
| PooToolsSource/Base/PTTabBarView.swift:397 | init | public | public init(frame: CGRect, appearance: PTTabBarAppearance) { |
| PooToolsSource/Base/PTTabBarView.swift:581 | func | public | public func setup(configs: [PTTabBarItemConfig], |
| PooToolsSource/Base/PTTabBarView.swift:723 | func | public | public func select(_ index: Int) { |
| PooToolsSource/Base/PTTabBarView.swift:881 | func | public | public func badge(index:Int,badgeValue:Any,badgeStyle:PTBadgeStyle = .number,anumationType:PTBadgeAnimType = .none,badgeCanDrag:Bool = false) { |
| PooToolsSource/Base/PTTabBarView.swift:887 | func | public | public func badge(index: Int, |
| PooToolsSource/Base/PTTabBarView.swift:917 | func | public | public func removeBadge(index:Int) { |
| PooToolsSource/Base/PTTabBarView.swift:935 | func | public | public func toggleMinimize(isMinimized: Bool, selectedIndex: Int) { |
| PooToolsSource/Base/PTTriangleView.swift:11 | enum | public | public enum PTTriangleDirection { |
| PooToolsSource/Base/PTTriangleView.swift:15 | class | public | public class PTTriangleView: UIView { |
| PooToolsSource/Base/PTTriangleView.swift:16 | var | public | public var fillColor: UIColor = .systemBlue |
| PooToolsSource/Base/PTTriangleView.swift:17 | var | public | public var direction: PTTriangleDirection = .up |
| PooToolsSource/Base/PTUnavailableFunction.swift:16 | class | open | open class PTEmptyDataViewConfig: NSObject { |
| PooToolsSource/Base/PTUnavailableFunction.swift:17 | var | public | public var mainTitleAtt: ASAttributedString? |
| PooToolsSource/Base/PTUnavailableFunction.swift:18 | var | public | public var secondaryEmptyAtt: ASAttributedString? |
| PooToolsSource/Base/PTUnavailableFunction.swift:19 | var | public | public var buttonTitle: String = "" |
| PooToolsSource/Base/PTUnavailableFunction.swift:20 | var | public | public var buttonFont: UIFont = .appfont(size: 18) |
| PooToolsSource/Base/PTUnavailableFunction.swift:21 | var | public | public var buttonTextColor: UIColor = .systemBlue |
| PooToolsSource/Base/PTUnavailableFunction.swift:22 | var | public | public var image: UIImage? = UIImage(.exclamationmark.triangle) |
| PooToolsSource/Base/PTUnavailableFunction.swift:23 | var | public | public var backgroundColor: UIColor = .clear |
| PooToolsSource/Base/PTUnavailableFunction.swift:24 | var | public | public var imageToTextPadding: CGFloat = 10 |
| PooToolsSource/Base/PTUnavailableFunction.swift:25 | var | public | public var textToSecondaryTextPadding: CGFloat = 5 |
| PooToolsSource/Base/PTUnavailableFunction.swift:26 | var | public | public var buttonToSecondaryButtonPadding: CGFloat = 15 |
| PooToolsSource/Base/PTUnavailableFunction.swift:27 | var | public | public var verticalOffSet: CGFloat = 0 |
| PooToolsSource/Base/PTUnavailableFunction.swift:28 | var | public | public var customerView: UIView? = nil |
| PooToolsSource/Base/PTUnavailableFunction.swift:31 | enum | public | public enum PTUnavailableState: Sendable { |
| PooToolsSource/Base/PTUnavailableFunction.swift:39 | struct | public | public struct PTUnavailableManager { // 👈 弃用单例，改用 Struct 静态方法 |
| PooToolsSource/Base/PTVideoCoverCache.swift:93 | struct | public | public struct PTVideoCacheItem { |
| PooToolsSource/Base/PTVideoCoverCache.swift:95 | let | public | public let originalURLString: String |
| PooToolsSource/Base/PTVideoCoverCache.swift:98 | var | public | public var coverImage: UIImage? |
| PooToolsSource/Base/PTVideoCoverCache.swift:101 | var | public | public var localVideoURL: URL? |
| PooToolsSource/Base/PTVideoCoverCache.swift:104 | var | public | public var isFullyCached: Bool { |
| PooToolsSource/Base/PTVideoCoverCache.swift:123 | func | public | @MainActor public func getVideoItem(for urlString: String, |
| PooToolsSource/Base/PTVideoCoverCache.swift:191 | func | public | public func cacheURL(for videoURL: URL) -> URL { |
| PooToolsSource/Base/PTVideoCoverCache.swift:198 | func | public | public func cachedFileURL(for url: URL) -> URL? { |
| PooToolsSource/Base/PTVideoCoverCache.swift:219 | func | public | public func prepareVideo(url: URL, |
| PooToolsSource/Base/PTVideoCoverCache.swift:343 | enum | public | public enum PTVideoCoverCache { |
| PooToolsSource/BioID/PTBiologyID.swift:13 | enum | public | @objc public enum PTBiometryStatus: Int { |
| PooToolsSource/BioID/PTBiologyID.swift:22 | class | public | public class PTBiometricsManager: NSObject { |
| PooToolsSource/BioID/PTBiologyID.swift:33 | var | public | public var currentBiometryStatus: PTBiometryStatus { |
| PooToolsSource/BioID/PTBiologyID.swift:48 | func | public | public func cancelAuthentication() { |
| PooToolsSource/BioID/PTBiologyID.swift:57 | func | public | public func startAuthentication(alertTitle: String = "生物识别验证", allowSystemFallback: Bool = true) async -> PTBiologyVerifyStatus { |
| PooToolsSource/BioID/PTBiologyID.swift:130 | func | public | public func saveAccount(_ reason: String = "保存账号密码需要验证", account: String, password: String) async -> Bool { |
| PooToolsSource/BioID/PTBiologyID.swift:148 | func | public | public func readPassword(for account: String, reason: String = "需要验证才能读取密码") async -> String? { |
| PooToolsSource/BioID/PTBiologyID.swift:158 | func | public | public func deleteBiometryID(account: String? = nil) async -> PTBiologyVerifyStatus { |
| PooToolsSource/BlackMagic/PTSwiftMethodSwizzle.swift:15 | enum | public | public enum PTSwizzleRegistry { |
| PooToolsSource/BlackMagic/PTSwiftMethodSwizzle.swift:35 | struct | public | public struct SwizzlePair { |
| PooToolsSource/BlackMagic/PTSwiftMethodSwizzle.swift:54 | struct | public | public struct Swizzle { |
| PooToolsSource/BlackMagic/PTSwiftMethodSwizzle.swift:57 | struct | public | public struct SwizzleFunctionBuilder { |
| PooToolsSource/BlackMagic/PTSwiftMethodSwizzle.swift:69 | init | public | public init(_ type: AnyClass, isClassMethod: Bool = false, @SwizzleFunctionBuilder _ makeSwizzlePairs: () -> [SwizzlePair]) { |
| PooToolsSource/BlackMagic/PTSwiftMethodSwizzle.swift:75 | init | public | public init(_ type: AnyClass, isClassMethod: Bool = false, @SwizzleFunctionBuilder _ makeSwizzlePairs: () -> SwizzlePair) { |
| PooToolsSource/BluetoothPermission/PTPermissionBluetooth.swift:20 | class | public | public class PTPermissionBluetooth: PTPermission { |
| PooToolsSource/BluetoothPermission/PTPermissionBluetooth.swift:23 | var | open | open var usageDescriptionKey: String? { "NSBluetoothAlwaysUsageDescription" } |
| PooToolsSource/Blur/PSecurityStrategy.swift:11 | let | public | public let effectTag = 19999 |
| PooToolsSource/Blur/PSecurityStrategy.swift:14 | class | public | public class PSecurityStrategy: NSObject { |
| PooToolsSource/Blur/PTFrostedGlassView.swift:13 | class | public | public class PTFrostedGlassView: UIView { |
| PooToolsSource/Blur/PTFrostedGlassView.swift:24 | var | public | public var visualStyle: PTVisualStyle = .automatic { |
| PooToolsSource/Blur/SSBlurView.swift:14 | class | public | public class SSBlurView: UIView { |
| PooToolsSource/Blur/SSBlurView.swift:24 | var | public | public var visualStyle: PTVisualStyle = .automatic { |
| PooToolsSource/Blur/SSBlurView.swift:28 | var | public | public var animationDuration: TimeInterval { |
| PooToolsSource/Blur/SSBlurView.swift:34 | var | public | public var style: UIBlurEffect.Style = .systemMaterial { |
| PooToolsSource/Blur/SSBlurView.swift:39 | var | public | public var blurContentView: UIView { blurEffectView.contentView } |
| PooToolsSource/Blur/SSBlurView.swift:40 | var | public | public var vibrancyContentView: UIView { vibrancyView.contentView } |
| PooToolsSource/Blur/SSBlurView.swift:76 | func | public | public func enable(animated: Bool = true) { |
| PooToolsSource/Blur/SSBlurView.swift:82 | func | public | public func disable(animated: Bool = true) { |
| PooToolsSource/Button/PFloatingButton.swift:11 | typealias | public | public typealias PTFloatingButtonTask = (_ button: PFloatingButton) -> Void |
| PooToolsSource/Button/PFloatingButton.swift:14 | class | open | open class PFloatingButton: UIButton { |
| PooToolsSource/Button/PFloatingButton.swift:23 | var | public | public var longPressBlock: PTFloatingButtonTask? { |
| PooToolsSource/Button/PFloatingButton.swift:62 | var | open | open var longPressEndedBlock: PTFloatingButtonTask? |
| PooToolsSource/Button/PFloatingButton.swift:63 | var | open | open var tapBlock: PTFloatingButtonTask? |
| PooToolsSource/Button/PFloatingButton.swift:64 | var | open | open var doubleTapBlock: PTFloatingButtonTask? |
| PooToolsSource/Button/PFloatingButton.swift:65 | var | open | open var layerConfigBlock: PTFloatingButtonTask? // 注意：轨迹优化后，这个闭包可能需要调整用法 |
| PooToolsSource/Button/PFloatingButton.swift:66 | var | open | open var draggingBlock: PTFloatingButtonTask? |
| PooToolsSource/Button/PFloatingButton.swift:67 | var | open | open var dragEndedBlock: PTFloatingButtonTask? |
| PooToolsSource/Button/PFloatingButton.swift:68 | var | open | open var autoDockEndedBlock: PTFloatingButtonTask? |
| PooToolsSource/Button/PFloatingButton.swift:69 | var | open | open var dragCancelledBlock: PTFloatingButtonTask? |
| PooToolsSource/Button/PFloatingButton.swift:70 | var | open | open var autoDockingBlock: PTFloatingButtonTask? |
| PooToolsSource/Button/PFloatingButton.swift:71 | var | open | open var willBeRemovedBlock: PTFloatingButtonTask? |
| PooToolsSource/Button/PFloatingButton.swift:74 | var | open | open var draggable: Bool = true |
| PooToolsSource/Button/PFloatingButton.swift:75 | var | open | open var autoDocking: Bool = false |
| PooToolsSource/Button/PFloatingButton.swift:76 | var | open | open var dragOutOfBoundsEnabled: Bool = false |
| PooToolsSource/Button/PFloatingButton.swift:77 | var | open | open var dockPoint: CGPoint = PFloatingButton.RC_POINT_NULL |
| PooToolsSource/Button/PFloatingButton.swift:78 | var | open | open var limitedDistance: CGFloat = -1.0 |
| PooToolsSource/Button/PFloatingButton.swift:79 | var | open | open var isTraceEnabled: Bool = false |
| PooToolsSource/Button/PFloatingButton.swift:80 | var | open | open var dragEnd: PTActionTask? |
| PooToolsSource/Button/PFloatingButton.swift:111 | init | public | public init(inView superview: UIView?, frame: CGRect) { |
| PooToolsSource/Button/PFloatingButton.swift:342 | func | public | public func startRecordingDraggingPath() { |
| PooToolsSource/Button/PFloatingButton.swift:348 | func | public | public func endRecordingDraggingPath() -> UIBezierPath { |
| PooToolsSource/Button/PFloatingButton.swift:353 | func | public | public func removeTraces() { |
| PooToolsSource/Button/PFloatingButton.swift:362 | func | public | public func setDraggableAfterLongPress(_ enabled: Bool) { |
| PooToolsSource/Button/PFloatingButton.swift:366 | func | public | public func triggerWillBeRemoved() { |
| PooToolsSource/Button/PTActionLayoutButton.swift:13 | class | public | public class PTActionLayoutButton: UIControl { |
| PooToolsSource/Button/PTActionLayoutButton.swift:15 | var | public | public var actionMargin:CGFloat = 10 |
| PooToolsSource/Button/PTActionLayoutButton.swift:20 | var | public | public var layoutStyle: PTLayoutButtonStyle = .leftImageRightTitle { |
| PooToolsSource/Button/PTActionLayoutButton.swift:24 | var | public | public var imageSize: CGSize = .zero { |
| PooToolsSource/Button/PTActionLayoutButton.swift:28 | var | public | public var midSpacing: CGFloat = 0 { |
| PooToolsSource/Button/PTActionLayoutButton.swift:32 | var | public | public var labelLineSpace: CGFloat = 2 { |
| PooToolsSource/Button/PTActionLayoutButton.swift:36 | var | public | public var textAlignment: NSTextAlignment = .center { |
| PooToolsSource/Button/PTActionLayoutButton.swift:40 | var | public | public var numbersOfLine: Int = 0 { |
| PooToolsSource/Button/PTActionLayoutButton.swift:44 | var | public | public var textLineBreakMode: NSLineBreakMode = .byCharWrapping { |
| PooToolsSource/Button/PTActionLayoutButton.swift:48 | var | public | public var imageContentMode: UIView.ContentMode = .scaleAspectFit { |
| PooToolsSource/Button/PTActionLayoutButton.swift:289 | var | public | public var currentString = "" |
| PooToolsSource/Button/PTActionLayoutButton.swift:295 | var | public | public var currentImage: Any? = nil |
| PooToolsSource/Button/PTActionLayoutButton.swift:301 | var | public | public var currentTitleColor: UIColor = .black |
| PooToolsSource/Button/PTActionLayoutButton.swift:307 | var | public | public var currentFont: UIFont = .systemFont(ofSize: 14) |
| PooToolsSource/Button/PTActionLayoutButton.swift:313 | var | public | public var currentBGColor: UIColor = .clear |
| PooToolsSource/Button/PTActionLayoutButton.swift:319 | var | public | public var currentAtt: ASAttributedString? = nil |
| PooToolsSource/Button/PTActionLayoutButton.swift:321 | var | public | public var progressLayerRadius: CGFloat = 0 |
| PooToolsSource/Button/PTActionLayoutButton.swift:322 | var | public | public var progressLayerTopLeft: CGFloat = 0 |
| PooToolsSource/Button/PTActionLayoutButton.swift:323 | var | public | public var progressLayerTopRight: CGFloat = 0 |
| PooToolsSource/Button/PTActionLayoutButton.swift:324 | var | public | public var progressLayerBottomLeft: CGFloat = 0 |
| PooToolsSource/Button/PTActionLayoutButton.swift:325 | var | public | public var progressLayerBottomRight: CGFloat = 0 |
| PooToolsSource/Button/PTActionLayoutButton.swift:326 | var | public | public var progressLayerCorner: UIRectCorner = .allCorners |
| PooToolsSource/Button/PTActionLayoutButton.swift:327 | var | public | public var progressLayerCapsule: Bool = false |
| PooToolsSource/Button/PTActionLayoutButton.swift:328 | var | public | public var progressLayerBorderWidth: CGFloat = PTAppBaseConfig.share.loadImageProgressBorderWidth |
| PooToolsSource/Button/PTActionLayoutButton.swift:329 | var | public | public var progressLayerBorderColor: UIColor = PTAppBaseConfig.share.loadImageProgressBorderColor |
| PooToolsSource/Button/PTActionLayoutButton.swift:330 | var | public | public var progressLayerShowValueLabel: Bool = PTAppBaseConfig.share.loadImageShowValueLabel |
| PooToolsSource/Button/PTActionLayoutButton.swift:331 | var | public | public var progressLayerValueLabelFont: UIFont = PTAppBaseConfig.share.loadImageShowValueFont |
| PooToolsSource/Button/PTActionLayoutButton.swift:332 | var | public | public var progressLayerValueLabelColor: UIColor = PTAppBaseConfig.share.loadImageShowValueColor |
| PooToolsSource/Button/PTActionLayoutButton.swift:333 | var | public | public var progressLayerUniCount: Int = PTAppBaseConfig.share.loadImageShowValueUniCount |
| PooToolsSource/Button/PTActionLayoutButton.swift:484 | func | public | public func getKitTitleSize(lineSpacing:CGFloat = 2.5, |
| PooToolsSource/Button/PTActionLayoutButton.swift:494 | func | public | public func getKitCurrentDimension(lineSpacing:CGFloat = 2.5, |
| PooToolsSource/Button/PTActionLayoutButton.swift:643 | typealias | public | public typealias PTControlTouchedBlock = (_ sender:PTActionLayoutButton) -> Void |
| PooToolsSource/Button/PTCollectionAnimationButton.swift:12 | class | open | open class PTCollectionAnimationButton: UIButton { |
| PooToolsSource/Button/PTCollectionAnimationButton.swift:18 | var | open | @IBInspectable open var image: UIImage! { |
| PooToolsSource/Button/PTCollectionAnimationButton.swift:23 | var | open | @IBInspectable open var imageColorOn: UIColor! = UIColor(red: 255/255, green: 172/255, blue: 51/255, alpha: 1.0) { |
| PooToolsSource/Button/PTCollectionAnimationButton.swift:30 | var | open | @IBInspectable open var imageColorOff: UIColor! = UIColor(red: 136/255, green: 153/255, blue: 166/255, alpha: 1.0) { |
| PooToolsSource/Button/PTCollectionAnimationButton.swift:40 | var | open | @IBInspectable open var circleColor: UIColor! = UIColor(red: 255/255, green: 172/255, blue: 51/255, alpha: 1.0) { |
| PooToolsSource/Button/PTCollectionAnimationButton.swift:47 | var | open | @IBInspectable open var lineColor: UIColor! = UIColor(red: 250/255, green: 120/255, blue: 68/255, alpha: 1.0) { |
| PooToolsSource/Button/PTCollectionAnimationButton.swift:62 | var | open | @IBInspectable open var duration: Double = 1.0 { |
| PooToolsSource/Button/PTCollectionAnimationButton.swift:86 | init | public | public init(frame: CGRect, image: UIImage!) { |
| PooToolsSource/Button/PTCollectionAnimationButton.swift:466 | func | open | open func select() { |
| PooToolsSource/Button/PTCollectionAnimationButton.swift:485 | func | open | open func deselect() { |
| PooToolsSource/Button/PTLayoutButton.swift:13 | enum | public | @objc public enum PTLayoutButtonStyle: Int { |
| PooToolsSource/Button/PTLayoutButton.swift:22 | enum | public | @objc public enum PTLayoutButtonConnerStyle: Int { |
| PooToolsSource/Button/PTLayoutButton.swift:32 | enum | public | @objc public enum PTLayoutButtonSizeStyle: Int { |
| PooToolsSource/Button/PTLayoutButton.swift:40 | enum | public | @objc public enum PTLayoutButtonTitleAlignmentStyle: Int { |
| PooToolsSource/Button/PTLayoutButton.swift:50 | class | public | public class PTLayoutButton: UIButton { |
| PooToolsSource/Button/PTLayoutButton.swift:52 | var | open | open var clearGlass:Bool = false { |
| PooToolsSource/Button/PTLayoutButton.swift:59 | var | open | open var layoutStyle: PTLayoutButtonStyle = .leftImageRightTitle { |
| PooToolsSource/Button/PTLayoutButton.swift:66 | var | open | open var midSpacing: CGFloat = 5 { |
| PooToolsSource/Button/PTLayoutButton.swift:73 | var | open | open var imageSize: CGSize = .zero { |
| PooToolsSource/Button/PTLayoutButton.swift:80 | var | open | open var cornerStyle: PTLayoutButtonConnerStyle = .none { |
| PooToolsSource/Button/PTLayoutButton.swift:87 | var | open | open var borderWidth: CGFloat = 0 { |
| PooToolsSource/Button/PTLayoutButton.swift:94 | var | open | open var textAlignment: PTLayoutButtonTitleAlignmentStyle = .center { |
| PooToolsSource/Button/PTLayoutButton.swift:101 | var | open | open var borderColor: UIColor = .clear { |
| PooToolsSource/Button/PTLayoutButton.swift:108 | var | open | open var cornerRadius: CGFloat = 0 { |
| PooToolsSource/Button/PTLayoutButton.swift:114 | var | open | open var configBackgroundColor: UIColor = .clear { |
| PooToolsSource/Button/PTLayoutButton.swift:120 | var | open | open var configBackgroundSelectedColor: UIColor = .clear { |
| PooToolsSource/Button/PTLayoutButton.swift:126 | var | open | open var configBackgroundHightlightColor: UIColor = .clear { |
| PooToolsSource/Button/PTLayoutButton.swift:132 | var | open | open var configBackgroundDisableColor: UIColor = .clear { |
| PooToolsSource/Button/PTLayoutButton.swift:138 | var | open | open var buttonSizeStyle: PTLayoutButtonSizeStyle = .none { |
| PooToolsSource/Button/PTLayoutButton.swift:144 | var | open | open var titlePadding: CGFloat = 0 { |
| PooToolsSource/Button/PTLayoutButton.swift:150 | var | open | open var showHightlightActivity: Bool = false { |
| PooToolsSource/Button/PTLayoutButton.swift:156 | var | open | open var activityColor: UIColor = .systemPurple { |
| PooToolsSource/Button/PTLayoutButton.swift:162 | var | open | open var loadingCanTap: Bool = false { |
| PooToolsSource/Button/PTLayoutButton.swift:168 | var | open | open var normalImage: UIImage? = nil { |
| PooToolsSource/Button/PTLayoutButton.swift:174 | var | open | open var selectedImage: UIImage? = nil { |
| PooToolsSource/Button/PTLayoutButton.swift:180 | var | open | open var hightlightImage: UIImage? = nil { |
| PooToolsSource/Button/PTLayoutButton.swift:186 | var | open | open var disabledImage: UIImage? = nil { |
| PooToolsSource/Button/PTLayoutButton.swift:192 | var | open | open var normalTitle: String = "" { |
| PooToolsSource/Button/PTLayoutButton.swift:210 | var | open | open var selectedTitle: String! { |
| PooToolsSource/Button/PTLayoutButton.swift:216 | var | open | open var hightlightTitle: String { |
| PooToolsSource/Button/PTLayoutButton.swift:227 | var | open | open var disabledTitle: String { |
| PooToolsSource/Button/PTLayoutButton.swift:238 | var | open | open var normalTitleColor: UIColor = .label { |
| PooToolsSource/Button/PTLayoutButton.swift:244 | var | open | open var selectedTitleColor: UIColor = .label { |
| PooToolsSource/Button/PTLayoutButton.swift:250 | var | open | open var hightlightTitleColor: UIColor = .label { |
| PooToolsSource/Button/PTLayoutButton.swift:256 | var | open | open var disabledTitleColor: UIColor = .secondaryLabel { |
| PooToolsSource/Button/PTLayoutButton.swift:262 | var | open | open var normalTitleFont: UIFont = .appfont(size: 14) { |
| PooToolsSource/Button/PTLayoutButton.swift:268 | var | open | open var selectedTitleFont: UIFont = .appfont(size: 14) { |
| PooToolsSource/Button/PTLayoutButton.swift:274 | var | open | open var hightlightTitleFont: UIFont = .appfont(size: 14) { |
| PooToolsSource/Button/PTLayoutButton.swift:280 | var | open | open var disabledTitleFont: UIFont = .appfont(size: 14) { |
| PooToolsSource/Button/PTLayoutButton.swift:286 | var | open | open var normalSubTitle: String? = "" { |
| PooToolsSource/Button/PTLayoutButton.swift:292 | var | open | open var selectedSubTitle: String { |
| PooToolsSource/Button/PTLayoutButton.swift:303 | var | open | open var hightlightSubTitle: String { |
| PooToolsSource/Button/PTLayoutButton.swift:314 | var | open | open var disabledSubTitle: String { |
| PooToolsSource/Button/PTLayoutButton.swift:325 | var | open | open var normalSubTitleColor: UIColor = .secondaryLabel { |
| PooToolsSource/Button/PTLayoutButton.swift:331 | var | open | open var selectedSubTitleColor: UIColor { |
| PooToolsSource/Button/PTLayoutButton.swift:342 | var | open | open var hightlightSubTitleColor: UIColor { |
| PooToolsSource/Button/PTLayoutButton.swift:353 | var | open | open var disabledSubTitleColor: UIColor = .tertiaryLabel { |
| PooToolsSource/Button/PTLayoutButton.swift:359 | var | open | open var normalSubTitleFont: UIFont = .appfont(size: 12) { |
| PooToolsSource/Button/PTLayoutButton.swift:365 | var | open | open var selectedSubTitleFont: UIFont { |
| PooToolsSource/Button/PTLayoutButton.swift:376 | var | open | open var hightlightSubTitleFont: UIFont { |
| PooToolsSource/Button/PTLayoutButton.swift:387 | var | open | open var disabledSubTitleFont: UIFont { |
| PooToolsSource/Button/PTLayoutButton.swift:398 | var | open | open var contentEdges: NSDirectionalEdgeInsets = .zero { |
| PooToolsSource/Button/PTLayoutButton.swift:451 | func | public | public func layoutHorizontal(withLeftView leftView: UIView?, rightView: UIView?) { |
| PooToolsSource/Button/PTLayoutButton.swift:494 | func | public | public func layoutVertical(withUp upView: UIView?, downView: UIView?) { |
| PooToolsSource/Button/PTLayoutButton.swift:722 | func | public | public func isLoading(value: Bool? = false) { |
| PooToolsSource/Button/PTLoginDescButton.swift:14 | class | public | public class PTLoginDescConfig: NSObject { |
| PooToolsSource/Button/PTLoginDescButton.swift:15 | var | public | public var textColor_L: DynamicColor = DynamicColor(hexString: "7f7f7f") ?? .clear |
| PooToolsSource/Button/PTLoginDescButton.swift:16 | var | public | public var textColor_R: DynamicColor = DynamicColor(hexString: "7f7f7f") ?? .clear |
| PooToolsSource/Button/PTLoginDescButton.swift:17 | var | public | public var textColor_line: DynamicColor = DynamicColor(hexString: "7f7f7f") ?? .clear |
| PooToolsSource/Button/PTLoginDescButton.swift:18 | var | public | public var textFont: UIFont = .appfont(size: 12) |
| PooToolsSource/Button/PTLoginDescButton.swift:19 | var | public | public var leftDesc: String = "A" |
| PooToolsSource/Button/PTLoginDescButton.swift:20 | var | public | public var rightDesc: String = "B" |
| PooToolsSource/Button/PTLoginDescButton.swift:21 | var | public | public var leftAttributedDesc: ASAttributedString? |
| PooToolsSource/Button/PTLoginDescButton.swift:22 | var | public | public var rightAttributedDesc: ASAttributedString? |
| PooToolsSource/Button/PTLoginDescButton.swift:23 | var | public | public var numberOfLines: Int = 1 |
| PooToolsSource/Button/PTLoginDescButton.swift:24 | var | public | public var lineBreakMode: NSLineBreakMode = .byWordWrapping |
| PooToolsSource/Button/PTLoginDescButton.swift:25 | var | public | public var lineWidth: CGFloat = 1 |
| PooToolsSource/Button/PTLoginDescButton.swift:26 | var | public | public var lineTopNBottomSpace: CGFloat = 2 |
| PooToolsSource/Button/PTLoginDescButton.swift:27 | var | public | public var itemSpace: CGFloat = 8 |
| PooToolsSource/Button/PTLoginDescButton.swift:30 | enum | public | public enum PTLoginDescButtonType { |
| PooToolsSource/Button/PTLoginDescButton.swift:42 | class | open | open class PTLoginDescButton: UIView { |
| PooToolsSource/Button/PTLoginDescButton.swift:44 | var | public | public var descHandler: ((PTLoginDescButtonType) -> Void)? |
| PooToolsSource/Button/PTLoginDescButton.swift:52 | init | public | public init(config: PTLoginDescConfig = PTLoginDescConfig()) { |
| PooToolsSource/Button/PTLoginDescButton.swift:66 | func | public | public func reloadConfiguration() { |
| PooToolsSource/Button/PTMenuSheetArrowButton.swift:11 | class | public | public class PTMenuSheetArrowButton: UIButton { |
| PooToolsSource/Button/PTMenuSheetArrowButton.swift:20 | var | public | public var animationDuration: TimeInterval = 0.2 |
| PooToolsSource/Button/PTMenuSheetArrowButton.swift:21 | var | public | public var arrowInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12) { |
| PooToolsSource/Button/PTMenuSheetArrowButton.swift:28 | var | public | public var arrowWidth: CGFloat = 1 { |
| PooToolsSource/Button/PTMenuSheetArrowButton.swift:36 | var | public | public var arrowColor: UIColor = .black { |
| PooToolsSource/Button/PTMenuSheetArrowButton.swift:43 | var | public | public var isArrowsHidden = false { |
| PooToolsSource/Button/PTMenuSheetArrowButton.swift:81 | func | public | public func showUpArrow() { updateArrow(direction: .up, animated: true) } |
| PooToolsSource/Button/PTMenuSheetArrowButton.swift:82 | func | public | public func showDownArrow() { updateArrow(direction: .down, animated: true) } |
| PooToolsSource/Button/PTMenuSheetArrowButton.swift:83 | func | public | public func showLeftArrow() { updateArrow(direction: .left, animated: true) } |
| PooToolsSource/Button/PTMenuSheetArrowButton.swift:84 | func | public | public func showRightArrow() { updateArrow(direction: .right, animated: true) } |
| PooToolsSource/Button/PTMenuSheetButtonItems.swift:11 | class | public | public class PTMenuSheetButtonItems { |
| PooToolsSource/Button/PTMenuSheetButtonItems.swift:13 | typealias | public | public typealias ActionBlock = (PTMenuSheetButtonItems) -> Void |
| PooToolsSource/Button/PTMenuSheetButtonItems.swift:18 | var | public | public var image: UIImage? |
| PooToolsSource/Button/PTMenuSheetButtonItems.swift:19 | var | public | public var highlightedImage: UIImage? |
| PooToolsSource/Button/PTMenuSheetButtonItems.swift:22 | var | public | public var attributedTitle: NSAttributedString? |
| PooToolsSource/Button/PTMenuSheetButtonItems.swift:23 | var | public | public var highlightedAttributedTitle: NSAttributedString? |
| PooToolsSource/Button/PTMenuSheetButtonItems.swift:26 | var | public | public var contentEdgeInsets: UIEdgeInsets = .zero |
| PooToolsSource/Button/PTMenuSheetButtonItems.swift:27 | var | public | public var titleEdgeInsets: UIEdgeInsets = .zero |
| PooToolsSource/Button/PTMenuSheetButtonItems.swift:28 | var | public | public var imageEdgeInsets: UIEdgeInsets = .zero |
| PooToolsSource/Button/PTMenuSheetButtonItems.swift:31 | var | public | public var size: CGSize? |
| PooToolsSource/Button/PTMenuSheetButtonItems.swift:34 | var | public | public var titleAlignment: NSTextAlignment = .center |
| PooToolsSource/Button/PTMenuSheetButtonItems.swift:37 | var | public | public var imageContentMode: UIView.ContentMode = .scaleAspectFit |
| PooToolsSource/Button/PTMenuSheetButtonItems.swift:40 | var | public | public var action: ActionBlock = {_ in} |
| PooToolsSource/Button/PTMenuSheetButtonItems.swift:43 | var | public | public var identifier: String = "" |
| PooToolsSource/Button/PTMenuSheetButtonItems.swift:47 | init | public | public init(image: UIImage? = nil, |
| PooToolsSource/Button/PTMenuSheetButtonView.swift:13 | class | public | public class PTMenuSheetButtonView: UIView { |
| PooToolsSource/Button/PTMenuSheetButtonView.swift:14 | enum | public | public enum Direction { |
| PooToolsSource/Button/PTMenuSheetButtonView.swift:18 | enum | public | public enum State { |
| PooToolsSource/Button/PTMenuSheetButtonView.swift:34 | var | public | public var animationDuration: TimeInterval = 0.2 { |
| PooToolsSource/Button/PTMenuSheetButtonView.swift:38 | var | public | public var closeOnAction: Bool = false |
| PooToolsSource/Button/PTMenuSheetButtonView.swift:39 | var | public | public var isHapticFeedback = true |
| PooToolsSource/Button/PTMenuSheetButtonView.swift:42 | var | public | public var arrowInsets: UIEdgeInsets { |
| PooToolsSource/Button/PTMenuSheetButtonView.swift:46 | var | public | public var arrowWidth: CGFloat { |
| PooToolsSource/Button/PTMenuSheetButtonView.swift:50 | var | public | public var arrowColor: UIColor { |
| PooToolsSource/Button/PTMenuSheetButtonView.swift:55 | var | public | public var closeImage: UIImage? |
| PooToolsSource/Button/PTMenuSheetButtonView.swift:56 | var | public | public var openImage: UIImage? |
| PooToolsSource/Button/PTMenuSheetButtonView.swift:59 | var | public | public var isSeparatorHidden: Bool = false { |
| PooToolsSource/Button/PTMenuSheetButtonView.swift:62 | var | public | public var separatorColor: UIColor = .black { |
| PooToolsSource/Button/PTMenuSheetButtonView.swift:65 | var | public | public var separatorInset: CGFloat = 8 { |
| PooToolsSource/Button/PTMenuSheetButtonView.swift:68 | var | public | public var separatorWidth: CGFloat = 1 { |
| PooToolsSource/Button/PTMenuSheetButtonView.swift:76 | init | public | public init(baseSize: CGSize, direction: Direction = .right, items: [PTMenuSheetButtonItems]) { |
| PooToolsSource/Button/PTMenuSheetButtonView.swift:100 | func | public | public func open() { |
| PooToolsSource/Button/PTMenuSheetButtonView.swift:104 | func | public | public func close(animated: Bool = true) { |
| PooToolsSource/Button/PTSortButton.swift:11 | enum | public | @objc public enum PTSortButtonType: Int { |
| PooToolsSource/Button/PTSortButton.swift:20 | enum | public | @objc public enum PTSortButtonShowType: Int { |
| PooToolsSource/Button/PTSortButton.swift:26 | class | public | public class PTSortButton: UIView { |
| PooToolsSource/Button/PTSortButton.swift:28 | var | public | public var sortTypeHandler: ((PTSortButtonType) -> Void)? |
| PooToolsSource/Button/PTSortButton.swift:30 | var | public | public var sortType: PTSortButtonType = .Normal { |
| PooToolsSource/Button/PTSortButton.swift:38 | var | public | public var buttonTitle: String = "" { |
| PooToolsSource/Button/PTSortButton.swift:47 | var | public | public var buttonTitleFont: UIFont = .appfont(size: 14) { |
| PooToolsSource/Button/PTSortButton.swift:56 | var | public | public var buttonTitleSelectedFont: UIFont = .appfont(size: 14) { |
| PooToolsSource/Button/PTSortButton.swift:65 | var | public | public var buttonTitleSelectedColor: UIColor = .white { |
| PooToolsSource/Button/PTSortButton.swift:73 | var | public | public var buttonTitleNormalColor: UIColor = .lightGray { |
| PooToolsSource/Button/PTSortButton.swift:81 | var | public | public var upNormalImage: Any = UIColor.lightGray.createImageWithColor().transformImage(size: CGSize(width: 10, height: 10)) { |
| PooToolsSource/Button/PTSortButton.swift:87 | var | public | public var upSelectedImage: Any = UIColor.systemRed.createImageWithColor().transformImage(size: CGSize(width: 10, height: 10)) { |
| PooToolsSource/Button/PTSortButton.swift:93 | var | public | public var dosDecreaseImage: Any = UIColor.systemRed.createImageWithColor().transformImage(size: CGSize(width: 10, height: 10)) { |
| PooToolsSource/Button/PTSortButton.swift:99 | var | public | public var dowmNormalImage: Any = UIColor.lightGray.createImageWithColor().transformImage(size: CGSize(width: 10, height: 10)) { |
| PooToolsSource/Button/PTSortButton.swift:105 | var | public | public var downSelectedImage: Any = UIColor.systemBlue.createImageWithColor().transformImage(size: CGSize(width: 10, height: 10)) { |
| PooToolsSource/Button/PTSortButton.swift:111 | var | public | public var contentImageSpace: CGFloat = 2 { |
| PooToolsSource/Button/PTSortButton.swift:119 | var | public | public var imageSpace: CGFloat = 4 { |
| PooToolsSource/Button/PTSortButton.swift:127 | var | public | public var imageSize: CGSize = CGSize(width: 6, height: 4) { |
| PooToolsSource/Button/PTSortButton.swift:165 | init | public | public init(showType: PTSortButtonShowType = .Tres) { |
| PooToolsSource/C7Collector/C7CameraConfig.swift:13 | class | public | public class C7CameraConfig: NSObject { |
| PooToolsSource/C7Collector/C7CameraConfig.swift:16 | var | public | public var devicePosition: C7CameraConfig.DevicePosition = .back |
| PooToolsSource/C7Collector/C7CameraConfig.swift:17 | enum | public | @objc public enum DevicePosition: Int { |
| PooToolsSource/C7Collector/C7CameraConfig.swift:55 | var | public | public var sessionPreset: C7CameraConfig.CaptureSessionPreset = .hd1920x1080 |
| PooToolsSource/C7Collector/C7CameraConfig.swift:57 | enum | public | @objc public enum CaptureSessionPreset: Int { |
| PooToolsSource/C7Collector/C7CameraConfig.swift:83 | class | public | public class func hasCameraAuthority() -> Bool { |
| PooToolsSource/C7Collector/C7Collector.swift:13 | protocol | public | @objc public protocol C7CollectorImageDelegate: NSObjectProtocol { |
| PooToolsSource/C7Collector/C7Collector.swift:36 | class | public | public class C7Collector: NSObject, Cacheable { |
| PooToolsSource/C7Collector/C7Collector.swift:38 | var | public | public var filters: [C7FilterProtocol] = [] |
| PooToolsSource/C7Collector/C7Collector.swift:39 | var | public | public var videoSettings: [String : Sendable] = [ |
| PooToolsSource/C7Collector/C7Collector.swift:43 | var | public | public var autoCorrectDirection: Bool = true |
| PooToolsSource/C7Collector/C7Collector.swift:59 | func | open | open func setupInit() { |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:27 | var | public | public var shotImageCallback: ((UIImage) -> Void)! |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:32 | var | public | public var largeCircleView: UIView! |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:34 | var | public | public var smallCircleView: UIView! |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:36 | var | public | public var borderLayer: CAShapeLayer! |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:37 | var | public | public var focusCursorView: UIImageView! |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:38 | var | public | public var isAdjustingFocusPoint = false |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:40 | var | public | public var recordLongGes: UILongPressGestureRecognizer? |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:43 | var | public | public var isTakingPicture = false |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:55 | let | public | public let sessionQueue = DispatchQueue(label: "camera.session.collector.metal") |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:58 | var | public | public var deviceInput: AVCaptureDeviceInput? |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:60 | var | public | public var movieFileOutput: AVCaptureMovieFileOutput? |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:90 | var | public | public var showedImageView:UIImageView! |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:91 | var | public | public var haveRecordVideo:PTActionTask? = nil |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:92 | var | public | public var avPlayer:C7CollectorVideo? |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:93 | var | public | public var savedVideo:PTActionTask? = nil |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:199 | func | public | public func takePicture(flashBtn:UIButton) { |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:236 | func | public | public func changeCamera(handle:PTActionTask?) { |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:321 | func | public | public func startRecord() { |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:388 | func | public | public func setVideoZoomFactor(_ zoomFactor: CGFloat) { |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:401 | func | public | public func finishRecord() { |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:419 | func | public | public func startRunning() { |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:428 | func | public | public func stopRunning() { |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:451 | func | public | public func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) { |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:454 | func | public | public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) { |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:457 | func | public | public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) { |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:470 | func | public | public func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) { |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:494 | func | public | public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) { |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:603 | func | public | public func saveVideoToAlbum() { |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:644 | func | public | public func resetCameraView() { |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:725 | func | public | public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) { |
| PooToolsSource/C7Collector/C7CollectorCamera.swift:737 | func | public | public func preview(_ collector: C7Collector, fliter image: C7Image) { |
| PooToolsSource/C7Collector/C7CollectorVideo.swift:15 | var | public | public var player: AVPlayer! |
| PooToolsSource/C7Collector/C7CollectorVideo.swift:39 | func | public | public func play() { |
| PooToolsSource/C7Collector/C7CollectorVideo.swift:44 | func | public | public func pause() { |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:33 | class | public | public class PTCameraFilterConfig: NSObject { |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:37 | typealias | public | public typealias Second = Int |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:41 | var | public | public var minRecordDuration: PTCameraFilterConfig.Second { |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:52 | var | public | public var maxRecordDuration: PTCameraFilterConfig.Second { |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:62 | var | public | public var videoExportType: PTCameraFilterConfig.VideoExportType = .mov |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:63 | enum | public | @objc public enum VideoExportType: Int { |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:117 | var | public | public var videoCodecType: AVVideoCodecType { |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:127 | var | public | public var selectBtnAnimationDuration: CFTimeInterval = 0.5 |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:130 | var | public | public var focusMode: PTCameraFilterConfig.FocusMode = .continuousAutoFocus |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:131 | enum | public | @objc public enum FocusMode: Int { |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:146 | var | public | public var exposureMode: PTCameraFilterConfig.ExposureMode = .continuousAutoExposure |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:147 | enum | public | @objc public enum ExposureMode: Int { |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:173 | var | open | open var onlyCamera:Bool = false |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:176 | var | open | open var focusImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44)) |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:179 | var | open | open var switchCameraImage:UIImage = UIImage(.camera) |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:180 | var | open | open var switchCameraImageSelected:UIImage = UIImage(.camera.fill) |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:183 | var | open | open var flashImage:UIImage = UIImage(.flashlight.offFill) |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:184 | var | open | open var flashImageSelected:UIImage = UIImage(.flashlight.onFill) |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:186 | var | open | open var backImage:UIImage = "❌".emojiToImage(emojiFont: .appfont(size: 20)) |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:188 | var | open | open var filtersImage:UIImage = UIImage(.square.andArrowUp) |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:189 | var | open | open var filtersImageSelected:UIImage = UIImage(.square.andArrowUpFill) |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:191 | var | open | open var reloadCameraImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44)) |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:192 | var | open | open var outputVideImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44)) |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:193 | var | open | open var recordingLineColor:DynamicColor = .randomColor |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:195 | var | open | open var reviewImageBack:UIImage = "❌".emojiToImage(emojiFont: .appfont(size: 20)) |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:196 | var | open | open var reviewImageUse:UIImage = "✅".emojiToImage(emojiFont: .appfont(size: 20)) |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:197 | var | open | open var reviewImageEdit:UIImage = UIImage(.pencil) |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:201 | var | public | public var filters: [PTHarBethFilter] { |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:216 | var | public | public var allowTakePhoto: Bool { |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:227 | var | public | public var allowRecordVideo: Bool { |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:237 | class | public | @objc public class func mergeVideos(fileUrls: [URL], completion: @escaping @Sendable (URL?, Error?) -> Void) { |
| PooToolsSource/C7Collector/PTFilterCameraViewController.swift:18 | class | public | public class PTFilterCameraViewController: PTBaseViewController { |
| PooToolsSource/C7Collector/PTFilterCameraViewController.swift:20 | var | public | public var onlyCamera:Bool = true |
| PooToolsSource/C7Collector/PTFilterCameraViewController.swift:21 | var | public | public var useThisImageHandler:((UIImage) -> Void)? |
| PooToolsSource/C7Collector/PTFilterCameraViewController.swift:22 | var | public | public var mediaLibDismissCallback:PTActionTask? = nil |
| PooToolsSource/C7Collector/PTFilterCameraViewController.swift:733 | func | public | public func preview(_ collector: C7Collector, fliter image: C7Image) { |
| PooToolsSource/C7Collector/PTFilterCameraViewController.swift:739 | func | public | public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { |
| PooToolsSource/C7Collector/PTFilterCameraViewController.swift:752 | func | public | public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) { |
| PooToolsSource/C7Collector/PTFilterImageCell.swift:17 | class | public | public class PTFilterImageCell: PTBaseNormalCell { |
| PooToolsSource/C7Collector/PTHarBethFilter.swift:12 | typealias | public | public typealias PTFilterApplierType = (_ image: UIImage) -> UIImage |
| PooToolsSource/C7Collector/PTHarBethFilter.swift:14 | typealias | public | public typealias maxminTuple = (current: Float, min: Float, max: Float)? |
| PooToolsSource/C7Collector/PTHarBethFilter.swift:15 | typealias | public | public typealias FilterCallback = (_ value: Float) -> C7FilterProtocol |
| PooToolsSource/C7Collector/PTHarBethFilter.swift:16 | typealias | public | public typealias FilterResult = (filter: C7FilterProtocol?, maxminValue: maxminTuple, callback: FilterCallback?) |
| PooToolsSource/C7Collector/PTHarBethFilter.swift:19 | class | public | public class PTHarBethFilter:NSObject { |
| PooToolsSource/C7Collector/PTHarBethFilter.swift:23 | var | public | public var tools:[PTHarBethFilter.FiltersTool] = PTHarBethFilter.FiltersTool.allCases |
| PooToolsSource/C7Collector/PTHarBethFilter.swift:25 | var | public | public var name:String |
| PooToolsSource/C7Collector/PTHarBethFilter.swift:26 | var | public | public var type:FiltersTool |
| PooToolsSource/C7Collector/PTHarBethFilter.swift:28 | init | public | public init(name: String, type: FiltersTool) { |
| PooToolsSource/C7Collector/PTHarBethFilter.swift:60 | func | public | public func getCurrentFilterImage(image:UIImage?) -> UIImage { |
| PooToolsSource/C7Collector/PTHarBethFilter.swift:72 | func | public | public func getFilterResults() -> [FilterResult] { |
| PooToolsSource/C7Collector/PTHarBethFilter.swift:80 | enum | public | @objc public enum FiltersTool: Int, CaseIterable { |
| PooToolsSource/C7Collector/PTHarBethFilter.swift:116 | func | public | public func getFilterResult(texture: MTLTexture?) -> FilterResult { |
| PooToolsSource/C7Collector/PTHarBethFilter.swift:306 | func | public | public func filterValue(_ value: Float) -> Float { |
| PooToolsSource/C7Collector/PTTakePictureReviewer.swift:14 | class | public | public class PTTakePictureReviewer:UIView { |
| PooToolsSource/C7Collector/PTTakePictureReviewer.swift:57 | init | public | public init(screenShotImage:UIImage,dismiss: PTActionTask? = nil) { |
| PooToolsSource/Calendar/PTEventOnCalendar.swift:17 | struct | public | public struct PTSendableEventArrayBox: @unchecked Sendable { |
| PooToolsSource/Calendar/PTEventOnCalendar.swift:18 | let | public | public let events: [EKEvent] |
| PooToolsSource/Calendar/PTEventOnCalendar.swift:20 | init | public | public init(_ events: [EKEvent]) { |
| PooToolsSource/Calendar/PTEventOnCalendar.swift:25 | struct | public | public struct PTSendableReminderArrayBox: @unchecked Sendable { |
| PooToolsSource/Calendar/PTEventOnCalendar.swift:26 | let | public | public let reminder: [EKReminder] |
| PooToolsSource/Calendar/PTEventOnCalendar.swift:28 | init | public | public init(_ reminder: [EKReminder]) { |
| PooToolsSource/Calendar/PTEventOnCalendar.swift:34 | class | public | public class PTEventOnCalendar: NSObject { |
| PooToolsSource/Calendar/PTEventOnCalendar.swift:91 | class | public | public class func createEvent(startDate:DateInRegion, |
| PooToolsSource/Calendar/PTEventOnCalendar.swift:107 | class | public | public class func createEvent(startDate:DateInRegion, |
| PooToolsSource/CalendarPermission/PTPermissionCalendar.swift:19 | class | public | public class PTPermissionCalendar: PTPermission { |
| PooToolsSource/CalendarPermission/PTPermissionCalendar.swift:30 | var | open | open var usageDescriptionKey: String? { |
| PooToolsSource/CallMessageMail/PTCallMessageMailFunction.swift:13 | typealias | public | public typealias MessageResultBlock = (_ sendResult: MessageComposeResult) -> Void |
| PooToolsSource/CallMessageMail/PTCallMessageMailFunction.swift:14 | typealias | public | public typealias MailResultBlock = (_ sendResult: MFMailComposeResult) -> Void |
| PooToolsSource/CallMessageMail/PTCallMessageMailFunction.swift:18 | class | public | public class PTCallMessageMailFunction: NSObject { |
| PooToolsSource/CallMessageMail/PTCallMessageMailFunction.swift:29 | class | public | public class func telpromptByWebView(phone:String) { |
| PooToolsSource/CallMessageMail/PTCallMessageMailFunction.swift:38 | class | public | public class func sendMessage(content:String, |
| PooToolsSource/CallMessageMail/PTCallMessageMailFunction.swift:50 | class | public | public class func sendMail(title:String, |
| PooToolsSource/CallMessageMail/PTCallMessageMailFunction.swift:88 | func | public | @nonobjc public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) { |
| PooToolsSource/CallMessageMail/PTCallMessageMailFunction.swift:105 | func | public | public func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) { |
| PooToolsSource/CallMessageMail/PTCallMessageMailFunction.swift:112 | func | public | public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) { |
| PooToolsSource/CallMessageMail/PTPhoneBlock.swift:12 | typealias | public | public typealias CallBlock = (_ timeInterval:TimeInterval)->Void |
| PooToolsSource/CallMessageMail/PTPhoneBlock.swift:13 | typealias | public | public typealias CanCall = (_ ok:Bool)->Void |
| PooToolsSource/CallMessageMail/PTPhoneBlock.swift:17 | class | public | public class PTPhoneBlock: NSObject { |
| PooToolsSource/CallMessageMail/PTPhoneBlock.swift:22 | var | open | open var callBlock:CallBlock? |
| PooToolsSource/CallMessageMail/PTPhoneBlock.swift:23 | var | open | open var cancelBlock:PTActionTask? |
| PooToolsSource/CallMessageMail/PTPhoneBlock.swift:24 | var | open | open var canCall:CanCall? |
| PooToolsSource/CallMessageMail/PTPhoneBlock.swift:26 | class | public | public class func callPhoneNumber(phoneNumber:String,call:@escaping CallBlock,cancel:@escaping PTActionTask,canCall:@escaping CanCall) { |
| PooToolsSource/CallMessageMail/PTPhoneBlock.swift:45 | class | public | public class func validPhone(phoneNumber:String) -> Bool { |
| PooToolsSource/CameraPermission/PTPermissionCamera.swift:21 | class | public | public class PTPermissionCamera: PTPermission { |
| PooToolsSource/CameraPermission/PTPermissionCamera.swift:24 | var | open | open var usageDescriptionKey: String? { "NSCameraUsageDescription" } |
| PooToolsSource/Category/AVCaptureDevice+PTEX.swift:12 | struct | public | public struct VideoSpec { |
| PooToolsSource/Category/AVCaptureDevice+PTEX.swift:13 | var | public | public var fps: Int32? |
| PooToolsSource/Category/AVCaptureDevice+PTEX.swift:14 | var | public | public var size: CGSize? |
| PooToolsSource/Category/AVExport+PTEX.swift:13 | struct | public | public struct PTAssetExportResult: @unchecked Sendable { |
| PooToolsSource/Category/AVExport+PTEX.swift:14 | let | public | public let session: AVAssetExportSession |
| PooToolsSource/Category/AVExport+PTEX.swift:15 | let | public | public let duration: Float64 |
| PooToolsSource/Category/AVExport+PTEX.swift:16 | let | public | public let outputFullFilePath: String |
| PooToolsSource/Category/AVExport+PTEX.swift:17 | let | public | public let outputFilePath: String |
| PooToolsSource/Category/AVExport+PTEX.swift:19 | init | public | public init(session: AVAssetExportSession, duration: Float64, outputFullFilePath: String, outputFilePath: String) { |
| PooToolsSource/Category/AutoScale+PTEX.swift:12 | enum | public | public enum InchWidth: Double { |
| PooToolsSource/Category/AutoScale+PTEX.swift:25 | enum | public | public enum InchHeight: Double { |
| PooToolsSource/Category/CGFloat+PTEX.swift:14 | enum | public | @objc public enum TemperatureUnit: Int { |
| PooToolsSource/Category/CGFloat+PTEX.swift:125 | typealias | public | public typealias PTNumberValueAdapterType = CGFloat |
| PooToolsSource/Category/CGFloat+PTEX.swift:126 | var | public | public var adapter: CGFloat { |
| PooToolsSource/Category/CGRect+PTEX.swift:70 | typealias | public | public typealias PTNumberValueAdapterType = CGRect |
| PooToolsSource/Category/CGRect+PTEX.swift:71 | var | public | public var adapter: CGRect { |
| PooToolsSource/Category/CGSize+PTEX.swift:71 | typealias | public | public typealias PTNumberValueAdapterType = CGSize |
| PooToolsSource/Category/CGSize+PTEX.swift:72 | var | public | public var adapter: CGSize { |
| PooToolsSource/Category/CLGeocoder+PTEX.swift:12 | typealias | public | public typealias InChinaMainlandCallback = @Sendable (_ errMsg: String?, _ inChinaMainland: Bool) -> Void |
| PooToolsSource/Category/CLGeocoder+PTEX.swift:13 | typealias | public | public typealias InHMTCallback = @Sendable (_ errMsg: String?, _ inHMT: Bool) -> Void |
| PooToolsSource/Category/CLGeocoder+PTEX.swift:14 | typealias | public | public typealias CLPlacemarkCallback = @Sendable (_ errMsg: String?, _ placemark: CLPlacemark?) -> Void |
| PooToolsSource/Category/CLGeocoder+PTEX.swift:16 | enum | public | public enum IsoCountryCode: String { |
| PooToolsSource/Category/Date+PTEX.swift:16 | enum | public | public enum PTTimestampType: Int { |
| PooToolsSource/Category/Date+PTEX.swift:25 | enum | public | @objc public enum CheckContractTimeRelationships: Int { |
| PooToolsSource/Category/DateFormatter+PTEX.swift:14 | let | public | public let jx_formatter = DateFormatter() |
| PooToolsSource/Category/Device+PTEX.swift:17 | enum | public | public enum UIDeviceApplePencilSupportType { |
| PooToolsSource/Category/Device+PTEX.swift:358 | enum | public | public enum SystemSoundIDShockType: Int64 { |
| PooToolsSource/Category/Double+PTEX.swift:138 | typealias | public | public typealias PTNumberValueAdapterType = Double |
| PooToolsSource/Category/Double+PTEX.swift:139 | var | public | public var adapter: Double { |
| PooToolsSource/Category/FileManager+PTEX.swift:42 | enum | public | public enum BasePath { |
| PooToolsSource/Category/Float+PTEX.swift:83 | typealias | public | public typealias PTNumberValueAdapterType = Float |
| PooToolsSource/Category/Float+PTEX.swift:84 | var | public | public var adapter: Float { |
| PooToolsSource/Category/Int+PTEX.swift:11 | enum | public | public enum PTMontiStatusType:Int { |
| PooToolsSource/Category/Int+PTEX.swift:101 | typealias | public | public typealias PTNumberValueAdapterType = Int |
| PooToolsSource/Category/Int+PTEX.swift:102 | var | public | public var adapter: Int { |
| PooToolsSource/Category/NSDecimalNumberHandler+PTEX.swift:22 | enum | public | public enum RoundingMode : UInt { |
| PooToolsSource/Category/NSDecimalNumberHandler+PTEX.swift:32 | enum | public | public enum DecimalNumberHandlerType: String { |
| PooToolsSource/Category/NSImageView+PTEX.swift:14 | typealias | public | public typealias PTGIFImageTask = (NSImageView) -> Void |
| PooToolsSource/Category/NSImageView+PTEX.swift:15 | typealias | public | public typealias PTGIFImageFailTask = (NSImageView,URL,Error?) -> Void |
| PooToolsSource/Category/PTColorRBGModel.swift:12 | class | public | public class PTColorRBGModel: NSObject { |
| PooToolsSource/Category/PTColorRBGModel.swift:13 | var | public | public var redFloat:CGFloat = 0.0 |
| PooToolsSource/Category/PTColorRBGModel.swift:14 | var | public | public var greenFloat:CGFloat = 0.0 |
| PooToolsSource/Category/PTColorRBGModel.swift:15 | var | public | public var blueFloat:CGFloat = 0.0 |
| PooToolsSource/Category/PTColorRBGModel.swift:16 | var | public | public var alphaFloat:CGFloat = 0.0 |
| PooToolsSource/Category/PTColorRBGModel.swift:20 | class | public | public class PTColorHSBAModel: NSObject { |
| PooToolsSource/Category/PTColorRBGModel.swift:21 | var | public | public var hueFloat:CGFloat = 0.0 |
| PooToolsSource/Category/PTColorRBGModel.swift:22 | var | public | public var saturationFloat:CGFloat = 0.0 |
| PooToolsSource/Category/PTColorRBGModel.swift:23 | var | public | public var brightnessFloat:CGFloat = 0.0 |
| PooToolsSource/Category/PTColorRBGModel.swift:24 | var | public | public var alphaFloat:CGFloat = 0.0 |
| PooToolsSource/Category/PTList+EX.swift:15 | var | public | public var layoutVersion: Int = 0 |
| PooToolsSource/Category/PTList+EX.swift:17 | var | public | public var headerTitle: String? |
| PooToolsSource/Category/PTList+EX.swift:18 | var | public | public var headerID: String? |
| PooToolsSource/Category/PTList+EX.swift:19 | var | public | public var footerID: String? |
| PooToolsSource/Category/PTList+EX.swift:20 | var | public | public var footerHeight: CGFloat? = CGFloat.leastNormalMagnitude |
| PooToolsSource/Category/PTList+EX.swift:21 | var | public | public var headerHeight: CGFloat? = CGFloat.leastNormalMagnitude |
| PooToolsSource/Category/PTList+EX.swift:22 | var | public | public var rows: [PTRows]? |
| PooToolsSource/Category/PTList+EX.swift:23 | var | public | public var headerDataModel: AnyObject? |
| PooToolsSource/Category/PTList+EX.swift:24 | var | public | public var footerDataModel: AnyObject? |
| PooToolsSource/Category/PTList+EX.swift:26 | var | public | public var footerClass: UICollectionReusableView.Type? |
| PooToolsSource/Category/PTList+EX.swift:27 | var | public | public var headerClass: UICollectionReusableView.Type? |
| PooToolsSource/Category/PTList+EX.swift:29 | var | public | public var decorationBackgroundColor: UIColor? = PTAppBaseConfig.share.decorationBackgroundColor |
| PooToolsSource/Category/PTList+EX.swift:30 | var | public | public var decorationCornerRadius: CGFloat = PTAppBaseConfig.share.decorationBackgroundCornerRadius |
| PooToolsSource/Category/PTList+EX.swift:31 | var | public | public var decorationBackgroundImage: UIImage? |
| PooToolsSource/Category/PTList+EX.swift:32 | var | public | public var decorationShadowOpacity: Float = 0.08 |
| PooToolsSource/Category/PTList+EX.swift:34 | init | public | public init(identifier: String = UUID().uuidString, |
| PooToolsSource/Category/PTList+EX.swift:67 | func | public | public func isSameIdentity(as other: PTSection) -> Bool { |
| PooToolsSource/Category/PTList+EX.swift:71 | var | public | public var headerReuseID: String? { |
| PooToolsSource/Category/PTList+EX.swift:78 | var | public | public var footerReuseID: String? { |
| PooToolsSource/Category/PTList+EX.swift:86 | func | public | public func isContentEqual(to other: PTSection) -> Bool { |
| PooToolsSource/Category/PTList+EX.swift:113 | var | public | public var diffHash: Int = 0 |
| PooToolsSource/Category/PTList+EX.swift:115 | var | public | public var title = "" |
| PooToolsSource/Category/PTList+EX.swift:116 | var | public | public var ID: String = "" |
| PooToolsSource/Category/PTList+EX.swift:117 | var | public | public var dataModel: AnyObject? |
| PooToolsSource/Category/PTList+EX.swift:118 | var | public | public var nibName = "" |
| PooToolsSource/Category/PTList+EX.swift:119 | var | public | public var badge: Int = 0 |
| PooToolsSource/Category/PTList+EX.swift:121 | var | public | public var cellClass: UICollectionViewCell.Type? |
| PooToolsSource/Category/PTList+EX.swift:123 | init | public | public init(title: String = "", |
| PooToolsSource/Category/PTList+EX.swift:140 | var | public | public var reuseID: String { |
| PooToolsSource/Category/PTList+EX.swift:164 | func | public | public func isSameIdentity(as other: PTRows) -> Bool { |
| PooToolsSource/Category/PTList+EX.swift:169 | func | public | public func isContentEqual(to other: PTRows) -> Bool { |
| PooToolsSource/Category/PTList+EX.swift:203 | protocol | public | public protocol PTCellRegisterable { |
| PooToolsSource/Category/PTList+EX.swift:213 | protocol | public | public protocol PTSupplementaryRegisterable { |
| PooToolsSource/Category/PTList+EX.swift:225 | func | public | public func registerClassCells(classs:[String:AnyClass]) { |
| PooToolsSource/Category/PTList+EX.swift:233 | func | public | public func registerNibCells(nib:[String:String]) { |
| PooToolsSource/Category/PTList+EX.swift:241 | func | public | public func registerSupplementaryView(classs:[String:AnyClass],kind:String) { |
| PooToolsSource/Category/PTList+EX.swift:250 | func | public | public func registerSupplementaryView(ids:[String],viewClass:AnyClass,kind:String) { |
| PooToolsSource/Category/PTVideoThumbnailService.swift:17 | struct | public | public struct PTVideoThumbnailRequest: Sendable { |
| PooToolsSource/Category/PTVideoThumbnailService.swift:18 | let | public | public let url: URL |
| PooToolsSource/Category/PTVideoThumbnailService.swift:19 | let | public | public let frameNumber: Int |
| PooToolsSource/Category/PTVideoThumbnailService.swift:20 | let | public | public let maximumSize: CGSize |
| PooToolsSource/Category/PTVideoThumbnailService.swift:21 | let | public | public let appliesPreferredTrackTransform: Bool |
| PooToolsSource/Category/PTVideoThumbnailService.swift:23 | init | public | public init(url: URL, |
| PooToolsSource/Category/PTVideoThumbnailService.swift:38 | protocol | public | public protocol PTVideoThumbnailProviding { |
| PooToolsSource/Category/PTVideoThumbnailService.swift:46 | struct | public | public struct PTDefaultVideoThumbnailProvider: PTVideoThumbnailProviding { |
| PooToolsSource/Category/PTVideoThumbnailService.swift:47 | init | public | public init() {} |
| PooToolsSource/Category/PTVideoThumbnailService.swift:49 | func | public | public func image(for request: PTVideoThumbnailRequest) async -> UIImage? { |
| PooToolsSource/Category/PTVideoThumbnailService.swift:57 | enum | public | public enum PTVideoThumbnailService { |
| PooToolsSource/Category/String+PTEX+Crypto.swift:27 | enum | public | public enum DDYSCAType { |
| PooToolsSource/Category/String+PTEX+Crypto.swift:120 | enum | public | public enum DDYSHAType { |
| PooToolsSource/Category/String+PTEX.swift:38 | enum | public | public enum PStrengthLevel { |
| PooToolsSource/Category/String+PTEX.swift:46 | enum | public | public enum UTF8StringType:Int { |
| PooToolsSource/Category/String+PTEX.swift:52 | enum | public | public enum StringTypeLength { |
| PooToolsSource/Category/String+PTEX.swift:67 | enum | public | public enum PTHashType { |
| PooToolsSource/Category/String+PTEX.swift:76 | enum | public | public enum PTConstellationType { |
| PooToolsSource/Category/UIButton+PTEX.swift:15 | typealias | public | public typealias TouchedBlock = (_ sender:UIButton) -> Void |
| PooToolsSource/Category/UIButton+PTEX.swift:282 | class | public | public class ConsoleMenuButton: UIButton { } |
| PooToolsSource/Category/UIColor+PTEX.swift:11 | enum | public | public enum PTColorTone { |
| PooToolsSource/Category/UIFont+PTEX.swift:207 | typealias | public | public typealias PTNumberValueAdapterType = UIFont |
| PooToolsSource/Category/UIFont+PTEX.swift:208 | var | public | public var adapter: UIFont { |
| PooToolsSource/Category/UIGestureRecognizer+PTEX.swift:11 | typealias | public | public typealias TapedBlock = (_ sender:AnyObject) -> Void |
| PooToolsSource/Category/UIImage+PTEX.swift:1171 | enum | public | public enum CompressionMode: Sendable { |
| PooToolsSource/Category/UIImage+PTFaceAware.swift:34 | var | public | public var debugFaceAware: Bool { |
| PooToolsSource/Category/UIImage+PTFaceAware.swift:45 | var | public | public var focusOnFaces: Bool { |
| PooToolsSource/Category/UIImage+PTFaceAware.swift:55 | var | public | public var didFocusOnFaces: (() -> Void)? { |
| PooToolsSource/Category/UIImage+PTFaceAware.swift:69 | func | public | public func set(image: UIImage?, focusOnFaces: Bool) { |
| PooToolsSource/Category/UIImageView+PTEX.swift:133 | typealias | public | public typealias PTGIFImageTask = (UIImageView) -> Void |
| PooToolsSource/Category/UIImageView+PTEX.swift:134 | typealias | public | public typealias PTGIFImageFailTask = (UIImageView,URL,Error?) -> Void |
| PooToolsSource/Category/UIPageControl+PTEX.swift:12 | typealias | public | public typealias PageControlTouchedBlock = (_ sender:UIPageControl) -> Void |
| PooToolsSource/Category/UIRefreshControl+PTEX.swift:10 | typealias | public | public typealias RefreshedBlock = (_ sender:UIRefreshControl) -> Void |
| PooToolsSource/Category/UIScreen+PTEX.swift:13 | enum | public | public enum UIScreenShotType { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:13 | enum | public | public enum PTRefreshState: Sendable { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:21 | struct | public | public struct PTRefreshTextConfig: Sendable { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:22 | var | public | public var idleText: String |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:23 | var | public | public var pullingText: String |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:24 | var | public | public var refreshingText: String |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:25 | var | public | public var noMoreDataText: String |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:26 | var | public | public var font: UIFont |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:27 | var | public | public var textColor: UIColor |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:28 | var | public | public var dimension: CGFloat |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:30 | var | public | public var showLastTime: Bool |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:31 | var | public | public var timeFont: UIFont |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:32 | var | public | public var timeColor: UIColor |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:34 | var | public | public var automaticallyHidden: Bool |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:37 | var | public | public var animationDuration: TimeInterval |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:39 | var | public | public var springDamping: CGFloat |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:41 | var | public | public var isHapticFeedbackEnabled: Bool |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:43 | var | public | public var showText: Bool |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:55 | var | public | public var header = PTRefreshTextConfig(idleText: "下拉可以刷新", |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:73 | var | public | public var footer = PTRefreshTextConfig(idleText: "上拉可以加载更多", |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:91 | var | public | public var leftHeader = PTRefreshTextConfig(idleText: "向右\n滑动", |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:108 | var | public | public var trailer = PTRefreshTextConfig(idleText: "滑动\n加载", |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:134 | class | open | open class PTRefreshComponent: UIView { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:144 | let | public | public let action: @MainActor () async -> Void |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:145 | var | public | public var currentTask: Task<Void, Never>? |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:148 | let | public | public let textLabel = UILabel() |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:149 | let | public | public let activityIndicator = UIActivityIndicatorView(style: .medium) |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:153 | var | public | public var triggerAutomaticallyRefreshPercent: CGFloat = 1.0 |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:156 | var | public | public var pullingPercent: CGFloat = 0.0 { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:165 | var | public | public var pullingPercentHandler: (@MainActor (CGFloat) -> Void)? |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:167 | var | public | public var stateChangedHandler: (@MainActor (PTRefreshState) -> Void)? |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:170 | var | public | public var customDimension: CGFloat? |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:174 | var | public | public var customStateTitles: [PTRefreshState: String] = [:] |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:175 | var | public | public var customFont: UIFont? |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:176 | var | public | public var customTextColor: UIColor? |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:179 | var | public | public var customView: UIView? |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:182 | var | public | public var state: PTRefreshState = .idle { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:195 | let | public | public let timeLabel = UILabel() |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:198 | var | public | public var lastTimeKey: String? { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:203 | var | public | public var customShowLastTime: Bool? |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:204 | var | public | public var customTimeFont: UIFont? |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:205 | var | public | public var customTimeColor: UIColor? |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:207 | var | public | public var customAutomaticallyHidden: Bool? |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:210 | var | public | public var customAnimationDuration: TimeInterval? |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:211 | var | public | public var customSpringDamping: CGFloat? |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:213 | var | public | public var customHapticFeedback: Bool? |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:215 | var | public | public var customShowText: Bool? |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:218 | init | public | public init(action: @escaping @MainActor () async -> Void) { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:231 | func | public | public func setTitle(_ title: String, for state: PTRefreshState) -> Self { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:242 | func | public | public func setTextColor(_ color: UIColor) -> Self { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:250 | func | public | public func setFont(_ font: UIFont) -> Self { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:258 | func | public | public func setDimension(_ dimension: CGFloat) -> Self { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:264 | func | public | public func onPullingPercentChanged(_ handler: @escaping @MainActor (CGFloat) -> Void) -> Self { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:270 | func | public | public func setShowLastTime(_ show: Bool) -> Self { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:278 | func | public | public func setTimeColor(_ color: UIColor) -> Self { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:286 | func | public | public func setTimeFont(_ font: UIFont) -> Self { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:294 | func | public | public func setLastTimeKey(_ key: String) -> Self { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:300 | func | public | public func setAutomaticallyHidden(_ hidden: Bool) -> Self { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:307 | func | open | open func checkAutomaticallyHidden() {} |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:311 | func | public | public func setCustomView(_ view: UIView) -> Self { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:327 | func | public | public func setSpringDamping(_ damping: CGFloat) -> Self { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:334 | func | public | public func setAnimationDuration(_ duration: TimeInterval) -> Self { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:341 | func | public | public func onStateChanged(_ handler: @escaping @MainActor (PTRefreshState) -> Void) -> Self { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:347 | func | public | public func setHapticFeedback(_ enabled: Bool) -> Self { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:353 | func | public | public func setShowText(_ show: Bool) -> Self { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:360 | var | open | open var isHapticEnabled: Bool { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:364 | var | public | public var ignoredContentInsetTop: CGFloat = 0.0 |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:365 | var | public | public var ignoredContentInsetBottom: CGFloat = 0.0 |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:366 | var | public | public var ignoredContentInsetLeft: CGFloat = 0.0 |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:367 | var | public | public var ignoredContentInsetRight: CGFloat = 0.0 |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:370 | func | public | public func setIgnoredContentInsetTop(_ inset: CGFloat) -> Self { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:376 | func | public | public func setIgnoredContentInsetBottom(_ inset: CGFloat) -> Self { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:382 | func | public | public func setIgnoredContentInsetLeft(_ inset: CGFloat) -> Self { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:388 | func | public | public func setIgnoredContentInsetRight(_ inset: CGFloat) -> Self { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:394 | func | public | public func resolvedTitle(for state: PTRefreshState, globalConfig: PTRefreshTextConfig) -> String { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:416 | func | open | open func setupUI() { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:454 | func | open | open func scrollViewContentSizeDidChange() {} |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:455 | func | open | open func scrollViewContentOffsetDidChange() {} |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:456 | func | open | open func scrollViewContentInsetDidChange() {} |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:457 | func | open | open func stateDidChanged(from oldState: PTRefreshState, to newState: PTRefreshState) {} |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:459 | func | open | open func pullingPercentDidChange(percent: CGFloat) {} |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:462 | func | open | open func scrollViewPanStateDidChange() { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:469 | func | public | public func beginRefreshing() { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:474 | func | public | public func endRefreshing() { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:481 | func | public | public func endRefreshingWithNoMoreData() { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:487 | func | public | public func resetNoMoreData() { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:491 | func | public | public func executeAction() { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:505 | func | public | public func updateTimeLabel() { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:524 | class | open | open class PTRefreshHeader: PTRefreshComponent { |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:1167 | let | public | public let gifView = UIImageView() |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:1211 | func | public | public func setImages(_ images: [UIImage], duration: TimeInterval? = nil, for state: PTRefreshState) -> Self { |
| PooToolsSource/Category/UISlider+PTEX.swift:11 | typealias | public | public typealias SliderBlock = (_ sender:UISlider) -> Void |
| PooToolsSource/Category/UISwitch+PTEX.swift:11 | typealias | public | public typealias SwitchBlock = (_ sender:UISwitch) -> Void |
| PooToolsSource/Category/UITabBar+PTEX.swift:33 | var | public | @MainActor public var standardAppearance: UITabBarAppearance { |
| PooToolsSource/Category/UITabBar+PTEX.swift:48 | var | public | @MainActor public var scrollEdgeAppearance: UITabBarAppearance { |
| PooToolsSource/Category/UIToolbar+PTEX.swift:33 | var | public | @MainActor public var standardAppearance: UIToolbarAppearance { |
| PooToolsSource/Category/UIToolbar+PTEX.swift:48 | var | public | @MainActor public var scrollEdgeAppearance: UIToolbarAppearance { |
| PooToolsSource/Category/UIView+PTEX.swift:16 | enum | public | @objc public enum Imagegradien:Int { |
| PooToolsSource/Category/UIView+PTEX.swift:25 | typealias | public | public typealias LayoutSubviewsCallback = (_ view:UIView) -> Void |
| PooToolsSource/Category/UIView+PTEX.swift:1803 | protocol | public | public protocol UIFadeOut {} |
| PooToolsSource/Category/UIView+PTEX.swift:1817 | func | public | public func fadeUpdate(duration: TimeInterval = 1, |
| PooToolsSource/Category/UIViewController+PTEX.swift:18 | enum | public | @objc public enum PTSheetPresentType:Int { |
| PooToolsSource/Category/UIViewController+PTEX.swift:513 | func | public | public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle { |
| PooToolsSource/Category/UIViewController+PTEX.swift:519 | func | public | public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle { |
| PooToolsSource/Category/UIViewController+PTEX.swift:526 | func | public | public func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>) { |
| PooToolsSource/Category/UIViewController+PTEX.swift:535 | class | public | public class func newPresentStyleWithoutZoom(current:UIViewController,target:UIViewController,type:UIViewController.Transition = .partialCurl,animated:Bool = true,completion:PTActionTask? = nil) { |
| PooToolsSource/Category/UIViewController+PTEX.swift:552 | class | public | public class func newZoomPresentStyle(current:UIViewController,target:UIViewController,source:UIView,animated:Bool = true,completion:PTActionTask? = nil) { |
| PooToolsSource/CheckBox/PTCheckBox.swift:11 | typealias | public | public typealias PTCheckboxValueChangedBlock = (_ isChecked: Bool) -> Void |
| PooToolsSource/CheckBox/PTCheckBox.swift:13 | enum | public | public enum PTCheckBoxStyle: Int { |
| PooToolsSource/CheckBox/PTCheckBox.swift:24 | enum | public | public enum PTCheckBoxBorderStyle: Int { |
| PooToolsSource/CheckBox/PTCheckBox.swift:32 | class | public | public class PTCheckBox: UIControl { |
| PooToolsSource/CheckBox/PTCheckBox.swift:34 | var | open | open var valueChanged: PTCheckboxValueChangedBlock? |
| PooToolsSource/CheckBox/PTCheckBox.swift:36 | var | open | open var checkmarkStyle: PTCheckBoxStyle = .Square |
| PooToolsSource/CheckBox/PTCheckBox.swift:38 | var | open | open var borderStyle: PTCheckBoxBorderStyle = .Square |
| PooToolsSource/CheckBox/PTCheckBox.swift:40 | var | open | open var boxBorderWidth: CGFloat = 2 { didSet { setNeedsDisplay() } } |
| PooToolsSource/CheckBox/PTCheckBox.swift:42 | var | open | open var checkmarkSize: CGFloat = 0.5 { didSet { setNeedsDisplay() } } |
| PooToolsSource/CheckBox/PTCheckBox.swift:44 | var | open | open var checkboxBackgroundColor: UIColor = .clear { didSet { setNeedsDisplay() } } |
| PooToolsSource/CheckBox/PTCheckBox.swift:46 | var | open | open var increasedTouchRadius: CGFloat = 5 |
| PooToolsSource/CheckBox/PTCheckBox.swift:48 | var | open | open var isAnimated: Bool = true |
| PooToolsSource/CheckBox/PTCheckBox.swift:51 | var | open | open var isChecked: Bool = true { |
| PooToolsSource/CheckBox/PTCheckBox.swift:58 | var | open | open var useHapticFeedback: Bool = true |
| PooToolsSource/CheckDirtyWord/PTCheckFWords.swift:16 | class | public | public class PTCheckFWords: NSObject { |
| PooToolsSource/CheckDirtyWord/PTCheckFWords.swift:20 | var | open | open var isFilterClose:Bool = false |
| PooToolsSource/CheckDirtyWord/PTCheckFWords.swift:27 | func | public | public func initFilter(filePath:String = Bundle.podBundleResource(bundleName: "PooToolsCheckDirtyWordResource", sourceName: "minganci", type: "txt")!) { |
| PooToolsSource/CheckDirtyWord/PTCheckFWords.swift:56 | func | public | public func haveFWord(str:NSString) -> Bool { |
| PooToolsSource/CheckDirtyWord/PTCheckFWords.swift:82 | func | public | public func filter(str:NSString) -> NSString { |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:87 | class | public | public class-based decoder API can migrate to immutable snapshot structs. |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:89 | class | public | public class PTTFPaging :PTCodableModelProtocol,@unchecked Sendable { |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:90 | var | public | public var total: Int = 0 |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:91 | var | public | public var limit: Int = 0 |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:95 | class | public | public class PTTFMeta :PTCodableModelProtocol,@unchecked Sendable { |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:96 | var | public | @SmartAny public var paging: PTTFPaging? |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:100 | class | public | public class PTTLinkMainModel:PTCodableModelProtocol,@unchecked Sendable { |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:101 | var | public | @SmartAny public var links: PTTFLinks? |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:105 | class | public | public class PTTFRelationships :PTCodableModelProtocol,@unchecked Sendable { |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:106 | var | public | @SmartAny public var app: PTTLinkMainModel? |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:107 | var | public | @SmartAny public var builds: PTTLinkMainModel? |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:108 | var | public | @SmartAny public var betaAppReviewSubmission:PTTLinkMainModel? |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:109 | var | public | @SmartAny public var appStoreVersion:PTTLinkMainModel? |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:110 | var | public | @SmartAny public var appEncryptionDeclaration:PTTLinkMainModel? |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:111 | var | public | @SmartAny public var individualTesters:PTTLinkMainModel? |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:112 | var | public | @SmartAny public var perfPowerMetrics:PTTLinkMainModel? |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:113 | var | public | @SmartAny public var betaBuildLocalizations:PTTLinkMainModel? |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:114 | var | public | @SmartAny public var betaGroups:PTTLinkMainModel? |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:115 | var | public | @SmartAny public var diagnosticSignatures:PTTLinkMainModel? |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:116 | var | public | @SmartAny public var preReleaseVersion:PTTLinkMainModel? |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:117 | var | public | @SmartAny public var buildBetaDetail:PTTLinkMainModel? |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:118 | var | public | @SmartAny public var icons:PTTLinkMainModel? |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:122 | class | public | public class PTTFLinks :PTCodableModelProtocol,@unchecked Sendable { |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:123 | var | public | public var currentLink: String = "" |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:124 | var | public | public var related: String = "" |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:125 | var | public | public var next:String = "" |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:129 | class | public | public class func mappingForKey() -> [SmartKeyTransformer]? { |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:134 | class | public | public class PTTFIconAssetTokenModle:PTCodableModelProtocol,@unchecked Sendable { |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:135 | var | public | public var width:CGFloat = 0 |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:136 | var | public | public var templateUrl:String = "" |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:137 | var | public | public var height:CGFloat = 0 |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:142 | class | public | public class PTTFAttributes :PTCodableModelProtocol,@unchecked Sendable { |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:143 | var | public | public var version: String = "" |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:144 | var | public | public var platform: String = "" |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:145 | var | public | public var minOsVersion:String = "" |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:146 | var | public | public var computedMinMacOsVersion:String = "" |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:147 | var | public | public var lsMinimumSystemVersion:String = "" |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:148 | var | public | public var uploadedDate:String = "" |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:149 | var | public | public var expired:Bool = true |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:150 | var | public | public var processingState:String = "" |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:151 | var | public | public var buildAudienceType:String = "" |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:152 | var | public | public var expirationDate:String = "" |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:153 | var | public | public var usesNonExemptEncryption:Bool = false |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:154 | var | public | public var computedMinVisionOsVersion:String = "" |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:155 | var | public | @SmartAny public var iconAssetToken:PTTFIconAssetTokenModle? |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:156 | var | public | public var locale:String = "" |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:157 | var | public | public var whatsNew:String = "" |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:158 | var | public | public var publicLink:String = "" |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:159 | var | public | public var name:String = "" |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:163 | var | public | public var processingStateBool:Bool { |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:173 | class | public | public class PTTFVersionData :PTCodableModelProtocol,@unchecked Sendable { |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:174 | var | public | public var id: String = "" |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:175 | var | public | @SmartAny public var relationships: PTTFRelationships? |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:176 | var | public | @SmartAny public var links: PTTFLinks? |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:177 | var | public | public var type: String = "" |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:178 | var | public | @SmartAny public var attributes: PTTFAttributes? |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:183 | class | public | public class PTTFModelCollection :PTCodableModelProtocol,@unchecked Sendable { |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:184 | var | public | @SmartAny public var meta: PTTFMeta? |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:185 | var | public | @SmartAny public var links: PTTFLinks? |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:186 | var | public | @SmartAny public var data: [PTTFVersionData]? |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:191 | class | public | public class PTTFNewerBuildVersionModel:PTCodableModelProtocol,@unchecked Sendable { |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:192 | var | public | @SmartAny public var links:PTTFLinks? |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:193 | var | public | @SmartAny public var data:PTTFVersionData? |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:198 | struct | public | public struct PTAppleClaims: Claims, Sendable { |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:205 | class | public | public class PTTFUpdateCustomModel:PTCodableModelProtocol,@unchecked Sendable { |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:214 | class | public | public class PTCheckUpdateFunction: NSObject,@unchecked Sendable { |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:220 | enum | public | public enum PTUpdateAlertType:Int { |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:225 | func | public | @MainActor public func renewVersion(newVersion:String) -> (String,String) { |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:242 | func | public | @MainActor public func tfUpdate(force:Bool, |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:274 | func | public | @MainActor public func updateAlert(force:Bool, |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:318 | func | public | @MainActor public func checkUpdateAlert(appid:String, |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:332 | func | public | @MainActor public func checkTheVersionWithappid(appid:String? = nil, |
| PooToolsSource/Circle/PTHalfCircleView.swift:11 | enum | public | @objc public enum PTHalfCircleViewType:Int,CaseIterable { |
| PooToolsSource/Circle/PTHalfCircleView.swift:19 | class | public | public class PTHalfCircleView: UIView { |
| PooToolsSource/Circle/PTHalfCircleView.swift:20 | var | public | public var circleType:PTHalfCircleViewType = .Right |
| PooToolsSource/Circle/PTHalfCircleView.swift:21 | var | public | public var diameter:CGFloat = 19 |
| PooToolsSource/Circle/PTHalfCircleView.swift:22 | var | public | public var circleColor:UIColor = .systemRed |
| PooToolsSource/CodeView/PTCodeView.swift:12 | class | public | public class PTCodeView: UIView { |
| PooToolsSource/CodeView/PTCodeView.swift:23 | var | open | open var codeBlock:((_ codeView:PTCodeView, _ code:String) -> Void)? |
| PooToolsSource/CodeView/PTCodeView.swift:31 | init | public | public init(numberOfCodes:Int = 4, |
| PooToolsSource/CodeView/PTCodeView.swift:90 | func | public | public func changeCode() { |
| PooToolsSource/Colors/Color+PTDerivingEX.swift:15 | enum | public | public enum GrayscalingMode { |
| PooToolsSource/Colors/Color+PTDynamicEX.swift:14 | enum | public | public enum DynamicColorSpace: Sendable { |
| PooToolsSource/Colors/Color+PTDynamicEX.swift:25 | enum | public | @objc public enum ColorDistanceType:Int { |
| PooToolsSource/Colors/Color+PTDynamicEX.swift:39 | typealias | public | public typealias DynamicColor = UIColor |
| PooToolsSource/Colors/Color+PTDynamicEX.swift:48 | typealias | public | public typealias DynamicColor = NSColor |
| PooToolsSource/Colors/PTColorHSL.swift:38 | init | public | public init(hue: CGFloat, saturation: CGFloat, lightness: CGFloat, alpha: CGFloat = 1.0) { |
| PooToolsSource/Colors/PTColorHSL.swift:48 | init | public | public init(color: DynamicColor) { |
| PooToolsSource/Colors/PTColorHSL.swift:129 | func | public | public func lighter(@PTClampedPropertyWrapper(range: 0...1) amount: CGFloat) -> HSL { |
| PooToolsSource/Colors/PTColorHSL.swift:136 | func | public | public func darkened(@PTClampedPropertyWrapper(range: 0...1) amount: CGFloat) -> HSL { |
| PooToolsSource/Colors/PTColorHSL.swift:144 | func | public | public func saturated(@PTClampedPropertyWrapper(range: 0...1) amount: CGFloat) -> HSL { |
| PooToolsSource/Colors/PTColorHSL.swift:151 | func | public | public func desaturated(@PTClampedPropertyWrapper(range: 0...1) amount: CGFloat) -> HSL { |
| PooToolsSource/Colors/PTDynamicGradient.swift:19 | struct | public | public struct PTDynamicGradient: Sendable { |
| PooToolsSource/Colors/PTDynamicGradient.swift:20 | let | public | public let colors: [DynamicColor] |
| PooToolsSource/Colors/PTDynamicGradient.swift:27 | init | public | public init(colors: [DynamicColor]) { |
| PooToolsSource/Colors/PTDynamicGradient.swift:34 | func | public | public func colorPalette(@PTClampedPropertyWrapper(range: 2...UInt.max) amount: UInt = 2, inColorSpace colorspace: DynamicColorSpace = .rgb) -> [DynamicColor] { |
| PooToolsSource/Colors/PTDynamicGradient.swift:48 | func | public | public func pickColorAt(@PTClampedPropertyWrapper(range: 0...1) scale: CGFloat, inColorSpace colorspace: DynamicColorSpace = .rgb) -> DynamicColor { |
| PooToolsSource/Colors/UIImage+PTColorEX.swift:11 | typealias | public | public typealias UIImage = NSImage |
| PooToolsSource/Colors/UIImage+PTColorEX.swift:12 | typealias | public | public typealias UIColor = NSColor |
| PooToolsSource/Colors/UIImage+PTColorEX.swift:18 | struct | public | public struct UIImageColors: Sendable { |
| PooToolsSource/Colors/UIImage+PTColorEX.swift:19 | let | public | public let background: UIColor |
| PooToolsSource/Colors/UIImage+PTColorEX.swift:20 | let | public | public let primary: UIColor |
| PooToolsSource/Colors/UIImage+PTColorEX.swift:21 | let | public | public let secondary: UIColor |
| PooToolsSource/Colors/UIImage+PTColorEX.swift:22 | let | public | public let detail: UIColor |
| PooToolsSource/Colors/UIImage+PTColorEX.swift:24 | init | public | public init(background: UIColor, primary: UIColor, secondary: UIColor, detail: UIColor) { |
| PooToolsSource/Colors/UIImage+PTColorEX.swift:32 | enum | public | public enum UIImageColorsQuality: CGFloat, Sendable { |
| PooToolsSource/Colors/UIImage+PTColorEX.swift:149 | func | public | public func getColors(quality: UIImageColorsQuality = .high, _ completion: @escaping @MainActor @Sendable (UIImageColors?) -> Void) { |
| PooToolsSource/Colors/UIImage+PTColorEX.swift:159 | func | public | public func getColors(quality: UIImageColorsQuality = .high) -> UIImageColors? { |
| PooToolsSource/Contact/PTContact.swift:23 | class | public | public class PTContactIndexModel: NSObject { |
| PooToolsSource/Contact/PTContact.swift:24 | var | open | open var indexStrings:[String] = [String]() |
| PooToolsSource/Contact/PTContact.swift:25 | var | open | open var contractModel:[PTContactModel] = [PTContactModel]() |
| PooToolsSource/Contact/PTContact.swift:30 | class | public | public class PTContactModel: NSObject { |
| PooToolsSource/Contact/PTContact.swift:31 | var | open | open var key:String = "" |
| PooToolsSource/Contact/PTContact.swift:32 | var | open | open var contractModel:[PTContactSubModel] = [PTContactSubModel]() |
| PooToolsSource/Contact/PTContact.swift:37 | class | public | public class PTContactSubModel: NSObject { |
| PooToolsSource/Contact/PTContact.swift:38 | var | open | open var givenName:String = "" |
| PooToolsSource/Contact/PTContact.swift:39 | var | open | open var familyName:String = "" |
| PooToolsSource/Contact/PTContact.swift:40 | var | open | open var phonenumbers:[String] = [] |
| PooToolsSource/Contact/PTContact.swift:41 | var | open | open var image:UIImage? |
| PooToolsSource/Contact/PTContact.swift:46 | class | public | public class PTContact: NSObject { |
| PooToolsSource/Contact/PTContact.swift:94 | func | public | public func getContactData(handle: @escaping @MainActor @Sendable (_ model:PTContactIndexModel?) -> Void) { |
| PooToolsSource/ContactsPermission/PTPermissionContacts.swift:19 | class | public | public class PTPermissionContacts: PTPermission { |
| PooToolsSource/ContactsPermission/PTPermissionContacts.swift:22 | var | open | open var usageDescriptionKey: String? { "NSContactsUsageDescription" } |
| PooToolsSource/Core/OSSVoice.swift:33 | struct | public | public struct OSSVoiceInfo: Sendable { |
| PooToolsSource/Core/OSSVoice.swift:34 | var | public | public var name: String? |
| PooToolsSource/Core/OSSVoice.swift:35 | var | public | public var language: String? |
| PooToolsSource/Core/OSSVoice.swift:36 | var | public | public var languageCode: String? |
| PooToolsSource/Core/OSSVoice.swift:38 | var | public | public var identifier: String? |
| PooToolsSource/Core/OSSVoice.swift:42 | enum | public | public enum OSSVoiceEnum: String, CaseIterable, Sendable { |
| PooToolsSource/Core/OSSVoice.swift:91 | func | public | public func getDetails() -> OSSVoiceInfo { |
| PooToolsSource/Core/OSSVoice.swift:102 | var | public | public var title: String { |
| PooToolsSource/Core/OSSVoice.swift:106 | var | public | public var demoMessage: String { |
| PooToolsSource/Core/OSSVoice.swift:147 | var | public | public var flag: UIImage? { |
| PooToolsSource/Core/OSSVoice.swift:155 | var | public | public var flag: NSImage? { |
| PooToolsSource/Core/OSSVoice.swift:162 | class | public | public class OSSVoice: AVSpeechSynthesisVoice, @unchecked Sendable { |
| PooToolsSource/Core/OSSVoice.swift:188 | var | public | public var voiceType: OSSVoiceEnum { |
| PooToolsSource/Core/OSSVoice.swift:197 | init | public | public init?(quality: AVSpeechSynthesisVoiceQuality, language: OSSVoiceEnum) { |
| PooToolsSource/Core/PTAppUserdefault.swift:12 | let | public | public let DevNetWorkKey = "UI_test_url" |
| PooToolsSource/Core/PTAppUserdefault.swift:13 | let | public | public let DevSocketKey = "UI_test_socket_url" |
| PooToolsSource/Core/PTAppUserdefault.swift:14 | let | public | public let PTDevMaskTouchBubbleKey = "PTDevMaskTouchBubbleKey" |
| PooToolsSource/Core/PTAppUserdefault.swift:15 | let | public | public let PTDevMaskKey = "PTDevMaskKey" |
| PooToolsSource/Core/PTAppUserdefault.swift:16 | let | public | public let ConsoleDebug = "UI_debug" |
| PooToolsSource/Core/PTAppUserdefault.swift:17 | let | public | public let TouchInspectorDebug = "TS_debug" |
| PooToolsSource/Core/PTAppUserdefault.swift:18 | let | public | public let TouchInspectorHitsDebug = "TS_Hit_debug" |
| PooToolsSource/Core/PTAppUserdefault.swift:67 | var | public | public var AppNoMoreShowUpdate: Bool { |
| PooToolsSource/Core/PTAppUserdefault.swift:74 | var | public | public var AppServiceIdentifier: String? { |
| PooToolsSource/Core/PTAppUserdefault.swift:80 | var | public | public var AppSocketServiceIdentifier: String? { |
| PooToolsSource/Core/PTAppUserdefault.swift:87 | var | public | public var AppSocketUrl: String { |
| PooToolsSource/Core/PTAppUserdefault.swift:93 | var | public | public var AppRequestUrl: String { |
| PooToolsSource/Core/PTAppUserdefault.swift:100 | var | public | public var AppDebugMode: Bool { |
| PooToolsSource/Core/PTAppUserdefault.swift:107 | var | public | public var WebImageOption: Bool { |
| PooToolsSource/Core/PTAppUserdefault.swift:114 | var | public | public var AppDebbugTouchBubble: Bool { |
| PooToolsSource/Core/PTAppUserdefault.swift:121 | var | public | public var AppDebbugMark: Bool { |
| PooToolsSource/Core/PTAppUserdefault.swift:128 | var | public | public var AppTouchInspectShow: Bool { |
| PooToolsSource/Core/PTAppUserdefault.swift:135 | var | public | public var AppTouchInspectShowHits: Bool { |
| PooToolsSource/Core/PTAppUserdefault.swift:140 | var | public | public var LocalConsoleCurrentFontSize: CGFloat { |
| PooToolsSource/Core/PTAppUserdefault.swift:145 | var | public | public var LocalConsoleCurrentFontColor: String { |
| PooToolsSource/Core/PTAppUserdefault.swift:152 | var | public | public var AppLanguage: String { |
| PooToolsSource/Core/PTAppUserdefault.swift:159 | var | public | public var NetworkSpeedTestFunctionHistoria: String { |
| PooToolsSource/Core/PTAppUserdefault.swift:166 | var | public | public var AppFirstPermissionShowed: Bool { |
| PooToolsSource/Core/PTAppUserdefault.swift:173 | var | public | public var PTWhatNewsLatestAppVersionPresented: String { |
| PooToolsSource/Core/PTAppUserdefault.swift:179 | var | public | public var PTLocalConsoleWidth: CGFloat? { |
| PooToolsSource/Core/PTAppUserdefault.swift:184 | var | public | public var PTLocalConsoleHeight: CGFloat? { |
| PooToolsSource/Core/PTAppUserdefault.swift:189 | var | public | public var PTLocalConsoleX: CGFloat? { |
| PooToolsSource/Core/PTAppUserdefault.swift:194 | var | public | public var PTLocalConsoleY: CGFloat? { |
| PooToolsSource/Core/PTAppUserdefault.swift:199 | var | public | public var PTMockLocationLat: CGFloat { |
| PooToolsSource/Core/PTAppUserdefault.swift:204 | var | public | public var PTMockLocationLng: CGFloat { |
| PooToolsSource/Core/PTAppUserdefault.swift:209 | var | public | public var PTMockLocationOpen: Bool { |
| PooToolsSource/Core/PTAppUserdefault.swift:215 | var | public | public var PTLogWrite: Bool { |
| PooToolsSource/Core/PTAppUserdefault.swift:220 | var | public | public var PTLogWrite: Bool { |
| PooToolsSource/Core/PTAppUserdefault.swift:230 | typealias | public | public typealias PTCoreUserDefaultsWrapper = PTCoreUserDefultsWrapper |
| PooToolsSource/Core/PTAssociatedObjectStore.swift:14 | protocol | public | public protocol PTAssociatedObjectStore { } |
| PooToolsSource/Core/PTBaseModel.swift:13 | class | open | open class PTBaseModel: Convertible { |
| PooToolsSource/Core/PTBaseModel.swift:18 | func | open | open func kj_modelKey(from property: KakaJSON.Property) -> ModelPropertyKey { |
| PooToolsSource/Core/PTBaseModel.swift:22 | func | open | open func kj_modelValue(from jsonValue:Any?,_ property:KakaJSON.Property) -> Any? { |
| PooToolsSource/Core/PTBaseModel.swift:29 | var | public | public var diffId: String { |
| PooToolsSource/Core/PTBaseModel.swift:33 | var | public | public var diffHash: Int { |
| PooToolsSource/Core/PTBaseModel.swift:41 | protocol | public | public protocol PTCodableModelProtocol: SmartCodableX {} |
| PooToolsSource/Core/PTBaseModel.swift:44 | struct | public | public struct PTDummyModel: PTCodableModelProtocol, Sendable { |
| PooToolsSource/Core/PTBaseModel.swift:45 | init | public | public init() {} |
| PooToolsSource/Core/PTBaseModel.swift:52 | protocol | public | public protocol PTModelProtocol: PTCodableModelProtocol, PTDiffableModel {} |
| PooToolsSource/Core/PTBaseModel.swift:76 | struct | public | public struct PTBaseStructModel<T> { |
| PooToolsSource/Core/PTBaseModel.swift:77 | var | public | public var originalString: String = "" |
| PooToolsSource/Core/PTBaseModel.swift:78 | var | public | public var customerModel: T? = nil |
| PooToolsSource/Core/PTBaseModel.swift:79 | var | public | public var resultData: Data? = Data() |
| PooToolsSource/Core/PTBaseModel.swift:81 | init | public | public init() {} |
| PooToolsSource/Core/PTBaseModel.swift:87 | typealias | public | public typealias PTLegacyStructModel = PTBaseStructModel<Any> |
| PooToolsSource/Core/PTBaseModel.swift:92 | struct | public | public struct PTProgressSnapshot: Sendable, Equatable { |
| PooToolsSource/Core/PTBaseModel.swift:93 | let | public | public let completedUnitCount: Int64 |
| PooToolsSource/Core/PTBaseModel.swift:94 | let | public | public let totalUnitCount: Int64 |
| PooToolsSource/Core/PTBaseModel.swift:95 | let | public | public let fractionCompleted: Double |
| PooToolsSource/Core/PTBaseModel.swift:97 | init | public | public init(completedUnitCount: Int64, |
| PooToolsSource/Core/PTBaseModel.swift:109 | struct | public | public struct PTResponseMetadata: Sendable, Equatable { |
| PooToolsSource/Core/PTBaseModel.swift:110 | let | public | public let statusCode: Int? |
| PooToolsSource/Core/PTBaseModel.swift:111 | let | public | public let headers: [String: String] |
| PooToolsSource/Core/PTBaseModel.swift:112 | let | public | public let isDegraded: Bool |
| PooToolsSource/Core/PTBaseModel.swift:113 | let | public | public let isCancelled: Bool |
| PooToolsSource/Core/PTBaseModel.swift:115 | init | public | public init(statusCode: Int? = nil, |
| PooToolsSource/Core/PTBaseModel.swift:130 | struct | public | public struct PTSendableTypeBox<T: Sendable>: Sendable { |
| PooToolsSource/Core/PTBaseModel.swift:131 | let | public | public let type: T? |
| PooToolsSource/Core/PTBaseModel.swift:133 | init | public | public init(_ type: T?) { |
| PooToolsSource/Core/PTFullScreenPopGesture.swift:12 | class | open | open class PTFullscreenPopGesture { |
| PooToolsSource/Core/PTFullScreenPopGesture.swift:33 | var | public | public var fullscreenPopGesture: UIPanGestureRecognizer { |
| PooToolsSource/Core/PTFullScreenPopGesture.swift:46 | var | public | public var viewControllerBasedNavBarAppearanceEnabled: Bool { |
| PooToolsSource/Core/PTFullScreenPopGesture.swift:82 | func | public | public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool { |
| PooToolsSource/Core/PTFullScreenPopGesture.swift:126 | var | public | public var interactivePopDisabled: Bool { |
| PooToolsSource/Core/PTFullScreenPopGesture.swift:132 | var | public | public var prefersNavigationBarHidden: Bool { |
| PooToolsSource/Core/PTFullScreenPopGesture.swift:138 | var | public | public var interactivePopMaxAllowedInitialDistanceToLeftEdge: Double { |
| PooToolsSource/Core/PTGCDManager.swift:13 | typealias | public | public typealias PTActionTask = @Sendable () -> Void |
| PooToolsSource/Core/PTGCDManager.swift:14 | typealias | public | public typealias PTActionAsyncTask = @Sendable () async -> Void |
| PooToolsSource/Core/PTGCDManager.swift:37 | actor | public | public actor PTGCDManager { |
| PooToolsSource/Core/PTGCDManager.swift:50 | var | public | public var cancelFlag: Bool = false |
| PooToolsSource/Core/PTGCDManager.swift:56 | func | public | public func scheduledTimer(withName name: String, |
| PooToolsSource/Core/PTGCDManager.swift:110 | func | public | public func cancelTimer(withName name: String) { |
| PooToolsSource/Core/PTGCDManager.swift:116 | func | public | public func isExistTimer(withName name: String) -> Bool { |
| PooToolsSource/Core/PTGCDManager.swift:128 | func | public | public func taskGroupUtility(semaphoreCount: Int = 3, |
| PooToolsSource/Core/PTGCDManager.swift:212 | func | public | public nonisolated func delayOnMain(time: TimeInterval, block: @escaping @MainActor @Sendable () -> Void) -> Task<Void, Never> { |
| PooToolsSource/Core/PTGCDManager.swift:221 | func | public | public nonisolated func runOnBackground(priority: TaskPriority? = nil, |
| PooToolsSource/Core/PTGCDManager.swift:230 | func | public | public nonisolated func runOnBackground(block: @escaping PTActionTask) -> Task<Void, Never> { |
| PooToolsSource/Core/PTGCDManager.swift:237 | func | public | public nonisolated func runOnMain(block: @escaping @MainActor @Sendable () -> Void) -> Task<Void, Never> { |
| PooToolsSource/Core/PTGCDManager.swift:243 | func | public | public nonisolated func countdown(timeInterval: TimeInterval, |
| PooToolsSource/Core/PTGifManager.swift:19 | typealias | public | public typealias PlatformImageView = NSImageView |
| PooToolsSource/Core/PTGifManager.swift:21 | typealias | public | public typealias PlatformImageView = UIImageView |
| PooToolsSource/Core/PTGifManager.swift:24 | typealias | public | public typealias PTGifLevelOfIntegrity = Float |
| PooToolsSource/Core/PTGifManager.swift:42 | enum | public | public enum PTGifParseError: Error,Sendable { |
| PooToolsSource/Core/PTGifManager.swift:51 | var | public | public var errorDescription: String? { |
| PooToolsSource/Core/PTGifManager.swift:68 | class | open | open class PTGifManager { |
| PooToolsSource/Core/PTGifManager.swift:82 | var | open | open var haveCache: Bool |
| PooToolsSource/Core/PTGifManager.swift:83 | var | open | open var remoteCache : [URL : Data] = [:] |
| PooToolsSource/Core/PTGifManager.swift:84 | var | public | public var mode: RunLoop.Mode = .common |
| PooToolsSource/Core/PTGifManager.swift:89 | init | public | public init(memoryLimit: Int) { |
| PooToolsSource/Core/PTGifManager.swift:97 | func | public | public func startTimerIfNeeded() { |
| PooToolsSource/Core/PTGifManager.swift:127 | func | public | public func stopTimer() { |
| PooToolsSource/Core/PTGifManager.swift:139 | func | open | open func addImageView(_ imageView: PlatformImageView) -> Bool { |
| PooToolsSource/Core/PTGifManager.swift:154 | func | open | open func deleteImageView(_ imageView: PlatformImageView) { |
| PooToolsSource/Core/PTGifManager.swift:163 | func | open | open func updateCacheSize(for imageView: PlatformImageView, add: Bool) { |
| PooToolsSource/Core/PTGifManager.swift:172 | func | open | open func clear() { |
| PooToolsSource/Core/PTGifManager.swift:181 | func | open | open func containsImageView(_ imageView: PlatformImageView) -> Bool{ |
| PooToolsSource/Core/PTGifManager.swift:188 | func | open | open func hasCache(_ imageView: PlatformImageView) -> Bool { |
| PooToolsSource/Core/PTLoadImageFunction.swift:17 | enum | public | public enum PTImageType : Sendable { |
| PooToolsSource/Core/PTLoadImageFunction.swift:25 | typealias | public | public typealias PTLoadImageProgressBlock = (@MainActor @Sendable (_ receivedSize: Int64, _ totalSize: Int64) -> Void) |
| PooToolsSource/Core/PTLoadImageFunction.swift:28 | enum | public | public enum PTImageSource { |
| PooToolsSource/Core/PTLoadImageFunction.swift:48 | enum | public | public enum PTImageSourceDescriptor: Sendable { |
| PooToolsSource/Core/PTLoadImageFunction.swift:58 | enum | public | public enum PTMediaResourceDescriptor: Sendable { |
| PooToolsSource/Core/PTLoadImageFunction.swift:65 | enum | public | public enum PTImageLoadingError: Error, LocalizedError, Sendable { |
| PooToolsSource/Core/PTLoadImageFunction.swift:69 | var | public | public var errorDescription: String? { |
| PooToolsSource/Core/PTLoadImageFunction.swift:80 | protocol | public | public protocol PTImageLoading: Sendable { |
| PooToolsSource/Core/PTLoadImageFunction.swift:87 | struct | public | public struct PTURLSessionImageLoader: PTImageLoading { |
| PooToolsSource/Core/PTLoadImageFunction.swift:88 | init | public | public init() {} |
| PooToolsSource/Core/PTLoadImageFunction.swift:90 | func | public | public func load(_ source: PTImageSourceDescriptor) async throws -> Data { |
| PooToolsSource/Core/PTLoadImageFunction.swift:113 | struct | public | public struct PTImageLoadConfiguration { |
| PooToolsSource/Core/PTLoadImageFunction.swift:114 | var | public | public var iCloudDocumentName: String |
| PooToolsSource/Core/PTLoadImageFunction.swift:115 | var | public | public var radius: CGFloat |
| PooToolsSource/Core/PTLoadImageFunction.swift:116 | var | public | public var topLeft: CGFloat |
| PooToolsSource/Core/PTLoadImageFunction.swift:117 | var | public | public var topRight: CGFloat |
| PooToolsSource/Core/PTLoadImageFunction.swift:118 | var | public | public var bottomLeft: CGFloat |
| PooToolsSource/Core/PTLoadImageFunction.swift:119 | var | public | public var bottomRight: CGFloat |
| PooToolsSource/Core/PTLoadImageFunction.swift:120 | var | public | public var corner: UIRectCorner |
| PooToolsSource/Core/PTLoadImageFunction.swift:121 | var | public | public var capsule: Bool |
| PooToolsSource/Core/PTLoadImageFunction.swift:122 | var | public | public var borderWidth: CGFloat? |
| PooToolsSource/Core/PTLoadImageFunction.swift:123 | var | public | public var borderColor: UIColor? |
| PooToolsSource/Core/PTLoadImageFunction.swift:124 | var | public | public var showValueLabel: Bool? |
| PooToolsSource/Core/PTLoadImageFunction.swift:125 | var | public | public var valueLabelFont: UIFont? |
| PooToolsSource/Core/PTLoadImageFunction.swift:126 | var | public | public var valueLabelColor: UIColor? |
| PooToolsSource/Core/PTLoadImageFunction.swift:127 | var | public | public var uniCount: Int? |
| PooToolsSource/Core/PTLoadImageFunction.swift:128 | var | public | public var emptyImage: UIImage? |
| PooToolsSource/Core/PTLoadImageFunction.swift:132 | var | public | public var targetSize: CGSize? |
| PooToolsSource/Core/PTLoadImageFunction.swift:134 | init | public | public init(iCloudDocumentName: String = "", |
| PooToolsSource/Core/PTLoadImageFunction.swift:170 | struct | public | public struct PTLoadImageResult { |
| PooToolsSource/Core/PTLoadImageFunction.swift:171 | let | public | public let allImages: [UIImage]? |
| PooToolsSource/Core/PTLoadImageFunction.swift:172 | let | public | public let firstImage: UIImage? |
| PooToolsSource/Core/PTLoadImageFunction.swift:173 | let | public | public let loadTime: TimeInterval |
| PooToolsSource/Core/PTLoadImageFunction.swift:174 | let | public | public let imageType: PTImageType |
| PooToolsSource/Core/PTLoadImageFunction.swift:176 | init | public | public init(allImages: [UIImage]?, firstImage: UIImage?, loadTime: TimeInterval, imageType: PTImageType = .unknown) { |
| PooToolsSource/Core/PTLoadImageFunction.swift:193 | class | public | public class PTLoadImageFunction: NSObject { |
| PooToolsSource/Core/PTMarcos_swift.swift:12 | let | public | public let CorePodBundleName = "PooToolsResource" |
| PooToolsSource/Core/PTMarcos_swift.swift:15 | typealias | public | public typealias PTBackgroundTask = @Sendable () -> Void |
| PooToolsSource/Core/PTMarcos_swift.swift:17 | typealias | public | public typealias PTBoolTask = (@Sendable (Bool) -> Void) |
| PooToolsSource/Core/PTMarcos_swift.swift:19 | var | public | @MainActor public var AppWindows: UIWindow? { |
| PooToolsSource/Core/PTMarcos_swift.swift:25 | let | public | public let Gobal_device_info = Device.current |
| PooToolsSource/Core/PTMarcos_swift.swift:28 | let | public | public let Gobal_device_isSimulator = Gobal_device_info.isSimulator |
| PooToolsSource/Core/PTMarcos_swift.swift:31 | let | public | public let Gobal_group_of_all_iPad:[Device] = Device.allPads |
| PooToolsSource/Core/PTMarcos_swift.swift:34 | let | public | public let Gobal_group_of_all_plus_device:[Device] = Device.allPlusSizedDevices |
| PooToolsSource/Core/PTMarcos_swift.swift:37 | let | public | public let Gobal_group_of_all_pro_device:[Device] = Device.allProDevices |
| PooToolsSource/Core/PTMarcos_swift.swift:40 | let | public | public let Gobal_group_of_all_X_device:[Device] = Device.allDevicesWithSensorHousing |
| PooToolsSource/Core/PTMarcos_swift.swift:43 | let | public | public let Gobal_group_of_all_small_device:[Device] = [.iPhone5,.iPhone5c,.iPhone5s,.iPodTouch5,.iPodTouch6,.iPodTouch7,.iPhone6,.iPhone6s,.iPhone7,.iPhone8,.iPhoneSE,.iPhoneSE2,.iPhone12Mini,.iPhone13Mini,.iPhone14,.simulator(.iPhone5),.simulator(.iPhone5c),.simulator(.iPhone5s),.simulator(.iPodTouch5),.simulator(.iPodTouch6),.simulator(.iPodTouch7),.simulator(.iPhone6),.simulator(.iPhone7),.simulator(.iPhone8),.simulator(.iPhoneSE),.simulator(.iPhoneSE2),.simulator(.iPhone12Mini),.simulator(.iPhone13Mini),.simulator(.iPhone14),.simulator(.iPhone15),.simulator(.iPhone16),.simulator(.iPhone17),.simulator(.iPhone16e),.iPhone17,.iPhone16e] |
| PooToolsSource/Core/PTMarcos_swift.swift:45 | var | public | public var isXModel: Bool { |
| PooToolsSource/Core/PTMarcos_swift.swift:51 | let | public | @MainActor public let kSCREEN_BOUNDS = UIScreen.main.bounds |
| PooToolsSource/Core/PTMarcos_swift.swift:54 | let | public | @MainActor public let kSCREEN_SIZE = kSCREEN_BOUNDS.size |
| PooToolsSource/Core/PTMarcos_swift.swift:57 | let | public | @MainActor public let kSCREEN_SCALE = UIScreen.main.scale |
| PooToolsSource/Core/PTMarcos_swift.swift:60 | let | public | @MainActor public let infoDictionary = Bundle.main.infoDictionary |
| PooToolsSource/Core/PTMarcos_swift.swift:63 | let | public | @MainActor public let kAppDisplayName: String? = infoDictionary?["CFBundleDisplayName"] as? String |
| PooToolsSource/Core/PTMarcos_swift.swift:66 | let | public | @MainActor public let kAppName: String? = infoDictionary?["CFBundleName"] as? String |
| PooToolsSource/Core/PTMarcos_swift.swift:69 | let | public | @MainActor public let kAppVersion: String? = infoDictionary?["CFBundleShortVersionString"] as? String |
| PooToolsSource/Core/PTMarcos_swift.swift:72 | let | public | @MainActor public let kAppBuildVersion: String? = infoDictionary?["CFBundleVersion"] as? String |
| PooToolsSource/Core/PTMarcos_swift.swift:75 | let | public | @MainActor public let kAppBundleId: String? = infoDictionary?["CFBundleIdentifier"] as? String |
| PooToolsSource/Core/PTMarcos_swift.swift:78 | let | public | @MainActor public let kPlatformName: String? = infoDictionary?["DTPlatformName"] as? String |
| PooToolsSource/Core/PTMarcos_swift.swift:81 | let | public | @MainActor public let kiOSVersion: String = UIDevice.current.systemVersion |
| PooToolsSource/Core/PTMarcos_swift.swift:84 | let | public | @MainActor public let kOSType: String = UIDevice.current.systemName + UIDevice.current.systemVersion |
| PooToolsSource/Core/PTMediaSaveService.swift:13 | enum | public | public enum PTMediaSaveError: Error, LocalizedError, Sendable { |
| PooToolsSource/Core/PTMediaSaveService.swift:19 | var | public | public var errorDescription: String? { |
| PooToolsSource/Core/PTMediaSaveService.swift:30 | enum | public | public enum PTMediaSaveResult { |
| PooToolsSource/Core/PTMediaSaveService.swift:36 | enum | public | public enum PTMediaSaveService { |
| PooToolsSource/Core/PTPhoneFeedBackControl.swift:13 | enum | public | public enum PTPhoneFeedbackControl { |
| PooToolsSource/Core/PTPropertyWrapperFunction.swift:14 | struct | public | @propertyWrapper public struct PTClampedPropertyWrapper<T: Comparable & Sendable>: Sendable { |
| PooToolsSource/Core/PTPropertyWrapperFunction.swift:18 | var | public | public var wrappedValue: T { |
| PooToolsSource/Core/PTPropertyWrapperFunction.swift:23 | init | public | public init(wrappedValue: T, range: ClosedRange<T>) { |
| PooToolsSource/Core/PTPropertyWrapperFunction.swift:31 | struct | public | @propertyWrapper public struct PTCapitalized: Sendable { |
| PooToolsSource/Core/PTPropertyWrapperFunction.swift:32 | var | public | public var wrappedValue: String { |
| PooToolsSource/Core/PTPropertyWrapperFunction.swift:36 | init | public | public init(wrappedValue: String) { |
| PooToolsSource/Core/PTPropertyWrapperFunction.swift:48 | init | public | public init(wrappedValue value: T) { |
| PooToolsSource/Core/PTPropertyWrapperFunction.swift:52 | var | public | public var wrappedValue: T { |
| PooToolsSource/Core/PTPropertyWrapperFunction.swift:58 | func | public | public func getValue() -> T { |
| PooToolsSource/Core/PTPropertyWrapperFunction.swift:63 | func | public | public func setValue(newValue: T) { |
| PooToolsSource/Core/PTPropertyWrapperFunction.swift:70 | struct | public | @propertyWrapper public struct PTUserDefault<T: Sendable>: Sendable { |
| PooToolsSource/Core/PTPropertyWrapperFunction.swift:75 | init | public | public init(withKey key: String, defaultValue: T) { |
| PooToolsSource/Core/PTPropertyWrapperFunction.swift:82 | var | public | public var wrappedValue: T { |
| PooToolsSource/Core/PTTimeUtils.swift:12 | class | public | public class PTTimeUtils { |
| PooToolsSource/Core/PTUpdateTipsViewController.swift:18 | class | public | public class PTUpdateTipsContentView : UIView { |
| PooToolsSource/Core/PTUpdateTipsViewController.swift:19 | init | public | public init(oV:String,nV:String,descriptionString:String) { |
| PooToolsSource/Core/PTUpdateTipsViewController.swift:118 | class | open | open class PTUpdateTipsViewController: PTBaseViewController { |
| PooToolsSource/Core/PTUpdateTipsViewController.swift:120 | var | public | @MainActor public var doneTask:PTActionTask? = nil |
| PooToolsSource/Core/PTUpdateTipsViewController.swift:121 | var | public | @MainActor public var cancelTask:PTActionTask? = nil |
| PooToolsSource/Core/PTUpdateTipsViewController.swift:181 | init | public | public init(titleString:String = "",cancelTitle:String = "",doneTitle:String) { |
| PooToolsSource/Core/PTUrlChange.swift:14 | enum | public | public enum PTURLParser { |
| PooToolsSource/Core/PTUrlChange.swift:58 | class | public | public class PTUrlChange: NSObject { |
| PooToolsSource/Core/PTUrlChange.swift:60 | class | public | public class func getRange(text: String, findText: String) -> [Int] { |
| PooToolsSource/Core/PTUtils+SceneConcurrency.swift:12 | func | public | @MainActor public func deviceSafeAreaInsets() -> UIEdgeInsets { |
| PooToolsSource/Core/PTUtils+SceneConcurrency.swift:20 | enum | public | public enum PTSceneContext { |
| PooToolsSource/Core/PTUtils+SceneConcurrency.swift:137 | protocol | public | public protocol PTSceneContextProviding { |
| PooToolsSource/Core/PTUtils+SceneConcurrency.swift:147 | struct | public | public struct PTDefaultSceneContextProvider: PTSceneContextProviding { |
| PooToolsSource/Core/PTUtils+SceneConcurrency.swift:148 | init | public | public init() {} |
| PooToolsSource/Core/PTUtils+SceneConcurrency.swift:150 | func | public | public func activeWindow(in scene: UIWindowScene? = nil) -> UIWindow? { |
| PooToolsSource/Core/PTUtils+SceneConcurrency.swift:154 | func | public | public func rootViewController(in scene: UIWindowScene? = nil) -> UIViewController? { |
| PooToolsSource/Core/PTUtils+SceneConcurrency.swift:158 | func | public | public func currentViewController(in scene: UIWindowScene? = nil) -> UIViewController? { |
| PooToolsSource/Core/PTUtils+SceneConcurrency.swift:166 | enum | public | public enum PTMainActorBridge { |
| PooToolsSource/Core/PTUtils+SceneConcurrency.swift:230 | func | public | public func register(_ handler: @escaping @MainActor () -> Void) -> UUID { |
| PooToolsSource/Core/PTUtils+SceneConcurrency.swift:236 | func | public | public func unregister(_ token: UUID) { |
| PooToolsSource/Core/PTUtils.swift:15 | enum | public | public enum PTVisualStyle: String, CaseIterable, Equatable, Hashable, Sendable { |
| PooToolsSource/Core/PTUtils.swift:23 | enum | public | public enum PTVisualStyleResolver { |
| PooToolsSource/Core/PTUtils.swift:62 | enum | public | public enum PTUIAccessibility { |
| PooToolsSource/Core/PTUtils.swift:151 | struct | public | public struct PTTimerBox { |
| PooToolsSource/Core/PTUtils.swift:172 | enum | public | @objc public enum PTUrlStringVideoType:Int { |
| PooToolsSource/Core/PTUtils.swift:179 | enum | public | @objc public enum PTAboutImageType:Int { |
| PooToolsSource/Core/PTUtils.swift:193 | enum | public | @objc public enum GradeType:Int { |
| PooToolsSource/Core/PTUtils.swift:199 | func | public | public func PTIVarList(_ className:String) -> [String] { |
| PooToolsSource/Core/PTUtils.swift:220 | func | public | public func PTPropertyList(_ classString: String) -> [String] { |
| PooToolsSource/Core/PTUtils.swift:243 | func | public | public func PTMethodsList(_ classString: String) -> [Selector] { |
| PooToolsSource/Core/PTUtils.swift:264 | func | public | public func checkCustomClass(for cls: AnyClass) -> Bool { |
| PooToolsSource/Core/PTUtils.swift:269 | typealias | public | public typealias PTImageLoadHandler = (_ error:Error?,_ sourceURL:URL?,_ image:UIImage?) -> Void |
| PooToolsSource/Core/PTUtils.swift:273 | class | public | public class PTUtils: NSObject { |
| PooToolsSource/Core/PTUtils.swift:276 | var | public | public var timer: DispatchSourceTimer? |
| PooToolsSource/Core/PTUtils.swift:280 | class | public | public class func cgBaseBundle()->Bundle { |
| PooToolsSource/Core/PTUtils.swift:286 | class | public | public class func maxOne<T:Comparable>( _ seq:[T]) -> T? { |
| PooToolsSource/Core/PTUtils.swift:291 | class | public | public class func isValidAmountInput(text:NSString, |
| PooToolsSource/Core/PTUtils.swift:307 | class | public | public class func outputURL() -> URL { |
| PooToolsSource/Core/PTUtils.swift:318 | class | public | public class func classFromString(_ className:String) -> AnyClass? { |
| PooToolsSource/Core/PTUtils.swift:582 | func | public | @objc public func swizzled_reverses_Action_Order() -> Bool { |
| PooToolsSource/Core/PTUtils.swift:598 | func | public | @MainActor @objc public func swizzled_did_add_subview(_ subview: UIView) { |
| PooToolsSource/Core/PTUtils.swift:608 | class | public | public class SwizzleTool: NSObject { |
| PooToolsSource/Core/ResponseModel.swift:41 | struct | public | public struct PTIPInfoSnapshot: Sendable { |
| PooToolsSource/Core/ResponseModel.swift:42 | let | public | public let lon: Double |
| PooToolsSource/Core/ResponseModel.swift:43 | let | public | public let zip: String |
| PooToolsSource/Core/ResponseModel.swift:44 | let | public | public let query: String |
| PooToolsSource/Core/ResponseModel.swift:45 | let | public | public let asBaseic: String |
| PooToolsSource/Core/ResponseModel.swift:46 | let | public | public let isp: String |
| PooToolsSource/Core/ResponseModel.swift:47 | let | public | public let countryCode: String |
| PooToolsSource/Core/ResponseModel.swift:48 | let | public | public let lat: Double |
| PooToolsSource/Core/ResponseModel.swift:49 | let | public | public let city: String |
| PooToolsSource/Core/ResponseModel.swift:50 | let | public | public let region: String |
| PooToolsSource/Core/ResponseModel.swift:51 | let | public | public let timezone: String |
| PooToolsSource/Core/ResponseModel.swift:52 | let | public | public let org: String |
| PooToolsSource/Core/ResponseModel.swift:53 | let | public | public let country: String |
| PooToolsSource/Core/ResponseModel.swift:54 | let | public | public let status: String |
| PooToolsSource/Core/ResponseModel.swift:55 | let | public | public let regionName: String |
| PooToolsSource/Core/ResponseModel.swift:80 | var | public | public var lon: CGFloat = 0.0 |
| PooToolsSource/Core/ResponseModel.swift:81 | var | public | public var zip: String = "" |
| PooToolsSource/Core/ResponseModel.swift:82 | var | public | public var query: String = "" |
| PooToolsSource/Core/ResponseModel.swift:83 | var | public | public var asBaseic: String = "" |
| PooToolsSource/Core/ResponseModel.swift:84 | var | public | public var isp: String = "" |
| PooToolsSource/Core/ResponseModel.swift:85 | var | public | public var countryCode: String = "" |
| PooToolsSource/Core/ResponseModel.swift:86 | var | public | public var lat: CGFloat = 0.0 |
| PooToolsSource/Core/ResponseModel.swift:87 | var | public | public var city: String = "" |
| PooToolsSource/Core/ResponseModel.swift:88 | var | public | public var region: String = "" |
| PooToolsSource/Core/ResponseModel.swift:89 | var | public | public var timezone: String = "" |
| PooToolsSource/Core/ResponseModel.swift:90 | var | public | public var org: String = "" |
| PooToolsSource/Core/ResponseModel.swift:91 | var | public | public var country: String = "" |
| PooToolsSource/Core/ResponseModel.swift:92 | var | public | public var status: String = "" |
| PooToolsSource/Core/ResponseModel.swift:93 | var | public | public var regionName: String = "" |
| PooToolsSource/Core/ResponseModel.swift:115 | func | public | public func snapshot() -> PTIPInfoSnapshot { |
| PooToolsSource/Country/PTCountryCodes.swift:12 | class | public | public class PTCountryCodeModel:NSObject { |
| PooToolsSource/Country/PTCountryCodes.swift:13 | var | public | public var countryCode:String = "" |
| PooToolsSource/Country/PTCountryCodes.swift:14 | var | public | public var countryName:String = "" |
| PooToolsSource/Country/PTCountryCodes.swift:18 | class | public | public class PTCountryCodes: NSObject { |
| PooToolsSource/Country/PTCountryCodes.swift:262 | func | public | public func codesModels() -> [PTCountryCodeModel] { |
| PooToolsSource/DarkMode/PTDarkModeControl.swift:15 | class | public | public class PTDarkModeControl: PTListViewController { |
| PooToolsSource/DarkMode/PTDarkModeControl.swift:24 | var | open | open var themeSetBlock: PTActionTask? |
| PooToolsSource/DarkMode/PTDarkModeControl.swift:243 | func | public | public func apply() { |
| PooToolsSource/DarkMode/PTDarkSmartFooter.swift:14 | class | public | public class PTDarkSmartFooter: PTBaseCollectionReusableView,@MainActor PTSupplementaryRegisterable { |
| PooToolsSource/DarkMode/PTDrakModeOption.swift:170 | func | public | public func apply() { |
| PooToolsSource/DarkMode/PTDrakModeOption.swift:177 | class | public | public class PTDarkModeOption { |
| PooToolsSource/DarkMode/PTThemeProvider.swift:15 | enum | public | public enum PTTabBarVisualStyle: Sendable { |
| PooToolsSource/DarkMode/PTThemeProvider.swift:49 | struct | public | public struct PTNavigationAppearance { |
| PooToolsSource/DarkMode/PTThemeProvider.swift:50 | var | public | public var backgroundColor: UIColor |
| PooToolsSource/DarkMode/PTThemeProvider.swift:51 | var | public | public var titleColor: UIColor |
| PooToolsSource/DarkMode/PTThemeProvider.swift:52 | var | public | public var titleFont: UIFont |
| PooToolsSource/DarkMode/PTThemeProvider.swift:53 | var | public | public var largeTitleFont: UIFont |
| PooToolsSource/DarkMode/PTThemeProvider.swift:55 | init | public | public init(backgroundColor: UIColor = .clear, |
| PooToolsSource/DarkMode/PTThemeProvider.swift:67 | struct | public | public struct PTTabBarAppearance { |
| PooToolsSource/DarkMode/PTThemeProvider.swift:68 | var | public | public var normalColor: UIColor |
| PooToolsSource/DarkMode/PTThemeProvider.swift:69 | var | public | public var selectedColor: UIColor |
| PooToolsSource/DarkMode/PTThemeProvider.swift:70 | var | public | public var normalFont: UIFont |
| PooToolsSource/DarkMode/PTThemeProvider.swift:71 | var | public | public var selectedFont: UIFont |
| PooToolsSource/DarkMode/PTThemeProvider.swift:72 | var | public | public var visualStyle: PTTabBarVisualStyle |
| PooToolsSource/DarkMode/PTThemeProvider.swift:74 | init | public | public init(normalColor: UIColor = .secondaryLabel, |
| PooToolsSource/DarkMode/PTThemeProvider.swift:100 | struct | public | public struct PTPermissionAppearance { |
| PooToolsSource/DarkMode/PTThemeProvider.swift:101 | var | public | public var titleColor: UIColor |
| PooToolsSource/DarkMode/PTThemeProvider.swift:102 | var | public | public var subtitleColor: UIColor |
| PooToolsSource/DarkMode/PTThemeProvider.swift:103 | var | public | public var deniedColor: UIColor |
| PooToolsSource/DarkMode/PTThemeProvider.swift:105 | init | public | public init(titleColor: UIColor = .label, |
| PooToolsSource/DarkMode/PTThemeProvider.swift:115 | struct | public | public struct PTMediaAppearance { |
| PooToolsSource/DarkMode/PTThemeProvider.swift:116 | var | public | public var placeholder: UIImage? |
| PooToolsSource/DarkMode/PTThemeProvider.swift:117 | var | public | public var backgroundColor: UIColor |
| PooToolsSource/DarkMode/PTThemeProvider.swift:119 | init | public | public init(placeholder: UIImage? = nil, backgroundColor: UIColor = .systemBackground) { |
| PooToolsSource/DarkMode/PTThemeProvider.swift:126 | struct | public | public struct PTListAppearance { |
| PooToolsSource/DarkMode/PTThemeProvider.swift:127 | var | public | public var backgroundColor: UIColor |
| PooToolsSource/DarkMode/PTThemeProvider.swift:128 | var | public | public var cellBackgroundColor: UIColor |
| PooToolsSource/DarkMode/PTThemeProvider.swift:130 | init | public | public init(backgroundColor: UIColor = .systemBackground, |
| PooToolsSource/DarkMode/PTThemeProvider.swift:138 | struct | public | public struct PTAlertAppearance { |
| PooToolsSource/DarkMode/PTThemeProvider.swift:139 | var | public | public var backgroundColor: UIColor |
| PooToolsSource/DarkMode/PTThemeProvider.swift:140 | var | public | public var cornerRadius: CGFloat |
| PooToolsSource/DarkMode/PTThemeProvider.swift:142 | init | public | public init(backgroundColor: UIColor = .secondarySystemBackground, |
| PooToolsSource/DarkMode/PTThemeProvider.swift:153 | struct | public | public struct PTTheme { |
| PooToolsSource/DarkMode/PTThemeProvider.swift:154 | var | public | public var navigation: PTNavigationAppearance |
| PooToolsSource/DarkMode/PTThemeProvider.swift:155 | var | public | public var tabBar: PTTabBarAppearance |
| PooToolsSource/DarkMode/PTThemeProvider.swift:156 | var | public | public var permission: PTPermissionAppearance |
| PooToolsSource/DarkMode/PTThemeProvider.swift:157 | var | public | public var media: PTMediaAppearance |
| PooToolsSource/DarkMode/PTThemeProvider.swift:158 | var | public | public var list: PTListAppearance |
| PooToolsSource/DarkMode/PTThemeProvider.swift:159 | var | public | public var alert: PTAlertAppearance |
| PooToolsSource/DarkMode/PTThemeProvider.swift:161 | init | public | public init(navigation: PTNavigationAppearance = .init(), |
| PooToolsSource/DarkMode/PTThemeProvider.swift:206 | protocol | public | public protocol PTThemeProvider: AnyObject { |
| PooToolsSource/DarkMode/PTThemeProvider.swift:212 | protocol | public | public protocol PTThemeable: AnyObject { |
| PooToolsSource/DarkMode/PTThemeProvider.swift:225 | class | public | public class LegacyThemeProvider: @MainActor PTThemeProvider { |
| PooToolsSource/DarkMode/PTThemeProvider.swift:232 | func | public | public func updateTheme() { |
| PooToolsSource/DarkMode/PTThemeProvider.swift:239 | func | public | public func register<Observer: PTThemeable>(observer: Observer) { |
| PooToolsSource/Debug/PTDebugFunction.swift:12 | class | public | public class PTDebugFunction: NSObject { |
| PooToolsSource/Debug/PTDebugViewController.swift:13 | class | public | public class PTDebugViewController: PTBaseViewController { |
| PooToolsSource/Debug/PTDebugViewController.swift:232 | func | public | public func textFieldShouldReturn(_ textField: UITextField) -> Bool { |
| PooToolsSource/Debug/PTDevFunction.swift:14 | class | public | public class PTDevFunction: NSObject { |
| PooToolsSource/Debug/PTDevFunction.swift:20 | class | public | public class func webImageLoadOptions() -> KingfisherOptionsInfo { |
| PooToolsSource/Debug/PTDevFunction.swift:34 | class | public | public class func gobalWebImageLoadOption() -> KingfisherOptionsInfo { |
| PooToolsSource/DebugColor/PTColorPickPlugin.swift:15 | typealias | public | public typealias PTColorPickMagnifyLayerBlock = (CGPoint) -> String |
| PooToolsSource/DebugColor/PTColorPickPlugin.swift:16 | let | public | public let kPTClosePluginNotification = "kPTClosePluginNotification" |
| PooToolsSource/DebugColor/PTColorPickPlugin.swift:25 | class | open | open class PTColorPickPlugin: NSObject { |
| PooToolsSource/DebugColor/PTColorPickPlugin.swift:28 | var | public | public var showed: Bool = false |
| PooToolsSource/DebugColor/PTColorPickPlugin.swift:34 | func | public | public func show() { |
| PooToolsSource/DebugColor/PTColorPickPlugin.swift:42 | func | public | public func show(in scene: UIWindowScene) { |
| PooToolsSource/DebugColor/PTColorPickPlugin.swift:47 | func | public | public func close() { |
| PooToolsSource/DebugColor/PTColorPickPlugin.swift:191 | var | public | public var closeBlock: ((UIButton, PTColorPickInfoView) -> Void)? |
| PooToolsSource/DebugColor/PTColorPickPlugin.swift:193 | var | public | public var currentColor: String? { |
| PooToolsSource/DebugColor/PTColorPickPlugin.swift:274 | class | public | public class PTColorPickWindow: UIWindow { |
| PooToolsSource/DebugColor/PTColorPickPlugin.swift:288 | var | public | public var currentColor: String? { |
| PooToolsSource/DebugCrash/PTCrashHandler.swift:47 | class | public | public class CrashUncaughtExceptionHandler { |
| PooToolsSource/DebugCrash/PTCrashHandler.swift:52 | func | public | @MainActor public func prepare() { |
| PooToolsSource/DebugCrash/PTCrashHandler.swift:99 | class | public | public class CrashSignalExceptionHandler { |
| PooToolsSource/DebugCrash/PTCrashHandler.swift:104 | func | public | @MainActor public func prepare() { |
| PooToolsSource/DebugCrash/PTCrashHandler.swift:199 | class | public | public class PTCrashHandler { |
| PooToolsSource/DebugCrash/PTCrashHandler.swift:201 | var | public | public var exceptionReceiveClosure: ((Int32?, NSException?, String) -> Void)? |
| PooToolsSource/DebugCrash/PTCrashHandler.swift:204 | var | public | @MainActor public var capturesSignals = false |
| PooToolsSource/DebugCrash/PTCrashHandler.swift:240 | func | public | @MainActor public func prepare() { |
| PooToolsSource/DebugCrash/Thread+PTDebugEx.swift:18 | class | public | public class func simpleCallStackSymbols(_ stack: [String] = Thread.callStackSymbols) -> [String] { |
| PooToolsSource/DebugCrash/Thread+PTDebugEx.swift:69 | class | public | public class var simpleCallStackString: String { |
| PooToolsSource/DebugFile/PTFileBrowser.swift:13 | class | public | public class PTFileBrowser: NSObject { |
| PooToolsSource/DebugFile/PTFileBrowser.swift:16 | var | public | public var rootDirectoryPath = FileManager.pt.getFileDirectory(type: .Directory) |
| PooToolsSource/DebugFile/PTFileBrowserViewController.swift:17 | class | public | public class PTFileBrowserViewController: PTBaseViewController { |
| PooToolsSource/DebugFile/PTFileBrowserViewController.swift:306 | func | public | public func numberOfPreviewItems(in controller: QLPreviewController) -> Int { |
| PooToolsSource/DebugFile/PTFileBrowserViewController.swift:310 | func | public | public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem { |
| PooToolsSource/DebugFile/PTFileModel.swift:12 | enum | public | public enum PTFileType: String { |
| PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift:398 | actor | public | public actor PTNetworkSpeedMonitor { |
| PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift:409 | func | public | public func getDownloadSpeeds() -> [Double] { |
| PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift:414 | func | public | public func getUploadSpeeds() -> [Double] { |
| PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift:419 | func | public | public func addDownloadSpeed(_ speed: Double) { |
| PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift:427 | func | public | public func addUploadSpeed(_ speed: Double) { |
| PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift:435 | func | public | public func averageDownloadSpeed() -> Double { |
| PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift:441 | func | public | public func averageUploadSpeed() -> Double { |
| PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift:447 | func | public | public func clearSpeeds() { |
| PooToolsSource/DebugNetwork/PTNetworkWatcherViewController.swift:253 | actor | public | public actor PTNetworkSpeedTestMonitor { |
| PooToolsSource/DebugNetwork/PTNetworkWatcherViewController.swift:265 | init | public | public init() {} |
| PooToolsSource/DebugNetwork/PTNetworkWatcherViewController.swift:267 | func | public | public func startMonitoring() { |
| PooToolsSource/DebugNetwork/PTNetworkWatcherViewController.swift:291 | func | public | public func stopMonitoring() { |
| PooToolsSource/DebugPerformance/PTFPSTool.swift:13 | class | public | public class PTFPSTool: NSObject { |
| PooToolsSource/DebugPerformance/PTFPSTool.swift:17 | var | open | open var fpsHandle:((_ fps:NSInteger) -> Void)? |
| PooToolsSource/DebugPerformance/PTFPSTool.swift:18 | var | open | open var closed:Bool = true |
| PooToolsSource/DebugPerformance/PTFPSTool.swift:67 | func | public | public func open() { |
| PooToolsSource/DebugPerformance/PTFPSTool.swift:75 | func | public | public func close() { |
| PooToolsSource/DebugPerformance/PTPerformanceLeakDetector.swift:17 | struct | public | public struct PTPerformanceLeak { |
| PooToolsSource/DebugPerformance/PTPerformanceLeakDetector.swift:18 | let | public | public let controller: UIViewController? |
| PooToolsSource/DebugPerformance/PTPerformanceLeakDetector.swift:19 | let | public | public let view: UIView? |
| PooToolsSource/DebugPerformance/PTPerformanceLeakDetector.swift:20 | let | public | public let message: String |
| PooToolsSource/DebugPerformance/PTPerformanceLeakDetector.swift:28 | var | public | public var isDeallocation: Bool { controller == nil && view == nil } |
| PooToolsSource/DebugPerformance/PTPerformanceLeakDetector.swift:32 | struct | public | public struct LeakModel: Sendable { |
| PooToolsSource/DebugPerformance/PTPerformanceLeakDetector.swift:33 | let | public | public let details: String |
| PooToolsSource/DebugPerformance/PTPerformanceLeakDetector.swift:34 | let | public | public let screenshot: UIImage? |
| PooToolsSource/DebugPerformance/PTPerformanceLeakDetector.swift:35 | let | public | public let id: Int |
| PooToolsSource/DebugPerformance/PTPerformanceLeakDetector.swift:37 | var | public | public var hasDeallocated = false |
| PooToolsSource/DebugPerformance/PTPerformanceLeakDetector.swift:38 | var | public | public var timeAllocated: String? |
| PooToolsSource/DebugPerformance/PTPerformanceLeakDetector.swift:40 | var | public | public var isActive: Bool { !hasDeallocated } |
| PooToolsSource/DebugPerformance/PTPerformanceLeakDetector.swift:41 | var | public | public var symbol: String { hasDeallocated ? "✳️" : "⚠️" } |
| PooToolsSource/DebugPerformance/PTPerformanceLeakDetector.swift:107 | func | public | @objc public func removeFromSuperviewDetectLeaks() { |
| PooToolsSource/DebugRuler/PTViewRulerPlugin.swift:15 | class | open | open class PTViewRulerPlugin: NSObject { |
| PooToolsSource/DebugRuler/PTViewRulerPlugin.swift:23 | var | public | public var showed:Bool = false |
| PooToolsSource/DebugRuler/PTViewRulerPlugin.swift:35 | func | public | public func show() { |
| PooToolsSource/DebugRuler/PTViewRulerPlugin.swift:43 | func | public | public func show(in scene: UIWindowScene) { |
| PooToolsSource/DebugRuler/PTViewRulerPlugin.swift:52 | func | public | public func hide() { |
| PooToolsSource/DevMask/PTDevMaskView.swift:15 | class | public | public class PTDevMaskConfig:NSObject { |
| PooToolsSource/DevMask/PTDevMaskView.swift:16 | var | open | open var isMask:Bool = false |
| PooToolsSource/DevMask/PTDevMaskView.swift:17 | var | open | @MainActor open var maskString:String = "PT Debug mode".localized() |
| PooToolsSource/DevMask/PTDevMaskView.swift:18 | var | open | open var maskFont:UIFont = .appfont(size: 100,bold: true) |
| PooToolsSource/DevMask/PTDevMaskView.swift:19 | var | open | open var motionColor:UIColor = .randomColor |
| PooToolsSource/DevMask/PTDevMaskView.swift:20 | var | open | open var showTouch:Bool = PTCoreUserDefultsWrapper.shared.AppDebbugTouchBubble |
| PooToolsSource/DevMask/PTDevMaskView.swift:24 | class | public | public class PTDevMaskView: PTBaseMaskView { |
| PooToolsSource/DevMask/PTDevMaskView.swift:26 | var | open | open var showTouch:Bool? { |
| PooToolsSource/DevMask/PTDevMaskView.swift:94 | init | public | public init(config:PTDevMaskConfig?) { |
| PooToolsSource/DevMask/SpringConfiguration.swift:10 | struct | public | public struct SpringConfiguration : Sendable { |
| PooToolsSource/DevMask/SpringConfiguration.swift:13 | var | public | public var angularFrequency: Float |
| PooToolsSource/DevMask/SpringConfiguration.swift:16 | var | public | public var dampingRatio: Float |
| PooToolsSource/DevMask/SpringConfiguration.swift:20 | init | public | public init(angularFrequency: Float, dampingRatio: Float) { |
| PooToolsSource/DevMask/SpringMotionLayer.swift:11 | class | open | open class SpringMotionLayer: CALayer { |
| PooToolsSource/DevMask/SpringMotionLayer.swift:14 | var | public | public var configuration: SpringConfiguration = .default { |
| PooToolsSource/DevMask/SpringMotionLayer.swift:23 | func | public | public func move(to point: CGPoint) { |
| PooToolsSource/DevMask/SpringMotionView-iOS.swift:12 | class | open | open class SpringMotionView: UIView { |
| PooToolsSource/DevMask/SpringMotionView-iOS.swift:15 | var | public | public var configuration: SpringConfiguration = .default { |
| PooToolsSource/DevMask/SpringMotionView-iOS.swift:24 | var | public | public var onPositionUpdate: ((CGPoint) -> Void)? |
| PooToolsSource/DevMask/SpringMotionView-iOS.swift:29 | func | public | public func move(to point: CGPoint) { |
| PooToolsSource/FaceIDPermission/PTPermissionFaceID.swift:19 | class | public | public class PTPermissionFaceID: PTPermission { |
| PooToolsSource/FaceIDPermission/PTPermissionFaceID.swift:22 | var | open | open var usageDescriptionKey: String? { "NSFaceIDUsageDescription" } |
| PooToolsSource/FloatPanel/PTBaseViewController+FloatPanel.swift:22 | func | open | open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool { |
| PooToolsSource/FloatPanel/PTSheetContentViewController.swift:14 | class | public | public class PTSheetContentViewController: PTBaseViewController { |
| PooToolsSource/FloatPanel/PTSheetContentViewController.swift:27 | var | public | public var contentBackgroundColor: UIColor? { |
| PooToolsSource/FloatPanel/PTSheetContentViewController.swift:37 | var | public | public var cornerCurve: CALayerCornerCurve { |
| PooToolsSource/FloatPanel/PTSheetContentViewController.swift:45 | var | public | public var cornerRadius: CGFloat = 0 { |
| PooToolsSource/FloatPanel/PTSheetContentViewController.swift:49 | var | public | public var gripSize: CGSize = CGSize(width: 50, height: 6) { |
| PooToolsSource/FloatPanel/PTSheetContentViewController.swift:55 | var | public | public var gripColor: UIColor? { |
| PooToolsSource/FloatPanel/PTSheetContentViewController.swift:60 | var | public | public var pullBarBackgroundColor: UIColor? { |
| PooToolsSource/FloatPanel/PTSheetContentViewController.swift:65 | var | public | public var treatPullBarAsClear: Bool = PTSheetViewController.treatPullBarAsClear { |
| PooToolsSource/FloatPanel/PTSheetContentViewController.swift:77 | var | public | public var contentWrapperView = UIView() |
| PooToolsSource/FloatPanel/PTSheetContentViewController.swift:78 | var | public | public var contentView = UIView() |
| PooToolsSource/FloatPanel/PTSheetContentViewController.swift:79 | var | public | public var childContainerView = UIView() |
| PooToolsSource/FloatPanel/PTSheetContentViewController.swift:99 | init | public | public init(childViewController: UIViewController, options: PTSheetOptions) { |
| PooToolsSource/FloatPanel/PTSheetContentViewController.swift:398 | func | public | public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) { |
| PooToolsSource/FloatPanel/PTSheetContentViewController.swift:402 | func | public | public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) { |
| PooToolsSource/FloatPanel/PTSheetOptions.swift:13 | struct | public | public struct PTSheetOptions { |
| PooToolsSource/FloatPanel/PTSheetOptions.swift:18 | enum | public | public enum TransitionOverflowType { |
| PooToolsSource/FloatPanel/PTSheetOptions.swift:28 | var | public | public var pullBarHeight: CGFloat = 24 |
| PooToolsSource/FloatPanel/PTSheetOptions.swift:30 | var | public | public var presentingViewCornerRadius: CGFloat = 12 |
| PooToolsSource/FloatPanel/PTSheetOptions.swift:32 | var | public | public var shouldExtendBackground = true |
| PooToolsSource/FloatPanel/PTSheetOptions.swift:34 | var | public | public var horizontalPadding: CGFloat = 0 |
| PooToolsSource/FloatPanel/PTSheetOptions.swift:36 | var | public | public var maxWidth: CGFloat? |
| PooToolsSource/FloatPanel/PTSheetOptions.swift:41 | var | public | public var setIntrinsicHeightOnNavigationControllers = true |
| PooToolsSource/FloatPanel/PTSheetOptions.swift:43 | var | public | public var useFullScreenMode = true |
| PooToolsSource/FloatPanel/PTSheetOptions.swift:45 | var | public | public var shrinkPresentingViewController = true |
| PooToolsSource/FloatPanel/PTSheetOptions.swift:47 | var | public | public var useInlineMode = false |
| PooToolsSource/FloatPanel/PTSheetOptions.swift:49 | var | public | public var isRubberBandEnabled: Bool = false |
| PooToolsSource/FloatPanel/PTSheetOptions.swift:54 | var | public | public var transitionAnimationOptions: UIView.AnimationOptions = [.curveEaseOut] |
| PooToolsSource/FloatPanel/PTSheetOptions.swift:56 | var | public | public var transitionDampening: CGFloat = 0.7 |
| PooToolsSource/FloatPanel/PTSheetOptions.swift:58 | var | public | public var transitionDuration: TimeInterval = 0.4 |
| PooToolsSource/FloatPanel/PTSheetOptions.swift:60 | var | public | public var transitionVelocity: CGFloat = 0.8 |
| PooToolsSource/FloatPanel/PTSheetOptions.swift:62 | var | public | public var transitionOverflowType: TransitionOverflowType = .automatic |
| PooToolsSource/FloatPanel/PTSheetOptions.swift:64 | var | public | public var pullDismissThreshold: CGFloat = 500.0 |
| PooToolsSource/FloatPanel/PTSheetOptions.swift:68 | var | public | public var pullDismissThreshod: CGFloat { |
| PooToolsSource/FloatPanel/PTSheetOptions.swift:81 | init | public | public init() { } |
| PooToolsSource/FloatPanel/PTSheetOptions.swift:85 | init | public | public init(pullBarHeight: CGFloat = 24, |
| PooToolsSource/FloatPanel/PTSheetOptions.swift:146 | init | public | public init(pullBarHeight: CGFloat? = nil, |
| PooToolsSource/FloatPanel/PTSheetTransition.swift:29 | class | public | public class PTSheetTransition: NSObject, UIViewControllerAnimatedTransitioning { |
| PooToolsSource/FloatPanel/PTSheetTransition.swift:44 | func | public | public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval { |
| PooToolsSource/FloatPanel/PTSheetTransition.swift:52 | func | public | public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:14 | enum | public | public enum PTSheetSize: Equatable, Sendable { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:23 | class | public | public class PTSheetViewController: PTBaseViewController { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:30 | var | public | public var autoAdjustToKeyboard = PTSheetViewController.autoAdjustToKeyboard |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:35 | var | public | public var allowPullingPastMaxHeight = PTSheetViewController.allowPullingPastMaxHeight |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:40 | var | public | public var allowPullingPastMinHeight = PTSheetViewController.allowPullingPastMinHeight |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:43 | var | public | public var sizes: [PTSheetSize] = [.intrinsic] { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:52 | var | public | public var orderedSizes: [PTSheetSize] = [] |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:56 | var | public | public var dismissOnPull: Bool = true { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:60 | var | public | public var dismissOnOverlayTap: Bool = true { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:64 | var | public | public var shouldRecognizePanGestureWithUIControls: Bool = true |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:67 | var | public | public var childViewController: UIViewController { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:80 | var | public | public var hasBlurBackground = PTSheetViewController.hasBlurBackground { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:89 | var | public | public var visualStyle: PTVisualStyle = .automatic { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:96 | var | public | public var minimumSpaceAbovePullBar: CGFloat { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:107 | var | public | public var overlayColor = PTSheetViewController.overlayColor { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:115 | var | public | public var blurEffect = PTSheetViewController.blurEffect { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:120 | var | public | public var allowGestureThroughOverlay: Bool = PTSheetViewController.allowGestureThroughOverlay { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:127 | var | public | public var cornerRadius: CGFloat { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:133 | var | public | public var cornerCurve: CALayerCornerCurve { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:139 | var | public | public var gripSize: CGSize { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:145 | var | public | public var gripColor: UIColor? { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:151 | var | public | public var pullBarBackgroundColor: UIColor? { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:157 | var | public | public var treatPullBarAsClear: Bool { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:164 | var | public | public var shouldDismiss: ((PTSheetViewController) -> Bool)? |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:165 | var | public | public var didDismiss: ((PTSheetViewController) -> Void)? |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:166 | var | public | public var sizeChanged: ((PTSheetViewController, PTSheetSize, CGFloat) -> Void)? |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:167 | var | public | public var panGestureShouldBegin: ((UIPanGestureRecognizer) -> Bool?)? |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:200 | var | public | public var contentBackgroundColor: UIColor? { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:209 | init | public | public init(controller: UIViewController, sizes: [PTSheetSize] = [.intrinsic], options: PTSheetOptions? = nil, dismissPanGes: Bool = true) { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:346 | func | public | public func handleScrollView(_ scrollView: UIScrollView) { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:352 | func | public | public func setSizes(_ sizes: [PTSheetSize], animated: Bool = true) { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:801 | func | public | public func resize(to size: PTSheetSize, duration: TimeInterval = 0.2, options: UIView.AnimationOptions = [.curveEaseOut], animated: Bool = true, complete: PTActionTask? = nil) { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:847 | func | public | public func attemptDismiss(animated: Bool) { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:871 | func | public | public func updateIntrinsicHeight() { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:905 | func | public | public func animateIn(to view: UIView, in parent: UIViewController, size: PTSheetSize? = nil, duration: TimeInterval = 0.3, completion: PTActionTask? = nil) { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:919 | func | public | public func animateIn(size: PTSheetSize? = nil, duration: TimeInterval = 0.3, completion: PTActionTask? = nil) { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:948 | func | public | public func animateOut(duration: TimeInterval = 0.3, completion: PTActionTask? = nil) { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:976 | func | public | public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:985 | func | public | public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:1020 | func | public | public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? { |
| PooToolsSource/FloatPanel/PTSheetViewController.swift:1025 | func | public | public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? { |
| PooToolsSource/FloatPanel/UIViewController+PTSheetEX.swift:14 | var | public | public var sheetViewController: PTSheetViewController? { |
| PooToolsSource/Font/FontName.swift:11 | struct | public | public struct FontName { |
| PooToolsSource/Foundation/PTCopying.swift:14 | protocol | public | public protocol PTCopying { |
| PooToolsSource/Foundation/PTCopying.swift:24 | func | public | public func copyObject() -> Self { |
| PooToolsSource/Foundation/PTCopying.swift:34 | func | public | public func copy() -> [Element] { |
| PooToolsSource/Guide/PTGuidePageHUD.swift:15 | enum | public | public enum PTGuidePageControlSelection { |
| PooToolsSource/Guide/PTGuidePageHUD.swift:19 | enum | public | public enum PTGuidePageControlOption { |
| PooToolsSource/Guide/PTGuidePageHUD.swift:29 | class | public | public class PTGuidePageModel: NSObject { |
| PooToolsSource/Guide/PTGuidePageHUD.swift:32 | var | public | public var tapHidden: Bool = false |
| PooToolsSource/Guide/PTGuidePageHUD.swift:34 | var | public | public var imageArrays: [Any] = [] |
| PooToolsSource/Guide/PTGuidePageHUD.swift:36 | var | public | public var mainView: UIView = UIView() |
| PooToolsSource/Guide/PTGuidePageHUD.swift:38 | var | public | public var pageControl: PTGuidePageControlSelection = .pageControl(type: .system) |
| PooToolsSource/Guide/PTGuidePageHUD.swift:40 | var | public | public var skipShow: Bool = false |
| PooToolsSource/Guide/PTGuidePageHUD.swift:42 | var | public | public var forwardImage: Any? |
| PooToolsSource/Guide/PTGuidePageHUD.swift:44 | var | public | public var backImage: Any? |
| PooToolsSource/Guide/PTGuidePageHUD.swift:46 | var | public | public var startBackgroundImage: UIImage = UIColor.randomColor.createImageWithColor() |
| PooToolsSource/Guide/PTGuidePageHUD.swift:48 | var | public | public var startTextColor: UIColor = UIColor.randomColor |
| PooToolsSource/Guide/PTGuidePageHUD.swift:50 | var | public | public var iCloudDocumentName: String = "" |
| PooToolsSource/Guide/PTGuidePageHUD.swift:52 | var | public | public var pageControlTintColor: UIColor = UIColor.lightGray |
| PooToolsSource/Guide/PTGuidePageHUD.swift:54 | var | public | public var pageControlCurrentPageColor: UIColor = UIColor.white |
| PooToolsSource/Guide/PTGuidePageHUD.swift:56 | var | public | public var fillPageControlIndicatorRadius: CGFloat = 4 |
| PooToolsSource/Guide/PTGuidePageHUD.swift:58 | var | public | public var customPageControlInActiveTintColor: UIColor = UIColor(white: 1, alpha: 0.3) |
| PooToolsSource/Guide/PTGuidePageHUD.swift:63 | var | public | public var pageControlActiveImage: Any = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "lldotActive") |
| PooToolsSource/Guide/PTGuidePageHUD.swift:65 | var | public | public var pageControlInActiveImage: Any = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "lldotInActive") |
| PooToolsSource/Guide/PTGuidePageHUD.swift:68 | var | public | public var customPageControlTintColor: UIColor = UIColor.white |
| PooToolsSource/Guide/PTGuidePageHUD.swift:70 | var | public | public var customPageControlIndicatorPadding: CGFloat = 8 |
| PooToolsSource/Guide/PTGuidePageHUD.swift:73 | var | public | public var skipName: String = "PT Button skip".localized() |
| PooToolsSource/Guide/PTGuidePageHUD.swift:74 | var | public | public var skipFont: UIFont = .appfont(size: 14) |
| PooToolsSource/Guide/PTGuidePageHUD.swift:75 | var | public | public var startString: String = "PT Guide start".localized() |
| PooToolsSource/Guide/PTGuidePageHUD.swift:76 | var | public | public var startFont: UIFont = .appfont(size: 21) |
| PooToolsSource/Guide/PTGuidePageHUD.swift:80 | class | public | public class PTGuidePageHUD: UIView { |
| PooToolsSource/Guide/PTGuidePageHUD.swift:88 | var | public | public var slideInto: Bool = false // 优化：去除可选类型，提供默认值 false |
| PooToolsSource/Guide/PTGuidePageHUD.swift:89 | var | public | public var animationTime: CGFloat = 3.0 |
| PooToolsSource/Guide/PTGuidePageHUD.swift:90 | var | public | public var adHadRemove: PTActionTask? |
| PooToolsSource/Guide/PTGuidePageHUD.swift:134 | init | public | public init(viewModel: PTGuidePageModel) { |
| PooToolsSource/Guide/PTGuidePageHUD.swift:147 | init | public | public init(mainView: UIView, videlURL: URL) { |
| PooToolsSource/Guide/PTGuidePageHUD.swift:372 | func | public | public func removeGuidePageHUD() { |
| PooToolsSource/Guide/PTGuidePageHUD.swift:377 | func | public | public func guideShow() { |
| PooToolsSource/Guide/PTGuidePageHUD.swift:416 | func | public | public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { |
| PooToolsSource/Guide/PTGuidePageHUD.swift:422 | func | public | public func scrollViewDidScroll(_ scrollView: UIScrollView) { |
| PooToolsSource/HealthKit/PTHealthKit.swift:13 | typealias | public | public typealias StepBlock = (_ isLoad:Bool,_ stepCount:Double) -> Void |
| PooToolsSource/HealthKit/PTHealthKit.swift:16 | class | public | public class PTHealthKit: NSObject { |
| PooToolsSource/HealthKit/PTHealthKit.swift:26 | var | public | public var loadBlock:StepBlock? |
| PooToolsSource/HealthKit/PTHealthKit.swift:88 | func | public | public func updateWorkoutEffortScore(_ sample:HKQuantitySample,workout:HKWorkout,newScore:Double,completion:@escaping @Sendable (Bool) -> Swift.Void) { |
| PooToolsSource/HealthKit/PTHealthKit.swift:121 | func | public | public func addWordoutEffortScore(_ workout:HKWorkout,score:Double,completion:@escaping @Sendable (Bool) -> Swift.Void) { |
| PooToolsSource/HealthPermission/PTPermissionHealth.swift:19 | class | public | public class PTPermissionHealth: PTPermission { |
| PooToolsSource/HealthPermission/PTPermissionHealth.swift:23 | var | open | open var readingUsageDescriptionKey: String? { "NSHealthUpdateUsageDescription" } |
| PooToolsSource/HealthPermission/PTPermissionHealth.swift:24 | var | open | open var writingUsageDescriptionKey: String? { "NSHealthShareUsageDescription" } |
| PooToolsSource/HeartRate/PTFiter.swift:11 | let | public | public let GAIN: Double = 1.894427025e+01 |
| PooToolsSource/HeartRate/PTFiter.swift:15 | class | public | public class PTFiter: NSObject { |
| PooToolsSource/HeartRate/PTFiter.swift:19 | func | public | public func processValue(_ value: Double) -> Double { |
| PooToolsSource/HeartRate/PTHeartRateManager.swift:13 | enum | public | public enum CameraType: Int { |
| PooToolsSource/HeartRate/PTHeartRateManager.swift:17 | func | public | public func captureDevice() -> AVCaptureDevice { |
| PooToolsSource/HeartRate/PTHeartRateManager.swift:32 | typealias | public | public typealias ImageBufferHandler = (_ imageBuffer: CMSampleBuffer) -> () |
| PooToolsSource/HeartRate/PTHeartRateManager.swift:34 | class | public | public class PTHeartRateManager: NSObject { |
| PooToolsSource/HeartRate/PTHeartRateManager.swift:41 | var | public | public var imageBufferHandler: ImageBufferHandler? |
| PooToolsSource/HeartRate/PTHeartRateManager.swift:43 | init | public | public init(cameraType: CameraType, preferredSpec: VideoSpec?, previewContainer: CALayer?) { |
| PooToolsSource/HeartRate/PTHeartRateManager.swift:92 | func | public | public func startCapture() { |
| PooToolsSource/HeartRate/PTHeartRateManager.swift:105 | func | public | public func stopCapture() { |
| PooToolsSource/HeartRate/PTHeartRateManager.swift:121 | func | public | public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) { |
| PooToolsSource/HeartRate/PTHeartRateViewController.swift:16 | typealias | public | public typealias RGB = (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) |
| PooToolsSource/HeartRate/PTHeartRateViewController.swift:17 | typealias | public | public typealias HSV = (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) |
| PooToolsSource/HeartRate/PTHeartRateViewController.swift:19 | func | public | public func hsv2rgb(_ hsv: HSV) -> RGB { |
| PooToolsSource/HeartRate/PTHeartRateViewController.swift:53 | func | public | public func rgb2hsv(_ rgb: RGB) -> HSV { |
| PooToolsSource/HeartRate/PTHeartRateViewController.swift:93 | class | public | public class PTHeartRateViewController: PTBaseViewController { |
| PooToolsSource/HeartRate/PTHeartRateViewController.swift:95 | let | public | public let sessionQueue = DispatchQueue(label: "camera.session.collector.metal") |
| PooToolsSource/HeartRate/PTPulseDetector.swift:11 | let | public | public let MAX_PERIOD = 1.5 |
| PooToolsSource/HeartRate/PTPulseDetector.swift:12 | let | public | public let MIN_PERIOD = 0.1 |
| PooToolsSource/HeartRate/PTPulseDetector.swift:13 | let | public | public let MAX_PERIODS_TO_STORE: Int = 20 |
| PooToolsSource/HeartRate/PTPulseDetector.swift:14 | let | public | public let AVERAGE_SIZE: Int = 20 |
| PooToolsSource/HeartRate/PTPulseDetector.swift:15 | let | public | public let INVALID_PULSE_PERIOD: Float = -1 |
| PooToolsSource/HeartRate/PTPulseDetector.swift:17 | class | public | public class PTPulseDetector: NSObject { |
| PooToolsSource/HeartRate/PTPulseDetector.swift:41 | func | public | public func addNewValue(_ newVal: Double, atTime time: Double) -> Float { |
| PooToolsSource/HeartRate/PTPulseDetector.swift:102 | func | public | public func getAverage() -> Float { |
| PooToolsSource/HeartRate/PTPulseDetector.swift:118 | func | public | public func reset() { |
| PooToolsSource/Hud/PTProgressHUD.swift:12 | class | public | public class PTProgressHUD: UIView { |
| PooToolsSource/Hud/PTProgressHUD.swift:16 | enum | public | public enum Mode: Equatable { |
| PooToolsSource/Hud/PTProgressHUD.swift:25 | enum | public | public enum AnimationType { |
| PooToolsSource/Hud/PTProgressHUD.swift:36 | var | public | public var mode: Mode = .indeterminate { |
| PooToolsSource/Hud/PTProgressHUD.swift:40 | var | public | public var title: String? { |
| PooToolsSource/Hud/PTProgressHUD.swift:44 | var | public | public var details: String? { |
| PooToolsSource/Hud/PTProgressHUD.swift:49 | var | public | public var autoHideWhenProgressCompletes: Bool = true |
| PooToolsSource/Hud/PTProgressHUD.swift:52 | var | public | public var progress: Float = 0.0 { |
| PooToolsSource/Hud/PTProgressHUD.swift:74 | var | public | public var minShowTime: TimeInterval = 0.0 |
| PooToolsSource/Hud/PTProgressHUD.swift:77 | var | public | public var graceTime: TimeInterval = 0.0 |
| PooToolsSource/Hud/PTProgressHUD.swift:80 | var | public | public var completionBlock: (() -> Void)? |
| PooToolsSource/Hud/PTProgressHUD.swift:85 | var | public | public var margin: CGFloat = 20.0 { |
| PooToolsSource/Hud/PTProgressHUD.swift:90 | var | public | public var isSquare: Bool = false { |
| PooToolsSource/Hud/PTProgressHUD.swift:95 | var | public | public var offset: CGPoint = .zero { |
| PooToolsSource/Hud/PTProgressHUD.swift:101 | var | public | public var animationType: AnimationType = .fade |
| PooToolsSource/Hud/PTProgressHUD.swift:103 | var | public | public var cornerRadius: CGFloat = 10.0 { |
| PooToolsSource/Hud/PTProgressHUD.swift:107 | var | public | public var titleColor: UIColor = .label { |
| PooToolsSource/Hud/PTProgressHUD.swift:111 | var | public | public var detailsColor: UIColor = .secondaryLabel { |
| PooToolsSource/Hud/PTProgressHUD.swift:115 | var | public | public var indicatorColor: UIColor = .white { |
| PooToolsSource/Hud/PTProgressHUD.swift:119 | var | public | public var dimBackground: Bool = false { |
| PooToolsSource/Hud/PTProgressHUD.swift:125 | var | public | public var titleFont: UIFont = .boldSystemFont(ofSize: 16) { |
| PooToolsSource/Hud/PTProgressHUD.swift:129 | var | public | public var detailsFont: UIFont = .systemFont(ofSize: 14) { |
| PooToolsSource/Hud/PTProgressHUD.swift:134 | var | public | public var blurEffectStyle: UIBlurEffect.Style = .systemThickMaterial { |
| PooToolsSource/Hud/PTProgressHUD.swift:143 | var | public | public var bezelColor: UIColor? { |
| PooToolsSource/Hud/PTProgressHUD.swift:391 | func | public | public func hide(animated: Bool, afterDelay delay: TimeInterval) { |
| PooToolsSource/Hud/PTProgressHUD.swift:405 | func | public | public func show(animated: Bool) { |
| PooToolsSource/Hud/PTProgressHUD.swift:449 | func | public | public func hide(animated: Bool) { |
| PooToolsSource/IAP/PTIAPManager.swift:13 | typealias | public | public typealias ProductsCompletionBlock = ([SKProduct]) -> Void |
| PooToolsSource/IAP/PTIAPManager.swift:14 | typealias | public | public typealias PurchaseCompletionBlock = (SKPaymentTransaction?) -> Void |
| PooToolsSource/IAP/PTIAPManager.swift:15 | typealias | public | public typealias IAPErrorBlock = (Error) -> Void |
| PooToolsSource/IAP/PTIAPManager.swift:18 | class | public | public class PTIAPManager: NSObject, @MainActor SKProductsRequestDelegate, @MainActor SKPaymentTransactionObserver { |
| PooToolsSource/IAP/PTIAPManager.swift:73 | func | public | public func hasPurchased(_ productID: String) -> Bool { |
| PooToolsSource/IAP/PTIAPManager.swift:87 | func | public | public func getProducts(forIds productIds: [String], completion: @escaping ProductsCompletionBlock) { |
| PooToolsSource/IAP/PTIAPManager.swift:120 | func | public | public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) { |
| PooToolsSource/IAP/PTIAPManager.swift:132 | func | public | public func restorePurchases() { |
| PooToolsSource/IAP/PTIAPManager.swift:136 | func | public | public func restorePurchases(completion: PTActionTask?, error: IAPErrorBlock?) { |
| PooToolsSource/IAP/PTIAPManager.swift:142 | func | public | public func purchase(product: SKProduct, completion: @escaping PurchaseCompletionBlock, error: @escaping IAPErrorBlock) { |
| PooToolsSource/IAP/PTIAPManager.swift:153 | func | public | public func purchase(productId: String, completion: @escaping PurchaseCompletionBlock, error: @escaping IAPErrorBlock) { |
| PooToolsSource/IAP/PTIAPManager.swift:163 | func | public | @MainActor public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) { |
| PooToolsSource/IAP/PTIAPManager.swift:208 | func | public | public func canPurchase() -> Bool { |
| PooToolsSource/IAP/PTIAPManager.swift:214 | func | public | public func addPurchasesChangedCallback(_ callback: @escaping PTActionTask, withContext context: AnyObject) { |
| PooToolsSource/IAP/PTIAPManager.swift:218 | func | public | public func removePurchasesChangedCallback(withContext context: AnyObject) { |
| PooToolsSource/IAP/PTIAPManager.swift:222 | func | public | @MainActor public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) { |
| PooToolsSource/IAP/PTIAPManager.swift:228 | func | public | public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) { |
| PooToolsSource/ImageEditor/PTAdjustSliderView.swift:19 | struct | public | public struct PTAdjustStatus { |
| PooToolsSource/ImageEditor/PTAdjustSliderView.swift:20 | var | public | public var brightness: Float = 1 |
| PooToolsSource/ImageEditor/PTAdjustSliderView.swift:21 | var | public | public var contrast: Float = 0 |
| PooToolsSource/ImageEditor/PTAdjustSliderView.swift:22 | var | public | public var saturation: Float = 0 |
| PooToolsSource/ImageEditor/PTAdjustSliderView.swift:24 | var | public | public var allValueIsZero: Bool { |
| PooToolsSource/ImageEditor/PTAdjustSliderView.swift:29 | class | public | public class PTAdjustSliderView: UIView { |
| PooToolsSource/ImageEditor/PTCutViewController.swift:905 | var | public | public var engineMaxClipFrame: CGRect { maxClipFrame } |
| PooToolsSource/ImageEditor/PTCutViewController.swift:906 | var | public | public var engineMinClipSize: CGSize { minClipSize } |
| PooToolsSource/ImageEditor/PTCutViewController.swift:969 | var | public | public var isCircle = false { |
| PooToolsSource/ImageEditor/PTCutViewController.swift:977 | var | public | public var isEditing = false { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:25 | struct | public | public struct PTCanvasMetrics { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:26 | let | public | public let ratio: CGFloat |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:27 | let | public | public let originalRatio: CGFloat |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:28 | let | public | public let toImageScale: CGFloat |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:29 | let | public | public let renderSize: CGSize |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:32 | enum | public | public enum PTClipPanEdge { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:37 | protocol | public | public protocol PTEditImageEngineContext: AnyObject { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:169 | func | public | public func getRawTextRects() -> [CGRect] { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:195 | struct | public | public struct PTTextStickerRenderer { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:274 | class | public | public class PTPassthroughView: UIView { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:290 | protocol | public | @MainActor public protocol PTEditImageToolEngine: AnyObject { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:303 | class | public | public class PTDrawEngine: NSObject, PTEditImageToolEngine { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:307 | var | public | public var canvasView: UIView { drawingImageView } |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:317 | var | public | public var drawPaths: [PTDrawPath] = [] |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:319 | var | public | public var deleteDrawPaths: Set<PTDrawPath> = [] |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:321 | var | public | public var drawColor: UIColor = .systemRed |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:322 | var | public | public var defaultDrawPathWidth: CGFloat = 0 |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:323 | var | public | public var isEraserMode: Bool = false |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:334 | var | public | public var onInteractStateChanged: ((Bool) -> Void)? |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:338 | init | public | public init(context: PTEditImageEngineContext) { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:346 | func | public | public func toolDidActivate() { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:350 | func | public | public func toolDidDeactivate() { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:355 | func | public | public func reloadRenderState() { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:364 | func | public | public func handlePanGesture(_ pan: UIPanGestureRecognizer) { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:448 | func | public | public func drawLine() { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:476 | class | public | public class PTMosaicEngine: NSObject, PTEditImageToolEngine { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:479 | var | public | public var canvasView: UIView { mosaicContainerView } |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:504 | var | public | public var mosaicPaths: [PTDrawPath] = [] |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:505 | var | public | public var isEraserMode: Bool = false |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:512 | var | public | public var onInteractStateChanged: ((Bool) -> Void)? |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:514 | init | public | public init(context: PTEditImageEngineContext) { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:522 | func | public | public func toolDidActivate() { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:543 | func | public | public func toolDidDeactivate() { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:547 | func | public | public func reloadRenderState() { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:554 | func | public | public func handlePanGesture(_ pan: UIPanGestureRecognizer) { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:665 | func | public | public func updateBaseMosaicImage(_ newBaseImage: UIImage) { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:672 | class | public | public class PTStickerEngine: NSObject, PTEditImageToolEngine { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:675 | var | public | public var customTextEditorClass: PTTextEditorConfigurable.Type = PTEditInputViewController.self |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:676 | var | public | public var canvasView: UIView { stickersContainer } |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:691 | var | public | public var onInteractStateChanged: ((Bool) -> Void)? |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:693 | var | public | public var onStickerTapped: ((PTBaseStickerView) -> Void)? |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:694 | var | public | public var onStickerAdded: ((PTBaseStickerView) -> Void)? |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:696 | var | public | public var currentSelectedSticker: PTBaseStickerView? |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:698 | var | public | public var onRequestImageSelection: ((_ completion: @escaping (UIImage?) -> Void) -> Void)? |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:699 | var | public | public var onProcessingStateChanged: ((Bool) -> Void)? |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:702 | init | public | public init(context: PTEditImageEngineContext) { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:711 | func | public | public func toolDidActivate() { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:715 | func | public | public func toolDidDeactivate() { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:725 | func | public | public func handlePanGesture(_ pan: UIPanGestureRecognizer) { } |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:727 | func | public | public func reloadRenderState() { } |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:764 | func | public | public func removeCurrentSelectedSticker() { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:791 | func | public | public func createTextSticker(text: String? = nil, textColor: UIColor? = nil, font: UIFont? = nil, style: PTInputTextStyle = PTInputTextStyle()) { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:859 | func | public | public func updateSelectedTextSticker(newFont: UIFont? = nil, newColor: UIColor? = nil, newStyle: PTInputTextStyle? = nil) { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:889 | func | public | public func addImageSticker(_ image: UIImage) { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:908 | func | public | public func removeBackgroundForSelectedSticker() { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:979 | func | public | public func undoOrRedoSticker(oldState: PTBaseStickertState?, newState: PTBaseStickertState?, isUndo: Bool) { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1000 | func | public | public func bringSelectedToFront() { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1005 | func | public | public func sendSelectedToBack() { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1010 | func | public | public func centerSelectedHorizontally() { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1016 | func | public | public func centerSelectedVertically() { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1023 | func | public | public func moveSelectedOneLayerUp() { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1037 | func | public | public func moveSelectedOneLayerDown() { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1050 | func | public | public func fillSelectedStickerToScreen() { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1104 | func | public | public func stickerBeginOperation(_ sticker: PTBaseStickerView) { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1131 | func | public | public func stickerOnOperation(_ sticker: PTBaseStickerView, panGes: UIPanGestureRecognizer) { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1154 | func | public | public func stickerEndOperation(_ sticker: PTBaseStickerView, panGes: UIPanGestureRecognizer) { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1184 | func | public | public func stickerDidTap(_ sticker: PTBaseStickerView) { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1194 | func | public | public func sticker(_ textSticker: PTTextStickerView, editText text: String) { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1216 | func | public | public func sticker(_ imageSticker: PTImageStickerView, editImage currentImage: UIImage) { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1246 | class | public | public class PTAdjustEngine: NSObject, PTEditImageToolEngine { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1252 | var | public | public var canvasView: UIView { emptyCanvasView } |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1261 | var | public | public var currentAdjustStatus = PTAdjustStatus() |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1262 | var | public | public var preAdjustStatus = PTAdjustStatus() |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1263 | var | public | public var selectedAdjustTool: PTHarBethFilter.FiltersTool? |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1274 | init | public | public init(context: PTEditImageEngineContext) { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1309 | func | public | public func toolDidActivate() { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1315 | func | public | public func toolDidDeactivate() { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1320 | func | public | public func handlePanGesture(_ pan: UIPanGestureRecognizer) { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1324 | func | public | public func reloadRenderState() { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1332 | func | public | public func changeAdjustTool(_ tool: PTHarBethFilter.FiltersTool) { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1385 | func | public | public func adjustFilterValueSet(filterImage: UIImage?) -> UIImage? { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1409 | class | public | public class PTFilterEngine: NSObject, PTEditImageToolEngine { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1414 | var | public | public var canvasView: UIView { emptyCanvasView } |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1416 | var | public | public var currentFilter: PTHarBethFilter = .none |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1417 | var | public | public var thumbnailFilterImages: [UIImage] = [] |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1432 | init | public | public init(context: PTEditImageEngineContext) { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1437 | func | public | public func toolDidActivate() { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1441 | func | public | public func toolDidDeactivate() { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1444 | func | public | public func handlePanGesture(_ pan: UIPanGestureRecognizer) { } |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1450 | func | public | public func reloadRenderState() { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1458 | func | public | public func generateFilterThumbnails() async { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1480 | func | public | public func changeFilter(_ filter: PTHarBethFilter) { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1512 | protocol | public | public protocol PTClipEngineContext: AnyObject { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1517 | class | public | public class PTClipEngine: NSObject { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1521 | var | public | public var clipBoxFrame: CGRect = .zero |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1522 | var | public | public var selectedRatio: PTImageClipRatio |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1533 | var | public | public var onInteractStateChanged: ((Bool) -> Void)? |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1536 | var | public | public var onClipBoxFrameChanged: ((CGRect) -> Void)? |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1540 | init | public | public init(context: PTClipEngineContext, initialRatio: PTImageClipRatio) { |
| PooToolsSource/ImageEditor/PTEditImageToolEngine.swift:1548 | func | public | @MainActor public func handlePanGesture(_ pan: UIPanGestureRecognizer, in view: UIView) { |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:25 | class | public | public class PTEditImageViewController: PTBaseViewController { |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:27 | var | public | public var editFinishBlock: ((UIImage, PTEditModel?) -> Void)? |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:31 | var | public | public var editResultBlock: (@MainActor @Sendable (PTImageEditorResult) -> Void)? |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:32 | var | public | public var backHandler:PTActionTask? |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:612 | init | public | public init(readyEditImage: UIImage) { |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:956 | func | public | public func editImageShow(vc:UIViewController) { |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1286 | func | public | public func viewForZooming(in scrollView: UIScrollView) -> UIView? { |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1290 | func | public | public func scrollViewDidZoom(_ scrollView: UIScrollView) { |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1296 | func | public | public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) { |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1316 | func | public | public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1323 | func | public | public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) { |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1333 | func | public | public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool { |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1360 | func | public | public func editorManager(_ manager: PTMediaEditManager, didUpdateActions actions: [PTMediaEditorAction], redoActions: [PTMediaEditorAction]) { |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1365 | func | public | public func editorManager(_ manager: PTMediaEditManager, undoAction action: PTMediaEditorAction) { |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1384 | func | public | public func editorManager(_ manager: PTMediaEditManager, redoAction action: PTMediaEditorAction) { |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1489 | var | public | public var engineScrollView: UIScrollView { mainScrollView } |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1490 | var | public | public var engineOriginalImageSize: CGSize { originalImage.size } |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1491 | var | public | public var engineEditImageSize: CGSize { editImage.size } |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1492 | var | public | public var engineEditRect: CGRect { currentClipStatus.editRect } |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1493 | var | public | public var engineShouldSwapSize: Bool { shouldSwapSize } |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1494 | var | public | public var engineCurrentAngle: CGFloat { currentClipStatus.angle } |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1495 | var | public | public var engineEditorManager: PTMediaEditManager { editorManager } |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1496 | var | public | public var engineEraserCircleView: UIImageView { eraserCircleView } |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1498 | var | public | public var engineOriginalImage: UIImage { originalImage } |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1499 | var | public | public var engineCurrentEditImage: UIImage { editImage } |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1502 | func | public | public func engineUpdateEditImage(_ newImage: UIImage) { |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1507 | var | public | public var engineMainView: UIView { view } |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1508 | var | public | public var engineViewController: UIViewController { self } |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1509 | var | public | public var engineAshbinView: UIView { ashbinView } |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1510 | var | public | public var engineAshbinImgView: UIImageView { ashbinImgView } |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1512 | var | public | public var engineImageWithoutAdjust: UIImage { editImageWithoutAdjust } |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1515 | func | public | public func engineRequestAdjustReferenceImage() -> UIImage { |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1524 | var | public | public var engineThumbnailImage: UIImage? { thumbnailImage } |
| PooToolsSource/ImageEditor/PTEditImageViewController.swift:1527 | func | public | public func engineDidUpdateFilteredBaseImage(_ newBaseImage: UIImage) { |
| PooToolsSource/ImageEditor/PTEditInputProtocol.swift:13 | protocol | public | public protocol PTTextEditorConfigurable: UIViewController { |
| PooToolsSource/ImageEditor/PTEditInputViewController.swift:21 | class | public | public class PTEditInputViewController: PTBaseViewController,PTTextEditorConfigurable { |
| PooToolsSource/ImageEditor/PTEditInputViewController.swift:44 | var | public | public var endInput: ((String, UIColor, UIFont, UIImage?, PTInputTextStyle) -> Void)? |
| PooToolsSource/ImageEditor/PTEditInputViewController.swift:616 | func | public | public func textViewDidChange(_ textView: UITextView) { |
| PooToolsSource/ImageEditor/PTEditInputViewController.swift:629 | func | public | public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool { |
| PooToolsSource/ImageEditor/PTEditInputViewController.swift:639 | func | public | public func layoutManager(_ layoutManager: NSLayoutManager, didCompleteLayoutFor textContainer: NSTextContainer?, atEnd layoutFinishedFlag: Bool) { |
| PooToolsSource/ImageEditor/PTEditModel.swift:21 | enum | public | public enum PTImageEditorError: Error, LocalizedError, Sendable, Equatable { |
| PooToolsSource/ImageEditor/PTEditModel.swift:26 | var | public | public var errorDescription: String? { |
| PooToolsSource/ImageEditor/PTEditModel.swift:42 | enum | public | public enum PTImageEditorResult { |
| PooToolsSource/ImageEditor/PTEditModel.swift:49 | class | public | public class PTEditModel:NSObject { |
| PooToolsSource/ImageEditor/PTEditModel.swift:50 | let | public | public let drawPaths: [PTDrawPath] |
| PooToolsSource/ImageEditor/PTEditModel.swift:52 | let | public | public let mosaicPaths: [PTDrawPath] |
| PooToolsSource/ImageEditor/PTEditModel.swift:54 | let | public | public let clipStatus: PTClipStatus |
| PooToolsSource/ImageEditor/PTEditModel.swift:56 | let | public | public let adjustStatus: PTAdjustStatus |
| PooToolsSource/ImageEditor/PTEditModel.swift:58 | let | public | public let selectFilter: PTHarBethFilter? |
| PooToolsSource/ImageEditor/PTEditModel.swift:60 | let | public | public let stickers: [PTBaseStickertState] |
| PooToolsSource/ImageEditor/PTEditModel.swift:62 | let | public | public let actions: [PTMediaEditorAction] |
| PooToolsSource/ImageEditor/PTEditModel.swift:64 | init | public | public init(drawPaths: [PTDrawPath], |
| PooToolsSource/ImageEditor/PTEditToolsCell.swift:21 | var | public | public var normalImage:UIImage = UIImage() |
| PooToolsSource/ImageEditor/PTEditToolsCell.swift:22 | var | public | public var selectedImage:UIImage? |
| PooToolsSource/ImageEditor/PTEditToolsCell.swift:23 | var | public | public var currentType:PTImageEditorConfig.EditTool = .draw |
| PooToolsSource/ImageEditor/PTEditToolsCell.swift:24 | var | public | public var isSelected:Bool = false |
| PooToolsSource/ImageEditor/PTFontPickerViewController.swift:20 | class | public | public class PTFontPickerViewController: PTBaseViewController { |
| PooToolsSource/ImageEditor/PTFontPickerViewController.swift:36 | var | public | public var selectedFontCallback:((UIFont)->Void)? |
| PooToolsSource/ImageEditor/PTFontPickerViewController.swift:37 | var | public | public var viewDismiss:PTActionTask? |
| PooToolsSource/ImageEditor/PTFontPickerViewController.swift:76 | func | public | public func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) { |
| PooToolsSource/ImageEditor/PTFontPickerViewController.swift:85 | func | public | public func fontPickerViewControllerDidCancel(_ viewController: UIFontPickerViewController) { |
| PooToolsSource/ImageEditor/PTImageClipRatio.swift:11 | struct | public | public struct PTClipStatus { |
| PooToolsSource/ImageEditor/PTImageClipRatio.swift:12 | var | public | public var angle: CGFloat = 0 |
| PooToolsSource/ImageEditor/PTImageClipRatio.swift:13 | var | public | public var editRect: CGRect |
| PooToolsSource/ImageEditor/PTImageClipRatio.swift:14 | var | public | public var ratio: PTImageClipRatio? |
| PooToolsSource/ImageEditor/PTImageClipRatio.swift:16 | init | public | public init(angle: CGFloat = 0, editRect: CGRect, ratio: PTImageClipRatio? = nil) { |
| PooToolsSource/ImageEditor/PTImageClipRatio.swift:24 | class | public | public class PTImageClipRatio: NSObject { |
| PooToolsSource/ImageEditor/PTImageClipRatio.swift:25 | var | public | @objc public var title: String |
| PooToolsSource/ImageEditor/PTImageClipRatio.swift:27 | let | public | @objc public let whRatio: CGFloat |
| PooToolsSource/ImageEditor/PTImageClipRatio.swift:29 | let | public | @objc public let isCircle: Bool |
| PooToolsSource/ImageEditor/PTImageClipRatio.swift:31 | init | public | @objc public init(title: String, whRatio: CGFloat, isCircle: Bool = false) { |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:22 | enum | public | public enum PTImageEditorOutputPolicy: Sendable, Equatable { |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:29 | enum | public | @objc public enum PTAdjustSliderType: Int { |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:35 | class | public | public class PTImageEditorConfig: NSObject { |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:41 | var | public | public var outputPolicy: PTImageEditorOutputPolicy = .safe |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:44 | var | public | public var maxFrameCountForGIF = 50 |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:48 | var | public | public var textStickerDefaultTextColor = UIColor.white |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:50 | var | public | public var textStickerDefaultFont: UIFont? |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:55 | var | public | public var adjustSliderType: PTAdjustSliderType = .vertical |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:58 | var | public | public var adjustSliderNormalColor: UIColor = .white |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:62 | var | public | public var themeColor: UIColor = .purple |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:67 | var | public | public var adjustSliderTintColor: UIColor { |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:77 | var | public | public var impactFeedbackWhenAdjustSliderValueIsZero = true |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:79 | var | public | public var impactFeedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:89 | var | public | public var clipRatios: [PTImageClipRatio] { |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:103 | var | public | public var dimClippedAreaDuringAdjustments = false |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:107 | enum | public | @objc public enum EditTool: Int, CaseIterable,Sendable { |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:121 | var | public | public var tools: [PTImageEditorConfig.EditTool] { |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:137 | var | public | public var filters: [PTHarBethFilter] { |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:151 | var | public | public var minimumZoomScale = 1.0 |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:154 | var | public | public var adjust_tools: [PTHarBethFilter.FiltersTool] { |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:171 | var | public | public var backImage:UIImage = "❌".emojiToImage(emojiFont: .appfont(size: 20)) |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:172 | var | public | public var submitImage:UIImage = "✅".emojiToImage(emojiFont: .appfont(size: 20)) |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:173 | var | public | public var undoNormal:UIImage = "↩️".emojiToImage(emojiFont: .appfont(size: 20)) |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:174 | var | public | public var undoDisable:UIImage = "⇠".emojiToImage(emojiFont: .appfont(size: 20)).withTintColor(.lightGray) |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:175 | var | public | public var redoNormal:UIImage = "↪️".emojiToImage(emojiFont: .appfont(size: 20)) |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:176 | var | public | public var redoDisable:UIImage = "⇢".emojiToImage(emojiFont: .appfont(size: 20)).withTintColor(.lightGray) |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:177 | var | public | public var doingAlertTitle:String = "PT Alert Doning".localized() |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:178 | var | public | public var deleteAlertTitle:String = "PT Photo picker drop delete".localized() |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:182 | var | public | public var cutBackImage:UIImage = "❌".emojiToImage(emojiFont: .appfont(size: 20)) |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:183 | var | public | public var cutSubmitImage:UIImage = "✅".emojiToImage(emojiFont: .appfont(size: 20)) |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:184 | var | public | public var cutUndoImage:UIImage = "↩️".emojiToImage(emojiFont: .appfont(size: 20)) |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:185 | var | public | public var cutRotateImage:UIImage = "🔄".emojiToImage(emojiFont: .appfont(size: 20)) |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:186 | var | public | public var cutTitleFont:UIFont = .appfont(size: 12) |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:190 | var | public | public var textBackImage:UIImage = "❌".emojiToImage(emojiFont: .appfont(size: 20)) |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:191 | var | public | public var textSubmitImage:UIImage = "✅".emojiToImage(emojiFont: .appfont(size: 20)) |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:195 | var | public | public var colorPickerBackImage:UIImage = "❌".emojiToImage(emojiFont: .appfont(size: 20)) |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:199 | var | public | public var adjustSliderFont:UIFont = .appfont(size: 12) |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:200 | var | public | public var adjustSliderCellFont:UIFont = .appfont(size: 12) |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:201 | var | public | public var adjustBrightnessString:String = "PT Photo picker brightness".localized() |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:202 | var | public | public var adjustSaturationString:String = "PT Photo picker saturation".localized() |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:203 | var | public | public var adjustContrastString:String = "PT Photo picker contrast".localized() |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:205 | var | public | public var drawLineWidth:CGFloat = 6 |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:206 | var | public | public var mosaicLineWidth:CGFloat = 25 |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:208 | var | public | public var staticEdgeInset:CGFloat = 20 |
| PooToolsSource/ImageEditor/PTImageEditorSticker.swift:11 | class | public | public class PTBaseStickertState: NSObject { |
| PooToolsSource/ImageEditor/PTImageEditorSticker.swift:12 | let | public | public let id: String |
| PooToolsSource/ImageEditor/PTImageEditorSticker.swift:13 | let | public | public let image: UIImage |
| PooToolsSource/ImageEditor/PTImageEditorSticker.swift:14 | let | public | public let originScale: CGFloat |
| PooToolsSource/ImageEditor/PTImageEditorSticker.swift:15 | let | public | public let originAngle: CGFloat |
| PooToolsSource/ImageEditor/PTImageEditorSticker.swift:16 | let | public | public let originFrame: CGRect |
| PooToolsSource/ImageEditor/PTImageEditorSticker.swift:17 | let | public | public let gesScale: CGFloat |
| PooToolsSource/ImageEditor/PTImageEditorSticker.swift:18 | let | public | public let gesRotation: CGFloat |
| PooToolsSource/ImageEditor/PTImageEditorSticker.swift:19 | let | public | public let totalTranslationPoint: CGPoint |
| PooToolsSource/ImageEditor/PTImageEditorSticker.swift:21 | init | public | public init(id: String, |
| PooToolsSource/ImageEditor/PTImageEditorSticker.swift:41 | class | public | public class PTImageStickerState: PTBaseStickertState { } |
| PooToolsSource/ImageEditor/PTImageEditorSticker.swift:43 | class | public | public class PTTextStickerState: PTBaseStickertState { |
| PooToolsSource/ImageEditor/PTMediaEditManager.swift:19 | enum | public | public enum PTMediaEditorAction { |
| PooToolsSource/ImageEditor/PTMediaEditManager.swift:29 | protocol | public | public protocol PTMediaEditorManagerDelegate: AnyObject { |
| PooToolsSource/ImageEditor/PTMediaEditManager.swift:37 | class | public | public class PTMediaEditManager:NSObject { |
| PooToolsSource/ImageEditor/PTMediaEditManager.swift:44 | init | public | public init(actions: [PTMediaEditorAction] = []) { |
| PooToolsSource/ImageEditor/PTMediaEditManager.swift:49 | func | public | public func storeAction(_ action: PTMediaEditorAction) { |
| PooToolsSource/ImageEditor/PTMediaEditManager.swift:56 | func | public | public func undoAction() { |
| PooToolsSource/ImageEditor/PTMediaEditManager.swift:63 | func | public | public func redoAction() { |
| PooToolsSource/ImageEditor/PTPaths.swift:12 | class | public | public class PTDrawPath: NSObject { |
| PooToolsSource/ImageEditor/PTPaths.swift:25 | var | public | public var isEraser = false |
| PooToolsSource/ImageEditor/PTStickerManager.swift:22 | struct | public | public struct PTInputTextStyle: Equatable { |
| PooToolsSource/ImageEditor/PTStickerManager.swift:24 | enum | public | public enum BackgroundStyle: Int { |
| PooToolsSource/ImageEditor/PTStickerManager.swift:30 | var | public | public var bgStyle: BackgroundStyle = .normal |
| PooToolsSource/ImageEditor/PTStickerManager.swift:31 | var | public | public var alignment: NSTextAlignment = .left |
| PooToolsSource/ImageEditor/PTStickerManager.swift:32 | var | public | public var isBold: Bool = true |
| PooToolsSource/ImageEditor/PTStickerManager.swift:33 | var | public | public var isItalic: Bool = false |
| PooToolsSource/ImageEditor/PTStickerManager.swift:34 | var | public | public var hasUnderline: Bool = false |
| PooToolsSource/ImageEditor/PTStickerManager.swift:35 | var | public | public var hasStrikethrough: Bool = false |
| PooToolsSource/ImageEditor/PTStickerManager.swift:36 | var | public | public var outputWithTextViewBound: Bool = false |
| PooToolsSource/ImageEditor/PTStickerManager.swift:37 | var | public | public var rects:[CGRect] = [] |
| PooToolsSource/ImageEditor/PTStickerManager.swift:40 | init | public | public init() {} |
| PooToolsSource/ImageEditor/PTStickerManager.swift:53 | class | public | public class PTImageStickerView: PTBaseStickerView { |
| PooToolsSource/ImageEditor/PTStickerManager.swift:54 | var | public | public var image: UIImage { |
| PooToolsSource/ImageEditor/PTStickerManager.swift:163 | protocol | public | @MainActor public protocol PTStickerViewDelegate: NSObject { |
| PooToolsSource/ImageEditor/PTStickerManager.swift:181 | protocol | public | public protocol PTStickerViewAdditional: NSObject { |
| PooToolsSource/ImageEditor/PTStickerManager.swift:191 | class | public | public class PTBaseStickerView: UIView, UIGestureRecognizerDelegate { |
| PooToolsSource/ImageEditor/PTStickerManager.swift:225 | var | public | public var gesIsEnabled = true |
| PooToolsSource/ImageEditor/PTStickerManager.swift:243 | var | public | public var state: PTBaseStickertState { fatalError() } |
| PooToolsSource/ImageEditor/PTStickerManager.swift:283 | class | public | public class func calculateSize(image: UIImage, maxLimitSize: CGSize) -> CGSize { |
| PooToolsSource/ImageEditor/PTStickerManager.swift:319 | class | public | public class func getStickerOriginFrame(_ size: CGSize,current: PTEditImageEngineContext?,container:PTPassthroughView) -> CGRect { |
| PooToolsSource/ImageEditor/PTStickerManager.swift:653 | func | public | public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { |
| PooToolsSource/ImageEditor/PTStickerManager.swift:865 | func | public | public func resetState() { |
| PooToolsSource/ImageEditor/PTStickerManager.swift:871 | func | public | public func moveToAshbin() { |
| PooToolsSource/ImageEditor/PTStickerManager.swift:876 | func | public | public func addScale(_ scale: CGFloat) { |
| PooToolsSource/ImageEditor/PTStickerManager.swift:927 | class | public | public class PTTextStickerView: PTBaseStickerView { |
| PooToolsSource/ImageEditor/PTStickerManager.swift:937 | var | public | public var text: String |
| PooToolsSource/ImageEditor/PTStickerManager.swift:939 | var | public | public var textColor: UIColor |
| PooToolsSource/ImageEditor/PTStickerManager.swift:941 | var | public | public var font: UIFont? |
| PooToolsSource/ImageEditor/PTStickerManager.swift:943 | var | public | public var style: PTInputTextStyle |
| PooToolsSource/ImageEditor/PTStickerManager.swift:945 | var | public | public var image: UIImage { |
| PooToolsSource/ImageEditor/PTWeakProxy.swift:18 | init | public | public init(target: NSObjectProtocol) { |
| PooToolsSource/ImageEditor/PTWeakProxy.swift:26 | class | public | public class func proxy(withTarget target: NSObjectProtocol) -> PTWeakProxy { |
| PooToolsSource/ImagePicker/PTImagePicker.swift:22 | enum | public | public enum PTSystemMediaPickerKind: Sendable { |
| PooToolsSource/ImagePicker/PTImagePicker.swift:31 | enum | public | public enum PTSystemMediaPickerResult: Sendable { |
| PooToolsSource/ImagePicker/PTImagePicker.swift:35 | var | public | public var assetIdentifier: String? { |
| PooToolsSource/ImagePicker/PTImagePicker.swift:42 | var | public | public var imageData: Data? { |
| PooToolsSource/ImagePicker/PTImagePicker.swift:47 | var | public | public var videoURL: URL? { |
| PooToolsSource/ImagePicker/PTImagePicker.swift:56 | enum | public | public enum PTSystemMediaPickerError: Error, LocalizedError, Sendable { |
| PooToolsSource/ImagePicker/PTImagePicker.swift:66 | var | public | public var errorDescription: String? { |
| PooToolsSource/ImagePicker/PTImagePicker.swift:92 | enum | public | public enum PTCameraCapturePayload { |
| PooToolsSource/ImagePicker/PTImagePicker.swift:129 | enum | public | public enum PTSystemMediaPicker { |
| PooToolsSource/ImagePicker/PTImagePicker.swift:486 | enum | public | public enum PTImagePicker { |
| PooToolsSource/ImagePicker/PTImagePicker.swift:488 | enum | public | public enum PickerType: Sendable { |
| PooToolsSource/ImagePicker/PTImagePicker.swift:496 | var | public | public var types:[String]{ |
| PooToolsSource/ImagePicker/PTImagePicker.swift:509 | enum | public | public enum PickerError:Error{ |
| PooToolsSource/ImagePicker/PTImagePicker.swift:521 | func | public | public func outPutLog(){ |
| PooToolsSource/ImagePicker/PTImagePicker.swift:538 | typealias | public | public typealias Completion<T: PTImagePickerObject> = @MainActor @Sendable (_ result: Result<T, PTImagePicker.PickerError>) -> Void |
| PooToolsSource/ImagePicker/PTImagePicker.swift:548 | class | public | public class Controller<T:PTImagePickerObject>:UIImagePickerController,UIImagePickerControllerDelegate,UINavigationControllerDelegate { |
| PooToolsSource/ImagePicker/PTImagePicker.swift:556 | func | public | public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) { |
| PooToolsSource/ImagePicker/PTImagePicker.swift:569 | func | public | public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { |
| PooToolsSource/ImagePicker/PTImagePickerObject.swift:12 | protocol | public | public protocol PTImagePickerObject { |
| PooToolsSource/ImagePicker/PTImagePickerObject.swift:68 | struct | public | public struct PTAlbumObject { |
| PooToolsSource/ImagePicker/PTImagePickerObject.swift:70 | let | public | public let imageData:Data? |
| PooToolsSource/ImagePicker/PTImagePickerObject.swift:72 | let | public | public let videoURL:URL? |
| PooToolsSource/ImagePicker/PTImagePickerObject.swift:75 | struct | public | public struct PTPhotoObject { |
| PooToolsSource/ImagePicker/PTImagePickerObject.swift:77 | let | public | public let image:UIImage? |
| PooToolsSource/ImagePicker/PTImagePickerObject.swift:79 | let | public | public let url:URL? |
| PooToolsSource/Input/AkiraTextField.swift:15 | class | open | @IBDesignable open class AkiraTextField: TextFieldEffects { |
| PooToolsSource/Input/HoshiTextField.swift:17 | class | open | @IBDesignable open class HoshiTextField: TextFieldEffects { |
| PooToolsSource/Input/HoshiTextField.swift:206 | class | open | open class PTHoshiTextField: UITextField { |
| PooToolsSource/Input/HoshiTextField.swift:229 | var | open | open var textAndPlceholderSpace: CGFloat = 0 { |
| PooToolsSource/Input/HoshiTextField.swift:234 | var | open | open var leftSpace: CGFloat? { |
| PooToolsSource/Input/HoshiTextField.swift:243 | var | open | open var textEditingEdges: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) |
| PooToolsSource/Input/IsaoTextField.swift:13 | class | open | @IBDesignable open class IsaoTextField: TextFieldEffects { |
| PooToolsSource/Input/JiroTextField.swift:13 | class | open | @IBDesignable open class JiroTextField: TextFieldEffects { |
| PooToolsSource/Input/KaedeTextField.swift:13 | class | open | @IBDesignable open class KaedeTextField: TextFieldEffects { |
| PooToolsSource/Input/MadokaTextField.swift:13 | class | open | @IBDesignable open class MadokaTextField: TextFieldEffects { |
| PooToolsSource/Input/MinoruTextField.swift:13 | class | open | @IBDesignable open class MinoruTextField: TextFieldEffects { |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:15 | class | public | public class PTFloatingPlaseholderConfig: NSObject { |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:16 | var | public | public var containerRadius: CGFloat = 0 |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:17 | var | public | public var borderLayerColor: UIColor = .clear |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:18 | var | public | public var borderLayerFloatingColor: UIColor = .systemBlue |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:19 | var | public | public var borderLayerWidth: CGFloat = 1 |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:20 | var | public | public var floatingPlaceholderColor: UIColor = .systemBlue |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:21 | var | public | public var normalPlaceholderColor: UIColor = .gray |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:22 | var | public | public var floatingPlaceholderFont: UIFont = .systemFont(ofSize: 12) |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:23 | var | public | public var normalPlaceholderFont: UIFont = .systemFont(ofSize: 16) |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:24 | var | public | public var textFont: UIFont = .systemFont(ofSize: 16) |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:25 | var | public | public var tinColor: UIColor = .systemBlue // 建议拼写修改为 tintColor |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:26 | var | public | public var clearMode: UITextField.ViewMode = .whileEditing |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:27 | var | public | public var textColor: UIColor = .black |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:28 | var | public | public var keyboardType: UIKeyboardType = .default |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:29 | var | public | public var isSecureTextEntry: Bool = false |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:30 | var | public | public var isMust: Bool = false |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:32 | var | public | public var insidePadding: CGFloat = 12 |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:33 | var | public | public var placeholderPaddingOffset: CGFloat = 4 |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:34 | var | public | public var placeholderWidthOffset: CGFloat = 8 |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:36 | var | public | public var placeholderFloatingTopOffset: CGFloat = -8 |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:37 | var | public | public var haveAction: Bool = false |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:38 | var | public | public var actionSize: CGSize = .zero |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:39 | var | public | public var actionNormal: Any? |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:40 | var | public | public var actionSelected: Any? |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:41 | var | public | public var actionSapcing: CGFloat = 8 // 建议拼写修改为 actionSpacing |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:42 | var | public | public var textAlignment: NSTextAlignment = .left |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:45 | class | public | public class PTFloatingPlaseholderTextField: UIView { |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:58 | var | public | public var inputedCallback: ((String) -> Void)? |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:59 | var | public | public var inputBegainCallback: PTActionTask? |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:60 | var | public | public var inputingCallback: ((String) -> Void)? |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:61 | var | public | public var actionTouchBlock: TouchedBlock? |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:103 | init | public | public init(config: PTFloatingPlaseholderConfig = PTFloatingPlaseholderConfig()) { |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:193 | func | public | public func configure(placeholder: String, text: String? = nil) { |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:294 | func | public | public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool { |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:304 | func | public | public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool { |
| PooToolsSource/Input/PTFloatingPlaseholderTextField.swift:309 | func | public | public func textFieldDidEndEditing(_ textField: UITextField) { |
| PooToolsSource/Input/PTGrowingText.swift:12 | typealias | public | public typealias GrowingTextDidChangeHeight = (_ view: PTGrowingTextView, _ height: CGFloat) -> Void |
| PooToolsSource/Input/PTGrowingText.swift:13 | typealias | public | public typealias GrowingTextDidChange = (_ view: PTGrowingTextView) -> Void |
| PooToolsSource/Input/PTGrowingText.swift:16 | class | open | open class PTGrowingTextView: UITextView { |
| PooToolsSource/Input/PTGrowingText.swift:19 | var | open | open var growingTextDidChangeHeight: GrowingTextDidChangeHeight? |
| PooToolsSource/Input/PTGrowingText.swift:20 | var | open | open var growingTextDidChange: GrowingTextDidChange? |
| PooToolsSource/Input/PTGrowingText.swift:23 | var | open | @IBInspectable open var maxLength: Int = 100 |
| PooToolsSource/Input/PTGrowingText.swift:24 | var | open | @IBInspectable open var trimWhiteSpaceWhenEndEditing: Bool = true |
| PooToolsSource/Input/PTGrowingText.swift:25 | var | open | @IBInspectable open var minHeight: CGFloat = 44 { didSet { recalcHeightAsync() } } |
| PooToolsSource/Input/PTGrowingText.swift:26 | var | open | @IBInspectable open var maxHeight: CGFloat = 400 { didSet { recalcHeightAsync() } } |
| PooToolsSource/Input/PTGrowingText.swift:29 | var | open | @IBInspectable open var placeholder: String? { didSet { setNeedsDisplay() } } |
| PooToolsSource/Input/PTGrowingText.swift:30 | var | open | @IBInspectable open var placeholderColor: UIColor = UIColor(white: 0.8, alpha: 1.0) { didSet { setNeedsDisplay() } } |
| PooToolsSource/Input/PTGrowingText.swift:31 | var | open | open var attributedPlaceholder: NSAttributedString? { didSet { setNeedsDisplay() } } |
| PooToolsSource/Input/PTInputBoxView.swift:12 | enum | public | public enum PTInputBoxConfigurationType { |
| PooToolsSource/Input/PTInputBoxView.swift:20 | class | open | open class PTInputBoxConfiguration { |
| PooToolsSource/Input/PTInputBoxView.swift:22 | var | open | open var inputBoxNumber: Int = 4 |
| PooToolsSource/Input/PTInputBoxView.swift:24 | var | open | open var inputBoxWidth: CGFloat = 45.0 |
| PooToolsSource/Input/PTInputBoxView.swift:26 | var | open | open var inputBoxHeight: CGFloat = 45.0 |
| PooToolsSource/Input/PTInputBoxView.swift:28 | var | open | open var inputBoxBorderWidth: CGFloat = 1.0 / UIScreen.main.scale |
| PooToolsSource/Input/PTInputBoxView.swift:30 | var | open | open var inputBoxCornerRadius: CGFloat = 6.0 |
| PooToolsSource/Input/PTInputBoxView.swift:32 | var | open | open var inputBoxSpacing: CGFloat = 10.0 |
| PooToolsSource/Input/PTInputBoxView.swift:35 | var | open | open var inputBoxColor: UIColor = .lightGray |
| PooToolsSource/Input/PTInputBoxView.swift:37 | var | open | open var inputBoxHighlightedColor: UIColor = .systemBlue |
| PooToolsSource/Input/PTInputBoxView.swift:39 | var | open | open var inputBoxFinishColor: UIColor? |
| PooToolsSource/Input/PTInputBoxView.swift:42 | var | open | open var tintColor: UIColor = .systemBlue |
| PooToolsSource/Input/PTInputBoxView.swift:44 | var | open | open var secureTextEntry: Bool = false |
| PooToolsSource/Input/PTInputBoxView.swift:46 | var | open | open var font: UIFont = UIFont.boldSystemFont(ofSize: 20.0) |
| PooToolsSource/Input/PTInputBoxView.swift:48 | var | open | open var textColor: UIColor = .black |
| PooToolsSource/Input/PTInputBoxView.swift:50 | var | open | open var inputType: PTInputBoxConfigurationType = .NumberAlphabet |
| PooToolsSource/Input/PTInputBoxView.swift:53 | var | open | open var autoShowKeyboard: Bool = true |
| PooToolsSource/Input/PTInputBoxView.swift:55 | var | open | open var showFlickerAnimation: Bool = true |
| PooToolsSource/Input/PTInputBoxView.swift:58 | var | open | open var showUnderLine: Bool = false |
| PooToolsSource/Input/PTInputBoxView.swift:60 | var | open | open var underLineHeight: CGFloat = 2.0 |
| PooToolsSource/Input/PTInputBoxView.swift:62 | var | open | open var underLineColor: UIColor = .lightGray |
| PooToolsSource/Input/PTInputBoxView.swift:64 | var | open | open var underLineHighlightedColor: UIColor = .systemBlue |
| PooToolsSource/Input/PTInputBoxView.swift:67 | var | open | open var customInputHolder: String = "" |
| PooToolsSource/Input/PTInputBoxView.swift:69 | var | open | open var keyboardType: UIKeyboardType = .numberPad |
| PooToolsSource/Input/PTInputBoxView.swift:71 | var | open | open var enableHapticFeedback: Bool = true |
| PooToolsSource/Input/PTInputBoxView.swift:73 | init | public | public init() {} |
| PooToolsSource/Input/PTInputBoxView.swift:77 | class | public | public class PTInputBoxView: UIView { |
| PooToolsSource/Input/PTInputBoxView.swift:80 | var | public | public var inputBlock: ((_ code: String) -> Void)? |
| PooToolsSource/Input/PTInputBoxView.swift:81 | var | public | public var finishBlock: ((_ codeView: PTInputBoxView, _ code: String) -> Void)? |
| PooToolsSource/Input/PTInputBoxView.swift:114 | init | public | public init(config: PTInputBoxConfiguration) { |
| PooToolsSource/Input/PTInputBoxView.swift:316 | func | public | public func clear() { |
| PooToolsSource/Input/PTInputBoxView.swift:324 | func | public | public func showInput() { |
| PooToolsSource/Input/PTInputBoxView.swift:329 | func | public | public func hideInput() { |
| PooToolsSource/Input/PTInputBoxView.swift:334 | func | public | public func setCode(_ code: String) { |
| PooToolsSource/Input/PTInputBoxView.swift:339 | func | public | public func getCode() -> String? { |
| PooToolsSource/Input/PTTextField.swift:13 | class | public | public class PTTextCustomRightViewConfig: NSObject { |
| PooToolsSource/Input/PTTextField.swift:14 | var | open | open var size: CGSize = .zero |
| PooToolsSource/Input/PTTextField.swift:15 | var | open | open var image: Any? |
| PooToolsSource/Input/PTTextField.swift:16 | var | open | open var rightSpace: CGFloat = 5 |
| PooToolsSource/Input/PTTextField.swift:20 | class | public | public class PTTextField: UITextField { |
| PooToolsSource/Input/PTTextField.swift:24 | var | open | open var leftSpace: CGFloat = 0 { |
| PooToolsSource/Input/PTTextField.swift:31 | var | open | open var rightTapBlock: PTActionTask? |
| PooToolsSource/Input/PTTextField.swift:33 | var | public | public var rightConfig: PTTextCustomRightViewConfig? { |
| PooToolsSource/Input/TextFieldEffects.swift:21 | class | open | open class TextFieldEffects: UITextField { |
| PooToolsSource/Input/TextFieldEffects.swift:24 | enum | public | public enum AnimationType: Int { |
| PooToolsSource/Input/TextFieldEffects.swift:33 | typealias | public | public typealias AnimationCompletionHandler = (_ type: AnimationType) -> Void |
| PooToolsSource/Input/TextFieldEffects.swift:36 | let | public | public let placeholderLabel = UILabel() |
| PooToolsSource/Input/TextFieldEffects.swift:39 | var | open | open var animationCompletionHandler: AnimationCompletionHandler? |
| PooToolsSource/Input/TextFieldEffects.swift:45 | func | open | open func animateViewsForTextEntry() { |
| PooToolsSource/Input/TextFieldEffects.swift:51 | func | open | open func animateViewsForTextDisplay() { |
| PooToolsSource/Input/TextFieldEffects.swift:58 | func | open | open func drawViewsForRect(_ rect: CGRect) { |
| PooToolsSource/Input/TextFieldEffects.swift:65 | func | open | open func updateViewsForBoundsChange(_ bounds: CGRect) { |
| PooToolsSource/Input/TextFieldEffects.swift:107 | func | open | @objc open func textFieldDidBeginEditing() { |
| PooToolsSource/Input/TextFieldEffects.swift:112 | func | open | @objc open func textFieldDidEndEditing() { |
| PooToolsSource/Input/UIView+PTEXShake.swift:12 | enum | public | public enum PTShakeDirection { |
| PooToolsSource/Input/YokoTextField.swift:13 | class | open | @IBDesignable open class YokoTextField: TextFieldEffects { |
| PooToolsSource/Input/YoshikoTextField.swift:13 | class | open | @IBDesignable open class YoshikoTextField: TextFieldEffects { |
| PooToolsSource/Input/YoshikoTextField.swift:28 | var | open | @IBInspectable open var borderSize: CGFloat = 2.0 { |
| PooToolsSource/Inspector/AdaptivePresentationControllerDelegate.swift:12 | typealias | public | public typealias ModalPresentationStyleProvider = (UIPresentationController, UITraitCollection) -> UIModalPresentationStyle |
| PooToolsSource/Inspector/AdaptivePresentationControllerDelegate.swift:14 | typealias | public | public typealias DismissDecisionProvider = (UIPresentationController) -> Bool |
| PooToolsSource/Inspector/AdaptivePresentationControllerDelegate.swift:16 | var | public | public var dismissHandler: ((AdaptivePresentationControllerDelegate) -> Void)? |
| PooToolsSource/Inspector/AdaptivePresentationControllerDelegate.swift:18 | let | public | public let adaptivePresentationStyleProvider: ModalPresentationStyleProvider? |
| PooToolsSource/Inspector/AdaptivePresentationControllerDelegate.swift:20 | let | public | public let shouldDismissProvider: DismissDecisionProvider? |
| PooToolsSource/Inspector/AdaptivePresentationControllerDelegate.swift:22 | let | public | public let dismissAttemptHandler: PTActionTask? |
| PooToolsSource/Inspector/AdaptivePresentationControllerDelegate.swift:24 | init | public | public init(onDismiss dismissHandler: ((AdaptivePresentationControllerDelegate) -> Void)? = .none, |
| PooToolsSource/Inspector/AdaptivePresentationControllerDelegate.swift:34 | func | public | public func presentationControllerDidDismiss(_: UIPresentationController) { |
| PooToolsSource/Inspector/AdaptivePresentationControllerDelegate.swift:38 | func | public | public func adaptivePresentationStyle(for controller: UIPresentationController, |
| PooToolsSource/Inspector/AdaptivePresentationControllerDelegate.swift:43 | func | public | public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool { |
| PooToolsSource/Inspector/AdaptivePresentationControllerDelegate.swift:47 | func | public | public func presentationControllerDidAttemptToDismiss(_: UIPresentationController) { |
| PooToolsSource/Inspector/BaseControl.swift:21 | var | open | open var animateOnTouch: Bool = false |
| PooToolsSource/Inspector/BaseControl.swift:69 | func | open | open func setup() {} |
| PooToolsSource/Inspector/BaseControl.swift:124 | func | open | open func stateDidChange(from oldState: State, to newState: State) {} |
| PooToolsSource/Inspector/CGRect+InspectorEX.swift:12 | func | public | public func hash(into hasher: inout Hasher) { |
| PooToolsSource/Inspector/Command.swift:13 | typealias | public | public typealias Closure = @MainActor @Sendable () -> Void |
| PooToolsSource/Inspector/Command.swift:15 | var | public | public var title: String |
| PooToolsSource/Inspector/Command.swift:17 | var | public | public var icon: UIImage? |
| PooToolsSource/Inspector/Command.swift:19 | var | public | public var keyInput: String? |
| PooToolsSource/Inspector/Command.swift:21 | var | public | public var modifierFlags: UIKeyModifierFlags |
| PooToolsSource/Inspector/Command.swift:23 | let | public | public let isSelected: Bool |
| PooToolsSource/Inspector/Command.swift:32 | init | public | public init( |
| PooToolsSource/Inspector/CommandsGroup.swift:15 | var | public | public var title: String? |
| PooToolsSource/Inspector/CommandsGroup.swift:16 | var | public | public var commands: [Command] |
| PooToolsSource/Inspector/Coordinator.swift:15 | class | open | open class Coordinator<Dependencies, Presenter, Content>: @preconcurrency CoordinatorProtocol, @preconcurrency Dismissable, @preconcurrency Startable { |
| PooToolsSource/Inspector/Coordinator.swift:16 | typealias | public | public typealias _Self = Coordinator<Dependencies, Presenter, Content> |
| PooToolsSource/Inspector/Coordinator.swift:19 | let | public | public let dependencies: Dependencies |
| PooToolsSource/Inspector/Coordinator.swift:22 | let | public | public let presenter: Presenter |
| PooToolsSource/Inspector/Coordinator.swift:37 | var | open | open var dismissHandler: ((_Self) -> Void)? |
| PooToolsSource/Inspector/Coordinator.swift:40 | var | open | open var content: Content! |
| PooToolsSource/Inspector/Coordinator.swift:44 | init | public | public init( |
| PooToolsSource/Inspector/Coordinator.swift:72 | func | open | @MainActor open func loadContent() -> Content? { .none } |
| PooToolsSource/Inspector/Coordinator.swift:75 | func | open | @MainActor open func start() -> Content { |
| PooToolsSource/Inspector/Coordinator.swift:93 | func | open | open func removeFromParent() { |
| PooToolsSource/Inspector/Coordinator.swift:106 | func | open | open func addChild(_ coordinator: CoordinatorProtocol) { |
| PooToolsSource/Inspector/Coordinator.swift:123 | func | open | open func removeChild(_ coordinator: CoordinatorProtocol) { |
| PooToolsSource/Inspector/Coordinator.swift:139 | func | open | open func removeAllChildren() { |
| PooToolsSource/Inspector/Coordinator.swift:216 | func | public | public func hash(into hasher: inout Hasher) { |
| PooToolsSource/Inspector/CoordinatorProtocol.swift:12 | typealias | public | public typealias CoordinatorStartable = CoordinatorProtocol & Startable |
| PooToolsSource/Inspector/CoordinatorProtocol.swift:14 | protocol | public | public protocol CoordinatorProtocol: AnyObject { |
| PooToolsSource/Inspector/Dismissable.swift:11 | protocol | public | public protocol Dismissable: AnyObject { |
| PooToolsSource/Inspector/DismissableNavigationController.swift:11 | class | open | open class DismissableNavigationController: UINavigationController, @MainActor Dismissable { |
| PooToolsSource/Inspector/DismissableNavigationController.swift:12 | var | public | public var dismissHandler: ((DismissableNavigationController) -> Void)? |
| PooToolsSource/Inspector/DismissableViewController.swift:11 | class | open | open class DismissableViewController: UIViewController, @MainActor Dismissable { |
| PooToolsSource/Inspector/DismissableViewController.swift:12 | var | open | open var dismissHandler: ((DismissableViewController) -> Void)? |
| PooToolsSource/Inspector/ElementInspectorPanelViewController.swift:12 | var | open | open var panelScrollView: UIScrollView? { nil } |
| PooToolsSource/Inspector/HashableValue.swift:10 | struct | public | public struct HashableValue<Value>: Hashable { |
| PooToolsSource/Inspector/HashableValue.swift:12 | var | public | public var wrappedValue: Value |
| PooToolsSource/Inspector/HashableValue.swift:14 | init | public | public init(wrappedValue: Value) { |
| PooToolsSource/Inspector/HashableValue.swift:22 | func | public | public func hash(into hasher: inout Hasher) { |
| PooToolsSource/Inspector/Inspector.swift:9 | typealias | public | public typealias Closure = @MainActor @Sendable () -> Void |
| PooToolsSource/Inspector/Inspector.swift:16 | var | public | public var configuration: InspectorConfiguration = .default { |
| PooToolsSource/Inspector/Inspector.swift:22 | var | public | public var customization: InspectorCustomizationProviding? { |
| PooToolsSource/Inspector/InspectorColorStyle.swift:93 | var | public | public var emptyLayerColor: UIColor { wireframeLayerColor } |
| PooToolsSource/Inspector/InspectorColorStyle.swift:95 | var | public | public var wireframeLayerColor: UIColor { tertiaryTextColor } |
| PooToolsSource/Inspector/InspectorConfiguration+KeyCommandSettings.swift:11 | var | public | public var layerToggleInputRange: ClosedRange<Int> = (1...9) |
| PooToolsSource/Inspector/InspectorConfiguration+KeyCommandSettings.swift:13 | var | public | public var layerToggleModifierFlags: UIKeyModifierFlags = [.control] |
| PooToolsSource/Inspector/InspectorConfiguration+KeyCommandSettings.swift:15 | var | public | public var allLayersToggleInput = String(0) |
| PooToolsSource/Inspector/InspectorConfiguration+KeyCommandSettings.swift:17 | var | public | public var presentationOptions = KeyCommandOptions( |
| PooToolsSource/Inspector/InspectorConfiguration+KeyCommandSettings.swift:22 | var | public | public var presentationSettings = KeyCommandOptions( |
| PooToolsSource/Inspector/InspectorConfiguration+KeyCommandSettings.swift:27 | struct | public | public struct KeyCommandOptions: Hashable { |
| PooToolsSource/Inspector/InspectorConfiguration+KeyCommandSettings.swift:28 | var | public | public var input: String |
| PooToolsSource/Inspector/InspectorConfiguration+KeyCommandSettings.swift:29 | var | public | public var modifierFlags: UIKeyModifierFlags |
| PooToolsSource/Inspector/InspectorConfiguration+KeyCommandSettings.swift:31 | init | public | public init( |
| PooToolsSource/Inspector/InspectorConfiguration+KeyCommandSettings.swift:43 | func | public | public func hash(into hasher: inout Hasher) { |
| PooToolsSource/Inspector/InspectorConfiguration.swift:10 | struct | public | public struct InspectorConfiguration { |
| PooToolsSource/Inspector/InspectorConfiguration.swift:13 | var | public | public var keyCommands: KeyCommandSettings = .init() |
| PooToolsSource/Inspector/InspectorConfiguration.swift:15 | var | public | public var snapshotExpirationTimeInterval: TimeInterval |
| PooToolsSource/Inspector/InspectorConfiguration.swift:17 | var | public | public var snapshotMaxCount: Int = 1 |
| PooToolsSource/Inspector/InspectorConfiguration.swift:19 | var | public | public var showAllViewSearchQuery: String |
| PooToolsSource/Inspector/InspectorConfiguration.swift:21 | var | public | public var nonInspectableClassNames: [String] |
| PooToolsSource/Inspector/InspectorConfiguration.swift:23 | let | public | public let enableLayoutSubviewsSwizzling: Bool |
| PooToolsSource/Inspector/InspectorConfiguration.swift:25 | var | public | public var showFullApplicationHierarchy: Bool |
| PooToolsSource/Inspector/InspectorConfiguration.swift:27 | var | public | public var verbose: Bool |
| PooToolsSource/Inspector/InspectorCustomizationProviding.swift:9 | protocol | public | public protocol InspectorCustomizationProviding { |
| PooToolsSource/Inspector/InspectorElementItemSeparatorStyle.swift:10 | enum | public | public enum InspectorElementItemSeparatorStyle: Hashable { |
| PooToolsSource/Inspector/InspectorElementLibraryProtocol.swift:10 | protocol | public | public protocol InspectorElementLibraryProtocol { |
| PooToolsSource/Inspector/InspectorElementProperty+InspectorEX.swift:82 | func | public | public func hash(into hasher: inout Hasher) { |
| PooToolsSource/Inspector/InspectorElementProperty.swift:10 | typealias | public | public typealias InspectorElementViewModelProperty = InspectorElementProperty |
| PooToolsSource/Inspector/InspectorElementProperty.swift:12 | enum | public | public enum InspectorElementProperty { |
| PooToolsSource/Inspector/InspectorElementProperty.swift:13 | struct | public | public struct PreviewTarget { |
| PooToolsSource/Inspector/InspectorElementProperty.swift:16 | init | public | @MainActor public init(view: UIView) { |
| PooToolsSource/Inspector/InspectorElementSection.swift:10 | typealias | public | public typealias InspectorElementSections = [InspectorElementSection] |
| PooToolsSource/Inspector/InspectorElementSection.swift:13 | struct | public | public struct InspectorElementSection { |
| PooToolsSource/Inspector/InspectorElementSection.swift:14 | var | public | public var title: String? |
| PooToolsSource/Inspector/InspectorElementSection.swift:17 | init | public | public init(title: String? = nil, rows: [InspectorElementSectionDataSource] = []) { |
| PooToolsSource/Inspector/InspectorElementSection.swift:22 | init | public | public init(title: String? = nil, rows: InspectorElementSectionDataSource...) { |
| PooToolsSource/Inspector/InspectorElementSection.swift:27 | init | public | public init(title: String? = nil, rows: [InspectorElementSectionDataSource?]) { |
| PooToolsSource/Inspector/InspectorElementSection.swift:32 | init | public | public init(title: String? = nil, rows: InspectorElementSectionDataSource?...) { |
| PooToolsSource/Inspector/InspectorElementSectionDataSource.swift:10 | typealias | public | public typealias InspectorElementViewModelProtocol = InspectorElementSectionDataSource |
| PooToolsSource/Inspector/InspectorElementSectionDataSource.swift:13 | protocol | public | public protocol InspectorElementSectionDataSource: AnyObject { |
| PooToolsSource/Inspector/InspectorElementSectionState.swift:10 | enum | public | public enum InspectorElementSectionState: Hashable { |
| PooToolsSource/Inspector/InspectorElementSectionView.swift:9 | protocol | public | public protocol InspectorElementFormItemViewDelegate: AnyObject { |
| PooToolsSource/Inspector/InspectorElementSectionView.swift:15 | protocol | public | public protocol InspectorElementSectionView: UIView { |
| PooToolsSource/Inspector/InspectorProvider.swift:19 | init | public | public init(closure: @escaping (From) -> To) { |
| PooToolsSource/Inspector/InspectorProvider.swift:27 | func | public | public func hash(into hasher: inout Hasher) { |
| PooToolsSource/Inspector/KeyCommandsSectionDataSource.swift:108 | typealias | public | public typealias AllCases = [UIKeyModifierFlags] |
| PooToolsSource/Inspector/KeyboardAnimatable.swift:32 | typealias | public | public typealias KeyboardAnimationInfo = (duration: TimeInterval, keyboardFrame: CGRect, curve: UIView.AnimationCurve) |
| PooToolsSource/Inspector/KeyboardAnimatable.swift:35 | typealias | public | public typealias KeyboardAnimations = @MainActor @Sendable (KeyboardAnimationInfo) -> Void |
| PooToolsSource/Inspector/KeyboardAnimatable.swift:36 | typealias | public | public typealias KeyboardCompletion = @MainActor @Sendable (UIViewAnimatingPosition) -> Void |
| PooToolsSource/Inspector/KeyboardAnimatable.swift:40 | protocol | public | @objc public protocol KeyboardAnimatable: AnyObject { |
| PooToolsSource/Inspector/KeyboardAnimation.swift:13 | struct | public | public struct KeyboardAnimation { |
| PooToolsSource/Inspector/KeyboardAnimation.swift:20 | init | public | public init(animation: @escaping KeyboardAnimations, completion: KeyboardCompletion? = nil) { |
| PooToolsSource/Inspector/KeyboardNotificationName.swift:12 | enum | public | public enum KeyboardNotificationName { |
| PooToolsSource/Inspector/KeyboardNotificationName.swift:34 | typealias | public | public typealias RawValue = Notification.Name |
| PooToolsSource/Inspector/KeyboardNotificationName.swift:36 | init | public | public init?(rawValue: Notification.Name) { |
| PooToolsSource/Inspector/KeyboardNotificationName.swift:61 | var | public | public var rawValue: Notification.Name { |
| PooToolsSource/Inspector/LayerView.swift:47 | var | open | open var sourceView: UIView { self } |
| PooToolsSource/Inspector/MKMapView+InspectorEX.swift:12 | typealias | public | public typealias AllCases = [MKMapType] |
| PooToolsSource/Inspector/MKMapView+InspectorEX.swift:25 | var | public | public var description: String { |
| PooToolsSource/Inspector/MapViewAttributesSectionDataSource.swift:152 | var | public | public var displayName: String { |
| PooToolsSource/Inspector/NSAttributeString+InspectorEX.swift:11 | typealias | public | public typealias AttributedString_Inspector = NSAttributedString |
| PooToolsSource/Inspector/NSAttributeString+InspectorEX.swift:48 | enum | public | public enum LigatureStyle: Int, RawRepresentable { |
| PooToolsSource/Inspector/NSAttributeString+InspectorEX.swift:104 | enum | public | public enum GlyphForm: Int, RawRepresentable { |
| PooToolsSource/Inspector/NSAttributeString+InspectorEX.swift:122 | typealias | public | public typealias AttributesDictionary = [NSAttributedString.Key : Any] |
| PooToolsSource/Inspector/NSLayoutConstraint+InspectorEX.swift:102 | typealias | public | public typealias AllCases = [NSLayoutConstraint.Axis] |
| PooToolsSource/Inspector/NSLayoutConstraint+InspectorEX.swift:111 | var | public | public var description: String { |
| PooToolsSource/Inspector/NSLayoutConstraint+InspectorEX.swift:126 | typealias | public | public typealias AllCases = [NSLayoutConstraint.Relation] |
| PooToolsSource/Inspector/NSTextAlignment+InspectorEX.swift:12 | typealias | public | public typealias AllCases = [NSTextAlignment] |
| PooToolsSource/Inspector/NavigationItemAttributesSectionDataSource.swift:88 | typealias | public | public typealias AllCases = [UINavigationItem.LargeTitleDisplayMode] |
| PooToolsSource/Inspector/NonInspectableView.swift:10 | protocol | public | public protocol NonInspectableView {} |
| PooToolsSource/Inspector/NoteControl.swift:9 | enum | public | public enum InspectorElemenPropertyNoteIcon: ColorStylable { |
| PooToolsSource/Inspector/RootViewControllerProtocol.swift:15 | protocol | public | public protocol RootViewControllerProtocol: UIViewController {} |
| PooToolsSource/Inspector/Startable.swift:13 | typealias | public | public typealias StartProtocol = Startable |
| PooToolsSource/Inspector/Startable.swift:15 | protocol | public | public protocol Startable { |
| PooToolsSource/Inspector/TableViewAttributesSectionDataSource.swift:144 | typealias | public | public typealias AllCases = [UITableViewCell.SeparatorStyle] |
| PooToolsSource/Inspector/TableViewAttributesSectionDataSource.swift:167 | typealias | public | public typealias AllCases = [UITableView.Style] |
| PooToolsSource/Inspector/UIActivityIndicatorView+InspectorEX.swift:12 | typealias | public | public typealias AllCases = [UIActivityIndicatorView.Style] |
| PooToolsSource/Inspector/UIActivityIndicatorView+InspectorEX.swift:21 | var | public | public var description: String { |
| PooToolsSource/Inspector/UIBarStyle+InspectorEX.swift:12 | typealias | public | public typealias AllCases = [UIBarStyle] |
| PooToolsSource/Inspector/UIBarStyle+InspectorEX.swift:21 | var | public | public var description: String { |
| PooToolsSource/Inspector/UIBlurEffect+InspectorEX.swift:12 | var | public | public var description: String { |
| PooToolsSource/Inspector/UIBlurEffect+InspectorEX.swift:61 | typealias | public | public typealias AllCases = [UIBlurEffect.Style] |
| PooToolsSource/Inspector/UIButton+InspectorEX.swift:12 | var | public | public var description: String { |
| PooToolsSource/Inspector/UIButton+InspectorEX.swift:27 | typealias | public | public typealias AllCases = [UIButton.ButtonType] |
| PooToolsSource/Inspector/UIControl+InspectorEX.swift:12 | typealias | public | public typealias AllCases = [UIControl.ContentHorizontalAlignment] |
| PooToolsSource/Inspector/UIControl+InspectorEX.swift:52 | typealias | public | public typealias AllCases = [UIControl.ContentVerticalAlignment] |
| PooToolsSource/Inspector/UIDataDetectorTypes+InspectorEX.swift:12 | var | public | public var description: String { |
| PooToolsSource/Inspector/UIDatePicker+InspectorEX.swift:12 | typealias | public | public typealias AllCases = [UIDatePicker.Mode] |
| PooToolsSource/Inspector/UIDatePicker+InspectorEX.swift:23 | var | public | public var description: String { |
| PooToolsSource/Inspector/UIDatePickerStyle+InspectorEX.swift:12 | typealias | public | public typealias AllCases = [UIDatePickerStyle] |
| PooToolsSource/Inspector/UIDatePickerStyle+InspectorEX.swift:25 | var | public | public var description: String { |
| PooToolsSource/Inspector/UIKeyCommand+InspectorEX.swift:129 | enum | public | public enum MenuElementAttributes { |
| PooToolsSource/Inspector/UIKeyCommand+InspectorEX.swift:134 | enum | public | public enum MenuElementState { |
| PooToolsSource/Inspector/UIKeyCommandTableView.swift:11 | protocol | public | public protocol UITableViewKeyCommandsDelegate: AnyObject { |
| PooToolsSource/Inspector/UIKeyCommandTableView.swift:19 | class | public | public class UIKeyCommandTableView: UITableView { |
| PooToolsSource/Inspector/UIKeyCommandTableView.swift:21 | enum | public | public enum OutOfBoundsBehavior { |
| PooToolsSource/Inspector/UIKeyCommandTableView.swift:65 | var | public | public var selectPreviousKeyCommandOptions: [UIKeyCommand.Options] = [.arrowUp] |
| PooToolsSource/Inspector/UIKeyCommandTableView.swift:67 | var | public | public var selectNextKeyCommandOptions: [UIKeyCommand.Options] = [.arrowDown] |
| PooToolsSource/Inspector/UIKeyCommandTableView.swift:69 | var | public | public var activateSelectionKeyCommandOptions: [UIKeyCommand.Options] = [.spaceBar, .return] |
| PooToolsSource/Inspector/UIKeyCommandTableView.swift:71 | var | public | public var activateAccessoryButtonKeyCommandOptions: [UIKeyCommand.Options] = [] |
| PooToolsSource/Inspector/UIKeyCommandTableView.swift:73 | var | public | public var clearSelectionKeyCommandOptions: [UIKeyCommand.Options] = [] |
| PooToolsSource/Inspector/UIKeyCommandTableView.swift:101 | var | public | public var totalNumberOfRows: Int { |
| PooToolsSource/Inspector/UIKeyCommandTableView.swift:105 | var | public | public var indexPathForLastRowInLastSection: IndexPath { |
| PooToolsSource/Inspector/UIKeyCommandTableView.swift:114 | func | public | public func selectRowIfPossible(at indexPath: IndexPath?) { |
| PooToolsSource/Inspector/UIKeyCommandTableView.swift:133 | func | public | public func selectPreviousRow() { |
| PooToolsSource/Inspector/UIKeyCommandTableView.swift:138 | func | public | public func selectNextRow() { |
| PooToolsSource/Inspector/UIKeyboardAppearance+InspectorEX.swift:12 | typealias | public | public typealias AllCases = [UIKeyboardAppearance] |
| PooToolsSource/Inspector/UIKeyboardAppearance+InspectorEX.swift:22 | var | public | public var description: String { |
| PooToolsSource/Inspector/UIKeyboardType+InspectorEX.swift:12 | typealias | public | public typealias AllCases = [UIKeyboardType] |
| PooToolsSource/Inspector/UIKeyboardType+InspectorEX.swift:31 | var | public | public var description: String { |
| PooToolsSource/Inspector/UILayoutPriority+InspectorEX.swift:12 | typealias | public | public typealias AllCases = [UILayoutPriority] |
| PooToolsSource/Inspector/UILayoutPriority+InspectorEX.swift:23 | var | public | public var name: String { |
| PooToolsSource/Inspector/UIModalPresentationStyle+InspectorEX.swift:12 | typealias | public | public typealias AllCases = [UIModalPresentationStyle] |
| PooToolsSource/Inspector/UIModalPresentationStyle+InspectorEX.swift:29 | var | public | public var description: String { |
| PooToolsSource/Inspector/UIModalTransitionStyle+InspectorEX.swift:12 | typealias | public | public typealias AllCases = [UIModalTransitionStyle] |
| PooToolsSource/Inspector/UIModalTransitionStyle+InspectorEX.swift:23 | var | public | public var description: String { |
| PooToolsSource/Inspector/UIReturnKeyType+InspectorEX.swift:12 | typealias | public | public typealias AllCases = [UIReturnKeyType] |
| PooToolsSource/Inspector/UIReturnKeyType+InspectorEX.swift:31 | var | public | public var description: String { |
| PooToolsSource/Inspector/UIScrollView+InspectorEX.swift:210 | typealias | public | public typealias AllCases = [UIScrollView.ContentInsetAdjustmentBehavior] |
| PooToolsSource/Inspector/UIScrollView+InspectorEX.swift:221 | var | public | public var description: String { |
| PooToolsSource/Inspector/UIScrollView+InspectorEX.swift:238 | typealias | public | public typealias AllCases = [UIScrollView.IndicatorStyle] |
| PooToolsSource/Inspector/UIScrollView+InspectorEX.swift:248 | var | public | public var description: String { |
| PooToolsSource/Inspector/UIScrollView+InspectorEX.swift:266 | typealias | public | public typealias AllCases = [UIScrollView.KeyboardDismissMode] |
| PooToolsSource/Inspector/UIScrollView+InspectorEX.swift:276 | var | public | public var description: String { |
| PooToolsSource/Inspector/UISemanticContentAttribute+InspectorEX.swift:12 | typealias | public | public typealias AllCases = [UISemanticContentAttribute] |
| PooToolsSource/Inspector/UISemanticContentAttribute+InspectorEX.swift:24 | var | public | public var description: String { |
| PooToolsSource/Inspector/UIStackView+InspectorEX.swift:16 | init | public | public init?(rawValue: UIStackView.Alignment) { |
| PooToolsSource/Inspector/UIStackView+InspectorEX.swift:51 | var | public | public var rawValue: UIStackView.Alignment { |
| PooToolsSource/Inspector/UIStackView+InspectorEX.swift:80 | init | public | public init?(rawValue: UIStackView.Alignment) { |
| PooToolsSource/Inspector/UIStackView+InspectorEX.swift:111 | var | public | public var rawValue: UIStackView.Alignment { |
| PooToolsSource/Inspector/UIStackView+InspectorEX.swift:289 | typealias | public | public typealias AllCases = [UIStackView.Alignment] |
| PooToolsSource/Inspector/UIStackView+InspectorEX.swift:302 | var | public | public var description: String { |
| PooToolsSource/Inspector/UIStackView+InspectorEX.swift:329 | typealias | public | public typealias AllCases = [UIStackView.Distribution] |
| PooToolsSource/Inspector/UIStackView+InspectorEX.swift:341 | var | public | public var description: String { |
| PooToolsSource/Inspector/UIStepper+InspectorEX.swift:41 | var | public | public var isContinuous: Bool |
| PooToolsSource/Inspector/UIStepper+InspectorEX.swift:50 | var | public | public var autorepeat: Bool |
| PooToolsSource/Inspector/UIStepper+InspectorEX.swift:59 | var | public | public var wraps: Bool |
| PooToolsSource/Inspector/UIStepper+InspectorEX.swift:68 | var | public | public var value: Double |
| PooToolsSource/Inspector/UIStepper+InspectorEX.swift:75 | var | public | public var minimumValue: Double |
| PooToolsSource/Inspector/UIStepper+InspectorEX.swift:81 | var | public | public var maximumValue: Double |
| PooToolsSource/Inspector/UIStepper+InspectorEX.swift:90 | var | public | public var stepValue: Double |
| PooToolsSource/Inspector/UIStepper+InspectorEX.swift:101 | init | public | public init( |
| PooToolsSource/Inspector/UIStepper+InspectorEX.swift:128 | init | public | public init( |
| PooToolsSource/Inspector/UISwitch+InspectorEX.swift:12 | typealias | public | public typealias AllCases = [UISwitch.Style] |
| PooToolsSource/Inspector/UISwitch+InspectorEX.swift:22 | var | public | public var description: String { |
| PooToolsSource/Inspector/UITextAutocapitalizationType+InspectorEX.swift:12 | typealias | public | public typealias AllCases = [UITextAutocapitalizationType] |
| PooToolsSource/Inspector/UITextAutocapitalizationType+InspectorEX.swift:23 | var | public | public var description: String { |
| PooToolsSource/Inspector/UITextAutocorrectionType+InspectorEX.swift:12 | typealias | public | public typealias AllCases = [UITextAutocorrectionType] |
| PooToolsSource/Inspector/UITextAutocorrectionType+InspectorEX.swift:22 | var | public | public var description: String { |
| PooToolsSource/Inspector/UITextContentType+InspectorEX.swift:12 | typealias | public | public typealias AllCases = [UITextContentType] |
| PooToolsSource/Inspector/UITextField+InspectorEX.swift:229 | typealias | public | public typealias AllCases = [UITextField.BorderStyle] |
| PooToolsSource/Inspector/UITextField+InspectorEX.swift:261 | typealias | public | public typealias AllCases = [UITextField.ViewMode] |
| PooToolsSource/Inspector/UITextSmartDashesType+InspectorEX.swift:12 | typealias | public | public typealias AllCases = [UITextSmartDashesType] |
| PooToolsSource/Inspector/UITextSmartDashesType+InspectorEX.swift:22 | var | public | public var description: String { |
| PooToolsSource/Inspector/UITextSmartQuotesType+InspectorEX.swift:12 | typealias | public | public typealias AllCases = [UITextSmartQuotesType] |
| PooToolsSource/Inspector/UITextSmartQuotesType+InspectorEX.swift:22 | var | public | public var description: String { |
| PooToolsSource/Inspector/UITextSpellCheckingType+InspectorEX.swift:12 | typealias | public | public typealias AllCases = [UITextSpellCheckingType] |
| PooToolsSource/Inspector/UIView+InspectorEX.swift:312 | typealias | public | public typealias AllCases = [UIView.AutoresizingMask] |
| PooToolsSource/Inspector/UIView+InspectorEX.swift:358 | typealias | public | public typealias AllCases = [UIView.ContentMode] |
| PooToolsSource/Inspector/UIViewController+InspectorEX.swift:132 | enum | public | public enum UserInterfaceStyle { |
| PooToolsSource/Inspector/UTTTypeOption.swift:13 | typealias | public | public typealias UTTTypeOptions = [UTTTypeOption] |
| PooToolsSource/Inspector/UTTTypeOption.swift:15 | enum | public | public enum UTTTypeOption: Equatable, Hashable { |
| PooToolsSource/Inspector/ViewHierarchyElementController.swift:11 | func | public | public func hash(into hasher: inout Hasher) { |
| PooToolsSource/Inspector/ViewHierarchyElementController.swift:17 | func | public | public func hash(into hasher: inout Hasher) { |
| PooToolsSource/Inspector/ViewHierarchyElementController.swift:23 | func | public | public func hash(into hasher: inout Hasher) { |
| PooToolsSource/Inspector/ViewHierarchyElementController.swift:29 | func | public | public func hash(into hasher: inout Hasher) { |
| PooToolsSource/Inspector/ViewHierarchyLayer.swift:15 | typealias | public | public typealias Filter = (UIView) -> Bool |
| PooToolsSource/Inspector/ViewHierarchyLayer.swift:19 | var | public | public var name: String |
| PooToolsSource/Inspector/ViewHierarchyLayer.swift:27 | var | public | @HashableValue public var filter: Filter |
| PooToolsSource/Inspector/ViewHierarchyRepresentable.swift:9 | protocol | public | public protocol ViewHierarchyRepresentable { |
| PooToolsSource/Inspector/WeekObject.swift:15 | init | public | public init(_ object: Object) { |
| PooToolsSource/Inspector/WeekObject.swift:29 | func | public | public func hash(into hasher: inout Hasher) { |
| PooToolsSource/KeyChain/PTKeyChain.swift:13 | let | public | public let kAccount = "kAccount" |
| PooToolsSource/KeyChain/PTKeyChain.swift:14 | let | public | public let kPassword = "kPassword" |
| PooToolsSource/KeyChain/PTKeyChain.swift:16 | enum | public | @objc public enum PTBiologyVerifyStatus: Int,Sendable { |
| PooToolsSource/KeyChain/PTKeyChain.swift:23 | typealias | public | public typealias PTKeyChainBlock = (_ success: Bool) -> Void |
| PooToolsSource/KeyChain/PTKeyChain.swift:24 | typealias | public | public typealias PTKeyChainStatusBlock = (_ success: Bool, _ status: PTBiologyVerifyStatus) -> Void |
| PooToolsSource/KeyChain/PTKeyChain.swift:27 | class | public | public class PTKeyChain: NSObject { |
| PooToolsSource/Keyboard/PTNumberKeyBoard.swift:12 | enum | public | @objc public enum PTKeyboardType: Int { |
| PooToolsSource/Keyboard/PTNumberKeyBoard.swift:16 | typealias | public | public typealias PTNumberKeyBoardBackSpace = (_ keyboard: PTNumberKeyBoard) -> Void |
| PooToolsSource/Keyboard/PTNumberKeyBoard.swift:17 | typealias | public | public typealias PTNumberKeyBoardReturnSTH = (_ keyboard: PTNumberKeyBoard, _ result: String) -> Void |
| PooToolsSource/Keyboard/PTNumberKeyBoard.swift:28 | class | public | public class PTNumberKeyBoard: UIView { |
| PooToolsSource/KingfisherSVG/Kingfisher+SVG.swift:14 | struct | public | public struct SVGProcessor: @preconcurrency ImageProcessor { |
| PooToolsSource/KingfisherSVG/Kingfisher+SVG.swift:18 | let | public | public let identifier = "svgprocessor" |
| PooToolsSource/KingfisherSVG/Kingfisher+SVG.swift:20 | init | public | public init(size: CGSize) { |
| PooToolsSource/KingfisherSVG/Kingfisher+SVG.swift:25 | func | public | @MainActor public func process(item: ImageProcessItem, |
| PooToolsSource/Label/PTActiveBuilder.swift:12 | typealias | public | public typealias PTConfigureLinkAttribute = @MainActor (PTActiveType, [NSAttributedString.Key : Any], Bool) -> [NSAttributedString.Key : Any] |
| PooToolsSource/Label/PTActiveBuilder.swift:14 | typealias | public | public typealias PTActiveDidSelectedHandle = @MainActor (String, PTActiveType) -> () |
| PooToolsSource/Label/PTActiveBuilder.swift:15 | typealias | public | public typealias PTActiveStringHandle = @MainActor (String) -> () |
| PooToolsSource/Label/PTActiveBuilder.swift:16 | typealias | public | public typealias PTActiveURLHandle = @MainActor (URL) -> () |
| PooToolsSource/Label/PTActiveBuilder.swift:17 | typealias | public | public typealias PTActiveStringBoolCallBack = @MainActor (String) -> Bool |
| PooToolsSource/Label/PTActiveLabel.swift:11 | class | public | public class PTActiveLabel: UILabel { |
| PooToolsSource/Label/PTActiveLabel.swift:13 | var | open | open var didSelectedHandle: PTActiveDidSelectedHandle? |
| PooToolsSource/Label/PTActiveLabel.swift:14 | var | open | open var enabledTypes: [PTActiveType] = [.mention, .hashtag, .url, .chinaCellPhone, .snsId] |
| PooToolsSource/Label/PTActiveLabel.swift:15 | var | open | open var urlMaximumLength: Int? |
| PooToolsSource/Label/PTActiveLabel.swift:16 | var | open | open var configureLinkAttribute: PTConfigureLinkAttribute? |
| PooToolsSource/Label/PTActiveLabel.swift:18 | var | open | open var mentionColor: UIColor = .blue { didSet { updateTextStorage(parseText: false) } } |
| PooToolsSource/Label/PTActiveLabel.swift:19 | var | open | open var mentionSelectedColor: UIColor? { didSet { updateTextStorage(parseText: false) } } |
| PooToolsSource/Label/PTActiveLabel.swift:20 | var | open | open var hashtagColor: UIColor = .blue { didSet { updateTextStorage(parseText: false) } } |
| PooToolsSource/Label/PTActiveLabel.swift:21 | var | open | open var hashtagSelectedColor: UIColor? { didSet { updateTextStorage(parseText: false) } } |
| PooToolsSource/Label/PTActiveLabel.swift:22 | var | open | open var URLColor: UIColor = .blue { didSet { updateTextStorage(parseText: false) } } |
| PooToolsSource/Label/PTActiveLabel.swift:23 | var | open | open var URLSelectedColor: UIColor? { didSet { updateTextStorage(parseText: false) } } |
| PooToolsSource/Label/PTActiveLabel.swift:24 | var | open | open var chinaCellPhoneColor: UIColor = .blue { didSet { updateTextStorage(parseText: false) } } |
| PooToolsSource/Label/PTActiveLabel.swift:25 | var | open | open var chinaCellPhoneSelectedColor: UIColor? { didSet { updateTextStorage(parseText: false) } } |
| PooToolsSource/Label/PTActiveLabel.swift:26 | var | open | open var snsIdColor: UIColor = .blue { didSet { updateTextStorage(parseText: false) } } |
| PooToolsSource/Label/PTActiveLabel.swift:27 | var | open | open var snsIdSelectedColor: UIColor? { didSet { updateTextStorage(parseText: false) } } |
| PooToolsSource/Label/PTActiveLabel.swift:28 | var | open | open var customColor: [PTActiveType : UIColor] = [:] { didSet { updateTextStorage(parseText: false) } } |
| PooToolsSource/Label/PTActiveLabel.swift:29 | var | open | open var customSelectedColor: [PTActiveType : UIColor] = [:] { didSet { updateTextStorage(parseText: false) } } |
| PooToolsSource/Label/PTActiveLabel.swift:31 | var | public | public var lineSpacing: CGFloat = 0 { didSet { updateTextStorage(parseText: false) } } |
| PooToolsSource/Label/PTActiveLabel.swift:32 | var | public | public var minimumLineHeight: CGFloat = 0 { didSet { updateTextStorage(parseText: false) } } |
| PooToolsSource/Label/PTActiveLabel.swift:33 | var | public | public var highlightFontName: String? = nil { didSet { updateTextStorage(parseText: false) } } |
| PooToolsSource/Label/PTActiveLabel.swift:34 | var | public | public var highlightFontSize: CGFloat? = nil { didSet { updateTextStorage(parseText: false) } } |
| PooToolsSource/Label/PTActiveLabel.swift:55 | func | open | open func handleMentionTap(_ handler: @escaping PTActiveStringHandle) { mentionTapHandler = handler } |
| PooToolsSource/Label/PTActiveLabel.swift:56 | func | open | open func handleHashtagTap(_ handler: @escaping PTActiveStringHandle) { hashtagTapHandler = handler } |
| PooToolsSource/Label/PTActiveLabel.swift:57 | func | open | open func handleURLTap(_ handler: @escaping PTActiveURLHandle) { urlTapHandler = handler } |
| PooToolsSource/Label/PTActiveLabel.swift:58 | func | open | open func handleCustomTap(for type: PTActiveType, handler: @escaping PTActiveStringHandle) { customTapHandlers[type] = handler } |
| PooToolsSource/Label/PTActiveLabel.swift:59 | func | open | open func handleEmailTap(_ handler: @escaping PTActiveStringHandle) { emailTapHandler = handler } |
| PooToolsSource/Label/PTActiveLabel.swift:60 | func | open | open func handleChinaCellPhoneTap(_ handler: @escaping PTActiveStringHandle) { chinaCellPhoneTapHandler = handler } |
| PooToolsSource/Label/PTActiveLabel.swift:61 | func | open | open func handleSnsIdTap(_ handler: @escaping PTActiveStringHandle) { snsIdTapHandler = handler } |
| PooToolsSource/Label/PTActiveLabel.swift:101 | func | open | open func customize(_ block: (_ label: PTActiveLabel) -> ()) -> PTActiveLabel { |
| PooToolsSource/Label/PTActiveLabel.swift:398 | func | public | public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { true } |
| PooToolsSource/Label/PTActiveLabel.swift:399 | func | public | public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool { true } |
| PooToolsSource/Label/PTActiveLabel.swift:400 | func | public | public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool { true } |
| PooToolsSource/Label/PTActiveType.swift:13 | enum | public | public enum PTActiveType: Hashable, Equatable, Sendable { |
| PooToolsSource/Label/PTAutoScrollLabel.swift:14 | enum | public | public enum PTScrollDirection { |
| PooToolsSource/Label/PTAutoScrollLabel.swift:21 | class | public | public class PTAutoScrollLabel: UIView { |
| PooToolsSource/Label/PTAutoScrollLabel.swift:33 | var | public | public var scrollInterval: TimeInterval = 2.0 |
| PooToolsSource/Label/PTAutoScrollLabel.swift:34 | var | public | public var textFont: UIFont = .systemFont(ofSize: 14) |
| PooToolsSource/Label/PTAutoScrollLabel.swift:35 | var | public | public var textColor: UIColor = .label |
| PooToolsSource/Label/PTAutoScrollLabel.swift:36 | var | public | public var numberOfLines: Int = 1 |
| PooToolsSource/Label/PTAutoScrollLabel.swift:37 | var | public | public var lineSpacing: CGFloat = 4 |
| PooToolsSource/Label/PTAutoScrollLabel.swift:38 | var | public | public var textAlignment: NSTextAlignment = .left |
| PooToolsSource/Label/PTAutoScrollLabel.swift:39 | var | public | public var scrollDirection: PTScrollDirection = .up |
| PooToolsSource/Label/PTAutoScrollLabel.swift:40 | var | public | public var itemSpacing: CGFloat = 20 |
| PooToolsSource/Label/PTAutoScrollLabel.swift:41 | var | public | public var marqueeSpeed: CGFloat = 40 |
| PooToolsSource/Label/PTAutoScrollLabel.swift:43 | var | public | public var onTap: ((Int, String) -> Void)? |
| PooToolsSource/Label/PTAutoScrollLabel.swift:70 | func | public | public func configure(with texts: [String], backgroundColors: [UIColor]? = nil) { |
| PooToolsSource/Label/PTAutoScrollLabel.swift:190 | func | public | public func stopScrolling() { |
| PooToolsSource/Label/PTAutoScrollLabel.swift:232 | func | public | @objc public func updateMarquee() { |
| PooToolsSource/Label/PTCountingLabel.swift:12 | let | public | public let kPTLabelCounterRate: CGFloat = 3 |
| PooToolsSource/Label/PTCountingLabel.swift:13 | typealias | public | public typealias PTCountingLabelAttributedFormatBlock = (CGFloat) -> NSAttributedString |
| PooToolsSource/Label/PTCountingLabel.swift:14 | typealias | public | public typealias PTCountingLabelFormatBlock = (CGFloat) -> String |
| PooToolsSource/Label/PTCountingLabel.swift:16 | enum | public | public enum PTCountingLabelType { |
| PooToolsSource/Label/PTCountingLabel.swift:63 | class | public | public class PTCountingLabel: UILabel { |
| PooToolsSource/Label/PTCountingLabel.swift:65 | var | open | open var countingType: PTCountingLabelType = .Linear |
| PooToolsSource/Label/PTCountingLabel.swift:66 | var | open | open var attributedFormatBlock: PTCountingLabelAttributedFormatBlock? |
| PooToolsSource/Label/PTCountingLabel.swift:67 | var | open | open var formatBlock: PTCountingLabelFormatBlock? |
| PooToolsSource/Label/PTCountingLabel.swift:68 | var | open | open var showCompletionBlock: PTActionTask? |
| PooToolsSource/Label/PTCountingLabel.swift:70 | var | open | open var format: String = "%f" { |
| PooToolsSource/Label/PTCountingLabel.swift:77 | var | open | open var positiveFormat: String = "" { |
| PooToolsSource/Label/PTCountingLabel.swift:108 | func | public | public func currentValue() -> CGFloat { |
| PooToolsSource/Label/PTCountingLabel.swift:129 | func | public | public func countFrom(value: CGFloat, toValue: CGFloat) { |
| PooToolsSource/Label/PTCountingLabel.swift:133 | func | public | public func countFromCurrentValue(toValue: CGFloat) { |
| PooToolsSource/Label/PTCountingLabel.swift:137 | func | public | public func countFormCurrentValue(toValue: CGFloat, duration: TimeInterval) { |
| PooToolsSource/Label/PTCountingLabel.swift:141 | func | public | public func countFromZero(toValue: CGFloat) { |
| PooToolsSource/Label/PTCountingLabel.swift:145 | func | public | public func countFromZero(toValue: CGFloat, duration: TimeInterval) { |
| PooToolsSource/Label/PTCountingLabel.swift:149 | func | public | public func countFrom(starValue: CGFloat, toValue: CGFloat, duration: TimeInterval) { |
| PooToolsSource/Label/PTLabel.swift:11 | enum | public | @objc public enum PTVerticalAlignment: Int { |
| PooToolsSource/Label/PTLabel.swift:17 | enum | public | @objc public enum PTStrikeThroughAlignment: Int { |
| PooToolsSource/Label/PTLabel.swift:24 | class | public | public class PTLabel: UILabel { |
| PooToolsSource/Label/PTLabel.swift:29 | var | public | public var verticalAlignment: PTVerticalAlignment = .middle { |
| PooToolsSource/Label/PTLabel.swift:39 | var | public | public var strikeThroughAlignment: PTStrikeThroughAlignment = .middle { |
| PooToolsSource/Label/PTLabel.swift:48 | var | public | public var strikeThroughEnabled: Bool = false { |
| PooToolsSource/Label/PTLabel.swift:57 | var | public | public var strikeThroughColor: UIColor = .systemRed { |
| PooToolsSource/Label/PTTagLabelScrollView.swift:12 | class | public | public class PTTagLabelScrollView: UIScrollView { |
| PooToolsSource/Label/PTTagLabelScrollView.swift:23 | init | public | public init(spacing: CGFloat = 6, |
| PooToolsSource/Label/PTTagLabelScrollView.swift:74 | func | public | public func setTags(_ tags: [String]) { |
| PooToolsSource/Label/PTTagLabelScrollView.swift:116 | func | public | public func clearTags() { |
| PooToolsSource/Label/PTTagLabelScrollView.swift:124 | class | public | public class PTPaddingLabel: UILabel { |
| PooToolsSource/Label/PTTagLabelScrollView.swift:127 | init | public | public init(padding: UIEdgeInsets) { |
| PooToolsSource/Language/PTLanguage.swift:39 | let | public | public let PTDefaultLanguage = "zh-Hans" |
| PooToolsSource/Language/PTLanguage.swift:41 | let | public | public let LanguageDidChangedKey = Notification.Name("LanguageDidChanged") |
| PooToolsSource/Language/PTLanguage.swift:43 | typealias | public | public typealias ChangedBlock = () -> Void |
| PooToolsSource/Language/PTLanguage.swift:44 | let | public | public let PTBaseBundle = "Base" |
| PooToolsSource/Language/PTLanguage.swift:46 | enum | public | public enum PTLocale: String, CaseIterable, Sendable { |
| PooToolsSource/Language/PTLanguage.swift:101 | var | public | public var identifier: String { rawValue } |
| PooToolsSource/Language/PTLanguage.swift:104 | var | public | public var languageCode: String { rawValue } |
| PooToolsSource/Language/PTLanguage.swift:116 | func | public | public func description(in locale: PTLocale) -> String { |
| PooToolsSource/Language/PTLanguage.swift:304 | var | public | public var language: String { |
| PooToolsSource/Language/PTLanguage.swift:334 | var | public | public var locale: Locale { |
| PooToolsSource/Language/PTLanguage.swift:339 | func | public | public func setLanguage(_ locale: PTLocale) { |
| PooToolsSource/Language/PTLanguage.swift:344 | class | public | public class func availableLanguages(_ excludeBase: Bool = false) -> [String] { |
| PooToolsSource/Language/PTLanguage.swift:349 | class | public | public class func defaultLanguage() -> String { |
| PooToolsSource/Language/PTLanguage.swift:354 | class | public | public class func displayNameForLanguage(_ language: String) -> String { |
| PooToolsSource/Language/PTLanguage.swift:406 | func | public | public func Localized(_ string: String) -> String { |
| PooToolsSource/Language/PTLanguage.swift:410 | func | public | public func Localized(_ string: String, arguments: CVarArg...) -> String { |
| PooToolsSource/Language/PTLanguage.swift:414 | func | public | public func LocalizedPlural(_ string: String, argument: CVarArg) -> String { |
| PooToolsSource/LaunchTimeProfiler/PTLaunchProfiler.swift:16 | class | public | public class PTLaunchProfiler { |
| PooToolsSource/LaunchTimeProfiler/PTLaunchProfiler.swift:22 | struct | public | public struct Milestone { |
| PooToolsSource/LaunchTimeProfiler/PTLaunchProfiler.swift:23 | let | public | public let name: String |
| PooToolsSource/LaunchTimeProfiler/PTLaunchProfiler.swift:24 | let | public | public let timestamp: TimeInterval |
| PooToolsSource/LaunchTimeProfiler/PTLaunchProfiler.swift:25 | let | public | public let threadName: String |
| PooToolsSource/LaunchTimeProfiler/PTLaunchProfiler.swift:27 | var | public | public var timeOffsetFromStart: TimeInterval = 0 |
| PooToolsSource/LaunchTimeProfiler/PTLaunchProfiler.swift:29 | var | public | public var timeOffsetFromPrevious: TimeInterval = 0 |
| PooToolsSource/LaunchTimeProfiler/PTLaunchProfiler.swift:55 | func | public | public func markMainStart() { |
| PooToolsSource/LaunchTimeProfiler/PTLaunchProfiler.swift:63 | func | public | public func markDidFinishLaunching() { |
| PooToolsSource/LaunchTimeProfiler/PTLaunchProfiler.swift:71 | func | public | public func markFirstScreenRender() { |
| PooToolsSource/LaunchTimeProfiler/PTLaunchProfiler.swift:86 | func | public | public func addMilestone(named name: String) { |
| PooToolsSource/LaunchTimeProfiler/PTLaunchProfiler.swift:96 | func | public | public func measure(named name: String, block: () -> Void) { |
| PooToolsSource/LaunchTimeProfiler/PTLaunchProfiler.swift:105 | func | public | public func getAllMilestones() -> [Milestone] { |
| PooToolsSource/LaunchTimeProfiler/PTLaunchProfiler.swift:196 | func | public | public func showEntry() { |
| PooToolsSource/Layout/PTCollectionLayout.swift:12 | class | public | public class PTCollectionLayout: NSObject { |
| PooToolsSource/Line/PTImaginaryLineView.swift:11 | enum | public | @objc public enum PTImaginaryLineType:Int{ |
| PooToolsSource/Line/PTImaginaryLineView.swift:17 | class | public | public class PTImaginaryLineView: UIView { |
| PooToolsSource/Line/PTImaginaryLineView.swift:21 | var | open | open var lineColor:UIColor = .lightGray { |
| PooToolsSource/Line/PTImaginaryLineView.swift:26 | var | open | open var lineType:PTImaginaryLineType = .Hor { |
| PooToolsSource/LivePhoto/PTLivePhoto.swift:50 | enum | public | public enum PTLivePhotoError: Error, LocalizedError, Sendable { |
| PooToolsSource/LivePhoto/PTLivePhoto.swift:57 | var | public | public var errorDescription: String? { |
| PooToolsSource/LivePhoto/PTLivePhoto.swift:84 | typealias | public | public typealias PTLivePhotoResources = (pairedImage: URL, pairedVideo: URL) |
| PooToolsSource/LivePhoto/PTLivePhoto.swift:108 | func | public | public func clearCache() { |
| PooToolsSource/LivePhoto/PTLivePhoto.swift:119 | class | public | public class func extractResources(from livePhoto: PHLivePhoto) async throws(PTLivePhotoError) -> PTLivePhotoResources { |
| PooToolsSource/LivePhoto/PTLivePhoto.swift:124 | class | public | public class func generate(from imageURL: URL?, videoURL: URL, progress: @Sendable @escaping (CGFloat) -> Void) async throws(PTLivePhotoError) -> (PHLivePhoto, PTLivePhotoResources) { |
| PooToolsSource/LivePhoto/PTLivePhoto.swift:130 | class | public | public class func saveToLibrary(_ resources: PTLivePhotoResources) async throws(PTLivePhotoError) -> Bool { |
| PooToolsSource/Loading/PTCycleLoadingView.swift:12 | class | public | public class PTCycleLoadingView: UIView { |
| PooToolsSource/Loading/PTCycleLoadingView.swift:15 | var | open | open var lineWidth: CGFloat = 1 { |
| PooToolsSource/Loading/PTCycleLoadingView.swift:21 | var | open | open var lineColor: UIColor = .lightGray { |
| PooToolsSource/Loading/PTCycleLoadingView.swift:81 | func | public | public func startAnimation() { |
| PooToolsSource/Loading/PTCycleLoadingView.swift:106 | func | public | public func stopAnimation(handle: PTActionTask? = nil) { |
| PooToolsSource/Loading/PTHudView.swift:29 | enum | public | @objc public enum PTHudStatus: Int { |
| PooToolsSource/Loading/PTHudView.swift:37 | class | public | public class PTHudConfig: NSObject { |
| PooToolsSource/Loading/PTHudView.swift:40 | var | open | open var lineWidth: CGFloat = 2 |
| PooToolsSource/Loading/PTHudView.swift:41 | var | open | open var length: CGFloat = maxLength |
| PooToolsSource/Loading/PTHudView.swift:43 | var | open | open var hudColors: [UIColor] = [ |
| PooToolsSource/Loading/PTHudView.swift:50 | var | open | open var masked: Bool = true |
| PooToolsSource/Loading/PTHudView.swift:51 | var | open | open var backgroundColor: UIColor = .clear |
| PooToolsSource/Loading/PTHudView.swift:54 | func | public | public func conterViewSizeSet(@PTClampedPropertyWrapper(range: 100...CGFloat.kSCREEN_WIDTH) size: CGFloat) { |
| PooToolsSource/Loading/PTHudView.swift:60 | class | public | public class PTHudView: UIView { |
| PooToolsSource/Loading/PTHudView.swift:96 | func | public | public func hudShow() { |
| PooToolsSource/Loading/PTHudView.swift:122 | func | public | public func hide(duration: TimeInterval = 0.35, completion: PTActionTask?) { |
| PooToolsSource/Loading/PTHudView.swift:146 | class | public | public class PTLoadingHud: UIView { |
| PooToolsSource/Loading/PTHudView.swift:147 | var | open | open var hudConfig = PTHudConfig.share |
| PooToolsSource/Loading/PTHudView.swift:148 | var | open | open var length: CGFloat = maxLength |
| PooToolsSource/Loading/PTHudView.swift:149 | var | open | open var gradualColor: UIColor = .randomColor |
| PooToolsSource/Loading/PTHudView.swift:150 | var | open | open var finalColor: UIColor = .randomColor |
| PooToolsSource/Loading/PTHudView.swift:151 | var | open | open var prevColor: UIColor = .randomColor |
| PooToolsSource/Loading/PTHudView.swift:152 | var | open | open var rotateAngle: NSInteger = NSInteger(arc4random() % 360) |
| PooToolsSource/Loading/PTHudView.swift:153 | var | open | open var colorIndex: NSInteger = 0 |
| PooToolsSource/Loading/PTHudView.swift:154 | var | open | open var waitingFrameCount: NSInteger = 0 |
| PooToolsSource/Loading/PTHudView.swift:155 | var | open | open var status: PTHudStatus = .Decrease |
| PooToolsSource/LocalConsole/GestureEndpointPredictor.swift:54 | func | public | public func relativeVelocity(forVelocity velocity: CGFloat, from currentLocation: CGFloat, to targetLocation: CGFloat) -> CGFloat { |
| PooToolsSource/LocalConsole/GestureEndpointPredictor.swift:66 | func | public | public func project(initialVelocity: CGFloat, decelerationRate: CGFloat) -> CGFloat { |
| PooToolsSource/LocalConsole/GestureEndpointPredictor.swift:71 | func | public | public func nearestTargetTo(_ point: CGPoint, possibleTargets: [CGPoint]) -> CGPoint { |
| PooToolsSource/LocalConsole/LocalConsole.swift:24 | let | public | public let LocalConsoleFontMin:CGFloat = 4 |
| PooToolsSource/LocalConsole/LocalConsole.swift:25 | let | public | public let LocalConsoleFontMax:CGFloat = 20 |
| PooToolsSource/LocalConsole/LocalConsole.swift:26 | let | public | public let SystemLogViewTag = 999999 |
| PooToolsSource/LocalConsole/LocalConsole.swift:27 | let | public | public let systemLog_base_width:CGFloat = 240 |
| PooToolsSource/LocalConsole/LocalConsole.swift:28 | let | public | public let systemLog_base_height:CGFloat = 148 |
| PooToolsSource/LocalConsole/LocalConsole.swift:29 | let | public | public let borderLine:CGFloat = 5 |
| PooToolsSource/LocalConsole/LocalConsole.swift:30 | let | public | public let diameter:CGFloat = 28 |
| PooToolsSource/LocalConsole/LocalConsole.swift:244 | enum | public | public enum PTLogLevel { |
| PooToolsSource/LocalConsole/LocalConsole.swift:259 | struct | public | public struct LogItem { |
| PooToolsSource/LocalConsole/LocalConsole.swift:313 | protocol | public | public protocol PTDebugPlugin { |
| PooToolsSource/LocalConsole/LocalConsole.swift:363 | enum | public | @objc public enum LocalConsoleActionType : Int { |
| PooToolsSource/LocalConsole/LocalConsole.swift:373 | typealias | public | public typealias PTLocalConsoleBlock = (_ actionType:LocalConsoleActionType,_ debug:Bool,_ logUrl:URL) -> Void |
| PooToolsSource/LocalConsole/LocalConsole.swift:377 | class | public | public class LocalConsole: NSObject { |
| PooToolsSource/LocalConsole/LocalConsole.swift:406 | func | public | public func registerDebugPlugin(_ plugin: PTDebugPlugin) { |
| PooToolsSource/LocalConsole/LocalConsole.swift:411 | func | public | public func clearDebugPlugins() { |
| PooToolsSource/LocalConsole/LocalConsole.swift:431 | var | public | public var closeAllOutsideFunction:PTActionTask? |
| PooToolsSource/LocalConsole/LocalConsole.swift:432 | var | public | public var leakCallback: (@MainActor @Sendable (PTPerformanceLeak) -> Void)? |
| PooToolsSource/LocalConsole/LocalConsole.swift:433 | var | public | public var networkStatus = "" |
| PooToolsSource/LocalConsole/LocalConsole.swift:435 | var | public | public var menu: UIMenuElement? = nil { |
| PooToolsSource/LocalConsole/LocalConsole.swift:443 | var | public | @MainActor public var isVisiable:Bool = { |
| PooToolsSource/LocalConsole/LocalConsole.swift:499 | func | public | public func setAttFontSize(@PTClampedPropertyWrapper(range:LocalConsoleFontMin...LocalConsoleFontMax) fontSizes:CGFloat) { |
| PooToolsSource/LocalConsole/LocalConsole.swift:504 | func | public | public func setAttFontColor(color:UIColor) { |
| PooToolsSource/LocalConsole/LocalConsole.swift:508 | var | public | public var terminal:PTTerminal? |
| PooToolsSource/LocalConsole/LocalConsole.swift:509 | var | public | public var maskView:PTDevMaskView? |
| PooToolsSource/LocalConsole/LocalConsole.swift:517 | var | public | public var showAllUserDefaultsKeys = false { |
| PooToolsSource/LocalConsole/LocalConsole.swift:646 | func | public | @MainActor public func cleanSystemLogView() { |
| PooToolsSource/LocalConsole/LocalConsole.swift:798 | func | public | @MainActor public func createSystemLogView() { |
| PooToolsSource/LocalConsole/LocalConsole.swift:885 | var | public | public var isCharacterLimitDisabled = false |
| PooToolsSource/LocalConsole/LocalConsole.swift:886 | var | public | public var isCharacterLimitWarningDisabled = false |
| PooToolsSource/LocalConsole/LocalConsole.swift:888 | func | public | public func print(_ items: Any, level: PTLogLevel = .info) { |
| PooToolsSource/LocalConsole/LocalConsole.swift:934 | func | public | public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? { |
| PooToolsSource/LocalConsole/LocalConsole.swift:1010 | func | public | public func clear() { |
| PooToolsSource/LocalConsole/LocalConsole.swift:1492 | class | public | public class PTTerminal:PFloatingButton { |
| PooToolsSource/LocalConsole/LocalConsole.swift:1493 | var | public | public var systemText : PTInvertedTextView? |
| PooToolsSource/LocalConsole/LocalConsole.swift:1572 | func | public | public func setAttributedText(_ string: String) { |
| PooToolsSource/LocalConsole/LocalConsole.swift:1589 | func | public | public func appendLog(_ item: PTLogBuffer.LogItem) { |
| PooToolsSource/LocalConsole/PTInvertedTextView.swift:11 | class | public | public class PTInvertedTextView: UITextView { |
| PooToolsSource/LocalConsole/PTInvertedTextView.swift:13 | var | public | public var pendingOffsetChange = false |
| PooToolsSource/LocalConsole/PTInvertedTextView.swift:26 | var | public | public var cancelNextContentSizeDidSet = false |
| PooToolsSource/LocalConsole/PTLocalConsoleFunction.swift:12 | class | public | public class PTLocalConsoleFunction: NSObject { |
| PooToolsSource/LocalConsole/PTLocalConsoleFunction.swift:15 | var | public | @MainActor public var localconsole : LocalConsole = { |
| PooToolsSource/LocalConsole/SystemReport.swift:11 | class | public | public class SystemReport { |
| PooToolsSource/LocalConsole/SystemReport.swift:14 | var | public | public var versionString: String { |
| PooToolsSource/LocalConsole/SystemReport.swift:21 | var | public | public var thermalState: String { |
| PooToolsSource/LocalConsole/SystemReport.swift:49 | var | public | public var deviceArchitecture: String { |
| PooToolsSource/LocalConsole/SystemReport.swift:66 | var | public | public var modelIdentifier: String { |
| PooToolsSource/LocalConsole/SystemReport.swift:73 | var | public | public var kernel: String { |
| PooToolsSource/LocalConsole/SystemReport.swift:84 | var | public | public var kernelVersion: String { |
| PooToolsSource/LocalConsole/SystemReport.swift:94 | var | public | public var compileDate: String { |
| PooToolsSource/Location/PTGetGPSData.swift:14 | class | public | public class PTGetGPSData: NSObject { |
| PooToolsSource/Location/PTGetGPSData.swift:16 | var | open | open var errorBlock:PTActionTask? |
| PooToolsSource/Location/PTGetGPSData.swift:17 | var | open | open var selectCurrentBlock:PTActionTask? |
| PooToolsSource/Location/PTGetGPSData.swift:18 | var | open | open var selectNewBlock:PTActionTask? |
| PooToolsSource/Location/PTGetGPSData.swift:19 | var | open | open var showChangeAlert:Bool = false |
| PooToolsSource/Location/PTGetGPSData.swift:33 | func | public | public func getUserLocation(block: ((_ lat:String,_ lon:String,_ cityName:String) -> Void)?) { |
| PooToolsSource/Location/PTGetGPSData.swift:51 | func | public | @MainActor public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { |
| PooToolsSource/Location/PTGetGPSData.swift:60 | func | public | public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { |
| PooToolsSource/Location/PTGetGPSData.swift:106 | func | public | @MainActor public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) { |
| PooToolsSource/LocationPermission/PTPermissionLocation.swift:19 | class | public | public class PTPermissionLocation: PTPermission { |
| PooToolsSource/LocationPermission/PTPermissionLocation.swift:30 | var | open | open var usageDescriptionKey: String? { |
| PooToolsSource/LocationPermission/PTPermissionLocation.swift:71 | var | public | public var isPrecise: Bool { |
| PooToolsSource/LocationPermission/PTPermissionLocationAccuracy.swift:14 | func | public | public func setAccuracy(_ value: PTPermissionLocationAccuracy) { |
| PooToolsSource/LocationPermission/PTPermissionLocationAccuracy.swift:19 | enum | public | public enum PTPermissionLocationAccuracy { |
| PooToolsSource/Log/Logger+PTEX.swift:15 | enum | public | public enum LoggerEXType: String, CaseIterable,Sendable { |
| PooToolsSource/Log/Logger+PTEX.swift:60 | enum | public | @objc public enum LoggerEXLevelType: Int, CaseIterable, Sendable { |
| PooToolsSource/Log/Logger+PTEX.swift:71 | var | public | public var PTLogMode: LoggerEXLevelType { |
| PooToolsSource/Log/PTLogFileManager.swift:4 | actor | public | public actor PTLogFileManager { |
| PooToolsSource/Log/PTLogFileManager.swift:11 | func | public | public func append(logText: String) { |
| PooToolsSource/Log/PTNSLog.swift:18 | enum | public | public enum PTLogSeverity: String, Sendable { |
| PooToolsSource/Log/PTNSLog.swift:25 | struct | public | public struct PTLogEvent: Sendable { |
| PooToolsSource/Log/PTNSLog.swift:26 | let | public | public let message: String |
| PooToolsSource/Log/PTNSLog.swift:27 | let | public | public let severity: PTLogSeverity |
| PooToolsSource/Log/PTNSLog.swift:28 | let | public | public let category: String |
| PooToolsSource/Log/PTNSLog.swift:30 | init | public | public init(message: String, |
| PooToolsSource/Log/PTNSLog.swift:39 | protocol | public | public protocol PTLogging: Sendable { |
| PooToolsSource/Log/PTNSLog.swift:43 | struct | public | public struct PTOSLogger: PTLogging { |
| PooToolsSource/Log/PTNSLog.swift:46 | init | public | public init(subsystem: String = Bundle.main.bundleIdentifier ?? "PooTools", |
| PooToolsSource/Log/PTNSLog.swift:51 | func | public | public func log(_ event: PTLogEvent) { |
| PooToolsSource/Log/PTNSLog.swift:99 | func | public | public func prettyJSONString(from object: Any) -> String? { |
| PooToolsSource/Log/PTNSLog.swift:114 | func | public | public func PTNSLogConsole(_ any: Any..., |
| PooToolsSource/Log/PTNSLog.swift:128 | func | public | public func PTNSLog(_ msg: Any..., |
| PooToolsSource/Log/PTNSLog.swift:208 | func | public | public func PTPrintPointer<T>(ptr: UnsafePointer<T>, |
| PooToolsSource/Log/PTNSLog.swift:220 | func | public | public func PTPrint<T>(val: inout T, |
| PooToolsSource/Log/PTNSLog.swift:237 | func | public | public func PTPrint<T>(ref: T, |
| PooToolsSource/Log/PTNSLog.swift:255 | enum | public | public enum PTMemAlign : Int { |
| PooToolsSource/Log/PTNSLog.swift:264 | struct | public | public struct PTMems<T> { |
| PooToolsSource/Log/PTNSLog.swift:369 | enum | public | public enum PTStringMemType : UInt8 { |
| PooToolsSource/Log/PTNSLog.swift:380 | struct | public | public struct PTMemsWrapper<Base> { |
| PooToolsSource/Log/PTNSLog.swift:382 | init | public | public init(_ base: Base) { |
| PooToolsSource/Log/PTNSLog.swift:387 | protocol | public | public protocol PTMemsCompatible {} |
| PooToolsSource/MXMetricKitManager/MetricsManager.swift:28 | func | public | public func didReceive(_ payloads: [MXMetricPayload]) { |
| PooToolsSource/MXMetricKitManager/MetricsManager.swift:49 | func | public | public func didReceive(_ payloads: [MXDiagnosticPayload]) { |
| PooToolsSource/MXMetricKitManager/MetricsManager.swift:86 | func | public | public func uploadPendingMetrics() { |
| PooToolsSource/MediaViewer/PTMediaBrowserCell.swift:324 | class | open | open class func centerOfScrollVIewContent(scrollView:UIScrollView) -> CGPoint { |
| PooToolsSource/MediaViewer/PTMediaBrowserCell.swift:650 | func | public | public func viewForZooming(in scrollView: UIScrollView) -> UIView? { |
| PooToolsSource/MediaViewer/PTMediaBrowserCell.swift:655 | func | public | public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) { |
| PooToolsSource/MediaViewer/PTMediaBrowserCell.swift:660 | func | public | public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) { } |
| PooToolsSource/MediaViewer/PTMediaBrowserCell.swift:662 | func | public | public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { } |
| PooToolsSource/MediaViewer/PTMediaBrowserCell.swift:664 | func | public | public func scrollViewDidZoom(_ scrollView: UIScrollView) { |
| PooToolsSource/MediaViewer/PTMediaBrowserCell.swift:674 | func | public | public func scrollViewDidScroll(_ scrollView: UIScrollView) { |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:11 | typealias | public | public typealias PTViewerSaveBlock = (_ finish:Bool) -> Void |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:12 | typealias | public | public typealias PTViewerIndexBlock = (_ dataIndex:Int) -> Void |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:13 | typealias | public | public typealias PTViewerEXIndexBlock = (_ dataIndex:Int,_ image:UIImage?) -> Void |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:15 | enum | public | @objc public enum PTViewerDataType:Int { |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:25 | enum | public | @objc public enum PTViewerActionType:Int { |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:35 | class | public | public class PTMediaBrowserConfig: NSObject { |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:38 | var | public | public var titleColor:UIColor = UIColor.white |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:40 | var | public | public var titleFont:UIFont = UIFont.systemFont(ofSize: 24) |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:42 | var | public | public var viewerFont:UIFont = UIFont.systemFont(ofSize: 13) |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:44 | var | public | public var viewerContentBackgroundColor:UIColor = .clear |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:46 | var | public | public var actionType:PTViewerActionType = .All |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:48 | var | public | public var closeViewerImage:UIImage = "❌".emojiToImage(emojiFont: .appfont(size: 20)) |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:50 | var | public | public var moreActionImage:UIImage = "🗃️".emojiToImage(emojiFont: .appfont(size: 20)) |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:52 | var | public | public var playButtonImage:UIImage = "▶️".emojiToImage(emojiFont: .appfont(size: 44)) |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:53 | var | public | public var playButtonImageSize:CGSize = .init(width: 44, height: 44) |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:56 | var | public | public var moreActionEX:[String] = [] |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:58 | var | public | public var iCloudDocumentName:String = "" |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:60 | var | public | public var dynamicBackground:Bool = false |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:62 | var | public | public var showMore:String = "...\("PT More".localized())" |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:64 | var | public | public var saveDesc:String = "PT Media save".localized() |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:66 | var | public | public var deleteDesc:String = "PT Media delete".localized() |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:68 | var | public | public var actionTitle:String = "PT Media option".localized() |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:70 | var | public | public var actionCancel:String = "PT Button cancel".localized() |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:72 | var | public | public var imageReloadButton:String = "PT Image load fail".localized() |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:74 | var | public | public var pageControlOption:PTMediaPageControlOption = .scrolling |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:76 | var | public | public var pageControlShow:Bool = false |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:78 | var | public | public var imageLongTapAction:Bool = true |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:80 | enum | public | public enum PTMediaPageControlOption:Int { |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:89 | var | public | @PTClampedPropertyWrapper(range: 50...200) public var dismissY:CGFloat = 200 |
| PooToolsSource/MediaViewer/PTMediaBrowserController.swift:20 | class | public | public class PTMediaBrowserController: PTBaseViewController { |
| PooToolsSource/MediaViewer/PTMediaBrowserController.swift:23 | var | public | public var viewDismissBlock:PTActionTask? |
| PooToolsSource/MediaViewer/PTMediaBrowserController.swift:25 | var | public | public var defaultIndex: Int = 0 |
| PooToolsSource/MediaViewer/PTMediaBrowserController.swift:31 | var | public | public var viewMoreActionBlock:PTViewerEXIndexBlock? |
| PooToolsSource/MediaViewer/PTMediaBrowserController.swift:33 | var | public | public var viewSaveImageBlock:PTViewerSaveBlock? |
| PooToolsSource/MediaViewer/PTMediaBrowserController.swift:35 | var | public | public var viewDeleteImageBlock:PTViewerIndexBlock? |
| PooToolsSource/MediaViewer/PTMediaBrowserController.swift:38 | var | public | public var browserCurrentDataBlock:((Int)->Void)? |
| PooToolsSource/MediaViewer/PTMediaBrowserController.swift:274 | init | public | public init(mediaData: [PTMediaBrowserModel], defaultIndex: Int = 0) { |
| PooToolsSource/MediaViewer/PTMediaBrowserController.swift:443 | func | public | public func mediasShow() { |
| PooToolsSource/MediaViewer/PTMediaBrowserController.swift:448 | func | public | public func reloadConfig(mediaData:[PTMediaBrowserModel]) { |
| PooToolsSource/MediaViewer/PTMediaBrowserModel.swift:13 | var | public | public var imageInfo: String = "" |
| PooToolsSource/MediaViewer/PTMediaBrowserModel.swift:17 | var | public | public var imageURL: Any? |
| PooToolsSource/MediaViewer/PTMediaBrowserModel.swift:18 | var | public | public var modelEX: String = "" |
| PooToolsSource/MeidaLibraryPermission/PTPermissionMedia.swift:19 | class | public | public class PTPermissionMedia: PTPermission { |
| PooToolsSource/MeidaLibraryPermission/PTPermissionMedia.swift:22 | var | open | open var usageDescriptionKey: String? { "NSAppleMusicUsageDescription" } |
| PooToolsSource/MessageKit/PTChatBaseCell.swift:11 | typealias | public | public typealias PTChatBaseCellHandler = (_ dataModel: PTChatListModel) -> Void |
| PooToolsSource/MessageKit/PTChatBaseCell.swift:15 | class | open | open class PTChatBaseCell: PTBaseNormalCell { |
| PooToolsSource/MessageKit/PTChatBaseCell.swift:25 | var | public | public var sendExp: PTChatBaseCellHandler? |
| PooToolsSource/MessageKit/PTChatBaseCell.swift:26 | var | public | public var sendMessageError: PTChatBaseCellHandler? |
| PooToolsSource/MessageKit/PTChatBaseCell.swift:31 | var | public | public var outputModel: PTChatListModel! |
| PooToolsSource/MessageKit/PTChatBaseCell.swift:117 | func | open | open func setBaseSubviews(cellModel: PTChatListModel) { |
| PooToolsSource/MessageKit/PTChatBaseCell.swift:122 | func | open | open func resetSubviewsFrame(cellModel: PTChatListModel) { |
| PooToolsSource/MessageKit/PTChatBaseCell.swift:199 | func | open | open func checkCellSendStatus(cellModel: PTChatListModel) { |
| PooToolsSource/MessageKit/PTChatBaseCell.swift:217 | func | open | open func startWaitAnimation() { |
| PooToolsSource/MessageKit/PTChatBaseCell.swift:224 | func | open | open func stopWaitAnimation() { |
| PooToolsSource/MessageKit/PTChatBubbleCircle.swift:10 | class | public | public class PTChatBubbleCircle: UIView { |
| PooToolsSource/MessageKit/PTChatBubbleCircle.swift:16 | func | open | open func roundedMask(corners: UIRectCorner, radius: CGFloat) -> CAShapeLayer { |
| PooToolsSource/MessageKit/PTChatConfig.swift:31 | class | public | public class PTMessageTextCustomAttTagModel:PTCodableModelProtocol { |
| PooToolsSource/MessageKit/PTChatConfig.swift:33 | var | public | public var tag:String = "" |
| PooToolsSource/MessageKit/PTChatConfig.swift:34 | var | public | @SmartAny public var tagColor:DynamicColor = .systemGray |
| PooToolsSource/MessageKit/PTChatConfig.swift:35 | var | public | @SmartAny public var tagSelectedColor:DynamicColor = .systemGray |
| PooToolsSource/MessageKit/PTChatConfig.swift:41 | class | public | public class PTChatConfig: NSObject { |
| PooToolsSource/MessageKit/PTChatConfig.swift:52 | var | public | public var imOwnerId:String = "" |
| PooToolsSource/MessageKit/PTChatConfig.swift:53 | var | public | @PTClampedPropertyWrapper(range:10...120) public var messageExpTime: Int = 60 |
| PooToolsSource/MessageKit/PTChatConfig.swift:67 | var | public | public var chatTopFixel:CGFloat = 0 |
| PooToolsSource/MessageKit/PTChatConfig.swift:69 | var | public | public var chatBottomFixel:CGFloat = 0 |
| PooToolsSource/MessageKit/PTChatConfig.swift:72 | var | public | public var chatTimeFont:UIFont = .appfont(size: 13) |
| PooToolsSource/MessageKit/PTChatConfig.swift:74 | var | public | public var chatTimeColor:UIColor = UIColor(hexString: "919191") ?? .secondaryLabel |
| PooToolsSource/MessageKit/PTChatConfig.swift:76 | var | public | @PTClampedPropertyWrapper(range:5...20) public var chatTimeContentFixel:CGFloat = 5 |
| PooToolsSource/MessageKit/PTChatConfig.swift:78 | var | public | public var chatTimeBackgroundColor:UIColor = UIColor(hexString: "cacaca") ?? .tertiarySystemFill |
| PooToolsSource/MessageKit/PTChatConfig.swift:80 | var | public | public var chatSystemMessageFont:UIFont = .appfont(size: 13) |
| PooToolsSource/MessageKit/PTChatConfig.swift:82 | var | public | public var chatSystemMessageColor:UIColor = UIColor(hexString: "919191") ?? .secondaryLabel |
| PooToolsSource/MessageKit/PTChatConfig.swift:84 | var | public | public var chatSystemTimeLineSpace:NSNumber = 2 |
| PooToolsSource/MessageKit/PTChatConfig.swift:86 | var | public | public var chatSystemContentLineSpace:NSNumber = 2 |
| PooToolsSource/MessageKit/PTChatConfig.swift:91 | var | open | @PTClampedPropertyWrapper(range:44...88) open var messageUserIconSize: CGFloat = 44 |
| PooToolsSource/MessageKit/PTChatConfig.swift:93 | var | public | public var showTimeLabel:Bool = true |
| PooToolsSource/MessageKit/PTChatConfig.swift:95 | var | public | public var showSenderName:Bool = true |
| PooToolsSource/MessageKit/PTChatConfig.swift:97 | var | public | public var senderNameFont:UIFont = .appfont(size: 13) |
| PooToolsSource/MessageKit/PTChatConfig.swift:99 | var | public | public var senderNameColor:UIColor = UIColor(hexString: "919191") ?? .secondaryLabel |
| PooToolsSource/MessageKit/PTChatConfig.swift:100 | var | public | public var senderNameBackgroundColor:UIColor = .clear |
| PooToolsSource/MessageKit/PTChatConfig.swift:101 | var | public | public var receiverNameColor:UIColor = UIColor(hexString: "919191") ?? .secondaryLabel |
| PooToolsSource/MessageKit/PTChatConfig.swift:102 | var | public | public var receiverNameBackgroundColor:UIColor = .clear |
| PooToolsSource/MessageKit/PTChatConfig.swift:103 | var | public | public var userIconTopSpacing:CGFloat = 0 |
| PooToolsSource/MessageKit/PTChatConfig.swift:105 | var | public | public var userIconFixelSpace:CGFloat = 10 |
| PooToolsSource/MessageKit/PTChatConfig.swift:107 | var | public | public var chatMeBubbleImage:UIImage = UIColor.white.createImageWithColor().transformImage(size: CGSize(width: 55, height: 55)) |
| PooToolsSource/MessageKit/PTChatConfig.swift:109 | var | public | public var chatMeHighlightedBubbleImage:UIImage = HSL(color: DynamicColor.white).lighter(amount: 0.8).toDynamicColor().createImageWithColor().transformImage(size: CGSize(width: 55, height: 55)) |
| PooToolsSource/MessageKit/PTChatConfig.swift:111 | var | public | public var chatOtherBubbleImage:UIImage = UIColor.systemBlue.createImageWithColor().transformImage(size: CGSize(width: 55, height: 55)) |
| PooToolsSource/MessageKit/PTChatConfig.swift:113 | var | public | public var chatOtherHighlightedBubbleImage:UIImage = HSL(color: DynamicColor.systemBlue).lighter(amount: 0.8).toDynamicColor().createImageWithColor().transformImage(size: CGSize(width: 55, height: 55)) |
| PooToolsSource/MessageKit/PTChatConfig.swift:115 | var | public | public var chatWaitImage:UIImage = "📀".emojiToImage(emojiFont: .appfont(size: 20)) |
| PooToolsSource/MessageKit/PTChatConfig.swift:117 | var | public | public var chatWaitErrorImage:UIImage = "‼️".emojiToImage(emojiFont: .appfont(size: 20)) |
| PooToolsSource/MessageKit/PTChatConfig.swift:119 | var | public | public var showReadStatus:Bool = true |
| PooToolsSource/MessageKit/PTChatConfig.swift:121 | var | public | public var readStatusFont:UIFont = .appfont(size: 13) |
| PooToolsSource/MessageKit/PTChatConfig.swift:123 | var | public | public var readStatusColor:UIColor = UIColor(hexString: "919191") ?? .secondaryLabel |
| PooToolsSource/MessageKit/PTChatConfig.swift:124 | var | public | public var readStatusName:String = "Read" |
| PooToolsSource/MessageKit/PTChatConfig.swift:125 | var | public | public var unreadStatusName:String = "unread" |
| PooToolsSource/MessageKit/PTChatConfig.swift:127 | var | open | @PTClampedPropertyWrapper(range:5...100) open var timeTopSpace: CGFloat = 5 |
| PooToolsSource/MessageKit/PTChatConfig.swift:131 | var | public | public var textMeMessageColor:UIColor = .black |
| PooToolsSource/MessageKit/PTChatConfig.swift:133 | var | public | public var textMeMessageFont:UIFont = .appfont(size: 15) |
| PooToolsSource/MessageKit/PTChatConfig.swift:135 | var | public | public var textOtherMessageColor:UIColor = .black |
| PooToolsSource/MessageKit/PTChatConfig.swift:137 | var | public | public var textOtherMessageFont:UIFont = .appfont(size: 15) |
| PooToolsSource/MessageKit/PTChatConfig.swift:139 | var | public | public var textOwnerContentEdges:UIEdgeInsets = UIEdgeInsets(top: 20, left: 10, bottom: 20, right: 15) |
| PooToolsSource/MessageKit/PTChatConfig.swift:141 | var | public | public var textOtherContentEdges:UIEdgeInsets = UIEdgeInsets(top: 20, left: 15, bottom: 20, right: 15) |
| PooToolsSource/MessageKit/PTChatConfig.swift:143 | var | public | public var textLineSpace:CGFloat = 2 |
| PooToolsSource/MessageKit/PTChatConfig.swift:145 | var | public | @PTClampedPropertyWrapper(range:38...88) public var contentBaseHeight: CGFloat = 38 |
| PooToolsSource/MessageKit/PTChatConfig.swift:147 | var | public | public var hashtagColor:DynamicColor = .systemBlue |
| PooToolsSource/MessageKit/PTChatConfig.swift:148 | var | public | public var hashtagSelectedColor:DynamicColor = .systemBlue |
| PooToolsSource/MessageKit/PTChatConfig.swift:150 | var | public | public var chinaCellPhoneColor:DynamicColor = .BurntOrangeColor |
| PooToolsSource/MessageKit/PTChatConfig.swift:151 | var | public | public var chinaCellPhoneSelectedColor:DynamicColor = .BurntOrangeColor |
| PooToolsSource/MessageKit/PTChatConfig.swift:153 | var | public | public var urlColor:DynamicColor = .SteelBlueColor |
| PooToolsSource/MessageKit/PTChatConfig.swift:154 | var | public | public var urlSelectedColor:DynamicColor = .SteelBlueColor |
| PooToolsSource/MessageKit/PTChatConfig.swift:156 | var | public | public var mentionColor:DynamicColor = .systemRed |
| PooToolsSource/MessageKit/PTChatConfig.swift:157 | var | public | public var mentionSelectedColor:DynamicColor = .systemRed |
| PooToolsSource/MessageKit/PTChatConfig.swift:159 | var | public | public var customerTagModels:[PTMessageTextCustomAttTagModel] = [] |
| PooToolsSource/MessageKit/PTChatConfig.swift:163 | var | public | @PTClampedPropertyWrapper(range:88...200) public var imageMessageImageWidth: CGFloat = 200 |
| PooToolsSource/MessageKit/PTChatConfig.swift:165 | var | public | @PTClampedPropertyWrapper(range:88...200) public var imageMessageImageHeight: CGFloat = 200 |
| PooToolsSource/MessageKit/PTChatConfig.swift:167 | var | public | @PTClampedPropertyWrapper(range:0...100) public var imageMessageImageCorner: CGFloat = 5 |
| PooToolsSource/MessageKit/PTChatConfig.swift:169 | var | public | @PTClampedPropertyWrapper(range:88...200) public var mediaMessageVideoWidth: CGFloat = 200 |
| PooToolsSource/MessageKit/PTChatConfig.swift:171 | var | public | @PTClampedPropertyWrapper(range:88...200) public var mediaMessageVideoHeight: CGFloat = 200 |
| PooToolsSource/MessageKit/PTChatConfig.swift:172 | var | public | public var mediaPlayButton:UIImage = "▶️".emojiToImage(emojiFont: .appfont(size: 40)) |
| PooToolsSource/MessageKit/PTChatConfig.swift:173 | var | public | public var mediaDownloadImage:UIImage = "⏬️".emojiToImage(emojiFont: .appfont(size: 40)) |
| PooToolsSource/MessageKit/PTChatConfig.swift:174 | var | public | public var mediaDownloadPauseImage:UIImage = "🔁".emojiToImage(emojiFont: .appfont(size: 40)) |
| PooToolsSource/MessageKit/PTChatConfig.swift:175 | var | public | public var mediaPlayButtonSize:CGSize = .init(width: 34, height: 34) |
| PooToolsSource/MessageKit/PTChatConfig.swift:179 | var | public | @PTClampedPropertyWrapper(range:88...200) public var mapMessageImageWidth: CGFloat = 200 |
| PooToolsSource/MessageKit/PTChatConfig.swift:181 | var | public | @PTClampedPropertyWrapper(range:88...200) public var mapMessageImageHeight: CGFloat = 200 |
| PooToolsSource/MessageKit/PTChatConfig.swift:183 | var | public | @PTClampedPropertyWrapper(range:0...100) public var mapMessageImageCorner: CGFloat = 5 |
| PooToolsSource/MessageKit/PTChatConfig.swift:185 | var | public | public var showBuilding:Bool = true |
| PooToolsSource/MessageKit/PTChatConfig.swift:187 | var | public | public var span:MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0) |
| PooToolsSource/MessageKit/PTChatConfig.swift:189 | var | public | public var showsPointsOfInterest: Bool = false |
| PooToolsSource/MessageKit/PTChatConfig.swift:191 | var | public | public var mapCellPinImage:UIImage = "🧭".emojiToImage(emojiFont: .appfont(size: 40)) |
| PooToolsSource/MessageKit/PTChatConfig.swift:195 | var | public | @PTClampedPropertyWrapper(range:150...250) public var audioMessageImageWidth: CGFloat = 250 |
| PooToolsSource/MessageKit/PTChatConfig.swift:197 | var | public | public var playButtonImage:UIImage = UIImage(.play).withTintColor(.systemBlue) |
| PooToolsSource/MessageKit/PTChatConfig.swift:199 | var | public | public var pauseButtonImage:UIImage = UIImage(.pause).withTintColor(.systemBlue) |
| PooToolsSource/MessageKit/PTChatConfig.swift:201 | var | public | public var durationFont:UIFont = .appfont(size: 14) |
| PooToolsSource/MessageKit/PTChatConfig.swift:203 | var | public | public var durationColor:UIColor = .systemBlue |
| PooToolsSource/MessageKit/PTChatConfig.swift:205 | var | public | public var progressColor:UIColor = .systemBlue |
| PooToolsSource/MessageKit/PTChatConfig.swift:208 | var | public | public var dotColor:UIColor = .lightGray |
| PooToolsSource/MessageKit/PTChatConfig.swift:211 | var | public | public var fileNameFont:UIFont = .appfont(size: 18,bold: true) |
| PooToolsSource/MessageKit/PTChatConfig.swift:212 | var | public | public var fileNameColor:UIColor = .black |
| PooToolsSource/MessageKit/PTChatConfig.swift:213 | var | public | public var fileSizeFont:UIFont = .appfont(size: 13) |
| PooToolsSource/MessageKit/PTChatConfig.swift:214 | var | public | public var fileSizeColor:UIColor = .lightGray |
| PooToolsSource/MessageKit/PTChatConfig.swift:215 | var | public | @PTClampedPropertyWrapper(range:0...15) public var fileContentSpace: CGFloat = 2 |
| PooToolsSource/MessageKit/PTChatConfig.swift:216 | var | public | public var fileImage:UIImage = "📁".emojiToImage(emojiFont: .appfont(size: 40)) |
| PooToolsSource/MessageKit/PTChatConfig.swift:217 | var | public | public var yesterDayName:String = "昨天" |
| PooToolsSource/MessageKit/PTChatFileCell.swift:13 | class | public | public class PTChatFileCell: PTChatBaseCell { |
| PooToolsSource/MessageKit/PTChatFileCell.swift:22 | var | public | public var cellModel: PTChatListModel! { |
| PooToolsSource/MessageKit/PTChatListModel.swift:11 | enum | public | public enum PTChatMessageType:Int,SmartCaseDefaultable { |
| PooToolsSource/MessageKit/PTChatListModel.swift:22 | enum | public | public enum PTChatMessageStatus:Int,SmartCaseDefaultable { |
| PooToolsSource/MessageKit/PTChatListModel.swift:32 | class | open | open class PTChatListModel: @preconcurrency PTCodableModelProtocol { |
| PooToolsSource/MessageKit/PTChatListModel.swift:37 | var | public | public var messageTimeStamp:TimeInterval = 0 |
| PooToolsSource/MessageKit/PTChatListModel.swift:39 | var | public | public var msgId:String = "" |
| PooToolsSource/MessageKit/PTChatListModel.swift:40 | var | public | public var messageType:PTChatMessageType = .Text |
| PooToolsSource/MessageKit/PTChatListModel.swift:42 | var | public | public var creatorId:String = "" |
| PooToolsSource/MessageKit/PTChatListModel.swift:44 | var | public | @SmartAny public var msgContent:Any? |
| PooToolsSource/MessageKit/PTChatListModel.swift:46 | var | public | public var senderCover:String = "" |
| PooToolsSource/MessageKit/PTChatListModel.swift:48 | var | public | public var messageStatus:PTChatMessageStatus = .Arrived |
| PooToolsSource/MessageKit/PTChatListModel.swift:50 | var | public | public var senderName:String = "" |
| PooToolsSource/MessageKit/PTChatListModel.swift:52 | var | public | public var belongToMe: Bool { |
| PooToolsSource/MessageKit/PTChatListModel.swift:58 | var | public | public var customerCellId:String = "" |
| PooToolsSource/MessageKit/PTChatListModel.swift:60 | var | public | public var isRead:Bool = false |
| PooToolsSource/MessageKit/PTChatListModel.swift:62 | var | public | @SmartAny public var msgExten:Any? |
| PooToolsSource/MessageKit/PTChatListModel.swift:68 | init | public | public init(diffIdentifier: String) { |
| PooToolsSource/MessageKit/PTChatListModel.swift:74 | var | public | public var diffId: String { |
| PooToolsSource/MessageKit/PTChatListModel.swift:84 | var | public | public var diffHash: Int { |
| PooToolsSource/MessageKit/PTChatMapCell.swift:13 | class | public | public class PTChatMapCell: PTChatBaseCell { |
| PooToolsSource/MessageKit/PTChatMapCell.swift:19 | var | public | public var cellModel:PTChatListModel! { |
| PooToolsSource/MessageKit/PTChatMediaCell.swift:15 | class | public | public class PTChatMediaCell: PTChatBaseCell { |
| PooToolsSource/MessageKit/PTChatMediaCell.swift:18 | var | public | public var videoCacheURL:URL? = nil |
| PooToolsSource/MessageKit/PTChatMediaCell.swift:19 | var | public | public var loadMediaURL:URL? = nil |
| PooToolsSource/MessageKit/PTChatMediaCell.swift:20 | var | public | public var needLoadVideo:Bool = false |
| PooToolsSource/MessageKit/PTChatMediaCell.swift:22 | var | public | public var mediaPlayButtonTapCallback:PTActionTask? |
| PooToolsSource/MessageKit/PTChatMediaCell.swift:23 | var | public | public var mediaDownloadFinishCallback:PTActionTask? |
| PooToolsSource/MessageKit/PTChatMediaCell.swift:28 | var | public | public var cellModel: PTChatListModel! { |
| PooToolsSource/MessageKit/PTChatMediaCell.swift:100 | var | public | public var isImage:Bool { |
| PooToolsSource/MessageKit/PTChatMediaCell.swift:306 | func | public | public func mediaDownloadFunction(urlReal:URL) { |
| PooToolsSource/MessageKit/PTChatSystemMessageCell.swift:13 | class | public | public class PTChatSystemMessageCell: PTBaseNormalCell { |
| PooToolsSource/MessageKit/PTChatSystemMessageCell.swift:16 | var | public | public var cellModel:PTChatListModel! { |
| PooToolsSource/MessageKit/PTChatTextCell.swift:12 | typealias | public | public typealias PTAttLabelCallBack = (String) -> Void |
| PooToolsSource/MessageKit/PTChatTextCell.swift:15 | class | public | public class PTChatTextCell: PTChatBaseCell { |
| PooToolsSource/MessageKit/PTChatTextCell.swift:18 | var | public | public var hashtagCallback: PTAttLabelCallBack? |
| PooToolsSource/MessageKit/PTChatTextCell.swift:19 | var | public | public var mentionCallback: PTAttLabelCallBack? |
| PooToolsSource/MessageKit/PTChatTextCell.swift:20 | var | public | public var chinaPhoneCallback: PTAttLabelCallBack? |
| PooToolsSource/MessageKit/PTChatTextCell.swift:21 | var | public | public var urlCallback: PTAttLabelCallBack? |
| PooToolsSource/MessageKit/PTChatTextCell.swift:22 | var | public | public var customCallback: PTAttLabelCallBack? |
| PooToolsSource/MessageKit/PTChatTextCell.swift:24 | var | public | public var cellModel: PTChatListModel! { |
| PooToolsSource/MessageKit/PTChatTypingBubble.swift:11 | class | public | public class PTChatTypingBubble: UIView { |
| PooToolsSource/MessageKit/PTChatTypingBubble.swift:16 | let | public | public let typingIndicator = PTChatTypingIndicator() |
| PooToolsSource/MessageKit/PTChatTypingBubble.swift:17 | let | public | public let contentBubble = UIView() |
| PooToolsSource/MessageKit/PTChatTypingBubble.swift:18 | let | public | public let cornerBubble = PTChatBubbleCircle() |
| PooToolsSource/MessageKit/PTChatTypingBubble.swift:19 | let | public | public let tinyBubble = PTChatBubbleCircle() |
| PooToolsSource/MessageKit/PTChatTypingBubble.swift:21 | var | open | open var isPulseEnabled = true |
| PooToolsSource/MessageKit/PTChatTypingBubble.swift:33 | var | open | open var contentPulseAnimationLayer: CABasicAnimation { |
| PooToolsSource/MessageKit/PTChatTypingBubble.swift:43 | var | open | open var circlePulseAnimationLayer: CABasicAnimation { |
| PooToolsSource/MessageKit/PTChatTypingBubble.swift:67 | func | open | open func setupSubviews() { |
| PooToolsSource/MessageKit/PTChatTypingBubble.swift:108 | func | open | open func startAnimating() { |
| PooToolsSource/MessageKit/PTChatTypingBubble.swift:118 | func | open | open func stopAnimating() { |
| PooToolsSource/MessageKit/PTChatTypingIndicator.swift:11 | class | public | public class PTChatTypingIndicator: UIView { |
| PooToolsSource/MessageKit/PTChatTypingIndicator.swift:24 | var | open | open var dotColor = PTChatConfig.share.dotColor { |
| PooToolsSource/MessageKit/PTChatTypingIndicator.swift:32 | var | open | open var initialOffsetAnimationLayer: CABasicAnimation { |
| PooToolsSource/MessageKit/PTChatTypingIndicator.swift:41 | var | public | public var bounceAnimationLayer: CABasicAnimation { |
| PooToolsSource/MessageKit/PTChatTypingIndicator.swift:52 | var | public | public var opacityAnimationLayer: CABasicAnimation { |
| PooToolsSource/MessageKit/PTChatTypingIndicator.swift:70 | func | public | public func startAnimating() { |
| PooToolsSource/MessageKit/PTChatTypingIndicator.swift:97 | func | public | public func stopAnimating() { |
| PooToolsSource/MessageKit/PTChatTypingIndicator.swift:110 | var | public | public var bounceOffset: CGFloat = 2.5 |
| PooToolsSource/MessageKit/PTChatTypingIndicator.swift:113 | var | public | public var isBounceEnabled = false |
| PooToolsSource/MessageKit/PTChatTypingIndicator.swift:116 | var | public | public var isFadeEnabled = true |
| PooToolsSource/MessageKit/PTChatTypingIndicator.swift:123 | let | public | public let stackView = UIStackView() |
| PooToolsSource/MessageKit/PTChatTypingIndicator.swift:125 | let | public | public let dots: [PTChatBubbleCircle] = { |
| PooToolsSource/MessageKit/PTChatTypingIndicatorCell.swift:11 | class | public | public class PTChatTypingIndicatorCell: PTBaseNormalCell { |
| PooToolsSource/MessageKit/PTChatTypingIndicatorCell.swift:14 | var | public | public var insets = UIEdgeInsets(top: 15, left: 0, bottom: 0, right: 0) |
| PooToolsSource/MessageKit/PTChatTypingIndicatorCell.swift:16 | let | public | public let typingBubble = PTChatTypingBubble() |
| PooToolsSource/MessageKit/PTChatTypingIndicatorCell.swift:28 | func | public | public func setupSubviews() { |
| PooToolsSource/MessageKit/PTChatView.swift:13 | typealias | public | public typealias PTChatHandler = @MainActor (PTChatListModel,IndexPath) -> Void |
| PooToolsSource/MessageKit/PTChatView.swift:14 | typealias | public | public typealias PTChatCellHandler = (_ collectionView:UICollectionView,_ sectionModel:PTSection,_ indexPath:IndexPath,_ baseCell:UICollectionViewCell) -> PTChatBaseCell? |
| PooToolsSource/MessageKit/PTChatView.swift:15 | typealias | public | public typealias PTChatCustomerCellHeightHandler = (_ dataModel:PTChatListModel,_ indexPath:Int) -> CGFloat |
| PooToolsSource/MessageKit/PTChatView.swift:16 | typealias | public | public typealias PTAttCellCallBack = (String,IndexPath,PTChatListModel) -> Void |
| PooToolsSource/MessageKit/PTChatView.swift:17 | typealias | public | public typealias PTCellMenuItemsHandler = (_ cellId:String) -> [String]? |
| PooToolsSource/MessageKit/PTChatView.swift:18 | typealias | public | public typealias PTCellMenuItemsTapCallBack = (_ indexPath:IndexPath,_ cellModel:PTChatListModel,_ itemName:String,_ itemIndex:Int) -> Void |
| PooToolsSource/MessageKit/PTChatView.swift:22 | class | public | public class PTChatView: UIView { |
| PooToolsSource/MessageKit/PTChatView.swift:27 | var | public | public var chatDataArr:[PTChatListModel] = [PTChatListModel]() |
| PooToolsSource/MessageKit/PTChatView.swift:29 | var | public | public var resendMessageHandler:PTChatHandler? = nil |
| PooToolsSource/MessageKit/PTChatView.swift:31 | var | public | public var headerLoadReadyHandler:PTActionTask? = nil |
| PooToolsSource/MessageKit/PTChatView.swift:35 | var | public | public var tapMessageHandler:PTChatHandler? = nil |
| PooToolsSource/MessageKit/PTChatView.swift:37 | var | public | public var userIconTapHandler:PTChatHandler? = nil |
| PooToolsSource/MessageKit/PTChatView.swift:40 | var | public | public var customerCellHandler:PTChatCellHandler? = nil |
| PooToolsSource/MessageKit/PTChatView.swift:42 | var | public | public var customerCellHeightHandler:PTChatCustomerCellHeightHandler? = nil |
| PooToolsSource/MessageKit/PTChatView.swift:44 | var | public | public var attCellUrlTapCallBack:PTAttCellCallBack? = nil |
| PooToolsSource/MessageKit/PTChatView.swift:45 | var | public | public var attCellChinaPhoneTapCallBack:PTAttCellCallBack? = nil |
| PooToolsSource/MessageKit/PTChatView.swift:46 | var | public | public var attCellHashtagTapCallBack:PTAttCellCallBack? = nil |
| PooToolsSource/MessageKit/PTChatView.swift:47 | var | public | public var attCellMentionTapCallBack:PTAttCellCallBack? = nil |
| PooToolsSource/MessageKit/PTChatView.swift:48 | var | public | public var attCellCustomTapCallBack:PTAttCellCallBack? = nil |
| PooToolsSource/MessageKit/PTChatView.swift:49 | var | public | public var messageDownloadedHandler:PTChatHandler? = nil |
| PooToolsSource/MessageKit/PTChatView.swift:52 | var | public | public var cellMenuItemsHandler:PTCellMenuItemsHandler? = nil |
| PooToolsSource/MessageKit/PTChatView.swift:53 | var | public | public var cellMenuItemsTapCallBack:PTCellMenuItemsTapCallBack? = nil |
| PooToolsSource/MessageKit/PTChatView.swift:55 | var | public | public var listTopOffset:CGFloat = 0 { |
| PooToolsSource/MessageKit/PTChatView.swift:61 | var | public | public var listBottomOffset:CGFloat = 0 { |
| PooToolsSource/MessageKit/PTChatView.swift:326 | func | public | public func chatRegisterClass(classs:[String:PTChatBaseCell.Type]) { |
| PooToolsSource/MessageKit/PTChatView.swift:367 | func | public | public func viewReloadData(loadFinish:PTCollectionCallback? = nil) { |
| PooToolsSource/MessageKit/PTChatVoiceCell.swift:13 | class | public | public class PTChatVoiceCell: PTChatBaseCell { |
| PooToolsSource/MessageKit/PTChatVoiceCell.swift:21 | var | public | public var cellModel:PTChatListModel! { |
| PooToolsSource/MessageKit/PTChatVoiceCell.swift:257 | func | public | public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { |
| PooToolsSource/MessageKit/PTChatVoiceCell.swift:261 | func | public | public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) { |
| PooToolsSource/MicPermission/PTPermissionMic.swift:19 | class | public | public class PTPermissionMic: PTPermission { |
| PooToolsSource/MicPermission/PTPermissionMic.swift:22 | var | open | open var usageDescriptionKey: String? { "NSMicrophoneUsageDescription" } |
| PooToolsSource/Motion/PTMotion.swift:12 | enum | public | public enum PTMotionDataSource: String, Sendable { |
| PooToolsSource/Motion/PTMotion.swift:18 | struct | public | public struct PTMotionData: Sendable { |
| PooToolsSource/Motion/PTMotion.swift:19 | var | public | public var currentDataSource: PTMotionDataSource = .iphone |
| PooToolsSource/Motion/PTMotion.swift:22 | var | public | public var stepCount: Int = 0 |
| PooToolsSource/Motion/PTMotion.swift:23 | var | public | public var distance: Double = 0.0 |
| PooToolsSource/Motion/PTMotion.swift:24 | var | public | public var currentPace: Double = 0.0 |
| PooToolsSource/Motion/PTMotion.swift:25 | var | public | public var currentCadence: Double = 0.0 |
| PooToolsSource/Motion/PTMotion.swift:26 | var | public | public var isWalkingPaused: Bool = false |
| PooToolsSource/Motion/PTMotion.swift:27 | var | public | public var confidence: String = "Unknown" |
| PooToolsSource/Motion/PTMotion.swift:28 | var | public | public var status: String = "Unknown" |
| PooToolsSource/Motion/PTMotion.swift:31 | var | public | public var floorsAscended: Int = 0 |
| PooToolsSource/Motion/PTMotion.swift:32 | var | public | public var floorsDescended: Int = 0 |
| PooToolsSource/Motion/PTMotion.swift:33 | var | public | public var relativeAltitude: Double = 0.0 |
| PooToolsSource/Motion/PTMotion.swift:34 | var | public | public var pressure: Double = 0.0 |
| PooToolsSource/Motion/PTMotion.swift:35 | var | public | public var altitudeAlertMessage: String? = nil |
| PooToolsSource/Motion/PTMotion.swift:39 | var | public | public var gForceX: Double = 0.0 |
| PooToolsSource/Motion/PTMotion.swift:40 | var | public | public var gForceY: Double = 0.0 |
| PooToolsSource/Motion/PTMotion.swift:41 | var | public | public var gForceZ: Double = 0.0 |
| PooToolsSource/Motion/PTMotion.swift:44 | var | public | public var pitch: Double = 0.0 |
| PooToolsSource/Motion/PTMotion.swift:45 | var | public | public var roll: Double = 0.0 |
| PooToolsSource/Motion/PTMotion.swift:46 | var | public | public var yaw: Double = 0.0 |
| PooToolsSource/Motion/PTMotion.swift:49 | var | public | public var maxLeftLean: Double = 0.0 |
| PooToolsSource/Motion/PTMotion.swift:50 | var | public | public var maxRightLean: Double = 0.0 |
| PooToolsSource/Motion/PTMotion.swift:51 | var | public | public var isTipOverDetected: Bool = false |
| PooToolsSource/Motion/PTMotion.swift:54 | var | public | public var rotX: Double = 0.0 // 角速度 |
| PooToolsSource/Motion/PTMotion.swift:55 | var | public | public var rotY: Double = 0.0 |
| PooToolsSource/Motion/PTMotion.swift:56 | var | public | public var rotZ: Double = 0.0 |
| PooToolsSource/Motion/PTMotion.swift:57 | var | public | public var gravX: Double = 0.0 // 重力矢量 |
| PooToolsSource/Motion/PTMotion.swift:58 | var | public | public var gravY: Double = 0.0 |
| PooToolsSource/Motion/PTMotion.swift:59 | var | public | public var gravZ: Double = 0.0 |
| PooToolsSource/Motion/PTMotion.swift:60 | var | public | public var quatX: Double = 0.0 // 四元数 |
| PooToolsSource/Motion/PTMotion.swift:61 | var | public | public var quatY: Double = 0.0 |
| PooToolsSource/Motion/PTMotion.swift:62 | var | public | public var quatZ: Double = 0.0 |
| PooToolsSource/Motion/PTMotion.swift:63 | var | public | public var quatW: Double = 0.0 |
| PooToolsSource/Motion/PTMotion.swift:65 | var | public | public var sensorLocation: CMDeviceMotion.SensorLocation? = nil |
| PooToolsSource/Motion/PTMotion.swift:68 | protocol | public | public protocol PTMotionDelegate: AnyObject { |
| PooToolsSource/Motion/PTMotion.swift:81 | class | public | public class PTMotion: NSObject, @unchecked Sendable,CMHeadphoneMotionManagerDelegate { |
| PooToolsSource/Motion/PTMotion.swift:101 | var | public | public var currentSpeedKmh: Double = 0.0 |
| PooToolsSource/Motion/PTMotion.swift:102 | var | public | public var motionStarted:Bool = false |
| PooToolsSource/Motion/PTMotion.swift:118 | func | public | public func addDelegate(_ delegate: PTMotionDelegate) { |
| PooToolsSource/Motion/PTMotion.swift:127 | func | public | public func calibrateZeroPoint() { |
| PooToolsSource/Motion/PTMotion.swift:135 | func | public | public func resetLeanAngles() { |
| PooToolsSource/Motion/PTMotion.swift:143 | func | public | @MainActor public func startMotion(from startDate: Date = Date()) { |
| PooToolsSource/Motion/PTMotion.swift:163 | func | public | public func stopMotion() { |
| PooToolsSource/Motion/PTMotion.swift:203 | func | public | public func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) { |
| PooToolsSource/MotionPermission/PTPermissionMotion.swift:19 | class | public | public class PTPermissionMotion: PTPermission { |
| PooToolsSource/MotionPermission/PTPermissionMotion.swift:22 | var | open | open var usageDescriptionKey: String? { "NSMotionUsageDescription" } |
| PooToolsSource/NFC/PTNFCToolKit.swift:50 | class | public | public class PTNFCToolKit: NSObject { |
| PooToolsSource/NFC/PTNFCToolKit.swift:53 | var | public | public var plzNearReadingMsg = "請將設備靠近 NFC 標籤" |
| PooToolsSource/NFC/PTNFCToolKit.swift:54 | var | public | public var plzNearWritingMsg = "請將設備靠近欲寫入的 NFC 標籤" |
| PooToolsSource/NFC/PTNFCToolKit.swift:55 | var | public | public var plzNear7816Msg = "請靠近支援 ISO7816 的卡片" |
| PooToolsSource/NFC/PTNFCToolKit.swift:56 | var | public | public var miFareErrorMsg = "MiFare 標籤尚未支援寫入/讀取" |
| PooToolsSource/NFC/PTNFCToolKit.swift:57 | var | public | public var connectErrorMsg = "連線失敗: " |
| PooToolsSource/NFC/PTNFCToolKit.swift:58 | var | public | public var apduErrorMsg = "APDU 錯誤: " |
| PooToolsSource/NFC/PTNFCToolKit.swift:59 | var | public | public var apduSuccessMsg = "APDU 回應成功 SW1=%@, SW2=%@" |
| PooToolsSource/NFC/PTNFCToolKit.swift:60 | var | public | public var nfc15693ErrorMsg = "ISO15693 尚未支援" |
| PooToolsSource/NFC/PTNFCToolKit.swift:61 | var | public | public var felicaErrorMsg = "FeliCa 尚未支援" |
| PooToolsSource/NFC/PTNFCToolKit.swift:62 | var | public | public var unknowErrorMsg = "未知標籤" |
| PooToolsSource/NFC/PTNFCToolKit.swift:63 | var | public | public var findErrorMsg = "查詢失敗: " |
| PooToolsSource/NFC/PTNFCToolKit.swift:64 | var | public | public var notSupportNDEFMsg = "不支援 NDEF" |
| PooToolsSource/NFC/PTNFCToolKit.swift:65 | var | public | public var unknowStateMsg = "未知的狀態" |
| PooToolsSource/NFC/PTNFCToolKit.swift:66 | var | public | public var readErrorMsg = "讀取失敗: " |
| PooToolsSource/NFC/PTNFCToolKit.swift:67 | var | public | public var readSuccessMsg = "讀取成功" |
| PooToolsSource/NFC/PTNFCToolKit.swift:68 | var | public | public var unFindMsg = "未發現有效資料" |
| PooToolsSource/NFC/PTNFCToolKit.swift:69 | var | public | public var writingErrorMsg = "寫入失敗: " |
| PooToolsSource/NFC/PTNFCToolKit.swift:70 | var | public | public var writingSuccessMsg = "寫入成功" |
| PooToolsSource/NFC/PTNFCToolKit.swift:71 | var | public | public var lockErrorMsg = "無法鎖定: " |
| PooToolsSource/NFC/PTNFCToolKit.swift:72 | var | public | public var onlyReadMsg = "標籤已鎖定為唯讀" |
| PooToolsSource/NFC/PTNFCToolKit.swift:86 | func | public | public func startReading(onSuccess: @escaping ([NFCNDEFPayload]) -> Void, |
| PooToolsSource/NFC/PTNFCToolKit.swift:102 | func | public | public func startWriting(message: NFCNDEFMessage, |
| PooToolsSource/NFC/PTNFCToolKit.swift:121 | func | public | public func sendAPDU(command: NFCISO7816APDU, |
| PooToolsSource/NetWork/Network.swift:28 | enum | public | public enum PTNetworkError: Error, LocalizedError, CustomNSError, Sendable { |
| PooToolsSource/NetWork/Network.swift:49 | var | public | public var errorDescription: String? { |
| PooToolsSource/NetWork/Network.swift:67 | var | public | public var errorCode: Int { |
| PooToolsSource/NetWork/Network.swift:105 | var | public | public var isReachable: Bool { |
| PooToolsSource/NetWork/Network.swift:111 | var | public | public var isExpensive: Bool { |
| PooToolsSource/NetWork/Network.swift:169 | var | public | public var statusStream: AsyncStream<NetWorkStatus> { |
| PooToolsSource/NetWork/Network.swift:238 | func | public | public func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) { |
| PooToolsSource/NetWork/Network.swift:275 | enum | public | public enum MimeTypeHelper { |
| PooToolsSource/NetWork/Network.swift:296 | protocol | public | public protocol NetworkPlugin: Sendable { |
| PooToolsSource/NetWork/Network.swift:301 | struct | public | public struct CacheObject: Codable { |
| PooToolsSource/NetWork/Network.swift:307 | enum | public | public enum PTNetworkCachePolicy:String, Sendable { |
| PooToolsSource/NetWork/Network.swift:315 | actor | public | public actor NetworkCache { |
| PooToolsSource/NetWork/Network.swift:386 | func | public | public func clearAll() { |
| PooToolsSource/NetWork/Network.swift:392 | func | public | public func cleanIfNeeded() { |
| PooToolsSource/NetWork/Network.swift:489 | init | public | public init() {} |
| PooToolsSource/NetWork/Network.swift:491 | func | public | public func willSend(_ request: inout URLRequest) async { |
| PooToolsSource/NetWork/Network.swift:502 | func | public | public func didReceive(_ result: Result<Data, AFError>, request: URLRequest, response: HTTPURLResponse?) async { |
| PooToolsSource/NetWork/Network.swift:560 | init | public | public init(configuration: PTNetworkConfig = PTNetworkConfig(), |
| PooToolsSource/NetWork/Network.swift:566 | var | public | public var plugins: [NetworkPlugin] { |
| PooToolsSource/NetWork/Network.swift:578 | func | public | public func register(plugin: NetworkPlugin) { |
| PooToolsSource/NetWork/Network.swift:608 | var | public | public var config: PTNetworkConfig { |
| PooToolsSource/NetWork/Network.swift:624 | var | public | public var requestEnvironment: PTNetworkRequestEnvironment { |
| PooToolsSource/NetWork/Network.swift:653 | var | public | public var hud:PTHudView? |
| PooToolsSource/NetWork/Network.swift:654 | var | public | @MainActor public var hudConfig : PTHudConfig { |
| PooToolsSource/NetWork/Network.swift:661 | func | public | public func hudShow() { |
| PooToolsSource/NetWork/Network.swift:671 | func | public | @MainActor public func hudHide(completion:PTActionTask? = nil) { |
| PooToolsSource/NetWork/Network.swift:685 | class | public | @MainActor public class func globalURL() async -> String { |
| PooToolsSource/NetWork/Network.swift:704 | class | public | @MainActor public class func socketGlobalURL() async -> String { |
| PooToolsSource/NetWork/Network.swift:721 | class | public | @MainActor public class func gobalUrl() async -> String { |
| PooToolsSource/NetWork/Network.swift:726 | class | public | @MainActor public class func socketGobalUrl() async -> String { |
| PooToolsSource/NetWork/Network.swift:749 | class | public | public class func requestIPInfoSnapshot(ipAddress: String, |
| PooToolsSource/NetWork/Network.swift:761 | class | public | public class func cancelAllNetworkRequest(completingOnQueue queue: DispatchQueue = .main, completion: (@Sendable () -> Void)? = nil) { |
| PooToolsSource/NetWork/Network.swift:988 | typealias | public | public typealias UploadResponseParser<T> = @Sendable (String, HTTPURLResponse?, Data?) throws -> PTBaseStructModel<T> |
| PooToolsSource/NetWork/Network.swift:1194 | func | public | public func performCodableRequest<T: SmartCodableX & Sendable>( |
| PooToolsSource/NetWork/Network.swift:1585 | class | public | public class func requestCodableBodyAPI<T: SmartCodableX & Sendable>(needGobal: Bool = true, urlStr: String, body: Data, header: HTTPHeaders? = nil, method: HTTPMethod = .post, |
| PooToolsSource/NetWork/Network.swift:1636 | class | public | public class func requestBodyAPI(needGobal: Bool = true, urlStr: String, body: Data, header: HTTPHeaders? = nil, method: HTTPMethod = .post, cachePolicy: PTNetworkCachePolicy? = nil, modelType: Convertible.Type? = nil) async throws -> PTBaseStructModel<Any> { |
| PooToolsSource/NetWork/Network.swift:1714 | func | public | public func get(_ url: String) -> DownloadTask? { tasks[url] } |
| PooToolsSource/NetWork/Network.swift:1837 | func | public | @MainActor public func download(fileUrl: String, saveFilePath: String, queue: DispatchQueue? = .main, progress: FileDownloadProgress? = nil, success: FileDownloadSuccess? = nil, fail: FileDownloadFail? = nil) { |
| PooToolsSource/NetWork/Network.swift:1859 | func | public | @MainActor public func download(fileUrl: String, saveFilePath: String, progress: FileDownloadProgress? = nil) async throws -> URL { |
| PooToolsSource/NetWork/Network.swift:1886 | func | public | public func suspend(fileUrl: String) { Task { await store.get(fileUrl)?.suspend() } } |
| PooToolsSource/NetWork/Network.swift:1887 | func | public | public func resume(fileUrl: String) { Task { await store.get(fileUrl)?.start(session: downloadSession) } } |
| PooToolsSource/NetWork/Network.swift:1888 | func | public | public func cancel(fileUrl: String) { Task { if let task = await store.get(fileUrl) { await store.remove(fileUrl); await task.cancel() } } } |
| PooToolsSource/NetWork/Network.swift:1891 | func | public | public func downloadAsyncStream(fileUrl: String, saveFilePath: String) -> AsyncThrowingStream<(progress: Double, fileURL: URL?), Error> { |
| PooToolsSource/NetWork/Network.swift:1913 | func | public | public func urlSession(_ session:URLSession,task:URLSessionTask,didFinishCollecting metrics: URLSessionTaskMetrics) { |
| PooToolsSource/NetWork/NetworkTypes.swift:5 | let | public | @MainActor public let AppTestMode = "PT App network environment test".localized() |
| PooToolsSource/NetWork/NetworkTypes.swift:6 | let | public | @MainActor public let AppCustomMode = "PT App network environment custom".localized() |
| PooToolsSource/NetWork/NetworkTypes.swift:7 | let | public | @MainActor public let AppDisMode = "PT App network environment distribution".localized() |
| PooToolsSource/NetWork/NetworkTypes.swift:9 | enum | public | public enum NetworkCellularType: String, Sendable { |
| PooToolsSource/NetWork/NetworkTypes.swift:17 | enum | public | public enum NetWorkStatus: Sendable { |
| PooToolsSource/NetWork/NetworkTypes.swift:43 | enum | public | public enum NetWorkEnvironment: Int, Sendable { |
| PooToolsSource/NetWork/NetworkTypes.swift:57 | typealias | public | public typealias NetWorkStatusBlock = @Sendable (NetWorkStatus, NetWorkEnvironment) -> Void |
| PooToolsSource/NetWork/NetworkTypes.swift:58 | typealias | public | public typealias UploadProgress = @MainActor @Sendable (Progress) -> Void |
| PooToolsSource/NetWork/NetworkTypes.swift:59 | typealias | public | public typealias FileDownloadSuccess = @MainActor @Sendable (AFDownloadResponse<URL?>) -> Void |
| PooToolsSource/NetWork/NetworkTypes.swift:60 | typealias | public | public typealias FileDownloadFail = @MainActor @Sendable (Error?) -> Void |
| PooToolsSource/NetWork/NetworkTypes.swift:62 | var | public | public var PTBaseURLMode: NetWorkEnvironment { |
| PooToolsSource/NetWork/NetworkTypes.swift:70 | var | public | public var PTSocketURLMode: NetWorkEnvironment { |
| PooToolsSource/NetWork/NetworkTypes.swift:78 | enum | public | public enum PTNetworkDedupPolicy: Sendable, Equatable { |
| PooToolsSource/NetWork/NetworkTypes.swift:92 | struct | public | public struct RequestKey: Hashable, Sendable { |
| PooToolsSource/NetWork/NetworkTypes.swift:116 | struct | public | public struct PTNetworkConfig: Sendable { |
| PooToolsSource/NetWork/NetworkTypes.swift:117 | var | public | public var requestTimeout: TimeInterval = 20 |
| PooToolsSource/NetWork/NetworkTypes.swift:118 | var | public | public var downloadRequestTimeout: TimeInterval = 5 |
| PooToolsSource/NetWork/NetworkTypes.swift:119 | var | public | public var resourceTimeout: TimeInterval = 3600 |
| PooToolsSource/NetWork/NetworkTypes.swift:121 | var | public | public var serverAddress: String = "" |
| PooToolsSource/NetWork/NetworkTypes.swift:122 | var | public | public var serverAddress_dev: String = "" |
| PooToolsSource/NetWork/NetworkTypes.swift:123 | var | public | public var socketAddress: String = "" |
| PooToolsSource/NetWork/NetworkTypes.swift:124 | var | public | public var socketAddress_dev: String = "" |
| PooToolsSource/NetWork/NetworkTypes.swift:126 | var | public | public var userToken: String = "" |
| PooToolsSource/NetWork/NetworkTypes.swift:127 | var | public | public var retryTimes: Int = 3 |
| PooToolsSource/NetWork/NetworkTypes.swift:128 | var | public | public var retryDelay: TimeInterval = 1.5 |
| PooToolsSource/NetWork/NetworkTypes.swift:129 | var | public | public var retryAPIStatusCode: Int = 502 |
| PooToolsSource/NetWork/NetworkTypes.swift:131 | var | public | public var networkCacheOption: PTNetworkCachePolicy = .cacheElseNetwork |
| PooToolsSource/NetWork/NetworkTypes.swift:132 | var | public | public var networkCacheExpiration: String = "600" |
| PooToolsSource/NetWork/NetworkTypes.swift:133 | var | public | public var networkDedupOption: PTNetworkDedupPolicy = .custom("auto") |
| PooToolsSource/NetWork/NetworkTypes.swift:135 | var | public | public var maxDiskSize: Int64 = 100 * 1024 * 1024 |
| PooToolsSource/NetWork/NetworkTypes.swift:136 | var | public | public var cleanThreshold: Double = 0.7 |
| PooToolsSource/NetWork/NetworkTypes.swift:137 | var | public | public var cleanCachePreSec: TimeInterval = 60 |
| PooToolsSource/NetWork/NetworkTypes.swift:138 | var | public | public var logMaxCount: Double = 3000 |
| PooToolsSource/NetWork/NetworkTypes.swift:144 | var | public | public var netRequsetTime: TimeInterval { |
| PooToolsSource/NetWork/NetworkTypes.swift:150 | var | public | public var downloadRequsetTime: TimeInterval { |
| PooToolsSource/NetWork/NetworkTypes.swift:156 | var | public | public var downloadEndTime: TimeInterval { |
| PooToolsSource/NetWork/NetworkTypes.swift:162 | var | public | public var networkCacheEXPTime: String { |
| PooToolsSource/NetWork/NetworkTypes.swift:168 | var | public | public var networkDudupOption: PTNetworkDedupPolicy { |
| PooToolsSource/NetWork/NetworkTypes.swift:173 | var | public | public var waitsForConnectivity: Bool = true |
| PooToolsSource/NetWork/NetworkTypes.swift:175 | init | public | public init() {} |
| PooToolsSource/NetWork/NetworkTypes.swift:181 | struct | public | public struct PTNetworkRequestEnvironment: Sendable, Equatable { |
| PooToolsSource/NetWork/NetworkTypes.swift:182 | let | public | public let serverAddress: String |
| PooToolsSource/NetWork/NetworkTypes.swift:183 | let | public | public let socketAddress: String |
| PooToolsSource/NetWork/NetworkTypes.swift:184 | let | public | public let userToken: String |
| PooToolsSource/NetWork/NetworkTypes.swift:185 | let | public | public let requestTimeout: TimeInterval |
| PooToolsSource/NetWork/NetworkTypes.swift:186 | let | public | public let downloadRequestTimeout: TimeInterval |
| PooToolsSource/NetWork/NetworkTypes.swift:187 | let | public | public let resourceTimeout: TimeInterval |
| PooToolsSource/NetWork/NetworkTypes.swift:188 | let | public | public let cachePolicy: PTNetworkCachePolicy |
| PooToolsSource/NetWork/NetworkTypes.swift:189 | let | public | public let cacheExpiration: String |
| PooToolsSource/NetWork/NetworkTypes.swift:190 | let | public | public let dedupPolicy: PTNetworkDedupPolicy |
| PooToolsSource/NetWork/NetworkTypes.swift:191 | let | public | public let waitsForConnectivity: Bool |
| PooToolsSource/NetWork/NetworkTypes.swift:193 | init | public | public init(configuration: PTNetworkConfig) { |
| PooToolsSource/NetWork/NetworkTypes.swift:210 | typealias | public | public typealias PTNetworkConfiguration = PTNetworkConfig |
| PooToolsSource/NetWork/NetworkTypes.swift:215 | actor | public | public actor RequestDeduplicator { |
| PooToolsSource/NetWork/NetworkTypes.swift:231 | func | public | public func execute<T: Sendable>( |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedHistoriaModel.swift:11 | class | public | public class PTNetworkSpeedHistoriaModel: PTCodableModelProtocol { |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedHistoriaModel.swift:12 | var | public | public var date:String = "" |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedHistoriaModel.swift:13 | var | public | public var networkType:String = "" |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedHistoriaModel.swift:14 | var | public | public var download:String = "" |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedHistoriaModel.swift:15 | var | public | public var upload:String = "" |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedHistoriaModel.swift:16 | var | public | public var latency:String = "" |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedTestFunction.swift:12 | enum | public | @objc public enum PTNetworkSpeedTestStateType:Int { |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedTestFunction.swift:18 | enum | public | @objc public enum PTNetworkSpeedTestType:Int { |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedTestFunction.swift:26 | class | public | public class PTNetworkSpeedTestFunction: NSObject { |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedTestFunction.swift:31 | var | public | public var netSpeedStateType:PTNetworkSpeedTestStateType = .Free |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedTestFunction.swift:50 | var | public | public var downloadCurrentTask : ((CGFloat)->Void)? |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedTestFunction.swift:51 | var | public | public var uploadCurrentTask : ((CGFloat)->Void)? |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedTestFunction.swift:52 | var | public | public var valueUpdateTask:((PTNetworkSpeedTestType,CGFloat)->Void)? |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedTestFunction.swift:53 | var | public | public var testDone:PTActionTask? |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedTestFunction.swift:55 | var | public | public var downloadTestURL = "http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4" |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedTestFunction.swift:56 | var | public | public var uploadTestURL = "https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable" |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedTestFunction.swift:85 | func | public | public func readyTest() { |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedTestFunction.swift:96 | func | public | public func suspendTest() { |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedTestFunction.swift:103 | func | public | public func saveHistory(jsonString:String) { |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedTestFunction.swift:117 | func | public | public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) { |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedTestFunction.swift:166 | func | public | public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) { |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedTestFunction.swift:180 | func | public | public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) { |
| PooToolsSource/NotificationPermission/PTPermissionNotification.swift:19 | class | public | public class PTPermissionNotification: PTPermission { |
| PooToolsSource/NotificationPermission/PTPermissionNotification.swift:23 | func | public | @MainActor public func authorizationStatus() async throws -> PTPermission.Status { |
| PooToolsSource/OSSKit/OSSSpeech.swift:29 | enum | public | public enum OSSSpeechKitAuthorizationStatus: Int, Sendable { |
| PooToolsSource/OSSKit/OSSSpeech.swift:35 | var | public | @MainActor public var message: String { |
| PooToolsSource/OSSKit/OSSSpeech.swift:46 | enum | public | public enum OSSSpeechKitErrorType: Int, Sendable { |
| PooToolsSource/OSSKit/OSSSpeech.swift:59 | var | public | @MainActor public var errorMessage: String { |
| PooToolsSource/OSSKit/OSSSpeech.swift:75 | var | public | @MainActor public var errorRequestType: String { |
| PooToolsSource/OSSKit/OSSSpeech.swift:89 | var | public | @MainActor public var error: Error? { |
| PooToolsSource/OSSKit/OSSSpeech.swift:96 | enum | public | public enum OSSSpeechRecognitionTaskType: Int, Sendable { |
| PooToolsSource/OSSKit/OSSSpeech.swift:102 | var | public | public var taskType: SFSpeechRecognitionTaskHint { |
| PooToolsSource/OSSKit/OSSSpeech.swift:113 | protocol | public | public protocol OSSSpeechDelegate: AnyObject, Sendable { |
| PooToolsSource/OSSKit/OSSSpeech.swift:126 | class | public | public class OSSSpeech: NSObject, @unchecked Sendable { |
| PooToolsSource/OSSKit/OSSSpeech.swift:157 | var | public | public var srp = SFSpeechRecognizer.self |
| PooToolsSource/OSSKit/OSSSpeech.swift:161 | var | public | public var audioSession: AVAudioSession { |
| PooToolsSource/OSSKit/OSSSpeech.swift:172 | var | public | public var voice: OSSVoice? { |
| PooToolsSource/OSSKit/OSSSpeech.swift:176 | var | public | public var shouldUseOnDeviceRecognition: Bool { |
| PooToolsSource/OSSKit/OSSSpeech.swift:180 | var | public | public var recognitionTaskType: OSSSpeechRecognitionTaskType { |
| PooToolsSource/OSSKit/OSSSpeech.swift:184 | var | public | public var utterance: OSSUtterance? { |
| PooToolsSource/OSSKit/OSSSpeech.swift:188 | var | public | public var saveRecord: Bool { |
| PooToolsSource/OSSKit/OSSSpeech.swift:192 | var | public | public var onUpdate: (([Float]) -> Void)? { |
| PooToolsSource/OSSKit/OSSSpeech.swift:209 | func | public | @MainActor public func speakText(_ text: String? = nil) { |
| PooToolsSource/OSSKit/OSSSpeech.swift:226 | func | public | @MainActor public func speakAttributedText(attributedText: NSAttributedString) { |
| PooToolsSource/OSSKit/OSSSpeech.swift:243 | func | public | public func pauseSpeaking() { |
| PooToolsSource/OSSKit/OSSSpeech.swift:246 | func | public | public func continueSpeaking() { |
| PooToolsSource/OSSKit/OSSSpeech.swift:249 | func | public | public func stopSpeaking() { |
| PooToolsSource/OSSKit/OSSSpeech.swift:292 | func | public | public func recordVoice(requestMicPermission requested: Bool = true) { |
| PooToolsSource/OSSKit/OSSSpeech.swift:302 | func | public | public func endVoiceRecording() { |
| PooToolsSource/OSSKit/OSSSpeech.swift:306 | func | public | public func clearSpokenText() { |
| PooToolsSource/OSSKit/OSSSpeech.swift:546 | func | public | public func getDocumentsDirectory() -> URL { |
| PooToolsSource/OSSKit/OSSSpeech.swift:550 | func | public | public func deleteVoiceFolderItem(url: URL?) { |
| PooToolsSource/OSSKit/OSSSpeech.swift:577 | func | public | public func recognizeSpeech(filePath: URL, finalBlock: (@Sendable (_ text: String) -> Void)? = nil) { |
| PooToolsSource/OSSKit/OSSSpeech.swift:630 | func | public | public func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) { |
| PooToolsSource/OSSKit/OSSSpeech.swift:645 | func | public | public func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) { |
| PooToolsSource/OSSKit/OSSSpeech.swift:650 | func | public | public func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) { |
| PooToolsSource/OSSKit/OSSSpeech.swift:654 | func | public | public func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask) {} |
| PooToolsSource/OSSKit/OSSSpeech.swift:655 | func | public | public func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask) {} |
| PooToolsSource/OSSKit/OSSSpeech.swift:656 | func | public | public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {} |
| PooToolsSource/OSSKit/OSSSpeech.swift:660 | func | public | public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) { |
| PooToolsSource/OSSKit/OSSUtterance.swift:27 | class | public | public class OSSUtterance: AVSpeechUtterance, @unchecked Sendable { |
| PooToolsSource/PDF/PTPDFManager.swift:13 | enum | public | public enum PTPDFManager { |
| PooToolsSource/PDF/PTPDFManager.swift:110 | class | public | public class PDFWithImage: NSObject { |
| PooToolsSource/PDF/PTViewToPDF.swift:12 | class | public | public class PTViewToPDF: NSObject { |
| PooToolsSource/PDF/UIImage+PTpdfEX.swift:63 | enum | public | public enum PDFImageSize { |
| PooToolsSource/PageControl/PTFilledPageControl.swift:11 | typealias | public | public typealias FillPageControlBlock = (_ sender: PTFilledPageControl) -> Void |
| PooToolsSource/PageControl/PTFilledPageControl.swift:15 | class | open | open class PTFilledPageControl: PTBasePageControl { |
| PooToolsSource/PageControl/PTFilledPageControl.swift:35 | var | open | open var inactiveRingWidth: CGFloat = 1 { |
| PooToolsSource/PageControl/PTImagePageControl.swift:12 | typealias | public | public typealias ImagePageControlBlock = (_ sender: PTImagePageControl) -> Void |
| PooToolsSource/PageControl/PTImagePageControl.swift:16 | class | open | open class PTImagePageControl: PTBasePageControl { |
| PooToolsSource/PageControl/PTImagePageControl.swift:23 | var | public | public var currentPageImage: Any = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "lldotInActive") { |
| PooToolsSource/PageControl/PTImagePageControl.swift:29 | var | public | public var pageImage: Any = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "lldotActive") { |
| PooToolsSource/PageControl/PTImagePageControl.swift:36 | var | public | public var dotBaseSize: CGSize = CGSize(width: 8, height: 4) { |
| PooToolsSource/PageControl/PTPageControllable.swift:26 | class | open | open class PTBasePageControl: UIControl { |
| PooToolsSource/PageControl/PTPageControllable.swift:29 | var | open | open var pageCount: Int = 0 { |
| PooToolsSource/PageControl/PTPageControllable.swift:49 | var | open | open var progress: CGFloat = 0 { |
| PooToolsSource/PageControl/PTPageControllable.swift:62 | var | open | open var currentPage: Int { |
| PooToolsSource/PageControl/PTPageControllable.swift:68 | var | open | open var activeTint: UIColor = .white { |
| PooToolsSource/PageControl/PTPageControllable.swift:72 | var | open | open var inactiveTint: UIColor = UIColor(white: 1, alpha: 0.3) { |
| PooToolsSource/PageControl/PTPageControllable.swift:76 | var | open | open var indicatorPadding: CGFloat = 8 { |
| PooToolsSource/PageControl/PTPageControllable.swift:86 | var | open | open var indicatorRadius: CGFloat = 4 { |
| PooToolsSource/PageControl/PTPageControllable.swift:96 | var | public | public var indicatorDiameter: CGFloat { |
| PooToolsSource/PageControl/PTPageControllable.swift:111 | var | open | open var progressAnimationDuration: CFTimeInterval { 0.3 } |
| PooToolsSource/PageControl/PTPageControllable.swift:126 | func | open | open func commonInit() { |
| PooToolsSource/PageControl/PTPageControllable.swift:131 | func | open | open func updateNumberOfPages(_ count: Int) {} |
| PooToolsSource/PageControl/PTPageControllable.swift:132 | func | open | open func updateProgress(_ safeProgress: CGFloat) {} |
| PooToolsSource/PageControl/PTPageControllable.swift:133 | func | open | open func updateAppearance() {} |
| PooToolsSource/PageControl/PTPageControllable.swift:134 | func | open | open func updateLayout() {} |
| PooToolsSource/PageControl/PTPageControllable.swift:167 | func | open | open func setProgress(_ newProgress: CGFloat, animated: Bool) { |
| PooToolsSource/PageControl/PTPageControllable.swift:278 | func | public | public func getStartX(totalWidth: CGFloat) -> CGFloat { |
| PooToolsSource/PageControl/PTPageControllable.swift:283 | func | public | public func getYCenter(itemHeight: CGFloat) -> CGFloat { |
| PooToolsSource/PageControl/PTPageControllable.swift:288 | func | public | public func getTargetPage(for touchLocation: CGPoint, totalWidth: CGFloat, unitWidth: CGFloat) -> Int { |
| PooToolsSource/PageControl/PTPageControllable.swift:301 | protocol | public | public protocol PTPageControllable : AnyObject { |
| PooToolsSource/PageControl/PTPageControllable.swift:308 | protocol | public | public protocol PTPageProgressControllable: PTPageControllable { |
| PooToolsSource/PageControl/PTPageControllable.swift:313 | func | public | public func setCurrentPage(index: Int) { |
| PooToolsSource/PageControl/PTPageControllable.swift:317 | func | public | public func update(currentPage: Int, totalPages: Int) { |
| PooToolsSource/PageControl/PTPageControllable.swift:324 | func | public | public func setCurrentPage(index: Int) { |
| PooToolsSource/PageControl/PTPageControllable.swift:328 | func | public | public func update(currentPage: Int, totalPages: Int) { |
| PooToolsSource/PageControl/PTPageControllable.swift:335 | func | public | public func setCurrentPage(index: Int) { |
| PooToolsSource/PageControl/PTPageControllable.swift:339 | func | public | public func update(currentPage: Int, totalPages: Int) { |
| PooToolsSource/PageControl/PTPageControllable.swift:346 | func | public | public func setCurrentPage(index: Int) { |
| PooToolsSource/PageControl/PTPageControllable.swift:350 | func | public | public func update(currentPage: Int, totalPages: Int) { |
| PooToolsSource/PageControl/PTPageControllable.swift:357 | func | public | public func setCurrentPage(index: Int) { |
| PooToolsSource/PageControl/PTPageControllable.swift:361 | func | public | public func update(currentPage: Int, totalPages: Int) { |
| PooToolsSource/PageControl/PTPageControllable.swift:368 | func | public | public func setCurrentPage(index: Int) { |
| PooToolsSource/PageControl/PTPageControllable.swift:372 | func | public | public func update(currentPage: Int, totalPages: Int) { |
| PooToolsSource/PageControl/PTPillPageControl.swift:11 | typealias | public | public typealias PillPageControlBlock = (_ sender: PTPillPageControl) -> Void |
| PooToolsSource/PageControl/PTPillPageControl.swift:15 | class | open | open class PTPillPageControl: PTBasePageControl { |
| PooToolsSource/PageControl/PTPillPageControl.swift:28 | var | open | open var pillSize: CGSize = CGSize(width: 20, height: 2.5) { |
| PooToolsSource/PageControl/PTScrollingPageControl.swift:11 | typealias | public | public typealias ScrollingPageControlBlock = (_ sender: PTScrollingPageControl) -> Void |
| PooToolsSource/PageControl/PTScrollingPageControl.swift:15 | class | open | open class PTScrollingPageControl: PTBasePageControl { |
| PooToolsSource/PageControl/PTScrollingPageControl.swift:20 | var | open | open var ringTint: UIColor? { |
| PooToolsSource/PageControl/PTScrollingPageControl.swift:33 | var | open | open var ringRadius: CGFloat = 10 { |
| PooToolsSource/PageControl/PTSnakePageControl.swift:11 | typealias | public | public typealias SnakePageControlBlock = (_ sender: PTSnakePageControl) -> Void |
| PooToolsSource/PageControl/PTSnakePageControl.swift:15 | class | open | open class PTSnakePageControl: PTBasePageControl { |
| PooToolsSource/PermissionCore/PTPermission.swift:16 | class | open | open class PTPermission { |
| PooToolsSource/PermissionCore/PTPermission.swift:18 | var | open | open var authorized: Bool { |
| PooToolsSource/PermissionCore/PTPermission.swift:22 | var | open | open var denied: Bool { |
| PooToolsSource/PermissionCore/PTPermission.swift:26 | var | open | open var notDetermined: Bool { |
| PooToolsSource/PermissionCore/PTPermission.swift:30 | var | open | open var debugName: String { |
| PooToolsSource/PermissionCore/PTPermission.swift:34 | var | open | @MainActor open var localisedName: String { |
| PooToolsSource/PermissionCore/PTPermission.swift:44 | func | open | open func openSettingPage() { |
| PooToolsSource/PermissionCore/PTPermission.swift:54 | func | open | open func openSettings() { |
| PooToolsSource/PermissionCore/PTPermission.swift:61 | func | public | public func currentStatus() -> Status { |
| PooToolsSource/PermissionCore/PTPermission.swift:67 | var | open | open var kind: PTPermission.Kind { |
| PooToolsSource/PermissionCore/PTPermission.swift:71 | var | open | open var status: PTPermission.Status { |
| PooToolsSource/PermissionCore/PTPermission.swift:75 | func | open | open func request(completion: @escaping PTActionTask) { |
| PooToolsSource/PermissionCore/PTPermission.swift:210 | func | public | public func requestStatus() async -> Status { |
| PooToolsSource/PermissionCore/PTPermission.swift:234 | func | public | public func request() async { |
| PooToolsSource/PermissionCore/PTPermission.swift:238 | var | open | open var canBePresentWithCustomInterface: Bool { |
| PooToolsSource/PermissionCore/PTPermission.swift:244 | init | public | public init() {} |
| PooToolsSource/PermissionCore/PTPermission.swift:248 | enum | public | @objc public enum Status: Int, CustomStringConvertible, Sendable { |
| PooToolsSource/PermissionCore/PTPermission.swift:255 | var | public | public var description: String { |
| PooToolsSource/PermissionCore/PTPermission.swift:265 | enum | public | public enum Kind: Sendable { |
| PooToolsSource/PermissionCore/PTPermission.swift:284 | var | public | public var name: String { |
| PooToolsSource/PermissionCore/PTPermission.swift:326 | enum | public | public enum CalendarAccess: Sendable { |
| PooToolsSource/PermissionCore/PTPermission.swift:332 | enum | public | public enum LocationAccess: Sendable { |
| PooToolsSource/PermissionCore/PTPermissionHeader.swift:19 | class | open | open class func cellHeight()->CGFloat { |
| PooToolsSource/PermissionCore/PTPermissionModel.swift:13 | class | public | public class PTPermissionModel: NSObject { |
| PooToolsSource/PermissionCore/PTPermissionModel.swift:17 | var | public | public var name: String = "" |
| PooToolsSource/PermissionCore/PTPermissionModel.swift:18 | var | public | public var desc:String = "" |
| PooToolsSource/PermissionCore/PTPermissionModel.swift:19 | var | public | public var type: PTPermission.Kind = .camera |
| PooToolsSource/PermissionCore/PTPermissionSettingViewController.swift:14 | class | public | public class PTPermissionSettingViewController: PTBaseViewController { |
| PooToolsSource/PermissionCore/PTPermissionSettingViewController.swift:111 | func | public | public func permissionShow(vc:UIViewController) { |
| PooToolsSource/PermissionCore/PTPermissionViewController.swift:18 | class | public | public class PTPermissionStatic:NSObject { |
| PooToolsSource/PermissionCore/PTPermissionViewController.swift:20 | var | public | public var permissionModels:[PTPermissionModel] = [PTPermissionModel]() |
| PooToolsSource/PermissionCore/PTPermissionViewController.swift:21 | var | public | public var permissionSettingFont:UIFont = .appfont(size: 16) |
| PooToolsSource/PermissionCore/PTPermissionViewController.swift:26 | class | public | public class PTPermissionViewController: PTListViewController { |
| PooToolsSource/PermissionCore/PTPermissionViewController.swift:31 | var | public | public var viewDismissBlock:PTActionTask? |
| PooToolsSource/PermissionCore/PTPermissionViewController.swift:405 | func | public | public func permissionShow(vc:UIViewController) { |
| PooToolsSource/PhoneInfo/PTPhoneNetWorkInfo.swift:20 | class | public | public class PTPhoneNetWorkInfo:NSObject { |
| PooToolsSource/PhoneInfo/PTPhoneNetWorkInfo.swift:22 | struct | public | public struct NetworkInterfaceInfo { |
| PooToolsSource/PhoneInfo/PTPhoneNetWorkInfo.swift:28 | class | public | public class func ipv4String() -> String { |
| PooToolsSource/PhotoLibraryPermission/PTPermissionPhotoLibrary.swift:18 | class | public | public class PTPermissionPhotoLibrary: PTPermission { |
| PooToolsSource/PhotoLibraryPermission/PTPermissionPhotoLibrary.swift:22 | var | open | open var fullAccessUsageDescriptionKey: String? { |
| PooToolsSource/PhotoLibraryPermission/PTPermissionPhotoLibrary.swift:26 | var | open | open var addingOnlyUsageDescriptionKey: String? { |
| PooToolsSource/PhotoPicker/PTMediaLibCameraContainerViewController.swift:20 | class | public | public class PTMediaLibCameraContainerViewController: PTBaseViewController { |
| PooToolsSource/PhotoPicker/PTMediaLibCameraContainerViewController.swift:26 | let | public | public let picker = UIImagePickerController() |
| PooToolsSource/PhotoPicker/PTMediaLibCameraContainerViewController.swift:30 | var | public | public var cameraOptions: PTMediaLibCameraOptions? |
| PooToolsSource/PhotoPicker/PTMediaLibCameraContainerViewController.swift:31 | var | public | public var handleNewAssetCallback:((_ asset: PHAsset) -> Void)? |
| PooToolsSource/PhotoPicker/PTMediaLibCameraContainerViewController.swift:32 | var | public | public var handleCameraFailureCallback: (@MainActor @Sendable (PTSystemMediaPickerError) -> Void)? |
| PooToolsSource/PhotoPicker/PTMediaLibCameraContainerViewController.swift:100 | func | public | public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) { |
| PooToolsSource/PhotoPicker/PTMediaLibCameraContainerViewController.swift:143 | func | public | public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:24 | enum | public | @objc public enum PTPhotoBrowserStyle: Int { |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:35 | enum | public | public enum PTMediaLibImageFilter: Sendable, Equatable { |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:44 | struct | public | public struct PTMediaLibCameraOptions: Sendable, Equatable { |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:45 | var | public | public var allowTakePhoto: Bool |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:46 | var | public | public var allowRecordVideo: Bool |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:47 | var | public | public var maxRecordDuration: Int |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:49 | init | public | public init(allowTakePhoto: Bool = true, |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:61 | struct | public | public struct PTMediaLibSelectionOptions: Sendable, Equatable { |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:62 | var | public | public var allowSelectImage: Bool |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:63 | var | public | public var allowSelectVideo: Bool |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:64 | var | public | public var allowSelectGif: Bool |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:65 | var | public | public var maxSelectCount: Int |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:66 | var | public | public var allowEditImage: Bool |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:67 | var | public | public var allowMixSelect: Bool |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:68 | var | public | public var allowTakePhotoInLibrary: Bool |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:69 | var | public | public var cameraOptions: PTMediaLibCameraOptions |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:70 | var | public | public var imageFilter: PTMediaLibImageFilter |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:71 | var | public | public var minVideoSelectCount: Int |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:72 | var | public | public var maxVideoSelectCount: Int |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:73 | var | public | public var minSelectVideoDuration: Int |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:74 | var | public | public var maxSelectVideoDuration: Int |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:75 | var | public | public var minSelectVideoDataSize: CGFloat |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:76 | var | public | public var maxSelectVideoDataSize: CGFloat |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:77 | var | public | public var downloadVideoBeforeSelecting: Bool |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:78 | var | public | public var allowEditVideo: Bool |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:79 | var | public | public var saveNewImageAfterEdit: Bool |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:80 | var | public | public var allowSelectOriginal: Bool |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:81 | var | public | public var alwaysRequestOriginal: Bool |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:82 | var | public | public var showSelectBtnWhenSingleSelect: Bool |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:83 | var | public | public var sortAscending: Bool |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:84 | var | public | public var cameraCellAtTop: Bool |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:86 | init | public | public init(allowSelectImage: Bool = true, |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:196 | class | public | public class PTMediaLibConfig:NSObject { |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:199 | typealias | public | public typealias KBUnit = CGFloat |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:201 | var | public | @PTClampedPropertyWrapper(range: 1...5) public var videoDownloadBorderWidth:CGFloat = 1.5 |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:204 | var | public | public var callbackDirectlyAfterTakingPhoto = false |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:207 | var | public | public var sortAscending = true |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:211 | var | public | public var allowSelectGif = true |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:214 | var | public | public var saveNewImageAfterEdit = true |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:217 | var | public | public var allowSelectOriginal = true |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:220 | var | public | public var alwaysRequestOriginal = false |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:223 | var | public | public var cameraConfiguration = PTCameraConfig() |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:228 | var | public | public var allowTakePhotoInLibrary: Bool { |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:238 | var | public | public var allowSelectImage = true |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:240 | var | public | public var allowSelectVideo = true |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:242 | var | public | public var allowOnlySelectLivePhoto = false |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:244 | var | open | open var allowOnlySelectRegularImage = false |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:247 | var | public | public var useCustomCamera = true |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:249 | var | public | public var maxPreviewCount = 9 |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:250 | var | public | public var allowMixSelect = true |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:253 | var | public | public var maxSelectCount: Int { |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:264 | var | public | public var minVideoSelectCount: Int { |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:276 | var | public | public var maxVideoSelectCount: Int { |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:290 | var | public | public var showSelectBtnWhenSingleSelect = false |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:291 | var | public | public var didDeselectAsset: ((PHAsset) -> Void)? |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:292 | var | public | public var canSelectAsset: ((PHAsset) -> Bool)? |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:294 | var | public | public var didSelectAsset: ((PHAsset) -> Void)? |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:298 | var | public | public var maxRecordDuration: Int { |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:309 | var | public | public var maxSelectVideoDuration: PTCameraFilterConfig.Second = 120 |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:311 | var | public | public var minSelectVideoDuration: PTCameraFilterConfig.Second = 0 |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:314 | var | public | public var maxSelectVideoDuration: Int = 120 |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:316 | var | public | public var minSelectVideoDuration: Int = 0 |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:319 | var | public | public var maxSelectVideoDataSize: PTMediaLibConfig.KBUnit = .greatestFiniteMagnitude |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:322 | var | public | public var minSelectVideoDataSize: PTMediaLibConfig.KBUnit = 0 |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:323 | var | public | public var downloadVideoBeforeSelecting = false |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:327 | var | public | public var editAfterSelectThumbnailImage = false |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:329 | var | public | public var allowEditImage: Bool { |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:339 | var | public | public var allowEditVideo: Bool { |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:347 | var | public | public var cropVideoAfterSelectThumbnail = true |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:351 | class | public | public class PTMediaLibUIConfig:NSObject { |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:354 | var | public | public var sortAscending = false |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:355 | var | public | public var style: PTPhotoBrowserStyle = .embedAlbumList |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:356 | var | public | public var animateSelectBtnWhenSelectInThumbVC = false |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:357 | var | public | public var showInvalidMask = true |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:358 | var | public | public var shortIsTop:Bool = true |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:363 | var | public | public var alertTitle:String = "PT Alert Opps".localized() |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:364 | var | public | public var alertDoingTitle:String = "PT Alert Doning".localized() |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:365 | var | public | public var takePhotoError:String = "PT Photo picker can not take photo".localized() |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:366 | var | public | public var cameraError:String = "PT Photo picker bad".localized() |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:367 | var | public | public var saveImageError:String = "PT Photo picker save image error".localized() |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:368 | var | public | public var saveVideoError:String = "PT Photo picker save video error".localized() |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:369 | var | public | public var downloadTimeOutError:String = "PT Photo picker time out".localized() |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:370 | var | public | public var mediaCoutError:String = "PT Photo picker select cout more than".localized() |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:371 | var | public | public var videoTimeMoreError:String = "PT Photo picker video time more than".localized() |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:372 | var | public | public var videoTimeLessError:String = "PT Photo picker video time less than".localized() |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:373 | var | public | public var videoSizeMoreError:String = "PT Photo picker video size more than".localized() |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:374 | var | public | public var videoSizeLessError:String = "PT Photo picker video size less than".localized() |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:375 | var | public | public var mediaCount:String = "PT Photo picker selected count".localized() |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:376 | var | public | public var mediaCountMax:String = "PT Photo picker video select more than max".localized() |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:377 | var | public | public var mediaCountMin:String = "PT Photo picker video select less than min".localized() |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:378 | var | public | public var backImage:UIImage = "❌".emojiToImage(emojiFont: .appfont(size: 20)) |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:379 | var | public | public var submitImage:UIImage = "✅".emojiToImage(emojiFont: .appfont(size: 20)) |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:380 | var | public | public var arrowDownImage:UIImage = "🔽".emojiToImage(emojiFont: .appfont(size: 10)) |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:381 | var | public | public var albumListNavName:String = "PT Photo picker album list title".localized() |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:382 | var | public | public var selectLibTitleFont:UIFont = .appfont(size: 15) |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:383 | var | public | public var selectLibSubTitleFont:UIFont = .appfont(size: 12) |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:386 | var | public | public var themeColor: UIColor = .purple |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:387 | var | public | public var selectedBorderColor:UIColor = UIColor.purple |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:391 | var | public | public var cellVideoTimeFont:UIFont = .appfont(size: 14) |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:392 | var | public | public var cellVideoImage:UIImage = UIImage(.video) |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:393 | var | public | public var cellLivePhotoImage:UIImage = UIImage(.livephoto) |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:394 | var | public | public var cellEditImage:UIImage = UIImage(.pencil) |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:395 | var | public | public var cellSelectedIndexFont:UIFont = .appfont(size: 12) |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:399 | var | public | public var cameraImage:UIImage = "📸".emojiToImage(emojiFont: .appfont(size: 24)) |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:404 | var | public | public var ablumListBackImage:UIImage = "❌".emojiToImage(emojiFont: .appfont(size: 20)) |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:405 | var | public | public var albumEmptyImage:UIImage = UIImage(.exclamationmark.triangle) |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:406 | var | public | public var albumEmptyTitleFont:UIFont = .appfont(size: 20,bold: true) |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:407 | var | public | public var albumEmptyDescFont:UIFont = .appfont(size: 18) |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:408 | var | public | public var albumEmptyTitle:String = "PT Alert Opps".localized() |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:409 | var | public | public var albumEmptySubDesc:String = "PT Photo picker empty media".localized() |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:414 | var | public | public var albumSelectedImage:UIImage = "✅".emojiToImage(emojiFont: .appfont(size: 15)) |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:415 | var | public | public var albumCellTitleFont:UIFont = .appfont(size: 18,bold: true) |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:416 | var | public | public var albumCellDescFont:UIFont = .appfont(size: 14) |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:421 | class | public | public class PTCameraConfig: NSObject { |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:424 | var | public | public var allowTakePhoto: Bool { |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:435 | var | public | public var allowRecordVideo: Bool { |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:445 | var | public | public var sessionPreset: AVCaptureSession.Preset = .hd1920x1080 |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:449 | var | public | public var showFlashSwitch = true |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:452 | var | public | public var allowSwitchCamera = true |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:18 | class | public | public class PTMediaLibListModel: NSObject { |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:19 | let | public | public let title: String |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:21 | var | public | public var count: Int { |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:25 | var | public | public var result: PHFetchResult<PHAsset> |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:27 | let | public | public let collection: PHAssetCollection |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:29 | let | public | public let option: PHFetchOptions |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:31 | let | public | public let isCameraRoll: Bool |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:36 | let | public | public let selectionOptions: PTMediaLibSelectionOptions |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:38 | var | public | public var headImageAsset: PHAsset? { |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:42 | var | public | public var models: [PTMediaModel] = [] |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:50 | init | public | public init(title: String, |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:65 | func | public | public func refetchPhotos() { |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:93 | let | public | public let ident: String |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:95 | let | public | public let asset: PHAsset |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:97 | var | public | public var type: PTMediaModel.MediaType = .unknown |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:99 | var | public | public var duration = "" |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:101 | var | public | public var isSelected = false |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:105 | var | public | public var dataSize: PTMediaLibConfig.KBUnit? { |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:116 | var | public | public var avEditorOutputItem:AVPlayerItem? |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:120 | var | public | public var editImage: UIImage? { |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:137 | var | public | public var second: Int { |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:144 | var | public | public var whRatio: CGFloat { |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:151 | var | public | @MainActor public var previewSize: CGSize { |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:166 | var | public | public var editImageModel: PTEditModel? |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:169 | init | public | public init(asset: PHAsset) { |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:180 | func | public | public func transformAssetType(for asset: PHAsset) -> PTMediaModel.MediaType { |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:197 | func | public | public func transformDuration(for asset: PHAsset) -> String { |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:236 | class | public | public class PTResultModel: NSObject { |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:237 | let | public | @objc public let asset: PHAsset |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:239 | let | public | @objc public let image: UIImage |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:242 | let | public | @objc public let isEdited: Bool |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:246 | let | public | @objc public let editModel: PTEditModel? |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:250 | let | public | @objc public let index: Int |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:252 | let | public | @objc public let avEditorOutputItem:AVPlayerItem? |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:255 | init | public | @objc public init(asset: PHAsset, image: UIImage, isEdited: Bool, editModel: PTEditModel? = nil,avEditorOutputItem: AVPlayerItem? = nil, index: Int) { |
| PooToolsSource/PhotoPicker/PTMediaLibListModel.swift:265 | init | public | @objc public init(asset: PHAsset, image: UIImage, isEdited: Bool,avEditorOutputItem: AVPlayerItem? = nil, index: Int) { |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:26 | struct | public | public struct PTSendableDictionaryBox: @unchecked Sendable { |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:27 | let | public | public let info: [AnyHashable: Any]? |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:29 | init | public | public init(_ info: [AnyHashable: Any]?) { |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:77 | enum | public | public enum PTMediaImageRequestError: Error, LocalizedError, Sendable { |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:81 | var | public | public var errorDescription: String? { |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:90 | struct | public | public struct PTMediaImageRequestResult { |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:91 | let | public | public let image: UIImage? |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:92 | let | public | public let isDegraded: Bool |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:93 | let | public | public let isCancelled: Bool |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:94 | let | public | public let error: PTMediaImageRequestError? |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:96 | init | public | public init(image: UIImage?, |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:108 | struct | public | public struct PTMediaImageDataRequestResult { |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:109 | let | public | public let data: Data? |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:110 | let | public | public let info: [AnyHashable: Any]? |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:111 | let | public | public let isDegraded: Bool |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:112 | let | public | public let isCancelled: Bool |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:113 | let | public | public let error: PTMediaImageRequestError? |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:115 | init | public | public init(data: Data?, |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:131 | struct | public | public struct PTMediaVideoRequestResult { |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:132 | let | public | public let playerItem: AVPlayerItem? |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:133 | let | public | public let info: [AnyHashable: Any]? |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:134 | let | public | public let isDegraded: Bool |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:135 | let | public | public let isCancelled: Bool |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:136 | let | public | public let error: PTMediaImageRequestError? |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:138 | init | public | public init(playerItem: AVPlayerItem?, |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:334 | class | public | public class PTMediaLibManager: NSObject { |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:337 | class | public | public class func saveVideoToAlbum(url: URL, completion: (@Sendable (Bool, PHAsset?) -> Void)?) { |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:352 | class | public | public class func fetchImage(for asset: PHAsset, size: CGSize, progress: (@Sendable (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping @Sendable (UIImage?, Bool) -> Void) -> PHImageRequestID { |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:359 | class | public | public class func requestImage(for asset: PHAsset, |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:419 | class | public | public class func fetchOriginalImage(for asset: PHAsset, progress: (@Sendable (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping @Sendable (UIImage?, Bool) -> Void) -> PHImageRequestID { |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:426 | class | public | public class func fetchOriginalImageData(for asset: PHAsset, progress: (@Sendable (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping @MainActor @Sendable (Data, [AnyHashable: Any]?, Bool) -> Void) -> PHImageRequestID { |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:435 | class | public | public class func requestImageData(for asset: PHAsset, |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:537 | class | public | public class func fetchPhoto(in result: PHFetchResult<PHAsset>, |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:562 | class | public | public class func fetchPhoto(in result: PHFetchResult<PHAsset>, |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:625 | class | public | public class func getCameraRollAlbum(options: PTMediaLibSelectionOptions, |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:646 | class | public | public class func getCameraRollAlbum(allowSelectImage: Bool, |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:662 | class | public | public class func getPhotoAlbumList(options: PTMediaLibSelectionOptions, |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:701 | class | public | public class func getPhotoAlbumList(ascending: Bool, |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:715 | class | public | public class func fetchAssetSize(for asset: PHAsset) -> PTMediaLibConfig.KBUnit? { |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:724 | class | public | public class func fetchAVAsset(forVideo asset: PHAsset, completion: @escaping @MainActor @Sendable (AVAsset?, [AnyHashable: Any]?) -> Void) -> PHImageRequestID { |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:751 | class | public | public class func requestVideo(for asset: PHAsset, |
| PooToolsSource/PhotoPicker/PTMediaLibManager.swift:814 | class | public | public class func fetchVideo(for asset: PHAsset, |
| PooToolsSource/PhotoPicker/PTMediaLibViewController.swift:23 | class | public | public class PTMediaLibView: UIView { |
| PooToolsSource/PhotoPicker/PTMediaLibViewController.swift:26 | var | public | public var updateTitle: PTActionTask? |
| PooToolsSource/PhotoPicker/PTMediaLibViewController.swift:459 | func | public | public func photoLibraryDidChange(_ changeInstance: PHChange) { |
| PooToolsSource/PhotoPicker/PTMediaLibViewController.swift:695 | class | public | public class PTMediaLibViewController: PTBaseViewController { |
| PooToolsSource/PhotoPicker/PTMediaLibViewController.swift:698 | var | public | public var selectedHudStatusBlock: PTBoolTask? |
| PooToolsSource/PhotoPicker/PTMediaLibViewController.swift:699 | var | public | public var selectImageBlock: (([PTResultModel], Bool) -> Void)? |
| PooToolsSource/PhotoPicker/PTMediaLibViewController.swift:700 | var | public | public var selectImageRequestErrorBlock: (([PHAsset], [Int]) -> Void)? |
| PooToolsSource/PhotoPicker/PTMediaLibViewController.swift:705 | var | public | public var selectionOptions: PTMediaLibSelectionOptions? |
| PooToolsSource/PhotoPicker/PTMediaLibViewController.swift:997 | func | public | public func mediaLibShow() { |
| PooToolsSource/PhotoPicker/PTMediaLibViewController.swift:1047 | func | public | public func requestSelectPhoto(viewController: UIViewController? = nil) { |
| PooToolsSource/PhotoPicker/PTMediaLibViewController.swift:1163 | func | public | public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { |
| PooToolsSource/PhotoPicker/PTMediaLibViewController.swift:1167 | func | public | public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) { |
| PooToolsSource/PhotoPicker/PTMediaSaveUI.swift:20 | typealias | public | public typealias PTImagePicker = PooToolsImagePicker.PTImagePicker |
| PooToolsSource/PhotoPicker/PTMediaSaveUI.swift:21 | typealias | public | public typealias PTImagePickerObject = PooToolsImagePicker.PTImagePickerObject |
| PooToolsSource/PhotoPicker/PTMediaSaveUI.swift:22 | typealias | public | public typealias PTAlbumObject = PooToolsImagePicker.PTAlbumObject |
| PooToolsSource/PhotoPicker/PTMediaSaveUI.swift:23 | typealias | public | public typealias PTPhotoObject = PooToolsImagePicker.PTPhotoObject |
| PooToolsSource/Picker/PTBasePickerView.swift:17 | protocol | public | public protocol PTPickerStringModel: Sendable { |
| PooToolsSource/Picker/PTBasePickerView.swift:24 | var | public | public var pickerDisplayText: String { return self } |
| PooToolsSource/Picker/PTBasePickerView.swift:29 | protocol | public | public protocol PTTreePickerModel: PTPickerStringModel { |
| PooToolsSource/Picker/PTBasePickerView.swift:34 | struct | public | public struct PTPickerResult: Sendable { |
| PooToolsSource/Picker/PTBasePickerView.swift:36 | let | public | public let index: Int |
| PooToolsSource/Picker/PTBasePickerView.swift:38 | let | public | public let value: String |
| PooToolsSource/Picker/PTBasePickerView.swift:40 | let | public | public let originalModel: PTPickerStringModel |
| PooToolsSource/Picker/PTBasePickerView.swift:47 | enum | public | public enum PTDatePickerMode: Sendable { |
| PooToolsSource/Picker/PTBasePickerView.swift:84 | enum | public | public enum PTDatePickerConfigurationError: Error, Sendable, Equatable { |
| PooToolsSource/Picker/PTBasePickerView.swift:90 | struct | public | public struct PTPickerStyle: Sendable { |
| PooToolsSource/Picker/PTBasePickerView.swift:94 | var | public | public var toolbarBackgroundColor: UIColor = .secondarySystemBackground |
| PooToolsSource/Picker/PTBasePickerView.swift:96 | var | public | public var containerBackgroundColor: UIColor = .clear |
| PooToolsSource/Picker/PTBasePickerView.swift:99 | var | public | public var cancelText: String = "取消" |
| PooToolsSource/Picker/PTBasePickerView.swift:100 | var | public | public var cancelTextColor: UIColor = .systemGray |
| PooToolsSource/Picker/PTBasePickerView.swift:101 | var | public | public var cancelTextFont: UIFont = .systemFont(ofSize: 16) |
| PooToolsSource/Picker/PTBasePickerView.swift:104 | var | public | public var confirmText: String = "確認" |
| PooToolsSource/Picker/PTBasePickerView.swift:105 | var | public | public var confirmTextColor: UIColor = .systemBlue |
| PooToolsSource/Picker/PTBasePickerView.swift:106 | var | public | public var confirmTextFont: UIFont = .systemFont(ofSize: 16) |
| PooToolsSource/Picker/PTBasePickerView.swift:109 | var | public | public var titleTextColor: UIColor = .label |
| PooToolsSource/Picker/PTBasePickerView.swift:110 | var | public | public var titleTextFont: UIFont = .systemFont(ofSize: 16, weight: .medium) |
| PooToolsSource/Picker/PTBasePickerView.swift:113 | var | public | public var pickerTextColor: UIColor = .label |
| PooToolsSource/Picker/PTBasePickerView.swift:114 | var | public | public var pickerTextFont: UIFont = .systemFont(ofSize: 16, weight: .medium) |
| PooToolsSource/Picker/PTBasePickerView.swift:115 | var | public | public var pickerRowHeight: CGFloat = 44.0 |
| PooToolsSource/Picker/PTBasePickerView.swift:117 | var | public | public var pickerBackgroundColor: UIColor = .systemBackground |
| PooToolsSource/Picker/PTBasePickerView.swift:122 | var | public | public var visualStyle: PTVisualStyle = .automatic |
| PooToolsSource/Picker/PTBasePickerView.swift:124 | var | public | public var toolBarTopBottomSpacing:CGFloat = 2.5 |
| PooToolsSource/Picker/PTBasePickerView.swift:126 | var | public | public var containerCornerRaidus:CGFloat = 16 |
| PooToolsSource/Picker/PTBasePickerView.swift:127 | var | public | public var pickerContainerCornerRaidus:CGFloat = 16 |
| PooToolsSource/Picker/PTBasePickerView.swift:132 | init | public | public init() {} |
| PooToolsSource/Picker/PTBasePickerView.swift:136 | class | open | open class PTBasePickerView: UIView { |
| PooToolsSource/Picker/PTBasePickerView.swift:139 | let | public | public let backgroundView = UIView() |
| PooToolsSource/Picker/PTBasePickerView.swift:141 | let | public | public let containerView = UIView() |
| PooToolsSource/Picker/PTBasePickerView.swift:143 | let | public | public let toolbarView = UIView() |
| PooToolsSource/Picker/PTBasePickerView.swift:145 | let | public | public let pickerContainer = UIView() |
| PooToolsSource/Picker/PTBasePickerView.swift:148 | let | public | public let titleLabel = UIButton(type: .custom) |
| PooToolsSource/Picker/PTBasePickerView.swift:149 | let | public | public let cancelButton = UIButton(type: .custom) |
| PooToolsSource/Picker/PTBasePickerView.swift:150 | let | public | public let confirmButton = UIButton(type: .custom) |
| PooToolsSource/Picker/PTBasePickerView.swift:170 | var | public | public var showsToolbarWhenEmbedded = false { |
| PooToolsSource/Picker/PTBasePickerView.swift:186 | var | public | public var onCancel: (@MainActor @Sendable () -> Void)? |
| PooToolsSource/Picker/PTBasePickerView.swift:188 | var | public | public var pickerStyle: PTPickerStyle = PTPickerStyle.shared { |
| PooToolsSource/Picker/PTBasePickerView.swift:194 | init | public | public init(style: PTPickerStyle? = nil) { |
| PooToolsSource/Picker/PTBasePickerView.swift:332 | func | public | public func resetTitleLabelwidth() { |
| PooToolsSource/Picker/PTBasePickerView.swift:452 | var | open | open var canConfirm: Bool { true } |
| PooToolsSource/Picker/PTBasePickerView.swift:455 | func | open | @objc open func confirmAction() { |
| PooToolsSource/Picker/PTBasePickerView.swift:461 | func | public | public func show() { |
| PooToolsSource/Picker/PTBasePickerView.swift:470 | func | public | public func show(in hostView: UIView, animated: Bool = true) -> Bool { |
| PooToolsSource/Picker/PTBasePickerView.swift:507 | func | public | @objc public func dismiss() { |
| PooToolsSource/Picker/PTBasePickerView.swift:514 | func | public | public func dismiss(animated: Bool) { |
| PooToolsSource/Picker/PTBasePickerView.swift:546 | class | public | public class PTStringPickerView: PTBasePickerView, UIPickerViewDelegate, UIPickerViewDataSource { |
| PooToolsSource/Picker/PTBasePickerView.swift:554 | var | public | public var onSelectionChanged: (@MainActor @Sendable ([PTPickerResult]) -> Void)? |
| PooToolsSource/Picker/PTBasePickerView.swift:556 | var | public | public var singleResultBlock: ((_ result: PTPickerResult) -> Void)? |
| PooToolsSource/Picker/PTBasePickerView.swift:557 | var | public | public var multiResultBlock: ((_ results: [PTPickerResult]) -> Void)? |
| PooToolsSource/Picker/PTBasePickerView.swift:568 | var | public | public var selectedIndex: Int { selectedRows.first ?? -1 } |
| PooToolsSource/Picker/PTBasePickerView.swift:570 | var | public | public var selectedIndices: [Int] { selectedRows } |
| PooToolsSource/Picker/PTBasePickerView.swift:572 | var | public | public var currentResults: [PTPickerResult] { |
| PooToolsSource/Picker/PTBasePickerView.swift:608 | func | public | public func configure(title: String, data: [PTPickerStringModel], defaultIndex: Int = 0) { |
| PooToolsSource/Picker/PTBasePickerView.swift:615 | func | public | public func configure(title: String, multiData: [[PTPickerStringModel]], defaultIndices: [Int]? = nil) { |
| PooToolsSource/Picker/PTBasePickerView.swift:629 | func | public | public func show(title: String, data: [PTPickerStringModel], defaultIndex: Int = 0, completion: @escaping (PTPickerResult) -> Void) { |
| PooToolsSource/Picker/PTBasePickerView.swift:635 | func | public | public func show(title: String, multiData: [[PTPickerStringModel]], defaultIndices: [Int]? = nil, completion: @escaping ([PTPickerResult]) -> Void) { |
| PooToolsSource/Picker/PTBasePickerView.swift:644 | func | public | public func selectRow(_ row: Int, inComponent component: Int, animated: Bool = false, notifySelectionChanged: Bool = true) { |
| PooToolsSource/Picker/PTBasePickerView.swift:683 | func | public | public func numberOfComponents(in pickerView: UIPickerView) -> Int { dataSource.count } |
| PooToolsSource/Picker/PTBasePickerView.swift:685 | func | public | public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { |
| PooToolsSource/Picker/PTBasePickerView.swift:689 | func | public | public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { |
| PooToolsSource/Picker/PTBasePickerView.swift:693 | func | public | public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView { |
| PooToolsSource/Picker/PTBasePickerView.swift:700 | func | public | public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) { |
| PooToolsSource/Picker/PTBasePickerView.swift:711 | class | public | public class PTDatePickerView: PTBasePickerView, UIPickerViewDelegate, UIPickerViewDataSource { |
| PooToolsSource/Picker/PTBasePickerView.swift:757 | var | public | public var onSelectionChanged: (@MainActor @Sendable (Date, String) -> Void)? |
| PooToolsSource/Picker/PTBasePickerView.swift:765 | var | public | public var currentSelectedDate: Date? { |
| PooToolsSource/Picker/PTBasePickerView.swift:769 | var | public | public var resultBlock: ((_ date: Date, _ dateString: String) -> Void)? |
| PooToolsSource/Picker/PTBasePickerView.swift:821 | func | public | public func configure(title: String, |
| PooToolsSource/Picker/PTBasePickerView.swift:852 | func | public | public func show(title: String, |
| PooToolsSource/Picker/PTBasePickerView.swift:1109 | func | public | public func numberOfComponents(in pickerView: UIPickerView) -> Int { |
| PooToolsSource/Picker/PTBasePickerView.swift:1113 | func | public | public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { |
| PooToolsSource/Picker/PTBasePickerView.swift:1128 | func | public | public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { |
| PooToolsSource/Picker/PTBasePickerView.swift:1132 | func | public | public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView { |
| PooToolsSource/Picker/PTBasePickerView.swift:1152 | func | public | public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) { |
| PooToolsSource/Picker/PTBasePickerView.swift:1201 | class | public | public class PTTreePickerView: PTBasePickerView, UIPickerViewDelegate, UIPickerViewDataSource { |
| PooToolsSource/Picker/PTBasePickerView.swift:1212 | var | public | public var selectedIndices: [Int] { selectedRows } |
| PooToolsSource/Picker/PTBasePickerView.swift:1215 | var | public | public var currentResults: [PTPickerResult] { |
| PooToolsSource/Picker/PTBasePickerView.swift:1225 | var | public | public var resultBlock: ((_ results: [PTPickerResult]) -> Void)? |
| PooToolsSource/Picker/PTBasePickerView.swift:1230 | var | public | public var onSelectionChanged: (@MainActor @Sendable ([PTPickerResult]) -> Void)? |
| PooToolsSource/Picker/PTBasePickerView.swift:1271 | func | public | public func configure(title: String, treeData: [PTTreePickerModel], defaultIndices: [Int]? = nil) { |
| PooToolsSource/Picker/PTBasePickerView.swift:1281 | func | public | public func show(title: String, treeData: [PTTreePickerModel], defaultIndices: [Int]? = nil, completion: @escaping ([PTPickerResult]) -> Void) { |
| PooToolsSource/Picker/PTBasePickerView.swift:1290 | func | public | public func selectRow(_ row: Int, inComponent component: Int, animated: Bool = false, notifySelectionChanged: Bool = true) { |
| PooToolsSource/Picker/PTBasePickerView.swift:1368 | func | public | public func numberOfComponents(in pickerView: UIPickerView) -> Int { |
| PooToolsSource/Picker/PTBasePickerView.swift:1372 | func | public | public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { |
| PooToolsSource/Picker/PTBasePickerView.swift:1376 | func | public | public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { |
| PooToolsSource/Picker/PTBasePickerView.swift:1380 | func | public | public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView { |
| PooToolsSource/Picker/PTBasePickerView.swift:1387 | func | public | public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) { |
| PooToolsSource/Ping/ICMP.swift:11 | enum | public | public enum ICMPv4TypeEcho : UInt8 { |
| PooToolsSource/Ping/ICMP.swift:18 | enum | public | public enum ICMPv6TypeEcho : UInt8 { |
| PooToolsSource/Ping/ICMP.swift:33 | struct | public | public struct ICMPHeader { |
| PooToolsSource/Ping/ICMP.swift:38 | var | public | public var type: UInt8 {didSet {headerBytes[0] = type}} |
| PooToolsSource/Ping/ICMP.swift:39 | var | public | public var code: UInt8 {didSet {headerBytes[1] = type}} |
| PooToolsSource/Ping/ICMP.swift:40 | var | public | public var checksum: UInt16 { |
| PooToolsSource/Ping/ICMP.swift:49 | var | public | public var identifier: UInt16 { |
| PooToolsSource/Ping/ICMP.swift:58 | var | public | public var sequenceNumber: UInt16 { |
| PooToolsSource/Ping/ICMP.swift:70 | init | public | public init(type t: UInt8, code c: UInt8, checksum chk: UInt16, identifier i: UInt16, sequenceNumber n: UInt16) { |
| PooToolsSource/Ping/ICMP.swift:97 | init | public | public init(data: Data) { |
| PooToolsSource/Ping/PTPingTool.swift:12 | enum | public | public enum PTPingTimeInterval: Sendable { |
| PooToolsSource/Ping/PTPingTool.swift:17 | var | public | public var second: TimeInterval { |
| PooToolsSource/Ping/PTPingTool.swift:29 | struct | public | public struct PTPingResponse: Sendable { |
| PooToolsSource/Ping/PTPingTool.swift:30 | var | public | public var pingAddressIP = "" |
| PooToolsSource/Ping/PTPingTool.swift:31 | var | public | public var responseTime: PTPingTimeInterval = .second(0) |
| PooToolsSource/Ping/PTPingTool.swift:32 | var | public | public var responseBytes: Int = 0 |
| PooToolsSource/Ping/PTPingTool.swift:36 | typealias | public | public typealias PingComplete = @Sendable (PTPingResponse?, (any Error)?) -> Void |
| PooToolsSource/Ping/PTPingTool.swift:38 | enum | public | public enum NetworkActivityIndicatorStatus: Sendable { |
| PooToolsSource/Ping/PTPingTool.swift:44 | enum | public | public enum PTPingError: Error, Equatable, Sendable { |
| PooToolsSource/Ping/PTPingTool.swift:58 | class | open | open class PTPingTool: NSObject { |
| PooToolsSource/Ping/PTPingTool.swift:59 | var | open | open var timeout: PTPingTimeInterval = .millisecond(1000) //自定义超时时间，默认1000毫秒，设置为0则一直等待 |
| PooToolsSource/Ping/PTPingTool.swift:60 | var | open | open var debugLog = true //是否开启日志输出 |
| PooToolsSource/Ping/PTPingTool.swift:61 | var | open | open var stopWhenError = false //遇到错误停止ping |
| PooToolsSource/Ping/PTPingTool.swift:63 | var | open | open var isRunning: Bool = false |
| PooToolsSource/Ping/PTPingTool.swift:64 | var | open | open var showNetworkActivityIndicator: NetworkActivityIndicatorStatus = .none //是否在状态栏显示 |
| PooToolsSource/Ping/PTPingTool.swift:66 | var | open | open var hostName: String? { |
| PooToolsSource/Ping/PTPingTool.swift:100 | init | public | public init(hostName: String? = nil) { |
| PooToolsSource/Ping/PTPingTool.swift:119 | func | public | public func start(pingType: AddressStyle = .any, interval: PTPingTimeInterval = .second(0), complete: PingComplete? = nil) { |
| PooToolsSource/Ping/PTPingTool.swift:131 | func | public | public func stop() { |
| PooToolsSource/Ping/SimplePing.swift:13 | enum | public | public enum AddressStyle: Sendable { |
| PooToolsSource/Ping/SimplePing.swift:23 | var | public | public var description: String { |
| PooToolsSource/Ping/SimplePing.swift:35 | protocol | public | public protocol SimplePingDelegate : AnyObject { |
| PooToolsSource/Ping/SimplePing.swift:135 | class | public | public class SimplePing { |
| PooToolsSource/Ping/SimplePing.swift:137 | let | public | public let hostName: String |
| PooToolsSource/Ping/SimplePing.swift:139 | var | public | public var addressStyle: AddressStyle |
| PooToolsSource/Ping/SimplePing.swift:147 | let | public | public let identifier: UInt16 |
| PooToolsSource/Ping/SimplePing.swift:156 | var | public | public var hostAddressFamily: sa_family_t { |
| PooToolsSource/Ping/SimplePing.swift:181 | init | public | public init(hostName hn: String, addressStyle s: AddressStyle = .any) { |
| PooToolsSource/Ping/SimplePing.swift:206 | func | public | public func start() { |
| PooToolsSource/Ping/SimplePing.swift:233 | func | public | public func sendPing(data: Data?) { |
| PooToolsSource/Ping/SimplePing.swift:306 | func | public | public func stop() { |
| PooToolsSource/Pinyin/PTPinyin.swift:12 | enum | public | public enum PinyinHelper { |
| PooToolsSource/ProgressBar/PTCircularProgressView.swift:11 | enum | public | public enum PTCircularProgressStyle { |
| PooToolsSource/ProgressBar/PTCircularProgressView.swift:17 | class | public | public class PTCircularProgressView: UIView { |
| PooToolsSource/ProgressBar/PTCircularProgressView.swift:19 | var | public | public var style: PTCircularProgressStyle = .loop |
| PooToolsSource/ProgressBar/PTCircularProgressView.swift:22 | var | public | public var progressColor: UIColor = .label { |
| PooToolsSource/ProgressBar/PTCircularProgressView.swift:27 | var | public | public var progress: CGFloat = 0 { |
| PooToolsSource/ProgressBar/PTCircularProgressView.swift:39 | init | public | public init(style: PTCircularProgressStyle) { |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:33 | enum | public | public enum PTFlexibleSteppedProgressBarTextLocation: Int { |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:40 | protocol | public | public protocol PTFlexibleSteppedProgressBarDelegate: AnyObject { |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:56 | class | open | @IBDesignable open class PTFlexibleSteppedProgressBar: UIView { |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:73 | var | open | @IBInspectable open var numberOfPoints: Int = 3 { didSet { setNeedsLayout() } } |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:75 | var | open | open var currentIndex: Int = 0 { |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:84 | var | open | open var completedTillIndex: Int = -1 { didSet { setNeedsLayout() } } |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:86 | var | open | open var currentSelectedCenterColor: UIColor = .black |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:87 | var | open | open var currentSelectedTextColor: UIColor = .orange |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:88 | var | open | open var viewBackgroundColor: UIColor = .white |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:89 | var | open | open var selectedOuterCircleStrokeColor: UIColor = .orange |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:90 | var | open | open var lastStateOuterCircleStrokeColor: UIColor = .orange |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:91 | var | open | open var lastStateCenterColor: UIColor = .lightGray |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:92 | var | open | open var centerLayerTextColor: UIColor = .black |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:93 | var | open | open var centerLayerDarkBackgroundTextColor: UIColor = .white |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:95 | var | open | open var useLastState: Bool = false { |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:106 | var | open | @IBInspectable open var lineHeight: CGFloat = 0.0 { didSet { setNeedsLayout() } } |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:107 | var | open | open var selectedOuterCircleLineWidth: CGFloat = 3.0 { didSet { setNeedsLayout() } } |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:108 | var | open | open var lastStateOuterCircleLineWidth: CGFloat = 5.0 { didSet { setNeedsLayout() } } |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:109 | var | open | open var textDistance: CGFloat = 20.0 { |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:120 | var | open | @IBInspectable open var radius: CGFloat = 0.0 { |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:130 | var | open | @IBInspectable open var progressRadius: CGFloat = 0.0 { |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:141 | var | open | @IBInspectable open var progressLineHeight: CGFloat = 0.0 { didSet { setNeedsLayout() } } |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:146 | var | open | @IBInspectable open var stepAnimationDuration: CFTimeInterval = 0.4 |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:147 | var | open | @IBInspectable open var displayStepText: Bool = true { |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:153 | var | open | open var stepTextFont: UIFont = UIFont(name: "HelveticaNeue-Medium", size: 14.0) ?? .systemFont(ofSize: 14.0) { |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:159 | var | open | open var stepTextColor: UIColor = .black { |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:164 | var | open | open var centerLayerTextFont: UIFont = .boldSystemFont(ofSize: 15) { |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:170 | var | open | @IBInspectable open var backgroundShapeColor: UIColor = UIColor(red: 238.0/255.0, green: 238.0/255.0, blue: 238.0/255.0, alpha: 0.8) { |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:175 | var | open | @IBInspectable open var selectedBackgoundColor: UIColor = UIColor(red: 251.0/255.0, green: 167.0/255.0, blue: 51.0/255.0, alpha: 1.0) { |
| PooToolsSource/ProgressBar/PTFlexibleSteppedProgressBar.swift:181 | var | open | open var isRTL: Bool = false { |
| PooToolsSource/ProgressBar/PTMediaBrowserLoadingView.swift:12 | enum | public | @objc public enum PTLoadingViewMode:Int { |
| PooToolsSource/ProgressBar/PTMediaBrowserLoadingView.swift:17 | let | public | public let PTLoadingBackgroundColor:UIColor = .DevMaskColor |
| PooToolsSource/ProgressBar/PTMediaBrowserLoadingView.swift:18 | let | public | public let PTLoadingItemSpace :CGFloat = 10 |
| PooToolsSource/ProgressBar/PTMediaBrowserLoadingView.swift:21 | class | public | public class PTMediaBrowserLoadingView: UIView { |
| PooToolsSource/ProgressBar/PTMediaBrowserLoadingView.swift:23 | var | public | public var hubTapCallback:PTActionTask? |
| PooToolsSource/ProgressBar/PTMediaBrowserLoadingView.swift:28 | var | public | public var viewCanTap:Bool = false { |
| PooToolsSource/ProgressBar/PTMediaBrowserLoadingView.swift:47 | var | public | public var progress:CGFloat = 0 { |
| PooToolsSource/ProgressBar/PTMediaBrowserLoadingView.swift:62 | var | public | public var progressColor:UIColor = .white { |
| PooToolsSource/ProgressBar/PTMediaBrowserLoadingView.swift:83 | init | public | public init(type:PTLoadingViewMode) { |
| PooToolsSource/ProgressBar/PTMediaBrowserLoadingView.swift:118 | func | public | public func hudShow(hudSize:CGSize = .init(width: 64, height: 64)) { |
| PooToolsSource/ProgressBar/PTMediaBrowserLoadingView.swift:145 | func | public | public func hudHide() { |
| PooToolsSource/ProgressBar/PTProgressBar.swift:12 | enum | public | @objc public enum PTProgressBarShowType: Int { |
| PooToolsSource/ProgressBar/PTProgressBar.swift:17 | enum | public | @objc public enum PTProgressBarAnimationType: Int { |
| PooToolsSource/ProgressBar/PTProgressBar.swift:23 | class | public | public class PTProgressBar: UIView { |
| PooToolsSource/ProgressBar/PTProgressBar.swift:26 | var | open | open var barColor: UIColor = .systemBlue { |
| PooToolsSource/ProgressBar/PTProgressBar.swift:33 | var | open | open var trackColor: UIColor = .systemGray5 { |
| PooToolsSource/ProgressBar/PTProgressBar.swift:39 | var | public | public var animationed: Bool { |
| PooToolsSource/ProgressBar/PTProgressBar.swift:44 | var | public | public var progressChanged: ((CGFloat) -> Void)? |
| PooToolsSource/ProgressBar/PTProgressBar.swift:49 | let | public | public let showType: PTProgressBarShowType |
| PooToolsSource/ProgressBar/PTProgressBar.swift:66 | init | public | public init(showType: PTProgressBarShowType) { |
| PooToolsSource/ProgressBar/PTProgressBar.swift:124 | func | public | public func animationProgress(duration: CGFloat, @PTClampedPropertyWrapper(range: 0...1) value: CGFloat) { |
| PooToolsSource/ProgressBar/PTProgressBar.swift:128 | func | public | public func startAnimation(type: PTProgressBarAnimationType, duration: CGFloat, @PTClampedPropertyWrapper(range: 0...1) value: CGFloat) { |
| PooToolsSource/ProgressBar/PTProgressBar.swift:170 | func | public | public func stopAnimation() { |
| PooToolsSource/ProgressBar/PTProgressBar.swift:190 | func | public | public func getProgress() -> CGFloat { |
| PooToolsSource/Protocol/PTProtocol.swift:14 | struct | public | public struct PTPOP<Base> { |
| PooToolsSource/Protocol/PTProtocol.swift:15 | let | public | public let base: Base // 升级：添加 public，确保在其他模块可以访问 base 实例 |
| PooToolsSource/Protocol/PTProtocol.swift:17 | init | public | public init(_ base: Base) { |
| PooToolsSource/Protocol/PTProtocol.swift:28 | protocol | public | public protocol PTProtocolCompatible {} |
| PooToolsSource/Protocol/PTProtocol.swift:102 | var | public | public var scale: Double { |
| PooToolsSource/Protocol/PTProtocol.swift:110 | func | public | public func calculateScaleIfNeeded() { |
| PooToolsSource/Protocol/PTProtocol.swift:134 | var | public | public var currentScale: Double { |
| PooToolsSource/Protocol/PTProtocol.swift:141 | func | public | public func setAdapterScale(_ scale: Double) { |
| PooToolsSource/Protocol/PTProtocol.swift:153 | func | public | public func calculateScaleIfNeeded() { |
| PooToolsSource/Protocol/PTProtocol.swift:163 | protocol | public | public protocol PTNumberValueAdapterable { |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:21 | class | public | public class PTScanBarInfo: NSObject { |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:24 | var | public | public var codeView: UIView = UIView() |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:27 | var | public | public var codeString: String = "" |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:30 | init | public | public init(codeView: UIView? = nil, codeString: String = "") { |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:38 | class | public | public class PTScanQRConfig:NSObject { |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:40 | var | open | open var backImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44)) |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:42 | var | open | open var photoImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44)) |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:44 | var | open | open var flashImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44)) |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:45 | var | open | open var flashImageSelected:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44)) |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:47 | var | open | open var scanLineImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44)) |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:49 | var | open | open var qrCodeImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44)) |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:51 | var | open | @MainActor open var barCodeTips:String = "PT Scan code".localized() |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:53 | var | open | @MainActor open var cancelButtonName:String = "PT Button cancel".localized() |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:55 | var | open | @MainActor open var scanedTips:String = "PT Scan tap".localized() |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:57 | var | open | open var canScanQR:Bool = true |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:59 | var | open | open var autoReturn:Bool = true |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:61 | var | open | open var openAblumFollowSystem:Bool = true |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:63 | var | open | @MainActor open var authorizedDoneButton:String = "PT Setting".localized() |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:65 | var | open | @MainActor open var authorizedCancelButton:String = "PT Button cancel".localized() |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:67 | var | open | @MainActor open var loadingTitle:String = "PT Alert Doning".localized() |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:70 | typealias | public | public typealias PTQRCodeResultBlock = (_ result:String,_ error:NSError?) -> Void |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:73 | class | public | public class PTScanQRController: PTBaseViewController { |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:75 | let | public | public let sessionQueue = DispatchQueue(label: "camera.session.collector.metal") |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:78 | var | public | public var resultBlock:PTQRCodeResultBlock? |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:243 | init | public | public init(viewConfig:PTScanQRConfig) { |
| PooToolsSource/QRCodeScan/PTScanQRController.swift:637 | func | public | public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) { |
| PooToolsSource/RateView/PTRateView.swift:13 | typealias | public | public typealias PTRateScoreBlock = (_ score:CGFloat) -> Void |
| PooToolsSource/RateView/PTRateView.swift:19 | class | public | public class PTRateConfig: NSObject { |
| PooToolsSource/RateView/PTRateView.swift:20 | var | public | public var scorePercent: CGFloat = 1 { |
| PooToolsSource/RateView/PTRateView.swift:23 | var | public | public var numberOfStar: Int = 5 |
| PooToolsSource/RateView/PTRateView.swift:24 | var | public | public var fImage: UIImage = "🌟".emojiToImage(emojiFont: .appfont(size: 24)) |
| PooToolsSource/RateView/PTRateView.swift:25 | var | public | public var bImage: UIImage = "⭐️".emojiToImage(emojiFont: .appfont(size: 24)) |
| PooToolsSource/RateView/PTRateView.swift:26 | var | public | public var canTap: Bool = false |
| PooToolsSource/RateView/PTRateView.swift:27 | var | public | public var hadAnimation: Bool = false |
| PooToolsSource/RateView/PTRateView.swift:28 | var | public | public var allowIncompleteStar: Bool = false |
| PooToolsSource/RateView/PTRateView.swift:29 | var | public | public var itemSpacing: CGFloat = 0 |
| PooToolsSource/RateView/PTRateView.swift:30 | var | public | public var imageContentMode: UIView.ContentMode = .scaleAspectFill |
| PooToolsSource/RateView/PTRateView.swift:35 | class | public | public class PTRateView: UIView { |
| PooToolsSource/RateView/PTRateView.swift:38 | var | public | public var rateBlock: PTRateScoreBlock? |
| PooToolsSource/RateView/PTRateView.swift:39 | var | public | public var viewConfig: PTRateConfig? { |
| PooToolsSource/RateView/PTRateView.swift:54 | init | public | public init(viewConfig: PTRateConfig) { |
| PooToolsSource/RemindersPermission/PTPermissionReminders.swift:19 | class | public | public class PTPermissionReminders: PTPermission { |
| PooToolsSource/RemindersPermission/PTPermissionReminders.swift:22 | var | open | open var usageDescriptionKey: String? { "NSRemindersUsageDescription" } |
| PooToolsSource/RemindersPermission/PTPermissionReminders.swift:23 | var | open | open var usageFullAccessDescriptionKey: String? { "NSRemindersFullAccessUsageDescription" } |
| PooToolsSource/Rotation/PTRotationManager.swift:24 | enum | public | public enum Orientation: CaseIterable { |
| PooToolsSource/Rotation/PTRotationManager.swift:51 | var | public | public var isLockOrientationWhenDeviceOrientationDidChange = true { |
| PooToolsSource/Rotation/PTRotationManager.swift:59 | var | public | public var isLockLandscapeWhenDeviceOrientationDidChange = false { |
| PooToolsSource/Rotation/PTRotationManager.swift:67 | var | public | public var isPortrait: Bool { orientationMask == .portrait } |
| PooToolsSource/Rotation/PTRotationManager.swift:70 | var | public | public var orientation: Orientation { |
| PooToolsSource/Rotation/PTRotationManager.swift:85 | var | public | public var orientationMaskDidChange: ((_ orientationMask: UIInterfaceOrientationMask) -> Void)? |
| PooToolsSource/Rotation/PTRotationManager.swift:86 | var | public | public var lockOrientationWhenDeviceOrientationDidChange: ((_ isLock: Bool) -> Void)? |
| PooToolsSource/Rotation/PTRotationManager.swift:87 | var | public | public var lockLandscapeWhenDeviceOrientationDidChange: ((_ isLock: Bool) -> Void)? |
| PooToolsSource/Rotation/PTRotationManager.swift:241 | class | public | public class PTRotationManagerState: ObservableObject { |
| PooToolsSource/Rotation/PTRotationManager.swift:242 | var | public | @Published public var orientation: PTRotationManager.Orientation = PTRotationManager.shared.orientation { |
| PooToolsSource/Rotation/PTRotationManager.swift:250 | var | public | @Published public var isLockOrientation: Bool = PTRotationManager.shared.isLockOrientationWhenDeviceOrientationDidChange { |
| PooToolsSource/Rotation/PTRotationManager.swift:257 | var | public | @Published public var isLockLandscape: Bool = PTRotationManager.shared.isLockLandscapeWhenDeviceOrientationDidChange { |
| PooToolsSource/Rotation/PTRotationManager.swift:266 | init | public | public init() { |
| PooToolsSource/Router/PTRouter.swift:116 | let | public | public let PTJumpTypeKey = "jumpType" |
| PooToolsSource/Router/PTRouter.swift:118 | let | public | public let PTRouterIvar1Key = "ivar1" |
| PooToolsSource/Router/PTRouter.swift:120 | let | public | public let PTRouterIvar2Key = "ivar2" |
| PooToolsSource/Router/PTRouter.swift:122 | let | public | public let PTRouterFunctionResultKey = "resultType" |
| PooToolsSource/Router/PTRouter.swift:124 | let | public | public let PTRouterPath = "path" |
| PooToolsSource/Router/PTRouter.swift:126 | let | public | public let PTRouterClassName = "class" |
| PooToolsSource/Router/PTRouter.swift:128 | let | public | public let PTRouterPriority = "priority" |
| PooToolsSource/Router/PTRouter.swift:130 | let | public | public let PTRouterTabBarSelecIndex = "tabBarSelecIndex" |
| PooToolsSource/Router/PTRouter.swift:132 | let | public | public let PTRouterDefaultPriority: UInt = 1000 |
| PooToolsSource/Router/PTRouter.swift:134 | typealias | public | public typealias ComplateHandler = (@MainActor ([String: Any]?, Any?) -> Void)? |
| PooToolsSource/Router/PTRouter.swift:136 | enum | public | public enum PTRouterError: Error, LocalizedError { |
| PooToolsSource/Router/PTRouter.swift:142 | var | public | public var errorDescription: String? { |
| PooToolsSource/Router/PTRouter.swift:156 | var | public | public var closure: ((Any) -> Void)? |
| PooToolsSource/Router/PTRouter.swift:158 | init | public | public init(closure: @escaping (Any) -> Void) { |
| PooToolsSource/Router/PTRouter.swift:162 | func | public | public func executeClosure(params: Any) { |
| PooToolsSource/Router/PTRouter.swift:168 | class | public | public class PTRouter: PTRouterParser { |
| PooToolsSource/Router/PTRouter.swift:171 | var | public | public var customNavClass: UINavigationController.Type = UINavigationController.self |
| PooToolsSource/Router/PTRouter.swift:174 | typealias | public | public typealias FailedHandleBlock = @MainActor ([String: Sendable]) -> Void |
| PooToolsSource/Router/PTRouter.swift:175 | typealias | public | public typealias RouteResponse = (pattern: PTRouterPattern?, queries: [String: Sendable]) |
| PooToolsSource/Router/PTRouter.swift:176 | typealias | public | public typealias MatchResult = (matched: Bool, queries: [String: Sendable]) |
| PooToolsSource/Router/PTRouter.swift:177 | typealias | public | public typealias LazyRegisterHandleBlock = @MainActor (_ url: String, _ userInfo: [String: Sendable]) -> (any Sendable)? |
| PooToolsSource/Router/PTRouter.swift:178 | typealias | public | public typealias RouterLogHandleBlock = @MainActor (_ url: String, _ logType: PTRouterLogType, _ errorMsg: String) -> Void |
| PooToolsSource/Router/PTRouter.swift:181 | typealias | public | public typealias CustomJumpActionClouse = @MainActor (PTJumpType, UIViewController) -> Void |
| PooToolsSource/Router/PTRouter.swift:193 | var | public | public var reloadRouterMap: [PTRouterInfo] = [] |
| PooToolsSource/Router/PTRouter.swift:196 | var | public | public var lazyRegisterHandleBlock: LazyRegisterHandleBlock? |
| PooToolsSource/Router/PTRouter.swift:199 | var | public | public var routerLoaded: Bool = false |
| PooToolsSource/Router/PTRouter.swift:201 | var | public | public var patterns = [PTRouterPattern]() |
| PooToolsSource/Router/PTRouter.swift:203 | var | public | public var webPath: String? |
| PooToolsSource/Router/PTRouter.swift:205 | var | public | public var serviceHost: String = "scheme://services?" |
| PooToolsSource/Router/PTRouter.swift:207 | var | public | public var logcat: RouterLogHandleBlock? |
| PooToolsSource/Router/PTRouter.swift:209 | var | public | public var customJumpAction: CustomJumpActionClouse? |
| PooToolsSource/Router/PTRouter.swift:220 | class | public | public class func addAsyncInterceptor(_ interceptor: PTRouterAsyncInterceptor) { |
| PooToolsSource/Router/PTRouter.swift:518 | enum | public | @objc public enum PTJumpType: Int { |
| PooToolsSource/Router/PTRouter.swift:528 | enum | public | @objc public enum PTRouterFunctionResultType: Int { |
| PooToolsSource/Router/PTRouter.swift:535 | enum | public | @objc public enum PTRouterReloadMapEnum: Int { |
| PooToolsSource/Router/PTRouter.swift:544 | enum | public | @objc public enum PTRouterLogType: Int { |
| PooToolsSource/Router/PTRouter.swift:549 | struct | public | public struct RouteItem { |
| PooToolsSource/Router/PTRouter.swift:551 | var | public | public var path: String = "" |
| PooToolsSource/Router/PTRouter.swift:552 | var | public | public var className: String = "" |
| PooToolsSource/Router/PTRouter.swift:553 | var | public | public var action: String = "" |
| PooToolsSource/Router/PTRouter.swift:554 | var | public | public var descriptions: String = "" |
| PooToolsSource/Router/PTRouter.swift:555 | var | public | public var params: [String: Any] = [:] |
| PooToolsSource/Router/PTRouter.swift:557 | init | public | public init(path: String, className: String, action: String = "", descriptions: String = "", params: [String: Any] = [:]) { |
| PooToolsSource/Router/PTRouter.swift:569 | class | public | public class func generate(_ patternString: String, params: [String: any Any & Sendable] = [:], jumpType: PTJumpType) -> (String, [String: any Any & Sendable]) { |
| PooToolsSource/Router/PTRouter.swift:602 | protocol | public | public protocol CustomRouterInfo { |
| PooToolsSource/Router/PTRouter.swift:610 | var | public | public var requiredURL: (String, [String: any Any & Sendable]) { |
| PooToolsSource/Router/PTRouter.swift:617 | struct | public | public struct PTAnyDecodable: Decodable { |
| PooToolsSource/Router/PTRouter.swift:618 | let | public | public let value: Any |
| PooToolsSource/Router/PTRouter.swift:620 | init | public | public init(from decoder: Decoder) throws { |
| PooToolsSource/Router/PTRouter.swift:644 | struct | public | public struct PTRouterInfo: Decodable { |
| PooToolsSource/Router/PTRouter.swift:645 | var | public | public var targetPath: String? |
| PooToolsSource/Router/PTRouter.swift:646 | var | public | public var orginPath: String? |
| PooToolsSource/Router/PTRouter.swift:647 | var | public | public var routerType: Int = 0 |
| PooToolsSource/Router/PTRouter.swift:648 | var | public | public var path: String? |
| PooToolsSource/Router/PTRouter.swift:649 | var | public | public var className: String? |
| PooToolsSource/Router/PTRouter.swift:652 | var | public | public var params: [String: Any]? |
| PooToolsSource/Router/PTRouter.swift:663 | init | public | public init() {} |
| PooToolsSource/Router/PTRouter.swift:665 | init | public | public init(from decoder: Decoder) throws { |
| PooToolsSource/Router/PTRouter.swift:719 | class | public | public class func openURLVC(_ urlString: String, userInfo: [String: Sendable] = [:]) async throws -> UIViewController { |
| PooToolsSource/Router/PTRouter.swift:739 | class | public | public class func openURL(_ urlString: String, userInfo: [String: any Any & Sendable] = [:]) async throws -> (any Sendable)? { |
| PooToolsSource/Router/PTRouter.swift:751 | class | public | public class func openURL(_ urlString: String, userInfo: [String: Sendable] = [String: Sendable](), complateHandler: ComplateHandler = nil) async throws -> (any Sendable)? { |
| PooToolsSource/Router/PTRouter.swift:763 | class | public | public class func openURL(_ uriTuple: (String, [String: Sendable]), complateHandler: ComplateHandler = nil) async -> (any Sendable)? { |
| PooToolsSource/Router/PTRouter.swift:772 | class | public | public class func openWebURL(_ uriTuple: (String, [String: Sendable])) async -> (any Sendable)? { |
| PooToolsSource/Router/PTRouter.swift:777 | class | public | public class func openWebURL(_ urlString: String, |
| PooToolsSource/Router/PTRouter.swift:783 | class | public | public class func openCacheRouter(_ uriTuple: (String, [String: Sendable]), complateHandler: ComplateHandler = nil) async -> (any Sendable)? { |
| PooToolsSource/Router/PTRouter.swift:797 | class | public | public class func routerJump(_ uriTuple: (String, [String: Sendable]), complateHandler: ComplateHandler = nil) async -> (any Sendable)? { |
| PooToolsSource/Router/PTRouter.swift:811 | class | public | public class func jump(jumpType: PTJumpType, vc: UIViewController, queries: [String: Any]) { |
| PooToolsSource/Router/PTRouter.swift:878 | class | public | public class func routerService(_ uriTuple: (String, [String: Any])) -> (any Sendable)? { |
| PooToolsSource/Router/PTRouter.swift:908 | class | public | public class func performTarget(protocolName: String, |
| PooToolsSource/Router/PTRouter.swift:927 | class | public | public class func performTargetVoidType(protocolName: String, |
| PooToolsSource/Router/PTRouterBridge.swift:12 | class | public | public class PTRouterBridge: NSObject { |
| PooToolsSource/Router/PTRouterBridge.swift:14 | class | public | public class func canOpenUrl(_ urlString: String) async -> Bool { |
| PooToolsSource/Router/PTRouterBridge.swift:20 | class | public | public class func openURL(_ urlString: String, userInfo: [String: Sendable] = [:], complateHandler: ComplateHandler = nil) async throws -> (any Sendable)? { |
| PooToolsSource/Router/PTRouterBridge.swift:27 | class | public | public class func openURL(_ uriTuple: (String, [String: Sendable]), complateHandler: ComplateHandler = nil) async -> Any? { |
| PooToolsSource/Router/PTRouterBridge.swift:33 | class | public | public class func openWebURL(_ uriTuple: (String, [String: Sendable])) async -> Any? { |
| PooToolsSource/Router/PTRouterBridge.swift:39 | class | public | public class func openWebURL(_ urlString: String, userInfo: [String: Sendable] = [:]) async -> Any? { |
| PooToolsSource/Router/PTRouterBuilder.swift:12 | class | public | public class PTRouterBuilder { |
| PooToolsSource/Router/PTRouterBuilder.swift:14 | var | public | public var buildResult: (String, [String: any Any & Sendable]) = ("", [:]) |
| PooToolsSource/Router/PTRouterBuilder.swift:16 | init | public | public init () {} |
| PooToolsSource/Router/PTRouterBuilder.swift:22 | class | public | public class func build(_ path: String) -> PTRouterBuilder { |
| PooToolsSource/Router/PTRouterBuilder.swift:29 | func | public | public func withInt(key: String, value: Int) -> Self { |
| PooToolsSource/Router/PTRouterBuilder.swift:35 | func | public | public func withString(key: String, value: String) -> Self { |
| PooToolsSource/Router/PTRouterBuilder.swift:41 | func | public | public func withBool(key: String, value: Bool) -> Self { |
| PooToolsSource/Router/PTRouterBuilder.swift:47 | func | public | public func withDouble(key: String, value: Double) -> Self { |
| PooToolsSource/Router/PTRouterBuilder.swift:53 | func | public | public func withFloat(key: String, value: Float) -> Self { |
| PooToolsSource/Router/PTRouterBuilder.swift:59 | func | public | public func withAny(key: String, value: any Any & Sendable) -> Self { |
| PooToolsSource/Router/PTRouterBuilder.swift:69 | func | public | public func buildService<PTRouterServiceProtocol>(_ protocolInstance: PTRouterServiceProtocol.Type, methodName: String) -> Self { |
| PooToolsSource/Router/PTRouterBuilder.swift:76 | func | public | public func buildServicePath<PTRouterServiceProtocol>(_ protocolInstance: PTRouterServiceProtocol.Type, methodName: String) -> String { |
| PooToolsSource/Router/PTRouterBuilder.swift:88 | func | public | public func buildDictionary(param: [String: any Any & Sendable]) -> Self { |
| PooToolsSource/Router/PTRouterBuilder.swift:94 | func | public | public func fetchService() async -> (any Sendable)? { |
| PooToolsSource/Router/PTRouterBuilder.swift:100 | func | public | public func navigation(_ handler: ComplateHandler = nil) async { |
| PooToolsSource/Router/PTRouterBuilder.swift:106 | struct | public | public struct PTTypedBuilder<T: PTRoutableStaticController> { |
| PooToolsSource/Router/PTRouterBuilder.swift:116 | init | public | public init(path: String) { |
| PooToolsSource/Router/PTRouterBuilder.swift:121 | func | public | public func with(params: T.Params) -> Self { |
| PooToolsSource/Router/PTRouterBuilder.swift:127 | func | public | public func jumpType(_ type: PTJumpType, |
| PooToolsSource/Router/PTRouterBuilder.swift:143 | func | public | public func navigation() async throws -> T { |
| PooToolsSource/Router/PTRouterDebugTool.swift:12 | class | public | public class PTRouterDebugTool: NSObject { |
| PooToolsSource/Router/PTRouterInterceptor.swift:12 | protocol | public | public protocol PTRouterAsyncInterceptor: Sendable { |
| PooToolsSource/Router/PTRouterManager.swift:13 | let | public | public let NSKVONotifyingPrefix = "KVONotifying_" |
| PooToolsSource/Router/PTRouterManager.swift:16 | let | public | public let kSADelegateClassSensorsSuffix = "_CN.SENSORSDATA" |
| PooToolsSource/Router/PTRouterManager.swift:18 | let | public | public let kSAppleSuffix = "com.apple" |
| PooToolsSource/Router/PTRouterManager.swift:21 | let | public | public let kSCocoaPodsSuffix = "org.cocoapods" |
| PooToolsSource/Router/PTRouterManager.swift:28 | class | public | public class PTRouterManager: NSObject { |
| PooToolsSource/Router/PTRouterManager.swift:33 | var | public | public var useCache: Bool = false |
| PooToolsSource/Router/PTRouterManager.swift:64 | class | public | public class func registerRouterMap(_ excludeCocoapods: Bool = false, |
| PooToolsSource/Router/PTRouterManager.swift:162 | class | public | public class func loadRouterClass(excludeCocoapods: Bool = false, |
| PooToolsSource/Router/PTRouterManager.swift:212 | class | public | public class func fetchRouterRegisterClass(_ excludeCocoapods: Bool = false, |
| PooToolsSource/Router/PTRouterManager.swift:311 | class | public | public class func registerServices(excludeCocoapods: Bool = false) { |
| PooToolsSource/Router/PTRouterPattern.swift:11 | class | public | public class PTRouterPattern { |
| PooToolsSource/Router/PTRouterPattern.swift:12 | var | public | public var patternString: String |
| PooToolsSource/Router/PTRouterPattern.swift:13 | var | public | public var classString: String |
| PooToolsSource/Router/PTRouterPattern.swift:14 | var | public | public var priority: UInt |
| PooToolsSource/Router/PTRouterPattern.swift:21 | init | public | public init(_ string: String, classString: String, priority: UInt = 0) { |
| PooToolsSource/Router/PTRouterPattern.swift:54 | func | public | public func matchResult(for requestURL: String) -> (matched: Bool, queries: [String: Sendable]) { |
| PooToolsSource/Router/PTRouterServiceManager.swift:14 | let | public | @MainActor public let instance: NSObject |
| PooToolsSource/Router/PTRouterServiceManager.swift:16 | init | public | @MainActor public init(instance: NSObject) { |
| PooToolsSource/Router/PTRouterServiceManager.swift:21 | typealias | public | public typealias PTServiceCreator = @Sendable () -> any Sendable |
| PooToolsSource/Router/PTRouterServiceManager.swift:23 | enum | public | public enum PTServiceScope { |
| PooToolsSource/Router/PTRouterServiceManager.swift:29 | actor | public | public actor PTRouterServiceManager { |
| PooToolsSource/Router/PTRouterServiceManager.swift:40 | func | public | public func registerService<Service>(_ serviceType: Service.Type, scope: PTServiceScope = .singleton, creator: @Sendable @escaping () -> Service) { |
| PooToolsSource/Router/PTRouterServiceManager.swift:45 | func | public | public func getService<Service: Sendable>(_ serviceType: Service.Type) -> Service? { |
| PooToolsSource/Router/PTRouterServiceManager.swift:175 | class | public | public class PTServiceActionMapper { |
| PooToolsSource/Router/PTRouterServiceManager.swift:182 | func | public | public func register(protocolName: String, methodName: String, action: @escaping (Any?, Any?) -> Any?) { |
| PooToolsSource/Router/PTRouterServiceManager.swift:188 | func | public | public func execute(protocolName: String, methodName: String, param: Any?, otherParam: Any?) -> (any Sendable)? { |
| PooToolsSource/Router/PTRouterServiceProtocol.swift:13 | protocol | public | public protocol PTRouterServiceProtocol: NSObjectProtocol { |
| PooToolsSource/Router/PTRouterServiceProtocol.swift:19 | protocol | public | public protocol PTRoutableController { |
| PooToolsSource/Router/PTRouterServiceProtocol.swift:24 | protocol | public | public protocol PTServiceProtocol: AnyObject {} |
| PooToolsSource/Router/PTRouterServiceProtocol.swift:27 | protocol | public | public protocol PTRoutableParams { |
| PooToolsSource/Router/PTRouterServiceProtocol.swift:35 | protocol | public | public protocol PTRoutableStaticController: PTRoutableController { |
| PooToolsSource/Router/PTRouterable.swift:11 | protocol | public | public protocol PTRouterable { |
| PooToolsSource/ScreenShot/PTSnapShotKitProtocol.swift:15 | struct | public | public struct SnapshotConfiguration: Sendable { |
| PooToolsSource/ScreenShot/PTSnapShotKitProtocol.swift:19 | var | public | public var scale: CGFloat |
| PooToolsSource/ScreenShot/PTSnapShotKitProtocol.swift:21 | var | public | public var isOpaque: Bool |
| PooToolsSource/ScreenShot/PTSnapShotKitProtocol.swift:26 | var | public | public var maximumPixelCount: Int |
| PooToolsSource/ScreenShot/PTSnapShotKitProtocol.swift:28 | init | public | public init(scale: CGFloat = 0.0, |
| PooToolsSource/ScreenShot/PTSnapShotKitProtocol.swift:41 | protocol | public | public protocol SnapshotKitProtocol { |
| PooToolsSource/ScreenShot/UIScrollView+PTSnapShot.swift:95 | func | public | public func scrollTakeSnapshotOfVisibleContent(with configuration: SnapshotConfiguration) -> UIImage? { |
| PooToolsSource/ScreenShot/UIScrollView+PTSnapShot.swift:99 | func | public | public func scrollTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration) -> UIImage? { |
| PooToolsSource/ScreenShot/UIScrollView+PTSnapShot.swift:103 | func | public | public func scrollAsyncTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration, |
| PooToolsSource/ScreenShot/UITableView+PTSnapShot.swift:31 | func | public | public func tableTakeSnapshotOfVisibleContent(with configuration: SnapshotConfiguration) -> UIImage? { |
| PooToolsSource/ScreenShot/UITableView+PTSnapShot.swift:35 | func | public | public func tableTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration) -> UIImage? { |
| PooToolsSource/ScreenShot/UITableView+PTSnapShot.swift:39 | func | public | public func tableAsyncTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration, |
| PooToolsSource/ScreenShot/UIView+PTSnapShot.swift:16 | func | public | public func takeSnapshotOfVisibleContent(with configuration: SnapshotConfiguration) -> UIImage? { |
| PooToolsSource/ScreenShot/UIView+PTSnapShot.swift:34 | func | public | public func takeSnapshotOfFullContent(with configuration: SnapshotConfiguration) -> UIImage? { |
| PooToolsSource/ScreenShot/UIView+PTSnapShot.swift:52 | func | public | public func asyncTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration, completion: @escaping ((UIImage?) -> Void)) { |
| PooToolsSource/ScreenShot/UIView+PTSnapShot.swift:69 | func | public | public func takeSnapshotOfFullContent(for croppingRect: CGRect, with configuration: SnapshotConfiguration? = nil) -> UIImage? { |
| PooToolsSource/ScreenShot/UIWindow+PTSnapShot.swift:25 | func | public | public func windowTakeSnapshotOfVisibleContent(with configuration: SnapshotConfiguration) -> UIImage? { |
| PooToolsSource/ScreenShot/UIWindow+PTSnapShot.swift:29 | func | public | public func windowTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration) -> UIImage? { |
| PooToolsSource/ScreenShot/UIWindow+PTSnapShot.swift:33 | func | public | public func windowAsyncTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration, completion: @escaping ((UIImage?) -> Void)) { |
| PooToolsSource/ScreenShot/WKWebView+PTSnapShot.swift:56 | func | public | public func wkTakeSnapshotOfVisibleContent(with configuration: SnapshotConfiguration) -> UIImage? { |
| PooToolsSource/ScreenShot/WKWebView+PTSnapShot.swift:60 | func | public | public func wkTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration) -> UIImage? { |
| PooToolsSource/ScreenShot/WKWebView+PTSnapShot.swift:64 | func | public | public func wkAsyncTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration, |
| PooToolsSource/ScrollBanner/PTBannerCell.swift:16 | class | public | public class PTBannerCell: PTBaseNormalCell { |
| PooToolsSource/ScrollBanner/PTBannerCell.swift:23 | var | public | public var videoURL: String? |
| PooToolsSource/ScrollBanner/PTBannerCell.swift:72 | func | public | public func configure(_ data: PTBannerModel, |
| PooToolsSource/ScrollBanner/PTBannerMediaManager.swift:19 | func | public | public func loadCover(url: String, |
| PooToolsSource/ScrollBanner/PTBannerMediaManager.swift:34 | func | public | public func loadCover(url: URL, |
| PooToolsSource/ScrollBanner/PTBannerMediaManager.swift:54 | var | public | public var player: AVPlayer? |
| PooToolsSource/ScrollBanner/PTBannerMediaManager.swift:55 | var | public | public var playerLayer: AVPlayerLayer? |
| PooToolsSource/ScrollBanner/PTBannerMediaManager.swift:59 | var | public | public var playEndCallback: PTActionTask? |
| PooToolsSource/ScrollBanner/PTBannerMediaManager.swift:149 | func | public | public func startPiP() { |
| PooToolsSource/ScrollBanner/PTBannerMediaManager.swift:159 | func | public | public func pause() { |
| PooToolsSource/ScrollBanner/PTBannerMediaManager.swift:163 | func | public | public func resume() { |
| PooToolsSource/ScrollBanner/PTBannerModel.swift:12 | class | public | public class PTBannerModel: NSObject { |
| PooToolsSource/ScrollBanner/PTBannerModel.swift:13 | var | open | open var media:Any? |
| PooToolsSource/ScrollBanner/PTBannerModel.swift:14 | var | open | open var title:String = "" |
| PooToolsSource/ScrollBanner/PTBannerModel.swift:15 | var | open | open var desc:String = "" |
| PooToolsSource/ScrollBanner/PTBannerModel.swift:16 | var | open | open var att:ASAttributedString? |
| PooToolsSource/ScrollBanner/PTBannerModel.swift:19 | var | open | open var titleColor: UIColor = UIColor.white |
| PooToolsSource/ScrollBanner/PTBannerModel.swift:20 | var | open | open var descColor: UIColor = UIColor.white |
| PooToolsSource/ScrollBanner/PTBannerModel.swift:22 | var | open | open var titleFont: UIFont = UIFont.systemFont(ofSize: 15) |
| PooToolsSource/ScrollBanner/PTBannerModel.swift:23 | var | open | open var descFont: UIFont = UIFont.systemFont(ofSize: 15) |
| PooToolsSource/ScrollBanner/PTBannerModel.swift:24 | var | open | open var titleLineSpacing:CGFloat = 1.5 |
| PooToolsSource/ScrollBanner/PTBannerModel.swift:25 | var | open | open var imageViewContentMode: UIView.ContentMode = .scaleAspectFit |
| PooToolsSource/ScrollBanner/PTBannerModel.swift:26 | var | open | open var cellCornerRadius: CGFloat = 0 |
| PooToolsSource/ScrollBanner/PTBannerModel.swift:27 | var | open | open var corner:UIRectCorner = .allCorners |
| PooToolsSource/ScrollBanner/PTBannerModel.swift:28 | var | public | public var cachedDescHeight: CGFloat? |
| PooToolsSource/ScrollBanner/PTBannerView.swift:19 | var | public | public var autoScrollInterval: TimeInterval = 2 { |
| PooToolsSource/ScrollBanner/PTBannerView.swift:102 | class | public | public class PTBannerConfiguration:NSObject { |
| PooToolsSource/ScrollBanner/PTBannerView.swift:103 | var | public | public var playButtonImage:UIImage = "▶️".emojiToImage(emojiFont: .appfont(size: 44)) |
| PooToolsSource/ScrollBanner/PTBannerView.swift:104 | var | public | public var pauseButtonImage:UIImage = "⏬️".emojiToImage(emojiFont: .appfont(size: 44)) |
| PooToolsSource/ScrollBanner/PTBannerView.swift:106 | var | public | public var numberOfLines: Int = 0 |
| PooToolsSource/ScrollBanner/PTBannerView.swift:108 | var | public | public var titleLeading: CGFloat = 15 |
| PooToolsSource/ScrollBanner/PTBannerView.swift:110 | var | public | public var titleNPageControlSpacing: CGFloat = 4 |
| PooToolsSource/ScrollBanner/PTBannerView.swift:112 | var | public | public var titleBackgroundColor: UIColor = UIColor.black.withAlphaComponent(0.3) |
| PooToolsSource/ScrollBanner/PTBannerView.swift:114 | var | public | public var pageControlBottom: CGFloat = 5 |
| PooToolsSource/ScrollBanner/PTBannerView.swift:115 | var | public | public var pageControlTintColor: UIColor = UIColor.lightGray |
| PooToolsSource/ScrollBanner/PTBannerView.swift:117 | var | public | public var pageControlCurrentPageColor: UIColor = UIColor.white |
| PooToolsSource/ScrollBanner/PTBannerView.swift:119 | var | public | public var fillPageControlIndicatorRadius: CGFloat = 4 |
| PooToolsSource/ScrollBanner/PTBannerView.swift:121 | var | public | public var customPageControlInActiveTintColor: UIColor = UIColor(white: 1, alpha: 0.3) |
| PooToolsSource/ScrollBanner/PTBannerView.swift:123 | var | public | public var pageControlActiveImage: UIImage? = nil |
| PooToolsSource/ScrollBanner/PTBannerView.swift:125 | var | public | public var pageControlInActiveImage: UIImage? = nil |
| PooToolsSource/ScrollBanner/PTBannerView.swift:126 | var | public | public var dotSpacing:CGFloat = 8 |
| PooToolsSource/ScrollBanner/PTBannerView.swift:128 | var | public | public var customPageControlStyle: PageControlStyle = .system |
| PooToolsSource/ScrollBanner/PTBannerView.swift:130 | var | public | public var customPageControlTintColor: UIColor = UIColor.white |
| PooToolsSource/ScrollBanner/PTBannerView.swift:132 | var | public | public var customPageControlIndicatorPadding: CGFloat = 8 |
| PooToolsSource/ScrollBanner/PTBannerView.swift:134 | var | public | public var pageControlPosition: PageControlPosition = .center |
| PooToolsSource/ScrollBanner/PTBannerView.swift:135 | var | public | public var scrollDirection: UICollectionView.ScrollDirection? = .horizontal |
| PooToolsSource/ScrollBanner/PTBannerView.swift:136 | var | public | public var autoScroll = true |
| PooToolsSource/ScrollBanner/PTBannerView.swift:137 | var | public | public var infiniteLoop = true |
| PooToolsSource/ScrollBanner/PTBannerView.swift:138 | var | public | public var autoPlayMedia: Bool = false |
| PooToolsSource/ScrollBanner/PTBannerView.swift:142 | var | public | public var autoScrollInterval: TimeInterval? |
| PooToolsSource/ScrollBanner/PTBannerView.swift:146 | var | public | public var placeholderImage: UIImage? |
| PooToolsSource/ScrollBanner/PTBannerView.swift:150 | var | public | public var showsNavigationButtons = false |
| PooToolsSource/ScrollBanner/PTBannerView.swift:151 | var | public | public var previousButtonImage: UIImage? |
| PooToolsSource/ScrollBanner/PTBannerView.swift:152 | var | public | public var nextButtonImage: UIImage? |
| PooToolsSource/ScrollBanner/PTBannerView.swift:156 | var | public | public var iCloudDocumentName = "" |
| PooToolsSource/ScrollBanner/PTBannerView.swift:157 | var | public | public var loadingProgressWidth: CGFloat = 1.5 |
| PooToolsSource/ScrollBanner/PTBannerView.swift:158 | var | public | public var loadingProgressColor: DynamicColor = .purple |
| PooToolsSource/ScrollBanner/PTBannerView.swift:162 | var | public | public var backgroundImage: UIImage? |
| PooToolsSource/ScrollBanner/PTBannerView.swift:163 | var | public | public var showPlayButton = true |
| PooToolsSource/ScrollBanner/PTBannerView.swift:164 | var | public | public var collectionViewBackgroundColor: UIColor = .clear |
| PooToolsSource/ScrollBanner/PTBannerView.swift:166 | var | public | public var pageControlLeadingOrTrialingContact: CGFloat = 28 |
| PooToolsSource/ScrollBanner/PTBannerView.swift:170 | class | public | public class PTBannerView: UIView { |
| PooToolsSource/ScrollBanner/PTBannerView.swift:172 | var | public | public var bannerModel: [PTBannerModel] = [] { |
| PooToolsSource/ScrollBanner/PTBannerView.swift:177 | var | public | public var didSelectIndex:PTCycleIndexClosure? = nil |
| PooToolsSource/ScrollBanner/PTBannerView.swift:178 | var | public | public var scrollViewDidScrollClosure: PTScrollViewDidScrollClosure? |
| PooToolsSource/ScrollBanner/PTBannerView.swift:179 | var | public | public var scrollFromClosure: PTCycleIndexClosure? |
| PooToolsSource/ScrollBanner/PTBannerView.swift:180 | var | public | public var scrollToClosure: PTCycleIndexClosure? |
| PooToolsSource/ScrollBanner/PTBannerView.swift:181 | var | public | public var playEndCallback: PTActionTask? |
| PooToolsSource/ScrollBanner/PTBannerView.swift:279 | init | public | public init(viewConfig:PTBannerConfiguration = PTBannerConfiguration()) { |
| PooToolsSource/ScrollBanner/PTBannerView.swift:514 | func | public | public func reloadData() { |
| PooToolsSource/ScrollBanner/PTBannerView.swift:518 | func | public | public func startAutoScroll() { |
| PooToolsSource/ScrollBanner/PTBannerView.swift:523 | func | public | public func stopAutoScroll() { |
| PooToolsSource/ScrollBanner/PTBannerView.swift:527 | func | public | public func setupTimer() { |
| PooToolsSource/ScrollBanner/PTBannerView.swift:531 | func | public | public func invalidateTimer() { |
| PooToolsSource/ScrollBanner/PTBannerView.swift:535 | func | public | public func currentIndex() -> NSInteger { |
| PooToolsSource/ScrollBanner/PTBannerView.swift:540 | func | public | public func scrollToPage(index: Int, animated: Bool = true) { |
| PooToolsSource/ScrollBanner/PTBannerView.swift:559 | func | public | public func scrollByDirection(_ gestureRecognizer: UITapGestureRecognizer) { |
| PooToolsSource/ScrollBanner/PTBannerView.swift:710 | func | public | public func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int { |
| PooToolsSource/ScrollBanner/PTBannerView.swift:714 | func | public | public func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell { |
| PooToolsSource/ScrollBanner/PTBannerView.swift:739 | func | public | public func collectionView(_ cv: UICollectionView, didSelectItemAt indexPath: IndexPath) { |
| PooToolsSource/ScrollBanner/PTBannerView.swift:743 | func | public | public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { |
| PooToolsSource/ScrollBanner/PTBannerView.swift:758 | func | public | public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) { |
| PooToolsSource/ScrollBanner/PTBannerView.swift:769 | func | public | public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { |
| PooToolsSource/ScrollBanner/PTBannerView.swift:775 | func | public | public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) { |
| PooToolsSource/ScrollBanner/PTBannerView.swift:787 | func | public | public func scrollViewDidScroll(_ scrollView: UIScrollView) { |
| PooToolsSource/ScrollBanner/PTBannerView.swift:942 | func | public | public func playCurrentCellVideo(playCallback: PTBoolTask? = nil) { |
| PooToolsSource/ScrollBanner/PTBannerView.swift:948 | func | public | public func pipStar(floatingCallback: @escaping ((AVPlayerLayer?) -> Void)) { |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:18 | enum | public | @objc public enum PageControlStyle: Int { |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:25 | enum | public | @objc public enum PageControlPosition: Int { |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:29 | typealias | public | public typealias PTCycleIndexClosure = (_ index: NSInteger) -> Void |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:30 | typealias | public | public typealias PTScrollViewDidScrollClosure = (_ index: NSInteger, _ offSet: CGFloat) -> Void |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:38 | class | public | public class PTCycleScrollView: PTBannerView { |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:50 | var | public | public var imagePaths: [Any] = [] { |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:57 | var | public | public var titles: [Any] = [] { |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:66 | var | public | public var didSelectItemAtIndexClosure: PTCycleIndexClosure? { |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:72 | var | public | public var autoScroll: Bool = true { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:73 | var | public | public var infiniteLoop: Bool = true { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:74 | var | public | public var scrollDirection: UICollectionView.ScrollDirection? = .horizontal { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:75 | var | public | public var autoScrollTimeInterval: Double = 2 { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:76 | var | public | public var collectionViewBackgroundColor: UIColor = .clear { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:77 | var | public | public var imageViewContentMode: UIView.ContentMode? { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:78 | var | public | public var textColor: UIColor = .white { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:79 | var | public | public var numberOfLines: NSInteger = 2 { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:80 | var | public | public var titleLeading: CGFloat = 15 { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:81 | var | public | public var font: UIFont = .systemFont(ofSize: 15) { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:82 | var | public | public var titleBackgroundColor: UIColor = UIColor.black.withAlphaComponent(0.3) { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:83 | var | public | public var arrowLRIcon: [Any]? { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:84 | var | public | public var arrowLRFrame: [CGRect]? { |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:92 | var | public | public var pageControlTintColor: UIColor = .lightGray { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:93 | var | public | public var pageControlCurrentPageColor: UIColor = .white { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:94 | var | public | public var fillPageControlIndicatorRadius: CGFloat = 4 { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:95 | var | public | public var customPageControlInActiveTintColor: UIColor = UIColor(white: 1, alpha: 0.3) { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:96 | var | public | public var pageControlActiveImage: UIImage? { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:97 | var | public | public var pageControlInActiveImage: UIImage? { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:98 | var | public | public var dotSpacing: CGFloat = 8 { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:99 | var | public | public var customPageControlStyle: PageControlStyle = .system { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:100 | var | public | public var customPageControlTintColor: UIColor = .white { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:101 | var | public | public var customPageControlIndicatorPadding: CGFloat = 8 { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:102 | var | public | public var pageControlPosition: PageControlPosition = .center { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:103 | var | public | public var pageControlLeadingOrTrialingContact: CGFloat = 28 { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:104 | var | public | public var pageControlBottom: CGFloat = 5 { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:106 | var | public | public var iCloudDocument: String = "" |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:107 | var | public | public var defaultPlaceholderImage: UIImage = PTAppBaseConfig.share.defaultPlaceholderImage { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:108 | var | public | public var loadingProgressWidth: CGFloat = 1.5 |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:109 | var | public | public var loadingProgressColor: DynamicColor = .purple |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:110 | var | public | public var autoPlayVideo: Bool = false { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:111 | var | public | public var showPlayButton: Bool = true { didSet { synchronizeLegacyState() } } |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:136 | class | public | public class func cycleScrollViewCreate(imageURLPaths: [Any]? = [], |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:146 | class | public | public class func cycleScrollViewWithTitles(backImage: UIImage? = nil, |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:158 | class | public | public class func cycleScrollViewWithArrow(arrowLRImages: [Any], |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:174 | func | public | public func setupArrowIcon() { |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:178 | func | public | public func automaticScroll() { |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:190 | func | public | public func scollToIndex(targetIndex: Int) { |
| PooToolsSource/ScrollBanner/PTCycleScrollView.swift:197 | func | public | public func pageControlIndexWithCurrentCellIndex(index: NSInteger) -> Int { |
| PooToolsSource/SearchBar/PTSearchBar.swift:12 | class | public | public class PTSearchBarTextFieldClearButtonConfig: NSObject { |
| PooToolsSource/SearchBar/PTSearchBar.swift:13 | var | public | public var clearAction: PTActionTask? |
| PooToolsSource/SearchBar/PTSearchBar.swift:14 | var | public | public var clearImage: Any? |
| PooToolsSource/SearchBar/PTSearchBar.swift:15 | var | public | public var clearTopSpace: CGFloat = 2 |
| PooToolsSource/SearchBar/PTSearchBar.swift:19 | class | public | public class PTSearchBar: UISearchBar { |
| PooToolsSource/SearchBar/PTSearchBar.swift:22 | var | open | open var searchPlaceholder: String = "PT Input text".localized() { didSet { updateTextUI() } } |
| PooToolsSource/SearchBar/PTSearchBar.swift:23 | var | open | open var searchPlaceholderFont: UIFont = .systemFont(ofSize: 16) { didSet { updateTextUI() } } |
| PooToolsSource/SearchBar/PTSearchBar.swift:24 | var | open | open var searchBarTextFieldBorderColor: UIColor = UIColor.random { didSet { updateBorderUI() } } |
| PooToolsSource/SearchBar/PTSearchBar.swift:25 | var | open | open var cursorColor: UIColor = .lightGray { didSet { updateTextUI() } } |
| PooToolsSource/SearchBar/PTSearchBar.swift:26 | var | open | open var searchPlaceholderColor: UIColor = UIColor.random { didSet { updateTextUI() } } |
| PooToolsSource/SearchBar/PTSearchBar.swift:27 | var | open | open var searchTextColor: UIColor = UIColor.random { didSet { updateTextUI() } } |
| PooToolsSource/SearchBar/PTSearchBar.swift:28 | var | open | open var searchBarOutViewColor: UIColor = UIColor.random { didSet { updateBackgroundUI() } } |
| PooToolsSource/SearchBar/PTSearchBar.swift:29 | var | open | open var searchBarTextFieldCornerRadius: CGFloat = 5 { didSet { updateBorderUI() } } |
| PooToolsSource/SearchBar/PTSearchBar.swift:30 | var | open | open var searchBarTextFieldBorderWidth: CGFloat = 0.5 { didSet { updateBorderUI() } } |
| PooToolsSource/SearchBar/PTSearchBar.swift:31 | var | open | open var searchTextFieldBackgroundColor: UIColor = UIColor.random { didSet { updateTextUI() } } |
| PooToolsSource/SearchBar/PTSearchBar.swift:33 | var | open | open var searchImageTopSpacing: CGFloat = 2 |
| PooToolsSource/SearchBar/PTSearchBar.swift:34 | var | open | open var searchBarImage: Any? { |
| PooToolsSource/SearchBar/PTSearchBar.swift:38 | var | open | open var clearConfig: PTSearchBarTextFieldClearButtonConfig? { |
| PooToolsSource/SegmentControl/PTMainSegmentCell.swift:16 | class | public | public class PTMainSegmentCell: JXSegmentedBaseCell { |
| PooToolsSource/SegmentControl/PTMainSegmentCell.swift:24 | let | public | public let lineView = UIView() |
| PooToolsSource/SegmentControl/PTMainSegmentCell.swift:26 | let | public | public let titleLabel = UILabel() |
| PooToolsSource/SegmentControl/PTMainSegmentCell.swift:27 | let | public | public let subTitleLabel = UILabel() |
| PooToolsSource/SegmentControl/PTMainSegmentDataSource.swift:16 | class | public | public class PTMainSegmentDataSource: JXSegmentedBaseDataSource, @unchecked Sendable { |
| PooToolsSource/SegmentControl/PTMainSegmentDataSource.swift:19 | var | open | open var dataSourceData = [PTSegmentControlBaseModel]() |
| PooToolsSource/SegmentControl/PTMainSegmentDataSource.swift:20 | var | open | open var change: PTSegmentControlModelType? = .ImageTitle(type: .Normal) |
| PooToolsSource/SegmentControl/PTMainSegmentDataSource.swift:21 | var | open | open var titleNormalColor: UIColor = .black |
| PooToolsSource/SegmentControl/PTMainSegmentDataSource.swift:22 | var | open | open var titleSelectedColor: UIColor = .black |
| PooToolsSource/SegmentControl/PTMainSegmentDataSource.swift:23 | var | open | open var itemWidths: CGFloat = CGFloat.kSCREEN_WIDTH / 4 |
| PooToolsSource/SegmentControl/PTMainSegmentModel.swift:12 | enum | public | public enum PTSegmentControlModelType { |
| PooToolsSource/SegmentControl/PTMainSegmentModel.swift:17 | enum | public | public enum PTSegmentControlModelSubType { |
| PooToolsSource/SegmentControl/PTMainSegmentModel.swift:23 | class | public | public class PTMainSegmentModel: JXSegmentedTitleItemModel,@unchecked Sendable { |
| PooToolsSource/SegmentControl/PTMainSegmentModel.swift:24 | var | open | open var subTitle: String? = "" |
| PooToolsSource/SegmentControl/PTMainSegmentModel.swift:25 | var | open | open var subTitleNormalColor: UIColor = .black |
| PooToolsSource/SegmentControl/PTMainSegmentModel.swift:26 | var | open | open var subTitleCurrentColor: UIColor = .black |
| PooToolsSource/SegmentControl/PTMainSegmentModel.swift:27 | var | open | open var subTitleSelectedColor: UIColor = .white |
| PooToolsSource/SegmentControl/PTMainSegmentModel.swift:28 | var | open | open var subTitleCurrentBGColor: UIColor = .clear |
| PooToolsSource/SegmentControl/PTMainSegmentModel.swift:29 | var | open | open var subTitleNormalBGColor: UIColor = .clear |
| PooToolsSource/SegmentControl/PTMainSegmentModel.swift:30 | var | open | open var subTitleSelectedBGColor: UIColor = .clear |
| PooToolsSource/SegmentControl/PTMainSegmentModel.swift:31 | var | open | open var itemWidthIncrement : CGFloat = 0 |
| PooToolsSource/SegmentControl/PTMainSegmentModel.swift:32 | var | open | open var onlyShowTitle:PTSegmentControlModelType? = .OnlyTitle(type: .Normal) |
| PooToolsSource/SegmentControl/PTMainSegmentModel.swift:33 | var | open | open var subTitleNormalFont: UIFont = .appfont(size: 12) |
| PooToolsSource/SegmentControl/PTMainSegmentModel.swift:34 | var | open | open var subTitleSelectedFont: UIFont = .appfont(size: 12,bold: true) |
| PooToolsSource/SegmentControl/PTMainSegmentModel.swift:35 | var | open | open var modelIndex:Int = 0 |
| PooToolsSource/SegmentControl/PTMainSegmentModel.swift:36 | var | open | open var itemSpace:CGFloat = 0 |
| PooToolsSource/SegmentControl/PTMainSegmentModel.swift:37 | var | open | open var imageURL:String = "" |
| PooToolsSource/SegmentControl/PTSegmentControlBaseModel.swift:12 | var | public | public var categoryName:String = "" |
| PooToolsSource/SegmentControl/PTSegmentControlBaseModel.swift:13 | var | public | public var subTitle:String = "" |
| PooToolsSource/SegmentControl/PTSegmentControlBaseModel.swift:14 | var | public | public var imageURL:String = "" |
| PooToolsSource/Segmented/PTSegmentView.swift:14 | enum | public | @objc public enum PTSegmentSelectedType : Int { |
| PooToolsSource/Segmented/PTSegmentView.swift:22 | class | public | public class PTSegmentConfig: NSObject { |
| PooToolsSource/Segmented/PTSegmentView.swift:24 | var | public | public var selectedFont:UIFont = .systemFont(ofSize: 16) |
| PooToolsSource/Segmented/PTSegmentView.swift:26 | var | public | public var normalFont:UIFont = .boldSystemFont(ofSize: 14) |
| PooToolsSource/Segmented/PTSegmentView.swift:28 | var | public | public var showType:PTSegmentSelectedType = .UnderLine |
| PooToolsSource/Segmented/PTSegmentView.swift:30 | var | public | public var selectedColor:UIColor = .red |
| PooToolsSource/Segmented/PTSegmentView.swift:32 | var | public | public var normalColor:UIColor = .black |
| PooToolsSource/Segmented/PTSegmentView.swift:34 | var | public | public var normalColor_BG:UIColor = .clear |
| PooToolsSource/Segmented/PTSegmentView.swift:36 | var | public | public var selectedColor_BG:UIColor = .systemBlue |
| PooToolsSource/Segmented/PTSegmentView.swift:38 | var | public | public var underHight:CGFloat = 3 |
| PooToolsSource/Segmented/PTSegmentView.swift:40 | var | public | public var normalSelecdIndex:Int = 0 |
| PooToolsSource/Segmented/PTSegmentView.swift:42 | var | public | public var subViewInContentSpace:CGFloat = 20 |
| PooToolsSource/Segmented/PTSegmentView.swift:44 | var | public | public var underlineRadius:Bool = true |
| PooToolsSource/Segmented/PTSegmentView.swift:46 | var | public | public var imagePosition:PTLayoutButtonStyle = .leftImageRightTitle |
| PooToolsSource/Segmented/PTSegmentView.swift:48 | var | public | public var imageTitleSpace:CGFloat = 5 |
| PooToolsSource/Segmented/PTSegmentView.swift:50 | var | public | public var bottomSquare:CGFloat = 5 |
| PooToolsSource/Segmented/PTSegmentView.swift:52 | var | public | public var leftEdges:Bool = false |
| PooToolsSource/Segmented/PTSegmentView.swift:54 | var | public | public var itemSpace:CGFloat = 0 |
| PooToolsSource/Segmented/PTSegmentView.swift:56 | var | public | public var originalX:CGFloat = 0 |
| PooToolsSource/Segmented/PTSegmentView.swift:57 | var | public | public var badgeXOffset:CGFloat = 5 |
| PooToolsSource/Segmented/PTSegmentView.swift:61 | class | public | public class PTSegmentModel:NSObject { |
| PooToolsSource/Segmented/PTSegmentView.swift:63 | var | public | public var titles:String = "" |
| PooToolsSource/Segmented/PTSegmentView.swift:65 | var | public | public var imageURL:Any? |
| PooToolsSource/Segmented/PTSegmentView.swift:67 | var | public | public var imagePlaceHolder:String = "" |
| PooToolsSource/Segmented/PTSegmentView.swift:69 | var | public | public var selectedImageURL:Any? |
| PooToolsSource/Segmented/PTSegmentView.swift:71 | var | public | public var iCloudDocument:String = "" |
| PooToolsSource/Segmented/PTSegmentView.swift:74 | enum | public | @objc public enum PTSegmentButtonShowType:Int { |
| PooToolsSource/Segmented/PTSegmentView.swift:81 | class | public | public class PTSegmentSubView:UIView { |
| PooToolsSource/Segmented/PTSegmentView.swift:221 | class | public | public class PTSegmentView: UIView { |
| PooToolsSource/Segmented/PTSegmentView.swift:224 | var | open | open var viewDatas = [PTSegmentModel]() |
| PooToolsSource/Segmented/PTSegmentView.swift:226 | enum | public | public enum PooSegmentBadgePosition { |
| PooToolsSource/Segmented/PTSegmentView.swift:238 | var | open | open var selectedIndex:Int? { |
| PooToolsSource/Segmented/PTSegmentView.swift:245 | var | public | public var segTapBlock:((_ currentIndex:Int) -> Void)? |
| PooToolsSource/Segmented/PTSegmentView.swift:259 | init | public | public init(config:PTSegmentConfig? = PTSegmentConfig()) { |
| PooToolsSource/Segmented/PTSegmentView.swift:265 | func | public | public func reloadViewData(block:((_ index:Int) -> Void)?) { |
| PooToolsSource/Segmented/PTSegmentView.swift:416 | func | public | public func setSelectItem(indexs:Int) { |
| PooToolsSource/Segmented/PTSegmentView.swift:448 | func | public | public func setSegBadge(indexView:Int, |
| PooToolsSource/Segmented/PTSegmentView.swift:463 | func | public | public func setSegBadge(indexView: Int, |
| PooToolsSource/Segmented/PTSegmentView.swift:498 | func | public | public func removeBadgeAtIndex(indexView:Int) { |
| PooToolsSource/Segmented/PTSegmentView.swift:506 | func | public | public func removeAllBadge() { |
| PooToolsSource/Share/PTActivityViewController.swift:12 | class | open | open class PTShareItem: NSObject,UIActivityItemSource { |
| PooToolsSource/Share/PTActivityViewController.swift:17 | init | public | public init(title: String, content: String, url: URL? = nil) { |
| PooToolsSource/Share/PTActivityViewController.swift:23 | func | public | public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any { |
| PooToolsSource/Share/PTActivityViewController.swift:27 | func | public | public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? { |
| PooToolsSource/Share/PTActivityViewController.swift:53 | class | public | public class PTShareCustomActivity: UIActivity { |
| PooToolsSource/Share/PTActivityViewController.swift:55 | var | open | open var text:String? |
| PooToolsSource/Share/PTActivityViewController.swift:56 | var | open | open var url:URL? |
| PooToolsSource/Share/PTActivityViewController.swift:57 | var | open | open var image:UIImage? |
| PooToolsSource/Share/PTActivityViewController.swift:59 | var | open | open var customActivityTitle:String? |
| PooToolsSource/Share/PTActivityViewController.swift:60 | var | open | open var customActivityImage:UIImage? |
| PooToolsSource/Share/PTActivityViewController.swift:132 | class | open | open class PTActivityViewController:UIActivityViewController { |
| PooToolsSource/Share/PTActivityViewController.swift:184 | var | open | open var fadeInDuration: TimeInterval = 0.3 |
| PooToolsSource/Share/PTActivityViewController.swift:187 | var | open | open var fadeOutDuration: TimeInterval = 0.3 |
| PooToolsSource/Share/PTActivityViewController.swift:190 | var | open | open var previewCornerRadius: CGFloat = 12 |
| PooToolsSource/Share/PTActivityViewController.swift:193 | var | open | open var previewImageCornerRadius: CGFloat = 3 |
| PooToolsSource/Share/PTActivityViewController.swift:196 | var | open | open var previewImageSideLength: CGFloat = 80 |
| PooToolsSource/Share/PTActivityViewController.swift:199 | var | open | open var previewPadding: CGFloat = 12 |
| PooToolsSource/Share/PTActivityViewController.swift:202 | var | open | open var previewNumberOfLines: Int = 5 |
| PooToolsSource/Share/PTActivityViewController.swift:205 | var | open | open var previewLinkColor: UIColor = UIColor(red: 0, green: 0.47, blue: 1, alpha: 1) |
| PooToolsSource/Share/PTActivityViewController.swift:208 | var | open | open var previewFont: UIFont = .appfont(size: 16,bold:true) |
| PooToolsSource/Share/PTActivityViewController.swift:211 | var | open | open var previewTopMargin: CGFloat = 8 |
| PooToolsSource/Share/PTActivityViewController.swift:214 | var | open | open var previewBottomMargin: CGFloat = 8 |
| PooToolsSource/Share/PTActivityViewController.swift:383 | func | public | public func presentActionSheet(_ vc: UIViewController, from view: UIView,completion:PTActionTask? = nil) { |
| PooToolsSource/SideMenuControl/PTBaseSideController.swift:12 | class | open | open class PTBaseSideController: PTBaseViewController { } |
| PooToolsSource/SideMenuControl/PTSideMenuBasicTransitionAnimator.swift:13 | class | public | public class PTSideMenuBasicTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning { |
| PooToolsSource/SideMenuControl/PTSideMenuBasicTransitionAnimator.swift:21 | init | public | public init(options: UIView.AnimationOptions = .transitionCrossDissolve, duration: TimeInterval = 0.4) { |
| PooToolsSource/SideMenuControl/PTSideMenuBasicTransitionAnimator.swift:27 | func | public | public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval { |
| PooToolsSource/SideMenuControl/PTSideMenuBasicTransitionAnimator.swift:31 | func | public | public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) { |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:11 | typealias | public | public typealias PTSideMenuControlHandler = (_ sideMenuControl: PTSideMenuControl) -> Void |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:12 | typealias | public | public typealias PTSideMenuControlShowAndAnimationHandler = (_ sideMenuControl: PTSideMenuControl, _ show: UIViewController, _ animated: Bool) -> Void |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:16 | class | open | open class PTSideMenuControl: PTBaseViewController { |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:18 | enum | public | public enum PTSideMenuError: Error, Equatable, Sendable { |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:24 | var | public | public var sideMenuControlGetMenuWidth: ((_ sideMenuControl: PTSideMenuControl, _ forSize: CGSize) -> CGFloat)? |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:25 | var | public | public var sideMenuControlWillShow: PTSideMenuControlShowAndAnimationHandler? |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:26 | var | public | public var sideMenuControlDidShow: PTSideMenuControlShowAndAnimationHandler? |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:27 | var | public | public var sideMenuControlWillReveal: PTSideMenuControlHandler? |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:28 | var | public | public var sideMenuControlWillHideReveal: PTSideMenuControlHandler? |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:29 | var | public | public var sideMenuControlDidReveal: PTSideMenuControlHandler? |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:30 | var | public | public var sideMenuControlDidHideMenu: PTSideMenuControlHandler? |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:31 | var | public | public var sideMenuControlAnimationIn: ((_ sideMenuControl: PTSideMenuControl, _ animationControllerFrom: UIViewController, _ toVC: UIViewController) -> UIViewControllerAnimatedTransitioning)? |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:32 | var | public | public var sideMenuControlShouldRevealMenu: ((_ sideMenuControl: PTSideMenuControl) -> Bool)? |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:38 | var | public | @IBInspectable public var contentSegueID: String = PTSideMenuSegue.ContentType.content.rawValue |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:39 | var | public | @IBInspectable public var menuSegueID: String = PTSideMenuSegue.ContentType.menu.rawValue |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:108 | var | open | open var contentViewController: UIViewController! { |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:114 | var | open | open var menuViewController: UIViewController! { |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:121 | var | open | open var isMenuRevealed: Bool { |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:338 | func | open | open func revealMenu(animated: Bool = true, completion: PTBoolTask? = nil) { |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:342 | func | open | open func hideMenu(animated: Bool = true, completion: PTBoolTask? = nil) { |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:758 | func | open | open func cache(viewControllerGenerator: @escaping () -> UIViewController?, with identifier: String) { |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:762 | func | open | open func cache(viewController: UIViewController, with identifier: String) { |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:766 | func | open | open func selectContent(with identifier: String, |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:784 | func | open | open func selectContent(with identifier: String, animated: Bool = false) async throws { |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:797 | func | open | open func setContentViewController(with identifier: String, |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:808 | func | open | open func setContentViewController(to viewController: UIViewController, |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:920 | func | open | open func currentCacheIdentifier() -> String? { |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:924 | func | open | open func clearCache(with identifier: String) { |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:948 | func | public | public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool { |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:978 | func | public | public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool { |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1105 | struct | public | public struct PTSideMenuPreferences { |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1106 | enum | public | public enum MenuDirection { |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1111 | enum | public | public enum MenuPosition { |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1117 | struct | public | public struct PTSideMenuAnimation { |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1118 | var | public | public var revealDuration: TimeInterval = 0.4 |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1119 | var | public | public var hideDuration: TimeInterval = 0.4 |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1120 | var | public | public var options: UIView.AnimationOptions = .curveEaseInOut |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1121 | var | public | public var dampingRatio: CGFloat = 1 |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1122 | var | public | public var initialSpringVelocity: CGFloat = 1 |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1123 | var | public | public var shouldAddShadowWhenRevealing = true |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1124 | var | public | public var shadowAlpha: CGFloat = 0.2 |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1125 | var | public | public var shadowColor: UIColor = .black |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1126 | var | public | public var shouldAddBlurWhenRevealing = false |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1128 | init | public | public init() {} |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1131 | struct | public | public struct PTSideMentConfiguration { |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1132 | var | public | public var menuWidth: CGFloat = 300 |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1133 | var | public | public var position: MenuPosition = .above |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1134 | var | public | public var shouldRespectLanguageDirection = true |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1135 | var | public | public var forceRightToLeft = false |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1136 | var | public | public var direction: MenuDirection = .left |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1137 | var | public | public var enablePanGesture = true |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1138 | var | public | public var revealFromScreenEdgeOnly = false |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1139 | var | public | public var enableRubberEffectWhenPanning = true |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1140 | var | public | public var hideMenuWhenEnteringBackground = false |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1141 | var | public | public var defaultCacheKey: String? |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1142 | var | public | public var shouldUseContentSupportedOrientations = false |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1143 | var | public | public var supportedOrientations: UIInterfaceOrientationMask = .allButUpsideDown |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1144 | var | public | public var shouldAutorotate = true |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1145 | var | public | public var panGestureSensitivity: CGFloat = 0.25 |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1146 | var | public | public var keepsMenuOpenAfterRotation = false |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1148 | init | public | public init() {} |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1152 | typealias | public | public typealias PTSideMenuConfiguration = PTSideMentConfiguration |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1154 | var | public | public var basic = PTSideMentConfiguration() |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1155 | var | public | public var animation = PTSideMenuAnimation() |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1157 | init | public | public init() {} |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1163 | func | open | open func revealMenuAsync(animated: Bool = true) async -> Bool { |
| PooToolsSource/SideMenuControl/PTSideMenuControl.swift:1172 | func | open | open func hideMenuAsync(animated: Bool = true) async -> Bool { |
| PooToolsSource/SideMenuControl/PTSideMenuSegue.swift:12 | class | open | open class PTSideMenuSegue: UIStoryboardSegue { |
| PooToolsSource/SideMenuControl/PTSideMenuSegue.swift:15 | enum | public | public enum ContentType: String { |
| PooToolsSource/SideMenuControl/PTSideMenuSegue.swift:23 | var | public | public var contentType = ContentType.content |
| PooToolsSource/SignView/PTEasySignatureView.swift:15 | class | public | public class PTSignatureConfig:NSObject { |
| PooToolsSource/SignView/PTEasySignatureView.swift:16 | var | public | public var lineWidth:CGFloat = 1 |
| PooToolsSource/SignView/PTEasySignatureView.swift:17 | var | public | public var signNavTitleFont:UIFont = UIFont.appfont(size: 12,bold: true) |
| PooToolsSource/SignView/PTEasySignatureView.swift:18 | var | public | public var signNavTitleColor:UIColor = UIColor.randomColor |
| PooToolsSource/SignView/PTEasySignatureView.swift:19 | var | public | public var signNavDescFont:UIFont = UIFont.appfont(size: 10) |
| PooToolsSource/SignView/PTEasySignatureView.swift:20 | var | public | public var signNavDescColor:UIColor = UIColor.randomColor |
| PooToolsSource/SignView/PTEasySignatureView.swift:21 | var | public | public var signContentTitleFont:UIFont = UIFont.appfont(size: 15,bold: true) |
| PooToolsSource/SignView/PTEasySignatureView.swift:22 | var | public | public var signContentTitleColor:UIColor = UIColor.randomColor |
| PooToolsSource/SignView/PTEasySignatureView.swift:23 | var | public | public var signContentDescFont:UIFont = UIFont.appfont(size: 13) |
| PooToolsSource/SignView/PTEasySignatureView.swift:24 | var | public | public var signContentDescColor:UIColor = UIColor.randomColor |
| PooToolsSource/SignView/PTEasySignatureView.swift:25 | var | public | @MainActor public var infoTitle:String = "PT Sign placeholder".localized() |
| PooToolsSource/SignView/PTEasySignatureView.swift:26 | var | public | @MainActor public var infoDesc:String = "PT Sign font".localized() |
| PooToolsSource/SignView/PTEasySignatureView.swift:27 | var | public | @MainActor public var clearName:String = "PT Button delete".localized() |
| PooToolsSource/SignView/PTEasySignatureView.swift:28 | var | public | public var clearFont:UIFont = .appfont(size: 14) |
| PooToolsSource/SignView/PTEasySignatureView.swift:29 | var | public | public var clearTextColor:UIColor = .randomColor |
| PooToolsSource/SignView/PTEasySignatureView.swift:30 | var | public | @MainActor public var saveName:String = "PT Button save".localized() |
| PooToolsSource/SignView/PTEasySignatureView.swift:31 | var | public | public var saveFont:UIFont = .appfont(size: 14) |
| PooToolsSource/SignView/PTEasySignatureView.swift:32 | var | public | public var saveTextColor:UIColor = .randomColor |
| PooToolsSource/SignView/PTEasySignatureView.swift:33 | var | public | public var navBarColor:UIColor = .randomColor |
| PooToolsSource/SignView/PTEasySignatureView.swift:34 | var | public | public var signViewBackground:UIColor = .randomColor |
| PooToolsSource/SignView/PTEasySignatureView.swift:35 | var | public | public var waterMarkMessage:String = "" |
| PooToolsSource/SignView/PTEasySignatureView.swift:38 | typealias | public | public typealias OnSignatureWriteAction = (_ have:Bool) -> Void |
| PooToolsSource/SignView/PTImageBlackToTransparent.swift:12 | class | public | public class PTImageBlackToTransparent: NSObject { |
| PooToolsSource/SignView/PTSignView.swift:14 | typealias | public | public typealias SignImageBlock = (_ signImage:UIImage?) -> Void |
| PooToolsSource/SignView/PTSignView.swift:17 | class | public | public class PTSignView: UIView { |
| PooToolsSource/SignView/PTSignView.swift:21 | var | open | open var doneBlock:SignImageBlock? |
| PooToolsSource/SignView/PTSignView.swift:22 | var | open | open var dismissBlock:PTActionTask? |
| PooToolsSource/SignView/PTSignView.swift:104 | init | public | public init(viewConfig:PTSignatureConfig) { |
| PooToolsSource/SignView/PTSignView.swift:147 | func | public | public func showView() { |
| PooToolsSource/SignView/PTSignView.swift:154 | func | public | public func viewDismiss() { |
| PooToolsSource/SiriPermission/PTPermissionSiri.swift:19 | class | public | public class PTPermissionSiri: PTPermission { |
| PooToolsSource/SiriPermission/PTPermissionSiri.swift:22 | var | open | open var usageDescriptionKey: String? { "NSSiriUsageDescription" } |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:16 | class | open | open class TapticEngine { |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:24 | class | open | open class Impact { |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:25 | enum | public | public enum ImpactStyle { |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:49 | func | public | public func feedback(_ style: ImpactStyle) { |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:55 | func | public | public func prepare(_ style: ImpactStyle) { |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:63 | class | open | open class Selection { |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:70 | func | public | public func feedback() { |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:75 | func | public | public func prepare() { |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:82 | class | open | open class Notification { |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:83 | enum | public | public enum NotificationType { |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:101 | func | public | public func feedback(_ type: NotificationType) { |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:106 | func | public | public func prepare() { |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:117 | protocol | public | public protocol PTRangeSeekSliderDelegate: AnyObject { |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:140 | class | open | open class PTRangeSeekSlider: UIControl { |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:165 | var | open | @IBInspectable open var minValue: CGFloat = 0.0 { didSet { refresh() } } |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:166 | var | open | @IBInspectable open var maxValue: CGFloat = 100.0 { didSet { refresh() } } |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:168 | var | open | @IBInspectable open var selectedMinValue: CGFloat = 0.0 { |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:172 | var | open | @IBInspectable open var selectedMaxValue: CGFloat = 100.0 { |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:176 | var | open | open var minLabelFont: UIFont = UIFont.systemFont(ofSize: 12.0) { |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:183 | var | open | open var maxLabelFont: UIFont = UIFont.systemFont(ofSize: 12.0) { |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:190 | var | open | open var numberFormatter: NumberFormatter = { |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:197 | var | open | @IBInspectable open var hideLabels: Bool = false { |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:204 | var | open | @IBInspectable open var labelsFixed: Bool = false |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:205 | var | open | @IBInspectable open var minDistance: CGFloat = 0.0 { didSet { if minDistance < 0.0 { minDistance = 0.0 } } } |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:206 | var | open | @IBInspectable open var maxDistance: CGFloat = .greatestFiniteMagnitude { didSet { if maxDistance < 0.0 { maxDistance = .greatestFiniteMagnitude } } } |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:208 | var | open | @IBInspectable open var minLabelColor: UIColor? |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:209 | var | open | @IBInspectable open var maxLabelColor: UIColor? |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:210 | var | open | @IBInspectable open var handleColor: UIColor? |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:211 | var | open | @IBInspectable open var handleBorderColor: UIColor? |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:212 | var | open | @IBInspectable open var colorBetweenHandles: UIColor? |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:213 | var | open | @IBInspectable open var initialColor: UIColor? |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:215 | var | open | @IBInspectable open var disableRange: Bool = false { |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:222 | var | open | @IBInspectable open var enableStep: Bool = false |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:223 | var | open | @IBInspectable open var step: CGFloat = 0.0 |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:225 | var | open | @IBInspectable open var handleImage: UIImage? { |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:236 | var | open | @IBInspectable open var handleDiameter: CGFloat = 16.0 { |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:245 | var | open | @IBInspectable open var selectedHandleDiameterMultiplier: CGFloat = 1.7 |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:247 | var | open | @IBInspectable open var lineHeight: CGFloat = 1.0 { didSet { updateLineHeight() } } |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:248 | var | open | @IBInspectable open var handleBorderWidth: CGFloat = 0.0 { |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:254 | var | open | @IBInspectable open var labelPadding: CGFloat = 8.0 { didSet { updateLabelPositions() } } |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:256 | var | open | @IBInspectable open var minLabelAccessibilityLabel: String? |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:257 | var | open | @IBInspectable open var maxLabelAccessibilityLabel: String? |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:258 | var | open | @IBInspectable open var minLabelAccessibilityHint: String? |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:259 | var | open | @IBInspectable open var maxLabelAccessibilityHint: String? |
| PooToolsSource/Slider/PTRangeSeekSlider.swift:394 | func | open | open func setupStyle() {} |
| PooToolsSource/Slider/PTSlider.swift:12 | enum | public | public enum PTSliderTitlePosition: Int { |
| PooToolsSource/Slider/PTSlider.swift:18 | class | public | public class PTSlider: UISlider { |
| PooToolsSource/Slider/PTSlider.swift:23 | var | public | public var titleStyle: PTSliderTitlePosition = .top { |
| PooToolsSource/Slider/PTSlider.swift:28 | var | public | public var isLabelFloatingWithThumb: Bool = true { |
| PooToolsSource/Slider/PTSlider.swift:33 | var | public | public var step: Float = 0 |
| PooToolsSource/Slider/PTSlider.swift:36 | var | public | public var enableHapticFeedback: Bool = true |
| PooToolsSource/Slider/PTSlider.swift:38 | var | public | public var titleColor: UIColor = .systemBlue { |
| PooToolsSource/Slider/PTSlider.swift:42 | var | public | public var titleFont: UIFont = .systemFont(ofSize: 14) { |
| PooToolsSource/Slider/PTSlider.swift:47 | var | public | public var valueFormatter: ((Float) -> String)? { |
| PooToolsSource/Slider/PTSlider.swift:52 | var | public | public var showTitle: Bool = false { |
| PooToolsSource/Slider/PTSlider.swift:55 | var | public | public var showRawValue: Bool = false { |
| PooToolsSource/Slider/PTSlider.swift:58 | var | public | public var titleValueUnit: String = "" { |
| PooToolsSource/Slider/PTSlider.swift:81 | init | public | public init(showTitle: Bool = false, showRawValue: Bool = false) { |
| PooToolsSource/SocketKit/PTSocketManager.swift:12 | let | public | public let nNetworkStatesChangeNotification = Notification.Name("nNetworkStatesChangeNotification") |
| PooToolsSource/SocketKit/PTSocketManager.swift:13 | let | public | public let nWebSocketDidReceiveMessageNotification = Notification.Name("nWebSocketDidReceiveMessageNotification") |
| PooToolsSource/SocketKit/PTSocketManager.swift:14 | let | public | public let nWebSocketDidConnect = Notification.Name("nWebSocketDidConnect") |
| PooToolsSource/SocketKit/PTSocketManager.swift:15 | let | public | public let nWebSocketDidDisconnect = Notification.Name("nWebSocketDidDisconnect") |
| PooToolsSource/SocketKit/PTSocketManager.swift:18 | enum | public | public enum SocketConnectionState: Sendable { |
| PooToolsSource/SocketKit/PTSocketManager.swift:33 | protocol | public | public protocol PTSocketManagerDelegate: AnyObject,Sendable { |
| PooToolsSource/SocketKit/PTSocketManager.swift:55 | var | public | public var maxReConnectCount: Int { |
| PooToolsSource/SocketKit/PTSocketManager.swift:61 | var | public | public var socketState: SocketConnectionState { |
| PooToolsSource/SocketKit/PTSocketManager.swift:66 | var | public | public var networkStatus: NetWorkStatus { |
| PooToolsSource/SocketKit/PTSocketManager.swift:106 | func | public | public func addDelegate(_ delegate: PTSocketManagerDelegate) { |
| PooToolsSource/SocketKit/PTSocketManager.swift:112 | func | public | public func removeDelegate(_ delegate: PTSocketManagerDelegate) { |
| PooToolsSource/SocketKit/PTSocketManager.swift:131 | func | public | public func socketSet(completion: @escaping @Sendable (Bool) -> Void) { |
| PooToolsSource/SocketKit/PTSocketManager.swift:153 | func | public | public func connect() { |
| PooToolsSource/SocketKit/PTSocketManager.swift:168 | func | public | public func disConnect(clearQueue: Bool = true) { |
| PooToolsSource/SocketKit/PTSocketManager.swift:185 | func | public | public func reConnect() { |
| PooToolsSource/SocketKit/PTSocketManager.swift:253 | func | public | public func sendMessage(_ msg: Sendable) { |
| PooToolsSource/SocketKit/PTSocketManager.swift:296 | func | public | public func startHeartBeat() { |
| PooToolsSource/SocketKit/PTSocketManager.swift:328 | func | public | public func stopHeartBeat() { |
| PooToolsSource/SocketKit/PTSocketManager.swift:337 | func | public | public func webSocketDidOpen(_ webSocket: SRWebSocket) { |
| PooToolsSource/SocketKit/PTSocketManager.swift:355 | func | public | public func webSocket(_ webSocket: SRWebSocket, didReceiveMessage message: Any) { |
| PooToolsSource/SocketKit/PTSocketManager.swift:377 | func | public | public func webSocket(_ webSocket: SRWebSocket, didReceivePong pongPayload: Data?) { |
| PooToolsSource/SocketKit/PTSocketManager.swift:381 | func | public | public func webSocket(_ webSocket: SRWebSocket, didFailWithError error: Error) { |
| PooToolsSource/SocketKit/PTSocketManager.swift:385 | func | public | public func webSocket(_ webSocket: SRWebSocket, didCloseWithCode code: Int, reason: String?, wasClean: Bool) { |
| PooToolsSource/Speech/PTSpeech.swift:13 | typealias | public | public typealias ErrorBlock = (_ error:NSError) -> Void |
| PooToolsSource/Speech/PTSpeech.swift:14 | typealias | public | public typealias FinishBlock = (_ text:String) -> Void |
| PooToolsSource/Speech/PTSpeech.swift:16 | enum | public | @objc public enum PTSpeechErrorType:Int { |
| PooToolsSource/Speech/PTSpeech.swift:24 | class | public | public class PTSpeech: NSObject { |
| PooToolsSource/Speech/PTSpeech.swift:27 | var | open | open var errorBlock:ErrorBlock? |
| PooToolsSource/Speech/PTSpeech.swift:28 | var | open | open var finishBlock:FinishBlock? |
| PooToolsSource/Speech/PTSpeech.swift:110 | func | public | public func startRecognize(handleBlock:((_ success:Bool)->Void)?) { |
| PooToolsSource/Speech/PTSpeech.swift:121 | func | public | public func stopRecognize() { |
| PooToolsSource/Speech/PTSpeech.swift:130 | func | public | public func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) { |
| PooToolsSource/Speech/PTSpeech.swift:134 | func | public | public func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) { |
| PooToolsSource/SpeechPremission/PTPermissionSpeech.swift:19 | class | public | public class PTPermissionSpeech: PTPermission { |
| PooToolsSource/SpeechPremission/PTPermissionSpeech.swift:22 | var | open | open var usageDescriptionKey: String? { "NSSpeechRecognitionUsageDescription" } |
| PooToolsSource/SpeedPanel/PTSpeedPanel.swift:11 | typealias | public | public typealias PTPanelDetailTask = (_ speed:CGFloat)->Void |
| PooToolsSource/SpeedPanel/PTSpeedPanel.swift:13 | class | public | public class PTSpeedPanelConfig:NSObject { |
| PooToolsSource/SpeedPanel/PTSpeedPanel.swift:15 | var | open | open var maxValue:CGFloat = 100 |
| PooToolsSource/SpeedPanel/PTSpeedPanel.swift:17 | var | open | open var numberOfTicks = 8 |
| PooToolsSource/SpeedPanel/PTSpeedPanel.swift:19 | var | open | open var ticksColor:UIColor = .white |
| PooToolsSource/SpeedPanel/PTSpeedPanel.swift:21 | var | open | open var ticksLableFont:UIFont = .appfont(size: 16) |
| PooToolsSource/SpeedPanel/PTSpeedPanel.swift:23 | var | open | open var ticksLableColor:UIColor = .white |
| PooToolsSource/SpeedPanel/PTSpeedPanel.swift:25 | var | open | open var progressColor:UIColor = .randomColor |
| PooToolsSource/SpeedPanel/PTSpeedPanel.swift:27 | var | open | open var progressBackgroundColor:UIColor = .lightGray |
| PooToolsSource/SpeedPanel/PTSpeedPanel.swift:32 | class | public | public class PTSpeedPanel: UIView { |
| PooToolsSource/SpeedPanel/PTSpeedPanel.swift:33 | var | open | open var callBack:PTPanelDetailTask? = nil |
| PooToolsSource/SpeedPanel/PTSpeedPanel.swift:58 | init | public | public init(viewConfig:PTSpeedPanelConfig) { |
| PooToolsSource/SpeedPanel/PTSpeedPanel.swift:192 | func | public | public func updateSpeed(speed: CGFloat) { |
| PooToolsSource/StatusBar/StatusBarManager.swift:13 | class | public | public class StatusBarState: NSObject { |
| PooToolsSource/StatusBar/StatusBarManager.swift:17 | var | open | open var isHidden = false |
| PooToolsSource/StatusBar/StatusBarManager.swift:18 | var | open | open var style: UIStatusBarStyle = .default |
| PooToolsSource/StatusBar/StatusBarManager.swift:19 | var | open | open var animation: UIStatusBarAnimation = .fade |
| PooToolsSource/StatusBar/StatusBarManager.swift:20 | var | open | open var key = defaultKey |
| PooToolsSource/StatusBar/StatusBarManager.swift:22 | var | open | open var subStates = [StatusBarState]() |
| PooToolsSource/StatusBar/StatusBarManager.swift:33 | class | public | public class StatusBarManager { |
| PooToolsSource/StatusBar/StatusBarManager.swift:50 | var | open | open var isHidden: Bool { |
| PooToolsSource/StatusBar/StatusBarManager.swift:55 | var | open | open var style: UIStatusBarStyle { |
| PooToolsSource/StatusBar/StatusBarManager.swift:60 | var | open | open var animation: UIStatusBarAnimation { |
| PooToolsSource/StatusBar/StatusBarManager.swift:66 | func | public | public func addSubState(with key: String, root: String? = nil) -> StatusBarState? { |
| PooToolsSource/StatusBar/StatusBarManager.swift:91 | func | public | public func removeState(with key: String) { |
| PooToolsSource/StatusBar/StatusBarManager.swift:110 | func | public | public func showState(for key: String, root: String? = nil) { |
| PooToolsSource/StatusBar/StatusBarManager.swift:120 | func | public | public func clearSubStates(with key: String, isUpdate: Bool = true) { |
| PooToolsSource/StatusBar/StatusBarManager.swift:132 | func | public | public func printAllStates(_ method: String = #function) { |
| PooToolsSource/StatusBar/StatusBarManager.swift:137 | func | public | public func setState(for key: String? = nil, isHidden: Bool? = nil, style: UIStatusBarStyle? = nil, animation: UIStatusBarAnimation? = nil) { |
| PooToolsSource/StatusBar/StatusBarManager.swift:210 | func | public | public func update(with style: PTNavigationBarStyle) { |
| PooToolsSource/Stepper/PTStepper.swift:13 | typealias | public | public typealias PTStepperErrorAlert = (_ type:Bool) -> Void |
| PooToolsSource/Stepper/PTStepper.swift:14 | typealias | public | public typealias PTStepperValue = (_ string:String,_ valueChangeType:PTStepperVahleChangeType) -> Void |
| PooToolsSource/Stepper/PTStepper.swift:16 | enum | public | public enum PTStepperVahleChangeType:Int { |
| PooToolsSource/Stepper/PTStepper.swift:22 | enum | public | public enum PTStepperShowType:Int { |
| PooToolsSource/Stepper/PTStepper.swift:28 | class | public | public class PTStepper: UIView { |
| PooToolsSource/Stepper/PTStepper.swift:30 | var | public | public var inputingCallback:((String) -> Void)? |
| PooToolsSource/Stepper/PTStepper.swift:33 | var | open | open var inputBackgroundColor:UIColor = .clear { |
| PooToolsSource/Stepper/PTStepper.swift:40 | var | open | open var viewShowType:PTStepperShowType = .LTR { |
| PooToolsSource/Stepper/PTStepper.swift:47 | var | open | open var contentSpace:CGFloat = 1 |
| PooToolsSource/Stepper/PTStepper.swift:50 | var | open | open var alertBlock:PTStepperErrorAlert? |
| PooToolsSource/Stepper/PTStepper.swift:53 | var | open | open var valueBlock:PTStepperValue? |
| PooToolsSource/Stepper/PTStepper.swift:56 | var | open | open var isShake:Bool = true |
| PooToolsSource/Stepper/PTStepper.swift:59 | var | open | open var multipleNum:Int = 1 |
| PooToolsSource/Stepper/PTStepper.swift:62 | var | open | open var baseNum:String = "0" { |
| PooToolsSource/Stepper/PTStepper.swift:69 | var | open | open var minNum:Int = 0 |
| PooToolsSource/Stepper/PTStepper.swift:72 | var | open | open var maxNum:Int = 99999 |
| PooToolsSource/Stepper/PTStepper.swift:75 | var | open | open var canText:Bool = true { |
| PooToolsSource/Stepper/PTStepper.swift:82 | var | open | open var hideBorder:Bool = true { |
| PooToolsSource/Stepper/PTStepper.swift:89 | var | open | open var stepperBorderColor:UIColor = .lightGray { |
| PooToolsSource/Stepper/PTStepper.swift:96 | var | open | open var buttonBackgroundColor:UIColor = .clear { |
| PooToolsSource/Stepper/PTStepper.swift:104 | var | open | open var numberTextColor:UIColor = .black { |
| PooToolsSource/Stepper/PTStepper.swift:111 | var | open | open var numberTextFont:UIFont = .appfont(size: 13) { |
| PooToolsSource/Stepper/PTStepper.swift:118 | var | open | open var inputTintColor:UIColor = .systemBlue { |
| PooToolsSource/Stepper/PTStepper.swift:125 | var | open | open var addImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44)) { |
| PooToolsSource/Stepper/PTStepper.swift:132 | var | open | open var reduceImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44)) { |
| PooToolsSource/Stepper/PTStepper.swift:297 | func | public | public func textFieldDidBeginEditing(_ textField: UITextField) { |
| PooToolsSource/Stepper/PTStepper.swift:302 | func | public | public func textFieldDidEndEditing(_ textField: UITextField) { |
| PooToolsSource/Stepper/PTStepper.swift:317 | func | public | public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool { |
| PooToolsSource/Stepper/PTStepperCellsCollection.swift:14 | class | public | public class PTStepperHorizontalCell: PTBaseNormalCell { |
| PooToolsSource/Stepper/PTStepperCellsCollection.swift:17 | var | public | public var cellModel: PTStepperListModel! { |
| PooToolsSource/Stepper/PTStepperCellsCollection.swift:136 | class | public | public class PTStepperVerticalCell: PTBaseNormalCell { |
| PooToolsSource/Stepper/PTStepperCellsCollection.swift:140 | var | public | public var cellModel: PTStepperListModel! { |
| PooToolsSource/Stepper/PTStepperView.swift:14 | enum | public | public enum PTStepperViewType { |
| PooToolsSource/Stepper/PTStepperView.swift:18 | enum | public | public enum PTStepperHorizontalSubType { |
| PooToolsSource/Stepper/PTStepperView.swift:23 | enum | public | public enum PTStepperVerticalSubType { |
| PooToolsSource/Stepper/PTStepperView.swift:29 | class | open | open class PTStepperListConfig:NSObject { |
| PooToolsSource/Stepper/PTStepperView.swift:31 | var | public | public var type:PTStepperViewType = .Horizontal(type: .Normal) |
| PooToolsSource/Stepper/PTStepperView.swift:33 | var | public | public var stepperModels:[PTStepperListModel]! |
| PooToolsSource/Stepper/PTStepperView.swift:36 | var | public | public var itemWidth:CGFloat = 100 |
| PooToolsSource/Stepper/PTStepperView.swift:38 | var | public | public var itemHeight:CGFloat = 100 |
| PooToolsSource/Stepper/PTStepperView.swift:40 | var | public | public var itemOriginalX:CGFloat = 0 |
| PooToolsSource/Stepper/PTStepperView.swift:42 | var | public | public var emptyConfig:PTEmptyDataViewConfig? |
| PooToolsSource/Stepper/PTStepperView.swift:44 | var | public | public var currentStopLineColorShow:Bool = true |
| PooToolsSource/Stepper/PTStepperView.swift:47 | enum | public | public enum PTStepperModelStopType { |
| PooToolsSource/Stepper/PTStepperView.swift:56 | class | open | open class PTStepperListModel:NSObject { |
| PooToolsSource/Stepper/PTStepperView.swift:58 | var | public | public var title:String = "" |
| PooToolsSource/Stepper/PTStepperView.swift:60 | var | public | public var titleAtt:ASAttributedString? |
| PooToolsSource/Stepper/PTStepperView.swift:62 | var | public | public var titleColor:UIColor = DynamicColor(light: .black, dark: .white) |
| PooToolsSource/Stepper/PTStepperView.swift:64 | var | public | public var titleFont:UIFont = .appfont(size: 14) |
| PooToolsSource/Stepper/PTStepperView.swift:66 | var | public | public var desc:String = "" |
| PooToolsSource/Stepper/PTStepperView.swift:68 | var | public | public var descColor:UIColor = DynamicColor(light: .black, dark: .white) |
| PooToolsSource/Stepper/PTStepperView.swift:70 | var | public | public var descFont:UIFont = .appfont(size: 14) |
| PooToolsSource/Stepper/PTStepperView.swift:72 | var | public | public var descAtt:ASAttributedString? |
| PooToolsSource/Stepper/PTStepperView.swift:74 | var | public | public var circleFillColor:Bool = true |
| PooToolsSource/Stepper/PTStepperView.swift:76 | var | public | @PTClampedPropertyWrapper(range:10...64) public var stopCircleWidth: CGFloat = 44 |
| PooToolsSource/Stepper/PTStepperView.swift:78 | var | public | @PTClampedPropertyWrapper(range:0...8) public var borderWidth: CGFloat = 0 |
| PooToolsSource/Stepper/PTStepperView.swift:80 | var | public | public var stopNormalColor = DynamicColor.lightGray |
| PooToolsSource/Stepper/PTStepperView.swift:82 | var | public | public var stopSelectedColor = DynamicColor.cyan |
| PooToolsSource/Stepper/PTStepperView.swift:84 | var | public | @PTClampedPropertyWrapper(range:1...5) public var stopLineHeight: CGFloat = 1 |
| PooToolsSource/Stepper/PTStepperView.swift:86 | var | public | public var stopFinish:Bool = true |
| PooToolsSource/Stepper/PTStepperView.swift:88 | var | public | public var stopType:PTStepperModelStopType = .Step |
| PooToolsSource/Stepper/PTStepperView.swift:90 | var | public | public var stopInfo:Any? |
| PooToolsSource/Stepper/PTStepperView.swift:92 | var | public | public var stopFont:UIFont = .appfont(size: 14) |
| PooToolsSource/Stepper/PTStepperView.swift:95 | class | open | open class PTStepperView: UIView { |
| PooToolsSource/Stepper/PTStepperView.swift:97 | var | open | open var viewConfig:PTStepperListConfig = PTStepperListConfig() |
| PooToolsSource/Stepper/PTStepperView.swift:278 | func | public | public func viewConfigSet(viewConfig:PTStepperListConfig) { |
| PooToolsSource/Switch/PTSwitch.swift:11 | class | open | open class PTSwitch: UIControl { |
| PooToolsSource/Switch/PTSwitch.swift:12 | var | public | public var valueChangeCallBack:PTBoolTask? |
| PooToolsSource/Switch/PTSwitch.swift:15 | var | public | public var isOn = false { |
| PooToolsSource/Switch/PTSwitch.swift:21 | var | public | public var switchTintColor:UIColor = .systemGray4 { |
| PooToolsSource/Switch/PTSwitch.swift:27 | var | public | public var onTintColor:UIColor = .systemGreen { |
| PooToolsSource/Switch/PTSwitch.swift:33 | var | public | public var thumbColor:Any { |
| PooToolsSource/Switch/PTSwitch.swift:152 | func | public | public func setOn(_ on: Bool, animated: Bool) { |
| PooToolsSource/TipsView/PTTipsView.swift:31 | enum | public | public enum PopTipDirection { |
| PooToolsSource/TipsView/PTTipsView.swift:55 | enum | public | public enum PopTipEntranceAnimation { |
| PooToolsSource/TipsView/PTTipsView.swift:69 | enum | public | public enum PopTipExitAnimation { |
| PooToolsSource/TipsView/PTTipsView.swift:81 | enum | public | public enum PopTipActionAnimation { |
| PooToolsSource/TipsView/PTTipsView.swift:96 | class | open | open class PTTipsView: UIView { |
| PooToolsSource/TipsView/PTTipsView.swift:101 | var | open | open var text: String? { |
| PooToolsSource/TipsView/PTTipsView.swift:108 | var | open | open var font = UIFont.systemFont(ofSize: UIFont.systemFontSize) |
| PooToolsSource/TipsView/PTTipsView.swift:150 | var | open | open var entranceAnimation = PopTipEntranceAnimation.scale |
| PooToolsSource/TipsView/PTTipsView.swift:152 | var | open | open var exitAnimation = PopTipExitAnimation.scale |
| PooToolsSource/TipsView/PTTipsView.swift:154 | var | open | open var actionAnimation = PopTipActionAnimation.none |
| PooToolsSource/TipsView/PTTipsView.swift:185 | var | open | open var from = CGRect.zero { |
| PooToolsSource/TipsView/PTTipsView.swift:190 | var | open | open var isVisible: Bool { get { return self.superview != nil } } |
| PooToolsSource/TipsView/PTTipsView.swift:207 | var | open | open var swipeRemoveGestureDirection = UISwipeGestureRecognizer.Direction.right { |
| PooToolsSource/TipsView/PTTipsView.swift:213 | var | open | open var tapHandler: ((PTTipsView) -> Void)? |
| PooToolsSource/TipsView/PTTipsView.swift:214 | var | open | open var tapOutsideHandler: ((PTTipsView) -> Void)? |
| PooToolsSource/TipsView/PTTipsView.swift:215 | var | open | open var tapCutoutHandler: ((PTTipsView) -> Void)? |
| PooToolsSource/TipsView/PTTipsView.swift:216 | var | open | open var swipeOutsideHandler: ((PTTipsView) -> Void)? |
| PooToolsSource/TipsView/PTTipsView.swift:217 | var | open | open var appearHandler: ((PTTipsView) -> Void)? |
| PooToolsSource/TipsView/PTTipsView.swift:218 | var | open | open var dismissHandler: ((PTTipsView) -> Void)? |
| PooToolsSource/TipsView/PTTipsView.swift:220 | var | open | open var entranceAnimationHandler: ((@escaping () -> Void) -> Void)? |
| PooToolsSource/TipsView/PTTipsView.swift:221 | var | open | open var exitAnimationHandler: ((@escaping () -> Void) -> Void)? |
| PooToolsSource/TipsView/PTTipsView.swift:600 | func | open | open func show(text: String, direction: PopTipDirection, maxWidth: CGFloat, in view: UIView, from frame: CGRect, duration: TimeInterval? = nil) { |
| PooToolsSource/TipsView/PTTipsView.swift:615 | func | open | open func show(attributedText: NSAttributedString, direction: PopTipDirection, maxWidth: CGFloat, in view: UIView, from frame: CGRect, duration: TimeInterval? = nil) { |
| PooToolsSource/TipsView/PTTipsView.swift:630 | func | open | open func show(customView: UIView, direction: PopTipDirection, in view: UIView, from frame: CGRect, duration: TimeInterval? = nil) { |
| PooToolsSource/TipsView/PTTipsView.swift:646 | func | open | open func show<V: View>(rootView: V, direction: PopTipDirection, in view: UIView, from frame: CGRect, parent: UIViewController, duration: TimeInterval? = nil) { |
| PooToolsSource/TipsView/PTTipsView.swift:679 | func | open | open func update(text: String) { |
| PooToolsSource/TipsView/PTTipsView.swift:684 | func | open | open func update(attributedText: NSAttributedString) { |
| PooToolsSource/TipsView/PTTipsView.swift:689 | func | open | open func update(customView: UIView) { |
| PooToolsSource/TipsView/PTTipsView.swift:696 | func | open | @objc open func hide(forced: Bool = false) { |
| PooToolsSource/TipsView/PTTipsView.swift:738 | func | open | open func startActionAnimation() { |
| PooToolsSource/TipsView/PTTipsView.swift:742 | func | open | open func stopActionAnimation(_ completion: (() -> Void)? = nil) { |
| PooToolsSource/TouchInspector/TouchInspectorWindow.swift:20 | class | public | public class TouchInspectorWindow: UIWindow { |
| PooToolsSource/TouchInspector/TouchInspectorWindow.swift:22 | var | public | public var showTouches: Bool = PTCoreUserDefultsWrapper.shared.AppTouchInspectShow { |
| PooToolsSource/TouchInspector/TouchInspectorWindow.swift:29 | var | public | public var showHitTesting: Bool = PTCoreUserDefultsWrapper.shared.AppTouchInspectShowHits { |
| PooToolsSource/TrackingPermission/PTPermissionTracking.swift:20 | class | public | public class PTPermissionTracking: PTPermission { |
| PooToolsSource/TrackingPermission/PTPermissionTracking.swift:23 | var | open | open var usageDescriptionKey: String? { "NSUserTrackingUsageDescription" } |
| PooToolsSource/VideoEditor/Compositor.swift:16 | let | public | public let requiredPixelBufferAttributesForRenderContext: [String : any Sendable] = [ |
| PooToolsSource/VideoEditor/Compositor.swift:20 | let | public | public let sourcePixelBufferAttributes: [String : any Sendable]? = [ |
| PooToolsSource/VideoEditor/Compositor.swift:36 | func | public | public func startRequest(_ request: AVAsynchronousVideoCompositionRequest) { |
| PooToolsSource/VideoEditor/Compositor.swift:54 | func | public | public func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) { |
| PooToolsSource/VideoEditor/ConverterCrop.swift:11 | struct | public | public struct ConverterCrop:Sendable { |
| PooToolsSource/VideoEditor/ConverterCrop.swift:12 | var | public | public var frame: CGRect |
| PooToolsSource/VideoEditor/ConverterCrop.swift:13 | var | public | public var contrastSize: CGSize |
| PooToolsSource/VideoEditor/ConverterOption.swift:12 | struct | public | public struct PTConverterOptionOutputType: Sendable { |
| PooToolsSource/VideoEditor/ConverterOption.swift:14 | var | public | public var type: AVFileType |
| PooToolsSource/VideoEditor/ConverterOption.swift:17 | init | public | public init(type: AVFileType = .mov) { |
| PooToolsSource/VideoEditor/ConverterOption.swift:22 | var | public | public var name: String { |
| PooToolsSource/VideoEditor/ConverterOption.swift:44 | struct | public | public struct ConverterOption: Sendable { |
| PooToolsSource/VideoEditor/ConverterOption.swift:47 | var | public | public var trimRange: (Double, Double) = (0.0, 1.0) |
| PooToolsSource/VideoEditor/ConverterOption.swift:48 | var | public | public var convertCrop: ConverterCrop? |
| PooToolsSource/VideoEditor/ConverterOption.swift:49 | var | public | public var rotate: CGFloat? |
| PooToolsSource/VideoEditor/ConverterOption.swift:50 | var | public | public var quality: String? |
| PooToolsSource/VideoEditor/ConverterOption.swift:51 | var | public | public var isMute: Bool = false |
| PooToolsSource/VideoEditor/ConverterOption.swift:52 | var | public | public var speed: Double = 1.0 |
| PooToolsSource/VideoEditor/ConverterOption.swift:53 | var | public | public var outputModel: PTConverterOptionOutputType = PTConverterOptionOutputType() |
| PooToolsSource/VideoEditor/CropDimView.swift:54 | func | public | public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) { |
| PooToolsSource/VideoEditor/CropPickerView.swift:12 | protocol | public | public protocol CropPickerViewDelegate: AnyObject { |
| PooToolsSource/VideoEditor/CropPickerView.swift:18 | class | public | public class CropPickerView: UIView { |
| PooToolsSource/VideoEditor/CropPickerView.swift:23 | var | public | public var cropMinSize: CGFloat = 100 |
| PooToolsSource/VideoEditor/CropPickerView.swift:27 | var | public | public var image: UIImage? { |
| PooToolsSource/VideoEditor/CropPickerView.swift:48 | var | public | public var changeImage: UIImage? { |
| PooToolsSource/VideoEditor/CropPickerView.swift:59 | var | public | public var cropLineColor: UIColor? { |
| PooToolsSource/VideoEditor/CropPickerView.swift:78 | var | public | public var scrollBackgroundColor: UIColor? { |
| PooToolsSource/VideoEditor/CropPickerView.swift:89 | var | public | public var imageBackgroundColor: UIColor? { |
| PooToolsSource/VideoEditor/CropPickerView.swift:100 | var | public | public var dimBackgroundColor: UIColor? { |
| PooToolsSource/VideoEditor/CropPickerView.swift:111 | var | public | public var scrollMinimumZoomScale: CGFloat { |
| PooToolsSource/VideoEditor/CropPickerView.swift:122 | var | public | public var scrollMaximumZoomScale: CGFloat { |
| PooToolsSource/VideoEditor/CropPickerView.swift:132 | var | public | public var isCrop = true { |
| PooToolsSource/VideoEditor/CropPickerView.swift:329 | func | public | public func imageMaxAdjustment(_ duration: TimeInterval = 0.4, animated: Bool) { |
| PooToolsSource/VideoEditor/CropPickerView.swift:334 | func | public | public func imageMinAdjustment(_ duration: TimeInterval = 0.4, animated: Bool) { |
| PooToolsSource/VideoEditor/CropPickerView.swift:345 | func | public | public func imageAdjustment(_ point: CGPoint, duration: TimeInterval = 0.4, animated: Bool) { |
| PooToolsSource/VideoEditor/CropPickerView.swift:360 | func | public | public func image(_ image: UIImage?, isMin: Bool = true, crop: CGRect? = nil, isRealCropRect: Bool = false) { |
| PooToolsSource/VideoEditor/CropPickerView.swift:413 | func | public | public func crop(_ handler: ((CropResult) -> Void)? = nil) { |
| PooToolsSource/VideoEditor/CropPickerView.swift:820 | func | public | public func scrollViewDidZoom(_ scrollView: UIScrollView) { |
| PooToolsSource/VideoEditor/CropPickerView.swift:846 | func | public | public func viewForZooming(in scrollView: UIScrollView) -> UIView? { |
| PooToolsSource/VideoEditor/CropResult.swift:12 | struct | public | public struct CropResult { |
| PooToolsSource/VideoEditor/CropResult.swift:13 | var | public | public var error: Error? |
| PooToolsSource/VideoEditor/CropResult.swift:14 | var | public | public var image: UIImage? |
| PooToolsSource/VideoEditor/CropResult.swift:15 | var | public | public var cropFrame: CGRect? |
| PooToolsSource/VideoEditor/CropResult.swift:16 | var | public | public var imageSize: CGSize? |
| PooToolsSource/VideoEditor/CropResult.swift:18 | init | public | public init() { } |
| PooToolsSource/VideoEditor/CropResult.swift:20 | init | public | public init(error: Error, cropFrame: CGRect? = nil, imageSize: CGSize? = nil) { |
| PooToolsSource/VideoEditor/CropResult.swift:26 | init | public | public init(image: UIImage, cropFrame: CGRect? = nil, imageSize: CGSize? = nil) { |
| PooToolsSource/VideoEditor/Error.swift:13 | enum | public | public enum Error: Swift.Error { |
| PooToolsSource/VideoEditor/Error.swift:26 | var | public | public var description: String { |
| PooToolsSource/VideoEditor/Error.swift:31 | var | public | public var localizedDescription: String { |
| PooToolsSource/VideoEditor/Exporter.swift:14 | typealias | public | public typealias ExporterBuffer = CVPixelBuffer |
| PooToolsSource/VideoEditor/Exporter.swift:23 | struct | public | public struct Exporter { |
| PooToolsSource/VideoEditor/Exporter.swift:25 | typealias | public | public typealias PixelBufferCallback = @Sendable (_ buffer: ExporterBuffer) -> ExporterBuffer? |
| PooToolsSource/VideoEditor/Exporter.swift:26 | typealias | public | public typealias ExportComplete = @Sendable (Result<URL, Exporter.Error>) -> Void |
| PooToolsSource/VideoEditor/Exporter.swift:54 | init | public | public init(provider: Exporter.Provider) { |
| PooToolsSource/VideoEditor/Exporter.swift:71 | func | public | public func export(options: [Exporter.Option: Any] = [:], filtering: @escaping PixelBufferCallback, complete: @escaping ExportComplete) async { |
| PooToolsSource/VideoEditor/Options.swift:16 | struct | public | public struct Option : Hashable, Equatable, RawRepresentable, Sendable { |
| PooToolsSource/VideoEditor/Options.swift:17 | let | public | public let rawValue: UInt16 |
| PooToolsSource/VideoEditor/Options.swift:18 | init | public | public init(rawValue: UInt16) { |
| PooToolsSource/VideoEditor/PTVideoEditorBaseFloatingViewController.swift:13 | class | open | open class PTVideoEditorBaseFloatingViewController: PTBaseViewController { |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:14 | class | public | public class PTVideoEditorConfig: NSObject { |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:17 | var | public | public var themeColor:UIColor = UIColor.purple |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:18 | var | public | public var dismissImage:UIImage = "❌".emojiToImage(emojiFont: .appfont(size: 20)) |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:19 | var | public | public var cutImage:UIImage = "✂️".emojiToImage(emojiFont: .appfont(size: 20)) |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:20 | var | public | public var doneImage:UIImage = "✅".emojiToImage(emojiFont: .appfont(size: 20)) |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:21 | var | public | public var playImage:UIImage = UIImage(.play.circleFill).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)) |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:22 | var | public | public var playImageSelected:UIImage = UIImage(.pause.circleFill).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)) |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:23 | var | public | public var muteImage:UIImage = UIImage(.speaker).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)) |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:26 | var | public | public var speedImage:UIImage = UIImage(.bolt.horizontalCircle).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)) |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:28 | var | public | public var trimImage:UIImage = UIImage(.timeline.selection).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)) |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:29 | var | public | public var cropImage:UIImage = UIImage(.crop).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)) |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:30 | var | public | public var rotateImage:UIImage = UIImage(.rotate.right).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)) |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:31 | var | public | public var presetsImage:UIImage = UIImage(.tv).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)) |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:32 | var | public | public var filterImage:UIImage = UIImage(.camera.filters).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)) |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:33 | var | public | public var rewriteImage:UIImage = UIImage(.repeat).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)) |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:34 | var | public | public var trimLeftImage:UIImage = UIImage(.arrow.left) |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:35 | var | public | public var trimRightImage:UIImage = UIImage(.arrow.right) |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:37 | var | public | public var trimTitle:String = "PT Video editor function trim".localized() |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:38 | var | public | public var cropTitle:String = "PT Video editor function crop".localized() |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:39 | var | public | public var rotateTitle:String = "PT Video editor function rotate".localized() |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:40 | var | public | public var presetsTitle:String = "PT Video editor function export preset".localized() |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:41 | var | public | public var filterTitle:String = "PT Video editor function filter".localized() |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:42 | var | public | public var rewriteTitle:String = "PT Video editor function rewrite".localized() |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:43 | var | public | public var muteTitle:String = "PT Video editor function mute".localized() |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:44 | var | public | public var speedTitle:String = "PT Video editor function speed".localized() |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:46 | var | public | public var alertTitleOpps = "PT Alert Opps".localized() |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:47 | var | public | public var alertTitleDoing = "PT Alert Doning".localized() |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:48 | var | public | public var alertTitleConvetering = "PT Video editor convetering".localized() |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:49 | var | public | public var alertTitleOutputing = "PT Video editor ouputing".localized() |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:50 | var | public | public var alertTitleSaveDone = "PT Video editor function save done".localized() |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:51 | var | public | public var alertTitleSaveError = "PT Photo picker save video error".localized() |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:52 | var | public | public var alertTitleOutputType = "PT Video editor output type".localized() |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:53 | var | public | public var alertTitleOutputTypeOption = "PT Video editor function export preset select current".localized() |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:54 | var | public | public var alertTitleExportType = "PT Video editor function export preset select".localized() |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:58 | var | public | public var filters: [PTHarBethFilter] { |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:71 | var | public | public var outPutBorderWidth:CGFloat = 5 |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:72 | var | public | public var outPutBorderCorlor:UIColor = .systemBlue |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:73 | var | public | public var outPutProgressShowValueLabel:Bool = true |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:74 | var | public | public var outPutProgressShowValueFont:UIFont = .systemFont(ofSize: 16,weight:.bold) |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:75 | var | public | public var outPutProgressShowValueColor:UIColor = .systemBlue |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:77 | var | public | public var videoTimeFont:UIFont = .systemFont(ofSize: 13) |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:79 | var | public | public var sliderBackgroundColor = PTDarkModeOption.colorLightDark(lightColor: UIColor(hexString:"#eeeff4")!, darkColor: .black) |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:80 | var | public | public var sliderFontColor = PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white) |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:81 | var | public | public var sliberBorder = #colorLiteral(red: 0.9490196078, green: 0.9568627451, blue: 0.9647058824, alpha: 1) // F2F4F6 |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:82 | var | public | public var croppingPreset = #colorLiteral(red: 0.9490196078, green: 0.9568627451, blue: 0.9647058824, alpha: 1) // F2F4F6 |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:83 | var | public | public var croppingPresetSelected = #colorLiteral(red: 0.7323174477, green: 0.7364212871, blue: 0.7465394735, alpha: 1) // F2F4F6 |
| PooToolsSource/VideoEditor/PTVideoEditorFilterControl.swift:15 | var | public | public var filterHandler:((PTHarBethFilter)->Void)! |
| PooToolsSource/VideoEditor/PTVideoEditorFilterControl.swift:55 | init | public | public init(currentImage:UIImageView,currentFilter:PTHarBethFilter,viewControl: PTVideoEditorToolsModel) { |
| PooToolsSource/VideoEditor/PTVideoEditorToolsModel.swift:12 | enum | public | public enum PTVideoEditorVideoToolsType: CaseIterable { |
| PooToolsSource/VideoEditor/PTVideoEditorToolsSlider.swift:88 | init | public | public init() { |
| PooToolsSource/VideoEditor/PTVideoEditorToolsSpeedControl.swift:17 | var | public | public var speedHandler:((Double)->Void)! |
| PooToolsSource/VideoEditor/PTVideoEditorToolsTrimmingControl.swift:19 | var | public | public var trimPositions: (Double, Double) |
| PooToolsSource/VideoEditor/PTVideoEditorToolsTrimmingControl.swift:28 | var | public | public var isConfigured: Bool = false |
| PooToolsSource/VideoEditor/PTVideoEditorToolsTrimmingControl.swift:38 | var | public | public var internalRightTrimValue: CGFloat { |
| PooToolsSource/VideoEditor/PTVideoEditorToolsViewController.swift:19 | let | public | public let OutputFilePath = FileManager.pt.DocumnetsDirectory() + "/AudioEditor" |
| PooToolsSource/VideoEditor/PTVideoEditorToolsViewController.swift:22 | actor | public | public actor PTDebouncer { |
| PooToolsSource/VideoEditor/PTVideoEditorToolsViewController.swift:28 | init | public | public init(delay: TimeInterval) { |
| PooToolsSource/VideoEditor/PTVideoEditorToolsViewController.swift:34 | func | public | public func debounce(action: @escaping @Sendable () async -> Void) { |
| PooToolsSource/VideoEditor/PTVideoEditorToolsViewController.swift:112 | func | public | public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) { |
| PooToolsSource/VideoEditor/PTVideoEditorToolsViewController.swift:122 | class | public | public class PTVideoEditorToolsViewController: PTBaseViewController { |
| PooToolsSource/VideoEditor/PTVideoEditorToolsViewController.swift:143 | var | public | public var onEditCompleteHandler:((URL)->Void)? |
| PooToolsSource/VideoEditor/PTVideoEditorToolsViewController.swift:144 | var | public | public var onlyOutput:Bool = false |
| PooToolsSource/VideoEditor/PTVideoEditorToolsViewController.swift:1009 | init | public | public init(asset:PHAsset,avAsset:AVAsset) { |
| PooToolsSource/VideoEditor/PTVideoEditorToolsViewController.swift:1199 | func | public | public func videoEditorShow(vc:UIViewController) { |
| PooToolsSource/VideoEditor/PTVideoEditorToolsViewController.swift:1392 | func | public | public func preview(_ collector: C7Collector, fliter image: C7Image) { |
| PooToolsSource/VideoEditor/PTVideoEditorToolsViewController.swift:1421 | func | public | public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { |
| PooToolsSource/VideoEditor/PTVideoEditorToolsViewController.swift:1425 | func | public | public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { |
| PooToolsSource/VideoEditor/PTVideoEditorVideoTimeLineGenerator.swift:13 | class | public | public class PTVideoFrameTimeLineFunction { |
| PooToolsSource/VideoEditor/Provider.swift:14 | struct | public | public struct Provider { |
| PooToolsSource/VideoEditor/Provider.swift:23 | init | public | public init(with videoURL: URL, to outputURL: URL? = nil) { |
| PooToolsSource/VideoEditor/Provider.swift:28 | init | public | public init(with asset: AVAsset, to outputURL: URL? = nil) { |
| PooToolsSource/VideoEditor/VideoConverter.swift:34 | class | open | open class VideoConverter { |
| PooToolsSource/VideoEditor/VideoConverter.swift:38 | let | public | public let asset: AVAsset |
| PooToolsSource/VideoEditor/VideoConverter.swift:39 | var | public | public var presets: [String] = [] |
| PooToolsSource/VideoEditor/VideoConverter.swift:41 | var | public | public var option: ConverterOption? |
| PooToolsSource/VideoEditor/VideoConverter.swift:178 | init | public | public init(asset: AVAsset) async { |
| PooToolsSource/VideoEditor/VideoConverter.swift:201 | func | open | open func restore(cleanupDisk: Bool = false) { |
| PooToolsSource/VideoEditor/VideoConverter.swift:224 | func | open | open func convert(_ option: ConverterOption? = nil) async throws -> (AVMutableComposition, AVMutableVideoComposition) { |
| PooToolsSource/VideoEditor/VideoConverter.swift:321 | func | open | open func convert(_ option: ConverterOption? = nil, handler: @escaping @Sendable (AVMutableComposition, AVMutableVideoComposition) -> Void) { |
| PooToolsSource/VideoEditor/VideoConverter.swift:332 | func | open | open func convert(_ option: ConverterOption? = nil, temporaryFileName: String? = nil, progress: (@Sendable (Double?) -> Void)? = nil, completion: @escaping @Sendable (URL?, Error?) -> Void) { |
| PooToolsSource/Vision/PTVision.swift:14 | struct | public | public struct PTVisionTextResult { |
| PooToolsSource/Vision/PTVision.swift:15 | let | public | public let text: String |
| PooToolsSource/Vision/PTVision.swift:16 | let | public | public let observations: [VNRecognizedTextObservation] |
| PooToolsSource/Vision/PTVision.swift:18 | init | public | public init(text: String, observations: [VNRecognizedTextObservation]) { |
| PooToolsSource/Vision/PTVision.swift:95 | func | public | public func findText(withImage image: UIImage, |
| PooToolsSource/Vision/PTVision.swift:161 | func | public | public func findText(withImageView imageView: UIImageView, |
| PooToolsSource/WebKit/PTHTMLHeightCalculator.swift:36 | func | public | public func calculateHeight(for html: String) async -> CGFloat { |
| PooToolsSource/WebKit/PTHTMLHeightCalculator.swift:92 | func | public | public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { |
| PooToolsSource/WebKit/PTHTMLHeightCalculator.swift:106 | func | public | public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:14 | enum | public | @objc public enum PTWhatsNewsPresentationOption:Int { |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:26 | class | public | public class PTWhatsNews:NSObject { |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:32 | class | public | @MainActor public class func shouldPresent(with option: PTWhatsNewsPresentationOption = .always, currentVersion: String? = nil) -> Bool { |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:54 | class | public | public class PTWhatsNewsTitleItem:NSObject { |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:55 | var | public | public var title:String = "" |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:56 | var | public | public var titleFont:UIFont = .systemFont(ofSize: 26) |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:57 | var | public | public var titleColor:UIColor = .black |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:58 | var | public | public var atts:ASAttributedString? |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:59 | var | public | public var textAlignment:NSTextAlignment = .center |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:61 | init | public | @MainActor public init(title: String = "What's News", titleFont: UIFont = UIFont.appfont(size: 26,bold: true), titleColor: UIColor? = nil, atts: ASAttributedString? = nil, textAlignment:NSTextAlignment = .center) { |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:71 | class | public | public class PTWhatsNewsIKnowItem:NSObject { |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:72 | var | public | public var title:String = "" |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:73 | var | public | public var titleFont:UIFont = .systemFont(ofSize: 16) |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:74 | var | public | public var titleColor:UIColor = .white |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:75 | var | public | public var backgroundColor:UIColor = .systemBlue |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:76 | var | public | public var itemLayout:PTSheetButtonStyle = .leftImageRightTitle |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:77 | var | public | public var image:Any? |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:78 | var | public | public var itemSpace:CGFloat = 10 |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:79 | var | public | public var privacy:String = "" |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:80 | var | public | public var privacyURL:String = "" |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:81 | var | public | public var privacyFont:UIFont = .systemFont(ofSize: 14) |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:82 | var | public | public var privacyColor:UIColor = .systemBlue |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:84 | init | public | public init(title: String = "I Know", |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:110 | class | public | public class PTWhatsNewsItem:NSObject { |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:111 | var | public | public var title:String = "" |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:112 | var | public | public var titleFont:UIFont = .systemFont(ofSize: 20) |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:113 | var | public | public var titleColor:UIColor = .black |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:114 | var | public | public var contentSpace:CGFloat = 2 |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:115 | var | public | public var subTitle:String = "" |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:116 | var | public | public var subTitleFont:UIFont = .systemFont(ofSize: 16) |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:117 | var | public | public var subTitleColor:UIColor = .lightGray |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:118 | var | public | public var newsImage:Any? |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:120 | init | public | @MainActor public init(title: String = "", |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:235 | class | public | public class PTWhatsNewsViewController: PTBaseViewController { |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:237 | var | public | public var privacyTapHandler:PTActionTask? |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:238 | var | public | public var iKnowTapHandler:PTActionTask? |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:240 | func | public | public func setContentLRSpace(@PTClampedPropertyWrapper(range:0...100) values:CGFloat = 48) { |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:329 | init | public | public init(titleItem: PTWhatsNewsTitleItem? = nil, |
| PooToolsSource/WhatsNewsKit/PTWhatsNewsViewController.swift:413 | func | public | public func whatsNewsShow(vc:UIViewController) { |
| PooToolsSource/WhereIsMyEye/PTEyeTrackingDataManager.swift:41 | init | public | public init() { |
| PooToolsSource/WhereIsMyEye/PTEyeTrackingManager.swift:15 | protocol | public | public protocol PTEyeTrackingDelegate: NSObjectProtocol { |
| PooToolsSource/WhereIsMyEye/PTEyeTrackingManager.swift:40 | enum | public | @objc public enum PTEyeTrackingState: Int { |
| PooToolsSource/WhereIsMyEye/PTEyeTrackingManager.swift:55 | class | public | public class PTEyeTrackingManager: NSObject { |
| PooToolsSource/WhereIsMyEye/PTEyeTrackingManager.swift:64 | class | public | @objc public class var isSupported: Bool { |
| PooToolsSource/WhereIsMyEye/PTEyeTrackingManager.swift:75 | var | public | public var delegate: PTEyeTrackingDelegate? |
| PooToolsSource/WhereIsMyEye/PTEyeTrackingManager.swift:133 | func | public | @objc public func run() { |
| PooToolsSource/WhereIsMyEye/PTEyeTrackingManager.swift:146 | func | public | @objc public func pause() { |
| PooToolsSource/WhereIsMyEye/PTEyeTrackingManager.swift:167 | func | public | @objc public func showStatusView(parent: UIView) { |
| PooToolsSource/WhereIsMyEye/PTEyeTrackingManager.swift:181 | func | public | @objc public func showCursorView(parent: UIView) { |
| PooToolsSource/WhereIsMyEye/PTEyeTrackingManager.swift:188 | func | public | @objc public func hideStatusView() { |
| PooToolsSource/WhereIsMyEye/PTEyeTrackingManager.swift:195 | func | public | @objc public func hideCursorView() { |
| PooToolsSource/WhereIsMyEye/PTFaceEye.swift:13 | class | public | public class PTFaceEye: NSObject { |
| PooToolsSource/WhereIsMyEye/PTFaceEye.swift:18 | var | public | public var eyeLookAt:((_ point:CGPoint)->Void)? |
| PooToolsSource/WhereIsMyEye/PTFaceEye.swift:20 | var | public | public var trackingEyeState:((_ state:PTEyeTrackingState)->Void)? |
| PooToolsSource/WhereIsMyEye/PTFaceEye.swift:35 | func | public | @MainActor public func createEye() { |
| PooToolsSource/WhereIsMyEye/PTFaceEye.swift:44 | func | public | @MainActor public func dismissEye() { |
| PooToolsSource/WhereIsMyEye/PTFaceEye.swift:51 | func | public | @MainActor public func hideCursorView() { |
| PooToolsSource/WhereIsMyEye/PTFaceEye.swift:56 | func | public | @MainActor public func showCursorView() { |
| PooToolsSource/WhereIsMyEye/PTFaceEye.swift:62 | func | public | public func didChange(eyeTrackingState: PTEyeTrackingState) { |
| PooToolsSource/WhereIsMyEye/PTFaceEye.swift:66 | func | public | public func didChange(lookAtPoint: CGPoint) { |
| PooToolsSource/iCloud/PTiCloudFileManager.swift:13 | class | public | public class PTiCloudFileManager { |
| PooToolsSource/iCloud/PTiCloudFileManager.swift:17 | let | public | public let fileManager = FileManager.default |
| PooToolsSource/iCloud/PTiCloudFileManager.swift:24 | func | public | public func isICloudAvailable() -> Bool { |
| PooToolsSource/iCloud/PTiCloudFileManager.swift:30 | var | public | public var iCloudDocumentsURL: URL? { |
| PooToolsSource/iCloud/PTiCloudFileManager.swift:56 | func | public | public func saveFileToICloud(data: Data, fileName: String) { |
| PooToolsSource/iCloud/PTiCloudFileManager.swift:76 | func | public | public func readFileFromICloud(fileName: String) -> Data? { |
| PooToolsSource/iCloud/PTiCloudFileManager.swift:104 | var | public | public var localDocumentsURL: URL { |
| PooToolsSource/iCloud/PTiCloudFileManager.swift:111 | func | public | public func backupDatabaseToICloud(dbName: String) { |
| PooToolsSource/iCloud/PTiCloudFileManager.swift:143 | func | public | public func restoreDatabaseFromICloud(dbName: String) -> Bool { |
| PooToolsSource/iCloud/PTiCloudKeychainService.swift:14 | enum | public | public enum PTKeychainError: Error { |
| PooToolsSource/iCloud/PTiCloudKeychainService.swift:20 | class | public | public class PTiCloudKeychainService { |
| PooToolsSource/iOS17Tips/PTTip.swift:14 | struct | public | public struct TestTip: Tip { |
| PooToolsSource/iOS17Tips/PTTip.swift:16 | var | public | public var title: Text { |
| PooToolsSource/iOS17Tips/PTTip.swift:21 | var | public | public var message: Text? { |
| PooToolsSource/iOS17Tips/PTTip.swift:26 | var | public | public var asset: Image? { |
| PooToolsSource/iOS17Tips/PTTip.swift:30 | var | public | public var id: String { |
| PooToolsSource/iOS17Tips/PTTip.swift:34 | var | public | public var newId: String |
| PooToolsSource/iOS17Tips/PTTip.swift:35 | var | public | public var tipTitles:String |
| PooToolsSource/iOS17Tips/PTTip.swift:36 | var | public | public var messageTitles:String |
| PooToolsSource/iOS17Tips/PTTip.swift:39 | var | public | public var actions: [Action] { |
| PooToolsSource/iOS17Tips/PTTip.swift:52 | var | public | public var rules: [Rule] { |
| PooToolsSource/iOS17Tips/PTTip.swift:64 | var | public | public var options: [TipOption] { |
| PooToolsSource/iOS17Tips/PTTip.swift:73 | struct | public | public struct Test1Tip: Tip { |
| PooToolsSource/iOS17Tips/PTTip.swift:74 | var | public | public var title: Text { |
| PooToolsSource/iOS17Tips/PTTip.swift:82 | var | public | public var message: Text? { |
| PooToolsSource/iOS17Tips/PTTip.swift:89 | var | public | public var asset: Image? { |
| PooToolsSource/iOS17Tips/PTTip.swift:95 | class | public | public class PTTip: NSObject { |
| PooToolsSource/iOS17Tips/PTTip.swift:106 | func | public | public func appdelegateTipSet() { |
| PooToolsSource/iOS17Tips/PTTip.swift:120 | func | public | @MainActor public func showTip(tips: any Tip, |
| PooToolsSource/iOS17Tips/PTTip.swift:145 | func | public | public func showTipsInView(tips: any Tip, |

## 兼容规则

- 5.x 只新增正确命名的 canonical API，不删除既有公开符号。
- 旧拼写入口只能作为薄包装器存在，并在迁移文档中登记。
- 6.0.0 删除前必须先通过 API 差异检查和宿主项目迁移验证。
