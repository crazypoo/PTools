#
# Be sure to run `pod lib lint PooTools.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name        = 'PooTools'
    s.version     = '1.4.0'
    s.author           = { 'crazypoo' => '273277355@qq.com' }
    s.homepage    = 'https://github.com/crazypoo/PTools'
    s.summary     = '自己用到的工具'
    s.source           = { :git => 'https://github.com/crazypoo/PTools.git', :tag => s.version.to_s }
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.platform = :ios, '8.0'
    s.requires_arc = true
    s.source_files = 'PooTools','PooTools/**/*.{h,m}'
    s.ios.deployment_target = '8.0'
    s.frameworks = 'UIKit', 'AudioToolbox','ExternalAccessory','CoreText','SystemConfiguration','WebKit','QuartzCore','CoreTelephony','Security','Foundation','AVFoundation','Speech','LocalAuthentication','HealthKit','CoreMotion','SceneKit'
    s.dependency 'AFNetworking'
    s.dependency 'SDWebImage'
    s.dependency 'CYLTabBarController'
    s.dependency 'Mantle'
    s.dependency 'TOWebViewController'
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
    s.dependency 'JMHoledView'
    s.dependency 'UITextField+Shake'
    s.dependency 'UINavigation-SXFixSpace'
    s.dependency 'MJExtension'
end
