Pod::Spec.new do |s|
    s.name        = 'PooTools'
    s.version     = '3.0.0'
    s.author           = { 'crazypoo' => '273277355@qq.com' }
    s.homepage    = 'https://github.com/crazypoo/PTools'
    s.summary     = '多年来积累的轮子'
    s.source           = { :git => 'https://github.com/crazypoo/PTools.git', :tag => s.version.to_s }
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.platform = :ios, '13.0'
    s.requires_arc = true
    s.ios.deployment_target = '13.0'
    s.swift_versions = '4.2'
    s.resource     = 'PooToolsSource/PooTools.bundle'
    s.default_subspec = "Core"
    s.subspec "Core" do |subspec|
        subspec.dependency 'SwiftDate'
        subspec.dependency 'NotificationBannerSwift'
        subspec.dependency 'WZLBadge'
        subspec.dependency 'SnapKit'
        subspec.dependency 'SwifterSwift'
        subspec.dependency 'CocoaLumberjack/Swift'
        subspec.dependency 'DeviceKit'
        subspec.dependency 'UIColor_Hex_Swift'
        subspec.dependency 'SJAttributesStringMaker'
        subspec.dependency 'YYText'
        subspec.dependency 'UIViewController+Swizzled'
        subspec.dependency 'IQKeyboardManager'
        subspec.dependency 'FDFullscreenPopGesture'
        subspec.dependency 'YYCategories'
        subspec.dependency 'pop'
        subspec.dependency 'FluentDarkModeKit'
        subspec.dependency 'SDWebImage'
        subspec.dependency 'MJRefresh'
        subspec.dependency 'ZXNavigationBar'
        subspec.dependency 'SwipeCellKit'
        subspec.dependency 'FloatingPanel'
        subspec.frameworks = 'UIKit','Foundation','AVKit','CoreFoundation','CoreText','AVFoundation','Photos'
        subspec.source_files = 'PooToolsSource/Core/*.{h,m,swift}','PooToolsSource/Blur/*.{h,m,swift}','PooToolsSource/Blur/*.{h,m,swift}','PooToolsSource/ActionsheetAndAlert/*.{h,m,swift}','PooToolsSource/Base/*.{h,m,swift}','PooToolsSource/AppStore/*.{h,m,swift}','PooToolsSource/ApplicationFunction/*.{h,m,swift}','PooToolsSource/BlackMagic/*.{h,m,swift}','PooToolsSource/Button/*.{h,m,swift}','PooToolsSource/Category/*.{h,m,swift}','PooToolsSource/DevMask/*.{h,m,swift}','PooToolsSource/LocalConsole/*.{h,m,swift}','PooToolsSource/Log/*.{h,m,swift}','PooToolsSource/StatusBar/*.{h,m,swift}','PooToolsSource/TouchInspector/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'DataEncrypt' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/AESAndDES/*.{h,m,swift}','PooToolsSource/Base64/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_DATAENCRYPT POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Animation' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/Animation/*.{h,m,swift}','PooToolsSource/Animation/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_ANIMATION POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'YB_Attributed' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/Attributed/*.{h,m,swift}','PooToolsSource/Attributed/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_YBATTRIBUTED POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'BankCard' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/BankCard/*.{h,m,swift}','PooToolsSource/BankCard/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_BANKCARD POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'BilogyID' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.frameworks = 'LocalAuthentication','Security'
        subspec.source_files = 'PooToolsSource/BioID/*.{h,m,swift}','PooToolsSource/BioID/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_BILOGYID POOTOOLS_COCOAPODS"
        }
    end

    s.subspec 'Calendar' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.frameworks = 'EventKit'
        subspec.source_files = 'PooToolsSource/Calendar/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_CALENDAR POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Telephony' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.frameworks = 'CoreTelephony','WebKit','MessageUI'
        subspec.source_files = 'PooToolsSource/CallMessageMail/*.{h,m,swift}','PooToolsSource/Carrie/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_TELEPHONY POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'CheckBox' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/CheckBox/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_CHECKBOX POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'CheckDirtyWord' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/CheckDirtyWord/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_CHECKDIRTYWORD POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'CodeView' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/CodeView/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_CODEVIEW POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Country' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/Country/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_COUNTRY POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'DarkModeSetting' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/DarkMode/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_DARKMODESETTING POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Guide' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/Guide/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_GUIDE POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Input' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'TextFieldEffects'
        subspec.dependency 'UITextField+Shake'
        subspec.dependency 'CRBoxInputView'
        subspec.dependency 'PhoneNumberKit'
        subspec.source_files = 'PooToolsSource/Input/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_INPUT POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'CustomerNumberKeyboard' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/Keyboard/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_CUSTOMERNUMBERKEYWORD POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'KeyChain' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/KeyChain/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_KEYCHAIN POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'CustomerLabel' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'YYText'
        subspec.frameworks = 'QuartzCore'
        subspec.source_files = 'PooToolsSource/Label/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_CUSTOMERLABEL POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'LanguageSetting' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/Language/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_LANGUAGESETTING POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Line' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/Line/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_LINE POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Loading' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/Loading/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_LOADING POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'MediaViewer' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.frameworks = 'CoreMotion','SceneKit','Photos'
        subspec.source_files = 'PooToolsSource/MediaViewer/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_MEDIAVIEWER POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Motion' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.frameworks = 'CoreMotion'
        subspec.source_files = 'PooToolsSource/Motion/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_MOTION POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'PhoneInfo' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.frameworks = 'Security'
        subspec.source_files = 'PooToolsSource/PhoneInfo/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PHONEINFO POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'RateView' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/RateView/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_RATE POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Rotation' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/Rotation/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_ROTATION POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'ScrollBanner' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/ScrollBanner/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_SCROLLBANNER POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'SearchBar' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/SearchBar/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_SEARCHBAR POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Segmented' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/Segmented/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_SEGMENT POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'HandSign' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/SignView/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_HANDSIGN POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Slider' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'Masonry'
        subspec.source_files = 'PooToolsSource/Slider/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_SLIDER POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Thermometer' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/Thermometer/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_THERMOMETER POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'NetWork' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'AFNetworking'
        subspec.dependency 'KakaJSON'
        subspec.dependency 'Alamofire'
        subspec.dependency 'SwiftyJSON'
        subspec.dependency 'HandyJSON'
        subspec.dependency 'EmptyDataSet-Swift'#空数据
        subspec.dependency 'LXFProtocolTool/LXFEmptyDataSetable'#Table/Collection空白时提示框架
        subspec.dependency 'MJExtension'
        subspec.dependency 'MBProgressHUD'
        subspec.source_files = 'PooToolsSource/NetWork/*.{h,m,swift}','PooToolsSource/Json/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_NETWORK POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'CheckUpdate' do |subspec|
        subspec.dependency 'PooTools/NetWork'
        subspec.source_files = 'PooToolsSource/CheckUpdate/*.{h,m,swift}','PooToolsSource/NetWork/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_CHECKUPDATE POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Layout' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'CollectionViewPagingLayout'
        subspec.source_files = 'PooToolsSource/Layout/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_LAYOUT POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Tabbar' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'CYLTabBarController'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_TABBAR POOTOOLS_COCOAPODS"
        }
    end

    s.subspec 'SmartScreenshot' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'SnapshotKit'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_SMARTSCREENSHOT POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'ZipArchive' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'SSZipArchive'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_ZIPARCHINE POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'GCDWebServer' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'GCDWebServer'
        subspec.dependency 'GCDWebServer/WebUploader'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_CGDWEBSERVER POOTOOLS_COCOAPODS"
        }
    end

    s.subspec 'ColorPicker' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'ChromaColorPicker'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_COLORPICKER POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'ImageColors' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'UIImageColors'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_IMAGECOLORS POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'FocusFaceImageView' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'FaceAware'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_FOCUSFACE POOTOOLS_COCOAPODS"
        }
    end
        
    s.subspec 'PagingControl' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'JXPagingView/Paging'
        subspec.dependency 'JXSegmentedView'
        subspec.source_files = 'PooToolsSource/SegmentControl/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PAGINGCONTROL POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'FloatingPanel' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'FloatingPanel'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_FLOATINGPANEL POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'ImagePicker' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'TZImagePickerController'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_IMAGEPICKER POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Picker' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'BRPickerView'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PICKER POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Instructions' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'Instructions'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_INSTRUCTIONS POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Appz' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'Appz'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_APPZ POOTOOLS_COCOAPODS"
        }
    end

    s.subspec 'LaunchTimeProfiler' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'AMKLaunchTimeProfiler'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_LAUNCHTIMEPROFILER POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'StepCount' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.frameworks = 'HealthKit'
        subspec.source_files = 'PooToolsSource/HealthKit/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_STEPCOUNT POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Speech' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.frameworks = 'Speech','AVFoundation'
        subspec.source_files = 'PooToolsSource/Speech/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_STEPCOUNT POOTOOLS_COCOAPODS"
        }
    end
    
#    s.subspec 'DEBUG' do |subspec|
#        subspec.dependency 'FLEX', :configurations => ['Debug']
#        subspec.dependency 'InAppViewDebugger', :configurations => ['Debug']
#        subspec.dependency 'LookinServer', :configurations => ['Debug']
#        subspec.pod_target_xcconfig = {
#            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_DEBUG POOTOOLS_COCOAPODS"
#        }
#    end
    
    s.subspec 'InputAll' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/DataEncrypt'
        subspec.dependency 'PooTools/Animation'
        subspec.dependency 'PooTools/YB_Attributed'
        subspec.dependency 'PooTools/BankCard'
        subspec.dependency 'PooTools/BilogyID'
        subspec.dependency 'PooTools/Calendar'
        subspec.dependency 'PooTools/Telephony'
        subspec.dependency 'PooTools/CheckBox'
        subspec.dependency 'PooTools/CheckDirtyWord'
        subspec.dependency 'PooTools/CodeView'
        subspec.dependency 'PooTools/Country'
        subspec.dependency 'PooTools/DarkModeSetting'
        subspec.dependency 'PooTools/Guide'
        subspec.dependency 'PooTools/Input'
        subspec.dependency 'PooTools/CustomerNumberKeyboard'
        subspec.dependency 'PooTools/KeyChain'
        subspec.dependency 'PooTools/CustomerLabel'
        subspec.dependency 'PooTools/LanguageSetting'
        subspec.dependency 'PooTools/Line'
        subspec.dependency 'PooTools/Loading'
        subspec.dependency 'PooTools/MediaViewer'
        subspec.dependency 'PooTools/Motion'
        subspec.dependency 'PooTools/PhoneInfo'
        subspec.dependency 'PooTools/RateView'
        subspec.dependency 'PooTools/Rotation'
        subspec.dependency 'PooTools/ScrollBanner'
        subspec.dependency 'PooTools/SearchBar'
        subspec.dependency 'PooTools/Segmented'
        subspec.dependency 'PooTools/Slider'
        subspec.dependency 'PooTools/Thermometer'
        subspec.dependency 'PooTools/NetWork'
        subspec.dependency 'PooTools/CheckUpdate'
        subspec.dependency 'PooTools/Layout'
        subspec.dependency 'PooTools/Tabbar'
        subspec.dependency 'PooTools/SmartScreenshot'
        subspec.dependency 'PooTools/ZipArchive'
        subspec.dependency 'PooTools/GCDWebServer'
        subspec.dependency 'PooTools/ColorPicker'
        subspec.dependency 'PooTools/ImageColors'
        subspec.dependency 'PooTools/FocusFaceImageView'
        subspec.dependency 'PooTools/PagingControl'
        subspec.dependency 'PooTools/ImagePicker'
        subspec.dependency 'PooTools/Picker'
        subspec.dependency 'PooTools/Instructions'
        subspec.dependency 'PooTools/Appz'
        subspec.dependency 'PooTools/LaunchTimeProfiler'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_INPUTALL POOTOOLS_COCOAPODS"
        }
    end
end
