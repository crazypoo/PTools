#
# Be sure to run `pod lib lint PooTools.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name        = 'PooTools'
    s.version     = '2.16.10'
    s.author           = { 'crazypoo' => '273277355@qq.com' }
    s.homepage    = 'https://github.com/crazypoo/PTools'
    s.summary     = '多年来积累的轮子'
    s.source           = { :git => 'https://github.com/crazypoo/PTools.git', :tag => s.version.to_s }
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.platform = :ios, '10.0'
    s.requires_arc = true
    s.source_files = 'PooToolsSource','PooToolsSource/**/*.{h,m,swift}'
    s.resource     = 'PooToolsSource/PooTools.bundle'
    s.ios.deployment_target = '10.0'
    s.swift_versions = '4.2'
    s.frameworks            = 'UIKit', 'AudioToolbox','ExternalAccessory','CoreText','SystemConfiguration','WebKit','QuartzCore','CoreTelephony','Security','Foundation','AVFoundation','LocalAuthentication','CoreMotion','SceneKit','CoreImage','Photos'#,'AssetsLibrary'
    s.dependency 'AFNetworking'
    s.dependency 'SDWebImage'
    s.dependency 'CYLTabBarController'
    s.dependency 'Mantle'
    s.dependency 'DZNEmptyDataSet'
    s.dependency 'IQKeyboardManager'
    s.dependency 'UITableView+FDTemplateLayoutCell'
    s.dependency 'FDFullscreenPopGesture'
    s.dependency 'LTNavigationBar'
    s.dependency 'HTAutocompleteTextField'
    s.dependency 'UIViewController+Swizzled'
    s.dependency 'FMDB'
    s.dependency 'DHSmartScreenshot'
    s.dependency 'YCXMenu'
    s.dependency 'Masonry'
    s.dependency 'MJRefresh'
    s.dependency 'MYBlurIntroductionView'
    s.dependency 'TextFieldEffects'
    s.dependency 'pop'
    s.dependency 'UITextField+Shake'
    s.dependency 'MJExtension'
    s.dependency 'SSZipArchive'
    s.dependency 'GCDWebServer'
    s.dependency 'GCDWebServer/WebUploader'
    s.dependency 'MBProgressHUD'
    s.dependency 'WZLBadge'
    s.dependency 'SnapKit'
    s.dependency 'YYCategories'
    s.dependency 'SwifterSwift'
    s.dependency 'HandyJSON'
    s.dependency 'DeviceKit'
    s.dependency 'UIColor_Hex_Swift'
    s.dependency 'SwifterSwift'
    s.dependency 'NotificationBannerSwift'
    s.dependency 'CocoaLumberjack/Swift'
    s.dependency 'SwiftDate'
    s.dependency 'UIImageColors'
    s.dependency 'KakaJSON'
    s.dependency 'Alamofire'
    s.dependency 'SwiftyJSON'
end
