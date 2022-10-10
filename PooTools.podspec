Pod::Spec.new do |s|
    s.name        = 'PooTools'
    s.version     = '3.0.0'
    s.author           = { 'crazypoo' => '273277355@qq.com' }
    s.homepage    = 'https://github.com/crazypoo/PTools'
    s.summary     = '多年来积累的轮子'
    s.source           = { :git => 'https://github.com/crazypoo/PTools.git', :tag => s.version.to_s }
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.platform = :ios, '11.0'
    s.requires_arc = true
    s.ios.deployment_target = '11.0'
    s.swift_versions = '5.0'
    s.resource     = 'PooToolsSource/PooTools.bundle'
    s.default_subspec = "Core"
    s.subspec "Core" do |subspec|
        s.dependency 'SwiftDate'
        s.dependency 'NotificationBannerSwift'
        s.dependency 'WZLBadge'
        s.dependency 'SnapKit'
        s.dependency 'SwifterSwift'
        s.dependency 'CocoaLumberjack/Swift'
        s.dependency 'DeviceKit'
        s.dependency 'UIColor_Hex_Swift'
        s.dependency 'SJAttributesStringMaker'
        s.dependency 'UIViewController+Swizzled'
        s.dependency 'IQKeyboardManager'
        s.dependency 'FDFullscreenPopGesture'
        s.dependency 'YYCategories'
        s.dependency 'pop'
        s.dependency 'FluentDarkModeKit'
        s.dependency 'SDWebImage'
        s.dependency 'MJRefresh'
        
        s.frameworks = 'UIKit','Foundation','AVKit','CoreFoundation','CoreText','AVFoundation'
        subspec.source_files = 'PooToolsSource/Core/*.{h,m,swift}','PooToolsSource/Blur/*.{h,m,swift}','PooToolsSource/Blur/*.{h,m,swift}','PooToolsSource/ActionsheetAndAlert/*.{h,m,swift}','PooToolsSource/AppStore/*.{h,m,swift}','PooToolsSource/BlackMagic/*.{h,m,swift}','PooToolsSource/Button/*.{h,m,swift}','PooToolsSource/Category/*.{h,m,swift}','PooToolsSource/DevMask/*.{h,m,swift}','PooToolsSource/LocalConsole/*.{h,m,swift}','PooToolsSource/Log/*.{h,m,swift}','PooToolsSource/StatusBar/*.{h,m,swift}','PooToolsSource/TouchInspector/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'DataEncrypt' do |subspec|
        s.source_files = 'PooToolsSource/AESAndDES/*.{h,m,swift}','PooToolsSource/Base64/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_DATAENCRYPT POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Animation' do |subspec|
        s.source_files = 'PooToolsSource/Animation/*.{h,m,swift}','PooToolsSource/Animation/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_ANIMATION POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'YB_Attributed' do |subspec|
        s.source_files = 'PooToolsSource/Attributed/*.{h,m,swift}','PooToolsSource/Attributed/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_YBATTRIBUTED POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'BankCard' do |subspec|
        s.source_files = 'PooToolsSource/BankCard/*.{h,m,swift}','PooToolsSource/BankCard/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_BANKCARD POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'BilogyID' do |subspec|
        s.frameworks = 'LocalAuthentication','Security'
        s.source_files = 'PooToolsSource/BioID/*.{h,m,swift}','PooToolsSource/BioID/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_BILOGYID POOTOOLS_COCOAPODS"
        }
    end

    s.subspec 'Calendar' do |subspec|
        s.frameworks = 'EventKit'
        s.source_files = 'PooToolsSource/Calendar/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_CALENDAR POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Telephony' do |subspec|
        s.frameworks = 'CoreTelephony','WebKit','MessageUI'
        s.source_files = 'PooToolsSource/CallMessageMail/*.{h,m,swift}','PooToolsSource/Carrie/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_TELEPHONY POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'CheckBox' do |subspec|
        s.source_files = 'PooToolsSource/CheckBox/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_CHECKBOX POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'CheckDirtyWord' do |subspec|
        s.source_files = 'PooToolsSource/CheckDirtyWord/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_CHECKDIRTYWORD POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'CodeView' do |subspec|
        s.source_files = 'PooToolsSource/CodeView/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_CODEVIEW POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Country' do |subspec|
        s.source_files = 'PooToolsSource/Country/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_COUNTRY POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'DarkModeSetting' do |subspec|
        s.source_files = 'PooToolsSource/DarkMode/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_DARKMODESETTING POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Guide' do |subspec|
        s.source_files = 'PooToolsSource/Guide/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_GUIDE POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Input' do |subspec|
        s.dependency 'TextFieldEffects'
        s.dependency 'UITextField+Shake'
        s.source_files = 'PooToolsSource/Input/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_INPUT POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'CustomerNumberKeyboard' do |subspec|
        s.source_files = 'PooToolsSource/Keyboard/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_CUSTOMERNUMBERKEYWORD POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'KeyChain' do |subspec|
        s.source_files = 'PooToolsSource/KeyChain/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_KEYCHAIN POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'CustomerLabel' do |subspec|
        s.frameworks = 'QuartzCore'
        s.source_files = 'PooToolsSource/Label/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_CUSTOMERLABEL POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'LanguageSetting' do |subspec|
        s.source_files = 'PooToolsSource/Language/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_LANGUAGESETTING POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Line' do |subspec|
        s.source_files = 'PooToolsSource/Line/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_LINE POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Loading' do |subspec|
        s.source_files = 'PooToolsSource/Loading/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_LOADING POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'MediaViewer' do |subspec|
        s.frameworks = 'CoreMotion','SceneKit','Photos'
        s.source_files = 'PooToolsSource/MediaViewer/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_MEDIAVIEWER POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Motion' do |subspec|
        s.frameworks = 'CoreMotion'
        s.source_files = 'PooToolsSource/Motion/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_MOTION POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'PhoneInfo' do |subspec|
        s.frameworks = 'Security'
        s.source_files = 'PooToolsSource/PhoneInfo/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PHONEINFO POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'RateView' do |subspec|
        s.source_files = 'PooToolsSource/RateView/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_RATE POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Rotation' do |subspec|
        s.source_files = 'PooToolsSource/Rotation/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_ROTATION POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'ScrollBanner' do |subspec|
        s.source_files = 'PooToolsSource/ScrollBanner/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_SCROLLBANNER POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'SearchBar' do |subspec|
        s.source_files = 'PooToolsSource/SearchBar/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_SEARCHBAR POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Segmented' do |subspec|
        s.source_files = 'PooToolsSource/Segmented/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_SEGMENT POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'HandSign' do |subspec|
        s.source_files = 'PooToolsSource/SignView/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_HANDSIGN POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Slider' do |subspec|
        s.dependency 'Masonry'
        s.source_files = 'PooToolsSource/Slider/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_SLIDER POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Thermometer' do |subspec|
        s.source_files = 'PooToolsSource/Thermometer/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_THERMOMETER POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'NetWork' do |subspec|
        s.dependency 'AFNetworking'
        s.dependency 'KakaJSON'
        s.dependency 'Alamofire'
        s.dependency 'SwiftyJSON'
        s.dependency 'HandyJSON'
        s.dependency 'EmptyDataSet-Swift'#空数据
        s.dependency 'LXFProtocolTool/LXFEmptyDataSetable'#Table/Collection空白时提示框架
        s.dependency 'MJExtension'
        s.dependency 'MBProgressHUD'
        s.source_files = 'PooToolsSource/NetWork/*.{h,m,swift}','PooToolsSource/Json/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_NETWORK POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'CheckUpdate' do |subspec|
        s.dependency 'AFNetworking'
        s.dependency 'KakaJSON'
        s.dependency 'Alamofire'
        s.dependency 'SwiftyJSON'
        s.dependency 'HandyJSON'
        s.source_files = 'PooToolsSource/CheckUpdate/*.{h,m,swift}','PooToolsSource/NetWork/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_CHECKUPDATE POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Layout' do |subspec|
        s.dependency 'CollectionViewPagingLayout'
        s.source_files = 'PooToolsSource/Layout/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_LAYOUT POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'TABBAR' do |subspec|
        s.dependency 'CYLTabBarController'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_TABBAR POOTOOLS_COCOAPODS"
        }
    end

    s.subspec 'SmartScreenshot' do |subspec|
        s.dependency 'DHSmartScreenshot'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_SMARTSCREENSHOT POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'ZipArchive' do |subspec|
        s.dependency 'SSZipArchive'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_ZIPARCHINE POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'GCDWebServer' do |subspec|
        s.dependency 'GCDWebServer'
        s.dependency 'GCDWebServer/WebUploader'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_CGDWEBSERVER POOTOOLS_COCOAPODS"
        }
    end

    s.subspec 'ColorPicker' do |subspec|
        s.dependency 'ChromaColorPicker'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_COLORPICKER POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'ImageColors' do |subspec|
        s.dependency 'UIImageColors'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_IMAGECOLORS POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'InputAll' do |subspec|
        s.dependency 'SwiftDate'
        s.dependency 'NotificationBannerSwift'
        s.dependency 'WZLBadge'
        s.dependency 'SnapKit'
        s.dependency 'SwifterSwift'
        s.dependency 'CocoaLumberjack/Swift'
        s.dependency 'DeviceKit'
        s.dependency 'UIColor_Hex_Swift'
        s.dependency 'SJAttributesStringMaker'
        s.dependency 'UIViewController+Swizzled'
        s.dependency 'IQKeyboardManager'
        s.dependency 'FDFullscreenPopGesture'
        s.dependency 'YYCategories'
        s.dependency 'pop'
        s.dependency 'FluentDarkModeKit'
        s.dependency 'SDWebImage'
        s.dependency 'MJRefresh'
	    s.dependency 'TextFieldEffects'
        s.dependency 'UITextField+Shake'
	    s.dependency 'Masonry'
        s.dependency 'AFNetworking'
        s.dependency 'KakaJSON'
        s.dependency 'Alamofire'
        s.dependency 'SwiftyJSON'
        s.dependency 'HandyJSON'
        s.dependency 'EmptyDataSet-Swift'#空数据
        s.dependency 'LXFProtocolTool/LXFEmptyDataSetable'#Table/Collection空白时提示框架
        s.dependency 'MJExtension'
        s.dependency 'MBProgressHUD'
        s.dependency 'CollectionViewPagingLayout'
        s.dependency 'CYLTabBarController'
        s.dependency 'DHSmartScreenshot'
        s.dependency 'SSZipArchive'
        s.dependency 'GCDWebServer'
        s.dependency 'GCDWebServer/WebUploader'
        s.dependency 'ChromaColorPicker'
        s.dependency 'UIImageColors'
        s.dependency 'TextFieldEffects'
        s.dependency 'UITextField+Shake'
        s.frameworks = 'UIKit','Foundation','AVKit','CoreFoundation','CoreText','AVFoundation','LocalAuthentication','Security','EventKit','CoreTelephony','WebKit','MessageUI','CoreMotion','SceneKit','Photos'
        s.source_files = 'PooToolsSource','PooToolsSource/**/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_INPUTALL POOTOOLS_COCOAPODS"
        }
    end
end
