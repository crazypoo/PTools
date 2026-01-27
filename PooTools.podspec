Pod::Spec.new do |s|
    s.name        = 'PooTools'
    s.version     = '3.84.28'
    s.author           = { 'crazypoo' => '273277355@qq.com' }
    s.homepage    = 'http://crazypoo.github.io/PTools/'
    s.summary     = '多年来积累的轮子'
    s.source           = { :git => 'https://github.com/crazypoo/PTools.git', :tag => s.version.to_s }
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.platform = :ios, '15.0'
#    s.requires_arc = true
#    s.static_framework = true
    s.ios.deployment_target = '15.0'
    s.swift_versions = '5.0'
    s.xcconfig = {"ENABLE_BITCODE" => "NO"}
    s.pod_target_xcconfig = {
      'OTHER_SWIFT_FLAGS[config=Debug]' => '-D DEBUG'
    }
    s.header_mappings_dir = 'PooToolsSource'
    
    s.default_subspec = "Core"
    s.subspec "Core" do |subspec|
        subspec.dependency 'SwiftDate'
        subspec.dependency 'SnapKit'
        subspec.dependency 'SwifterSwift'
        subspec.dependency 'CocoaLumberjack/Swift'
        subspec.dependency 'DeviceKit'
        subspec.dependency 'UIColor_Hex_Swift'
        subspec.dependency 'AttributedString'
        subspec.dependency 'UIViewController+Swizzled'
        subspec.dependency 'IQKeyboardToolbarManager'
        subspec.dependency 'IQKeyboardManagerSwift'
        subspec.dependency 'FDFullscreenPopGesture'
        subspec.dependency 'pop'
        subspec.dependency 'Kingfisher'
        subspec.dependency 'SafeSFSymbols'
        subspec.dependency 'KakaJSON'
        #        subspec.dependency 'MetaCodable'
        #        subspec.dependency 'MetaCodable/HelperCoders'
        subspec.resource_bundles = {
            'PooToolsResource' => ['PooToolsSource/Resource/**/*','PooToolsSource/Resource/PrivacyInfo.xcprivacy','PooToolsSource/Resources/*.lproj']
        }
        subspec.frameworks = 'UIKit','Foundation','AVKit','CoreFoundation','CoreText','AVFoundation','Photos','AudioToolbox'
        subspec.source_files = 'PooToolsSource/Core/*.{h,m,swift,S}','PooToolsSource/Blur/*.{h,m,swift}','PooToolsSource/ActionsheetAndAlert/*.{h,m,swift}','PooToolsSource/Base/*.{h,m,swift}','PooToolsSource/AppStore/*.{h,m,swift}','PooToolsSource/ApplicationFunction/*.{h,m,swift}','PooToolsSource/BlackMagic/*.{h,m,swift}','PooToolsSource/Button/*.{h,m,swift}','PooToolsSource/Category/*.{h,m,swift}','PooToolsSource/Log/*.{h,m,swift}','PooToolsSource/StatusBar/*.{h,m,swift}','PooToolsSource/Protocol/*.{h,m,swift}','PooToolsSource/Animation/*.{h,m,swift}','PooToolsSource/PermissionCore/*.{h,m,swift}','PooToolsSource/PhotoLibraryPermission/*.{h,m,swift}','PooToolsSource/AppDelegate/*.{h,m,swift}','PooToolsSource/Foundation/*.{h,m,swift}','PooToolsSource/Language/*.{h,m,swift}','PooToolsSource/DarkMode/*.{h,m,swift}','PooToolsSource/Line/*.{h,m,swift}','PooToolsSource/Badge/*.{h,m,swift}','PooToolsSource/Rotation/*.{h,m,swift}','PooToolsSource/Switch/*.{h,m,swift}','PooToolsSource/Colors/*.{h,m,swift}','PooToolsSource/Font/*.{h,m,swift}','PooToolsSource/FloatPanel/*.{h,m,swift}','PooToolsSource/SideMenuControl/*.{h,m,swift}','PooToolsSource/iCloud/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'NetWork' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/Loading'
        subspec.dependency 'Alamofire'
        subspec.source_files = 'PooToolsSource/NetWork/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_NETWORK POOTOOLS_COCOAPODS"
        }
    end

#    s.subspec 'SwipeCell' do |subspec|
#        subspec.dependency 'PooTools/Core'
#        subspec.dependency 'SwipeCellKit'
#        subspec.source_files = 'PooToolsSource/SwipeCell/*.{h,m,swift}'
#        subspec.pod_target_xcconfig = {
#            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_SWIPECELL POOTOOLS_COCOAPODS"
#        }
#    end

    s.subspec 'NotificationBanner' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'NotificationBannerSwift'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_NOTIFICATIONBANNER POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'ScrollRefresh' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'MJRefresh'
        subspec.source_files = 'PooToolsSource/ScrollRefresh/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_SCROLLREFRESH POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'DataEncrypt' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'CryptoSwift'
        subspec.source_files = 'PooToolsSource/AESAndDES/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_DATAENCRYPT POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Stepper' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/Stepper/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_STEPPER POOTOOLS_COCOAPODS"
        }
    end
            
    s.subspec 'BankCard' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/BankCard/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_BANKCARD POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'BilogyID' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/FaceIDPermission'
        subspec.dependency 'PooTools/KeyChain'
        subspec.frameworks = 'LocalAuthentication','Security'
        subspec.source_files = 'PooToolsSource/BioID/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_BILOGYID POOTOOLS_COCOAPODS"
        }
    end

    s.subspec 'Calendar' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/CalendarPermission'
        subspec.dependency 'PooTools/RemindersPermission'
        subspec.frameworks = 'EventKit'
        subspec.source_files = 'PooToolsSource/Calendar/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_CALENDAR POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Telephony' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.frameworks = 'CoreTelephony','WebKit','MessageUI'
        subspec.source_files = 'PooToolsSource/CallMessageMail/*.{h,m,swift}'
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
        subspec.resource_bundles = {
            'PooToolsCheckDirtyWordResource' => ['PooToolsSource/CheckDirtyWord/Resource/**/*']
        }
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
        
    s.subspec 'Guide' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/PageControl'
        subspec.source_files = 'PooToolsSource/Guide/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_GUIDE POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Input' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'UITextField+Shake'
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
        subspec.frameworks = 'QuartzCore'
        subspec.source_files = 'PooToolsSource/Label/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_CUSTOMERLABEL POOTOOLS_COCOAPODS"
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
        subspec.dependency 'PooTools/ProgressBar'
        subspec.dependency 'PooTools/NetWork'
        subspec.dependency 'PooTools/PageControl'
        subspec.dependency 'PooTools/LivePhoto'
        subspec.frameworks = 'Photos'
        subspec.source_files = 'PooToolsSource/MediaViewer/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_MEDIAVIEWER POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Motion' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/MotionPermission'
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
        
    s.subspec 'PageControl' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/PageControl/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PAGECONTROL POOTOOLS_COCOAPODS"
        }
    end

    s.subspec 'ScrollBanner' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/PageControl'
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
        subspec.dependency 'RangeSeekSlider'
        subspec.source_files = 'PooToolsSource/Slider/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_SLIDER POOTOOLS_COCOAPODS"
        }
    end
            
    s.subspec 'CheckUpdate' do |subspec|
        subspec.dependency 'PooTools/NetWork'
        subspec.source_files = 'PooToolsSource/CheckUpdate/*.{h,m,swift}'
        subspec.dependency 'SwiftJWT'
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
    
    s.subspec 'Location' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/LocationPermission'
        subspec.source_files = 'PooToolsSource/Location/*.{h,m,swift}'
        subspec.frameworks = 'CoreLocation'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_LOCATION POOTOOLS_COCOAPODS"
        }
    end
        
    s.subspec 'Tabbar' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'ESTabBarController-swift'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_TABBAR POOTOOLS_COCOAPODS"
        }
    end

    s.subspec 'SmartScreenshot' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/ScreenShot/*.{h,m,swift}'
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
            
    s.subspec 'ScanQRCode' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/PhotoPicker'
        subspec.dependency 'PooTools/CameraPermission'
        subspec.source_files = 'PooToolsSource/QRCodeScan/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_SCANQRCODE POOTOOLS_COCOAPODS"
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
        subspec.dependency 'PooTools/HealthPermission'
        subspec.frameworks = 'HealthKit'
        subspec.source_files = 'PooToolsSource/HealthKit/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_STEPCOUNT POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Speech' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/SpeechRecognizerPermission'
        subspec.dependency 'OSSSpeechKit'
        subspec.frameworks = 'Speech','AVFoundation'
        subspec.source_files = 'PooToolsSource/Speech/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_SPEECH POOTOOLS_COCOAPODS"
        }
    end
        
    s.subspec 'DEBUG' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/NetWork'
        subspec.dependency 'PooTools/Share'
        subspec.dependency 'PooTools/SearchBar'
        subspec.dependency 'PooTools/PDF'
        subspec.source_files = 'PooToolsSource/Debug/*.{h,m,swift}','PooToolsSource/LocalConsole/*.{h,m,swift}','PooToolsSource/DevMask/*.{h,m,swift}','PooToolsSource/TouchInspector/*.{h,m,swift}','PooToolsSource/DEBUGLocation/*.{h,m,swift}','PooToolsSource/Inspector/*.{h,m,swift}'
    subspec.pod_target_xcconfig = {
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_DEBUG POOTOOLS_COCOAPODS"
    }
    end
    
    s.subspec 'DEBUG_TrackingEyes' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/DEBUG'
        subspec.dependency 'PooTools/CameraPermission'
        subspec.source_files = 'PooToolsSource/WhereIsMyEye/*.{h,m,swift}'
    subspec.pod_target_xcconfig = {
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_DEBUGTRACKINGEYES POOTOOLS_COCOAPODS"
    }
    end

    s.subspec 'Contact' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/ContactsPermission'
        subspec.source_files = 'PooToolsSource/Contact/*.{h,m,swift}'
    subspec.pod_target_xcconfig = {
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_CONTACT POOTOOLS_COCOAPODS"
    }
    end
    
    #########Permission#########
    s.subspec 'NotificationPermission' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/NotificationPermission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_NOTIFICATION POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'CameraPermission' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/CameraPermission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_CAMERA POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'LocationPermission' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/LocationPermission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_LOCATION POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'CalendarPermission' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/CalendarPermission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_CALENDAR POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'MotionPermission' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/MotionPermission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_MOTION POOTOOLS_COCOAPODS"
        }
    end
        
    s.subspec 'TrackingPermission' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/TrackingPermission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_TRACKING POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'RemindersPermission' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/RemindersPermission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_REMINDERS POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'SpeechRecognizerPermission' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/SpeechPremission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_SPEECH POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'HealthPermission' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/HealthPermission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_HEALTH POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'FaceIDPermission' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/FaceIDPermission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_FACEIDPERMISSION POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'ContactsPermission' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/ContactsPermission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_CONTACTS POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'MicPermission' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/MicPermission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_MIC POOTOOLS_COCOAPODS"
        }
    end

    s.subspec 'MeidaPermission' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/MeidaLibraryPermission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_MEDIA POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'BluetoothPermission' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/BluetoothPermission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_BLUETOOTH POOTOOLS_COCOAPODS"
        }
    end

    s.subspec 'SiriPermission' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/SiriPermission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_SIRI POOTOOLS_COCOAPODS"
        }
    end
    #########Permission#########

    s.subspec 'HarbethKit' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'Harbeth'
        subspec.dependency 'PooTools/CameraPermission'
#        subspec.dependency 'PooTools/MicPermission'
        subspec.source_files = 'PooToolsSource/C7Collector/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_HARBETHKIT POOTOOLS_COCOAPODS"
        }
    end
        
    s.subspec 'PopoverKit' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'Popovers'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_POPOVERKIT POOTOOLS_COCOAPODS"
        }
    end
        
    s.subspec 'SVG' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PocketSVG'
        subspec.dependency 'Protobuf', '= 3.22.1'
        subspec.dependency 'SVGAPlayer'
        subspec.source_files = 'PooToolsSource/KingfisherSVG/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_SVG POOTOOLS_COCOAPODS"
        }
    end
    
#    s.subspec 'SVGA' do |subspec|
#        subspec.dependency 'PooTools/Core'
#        subspec.dependency 'Protobuf', '= 3.22.1'
#        subspec.dependency 'SVGAPlayer'
#        subspec.source_files = 'PooToolsSource/SVGA/*.{h,m,swift}'
#        subspec.pod_target_xcconfig = {
#            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_SVGA POOTOOLS_COCOAPODS"
#        }
#    end
    
    s.subspec 'Share' do |subspec|
        subspec.dependency 'PooTools/CustomerLabel'
        subspec.source_files = 'PooToolsSource/Share/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_SHARE POOTOOLS_COCOAPODS"
        }
    end
        
    s.subspec 'ListEmptyData' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'EmptyDataSet-Swift'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_LISTEMPTYDATA POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Vision' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/Vision/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_VISION POOTOOLS_COCOAPODS"
        }
    end
         
    s.subspec 'Router' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/Router/*.{h,m,swift}'
        subspec.public_header_files = 'PooToolsSource/Router/*.h'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_ROUTER POOTOOLS_COCOAPODS"
        }
    end

    s.subspec 'Ping' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/Ping/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PING POOTOOLS_COCOAPODS"
        }
    end

    s.subspec 'VideoEditor' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/HarbethKit'
        subspec.dependency 'PooTools/ProgressBar'
        subspec.dependency 'PooTools/Loading'
        subspec.source_files = 'PooToolsSource/VideoEditor/*.{h,m,swift}'
#        subspec.resource_bundles = {
#            'PTVideoEditorResources' => ['PooToolsSource/VideoEditor/*.xcassets']
#        }
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_VIDEOEDITOR POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'SpeedPanel' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/SpeedPanel/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_SPEEDPANEL POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'NetworkSpeedTest' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/NetworkSpeedTest/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_NETWORKSPEEDTEST POOTOOLS_COCOAPODS"
        }
    end
    
    #
    #<key>LSApplicationQueriesSchemes</key>
    #<array>
    #    <string>undecimus</string>
    #    <string>sileo</string>
    #    <string>zbra</string>
    #    <string>filza</string>
    #   <string>activator</string>
    #</array>
    #
    s.subspec 'SecuritySuite' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'IOSSecuritySuite'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_SECURITYSUITE POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'OSSKitSpeech' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/SpeechRecognizerPermission'
        subspec.frameworks = 'Speech'
        subspec.source_files = 'PooToolsSource/OSSKit/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_OSSKITSPEECH POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'iOS17Tips' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/iOS17Tips/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_iOS17TIPS POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'WhatsNewsKit' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/WhatsNewsKit/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_WHATSNEWSKIT POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'HeartRate' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'lottie-ios'
        subspec.dependency 'PooTools/CameraPermission'
        subspec.source_files = 'PooToolsSource/HeartRate/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_HEARTRATE POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'PhotoPicker' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/CameraPermission'
        subspec.dependency 'PooTools/NetWork'
        subspec.dependency 'PooTools/Loading'
        subspec.dependency 'Kakapos'
        subspec.source_files = 'PooToolsSource/PhotoPicker/*.{h,m,swift}','PooToolsSource/ImagePicker/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PHOTOPICKER POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'FilterCamera' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/CameraPermission'
        subspec.dependency 'PooTools/MicPermission'
        subspec.dependency 'PooTools/HarbethKit'
        subspec.dependency 'PooTools/MediaViewer'
        subspec.source_files = 'PooToolsSource/FilterCamera/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_FILTERCAMERA POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'ImageEditor' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/HarbethKit'
        subspec.dependency 'PooTools/FilterCamera'
        subspec.source_files = 'PooToolsSource/ImageEditor/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_IMAGEEDITOR POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'ProgressBar' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/ProgressBar/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PROGRESSBAR POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'ChinesePinyin' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/Pinyin/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_CHINESEPINYIN POOTOOLS_COCOAPODS"
        }
    end
        
    s.subspec 'Circle' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/Circle/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_CIRCLE POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'MessageKit' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/CustomerLabel'
        subspec.source_files = 'PooToolsSource/MessageKit/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_MESSAGEKIT POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'SocketKit' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'SocketRocket'
        subspec.source_files = 'PooToolsSource/SocketKit/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_SOCKETKIT POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'PDF' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/PDF/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PDF POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'IAP' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/IAP/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_IAP POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'LivePhoto' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/LivePhoto/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_LIVEPHOTO POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'Flag' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'FlagKit'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_FLAG POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'WebKit' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/WebKit/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_WEBKIT POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'MXMetricManagerKit' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/MXMetricKitManager/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_MXMERRICKITMANAGER POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'NFCKit' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/NFC/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_NFC POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'TipsView' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/TipsView/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_TIPSVIEW POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'VideoCache' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'KTVHTTPCache'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_VIDEOCACHE POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'InputAll' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/DataEncrypt'
        subspec.dependency 'PooTools/BankCard'
        subspec.dependency 'PooTools/BilogyID'
        subspec.dependency 'PooTools/Calendar'
        subspec.dependency 'PooTools/Telephony'
        subspec.dependency 'PooTools/CheckBox'
        subspec.dependency 'PooTools/CheckDirtyWord'
        subspec.dependency 'PooTools/CodeView'
        subspec.dependency 'PooTools/Country'
        subspec.dependency 'PooTools/Guide'
        subspec.dependency 'PooTools/Input'
        subspec.dependency 'PooTools/CustomerNumberKeyboard'
        subspec.dependency 'PooTools/KeyChain'
        subspec.dependency 'PooTools/CustomerLabel'
        subspec.dependency 'PooTools/Loading'
        subspec.dependency 'PooTools/MediaViewer'
        subspec.dependency 'PooTools/Motion'
        subspec.dependency 'PooTools/PhoneInfo'
        subspec.dependency 'PooTools/RateView'
        subspec.dependency 'PooTools/PageControl'
        subspec.dependency 'PooTools/ScrollBanner'
        subspec.dependency 'PooTools/SearchBar'
        subspec.dependency 'PooTools/Segmented'
        subspec.dependency 'PooTools/Slider'
        subspec.dependency 'PooTools/CheckUpdate'
        subspec.dependency 'PooTools/Layout'
        subspec.dependency 'PooTools/Tabbar'
        subspec.dependency 'PooTools/SmartScreenshot'
        subspec.dependency 'PooTools/ZipArchive'
        subspec.dependency 'PooTools/GCDWebServer'
        subspec.dependency 'PooTools/FocusFaceImageView'
        subspec.dependency 'PooTools/PagingControl'
        subspec.dependency 'PooTools/Picker'
        subspec.dependency 'PooTools/Instructions'
        subspec.dependency 'PooTools/Appz'
        subspec.dependency 'PooTools/LaunchTimeProfiler'
        subspec.dependency 'PooTools/HarbethKit'
        subspec.dependency 'PooTools/PopoverKit'
        subspec.dependency 'PooTools/ScanQRCode'
        subspec.dependency 'PooTools/Stepper'
        subspec.dependency 'PooTools/Location'
        subspec.dependency 'PooTools/ScrollRefresh'
        subspec.dependency 'PooTools/SVG'
        subspec.dependency 'PooTools/Share'
        subspec.dependency 'PooTools/ListEmptyData'
        subspec.dependency 'PooTools/DEBUG'
        subspec.dependency 'PooTools/DEBUG_TrackingEyes'
        subspec.dependency 'PooTools/Vision'
        subspec.dependency 'PooTools/NotificationBanner'
        subspec.dependency 'PooTools/NetWork'
        subspec.dependency 'PooTools/Router'
        subspec.dependency 'PooTools/Ping'
        subspec.dependency 'PooTools/VideoEditor'
        subspec.dependency 'PooTools/SecuritySuite'
        subspec.dependency 'PooTools/OSSKitSpeech'
        subspec.dependency 'PooTools/iOS17Tips'
        subspec.dependency 'PooTools/WhatsNewsKit'
        subspec.dependency 'PooTools/HeartRate'
        subspec.dependency 'PooTools/PhotoPicker'
        subspec.dependency 'PooTools/ImageEditor'
        subspec.dependency 'PooTools/ProgressBar'
        subspec.dependency 'PooTools/ChinesePinyin'
#        subspec.dependency 'PooTools/SVGA'
        subspec.dependency 'PooTools/Circle'
        subspec.dependency 'PooTools/MessageKit'
        subspec.dependency 'PooTools/SocketKit'
        subspec.dependency 'PooTools/PDF'
        subspec.dependency 'PooTools/IAP'
        subspec.dependency 'PooTools/LivePhoto'
        subspec.dependency 'PooTools/Flag'

        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_INPUTALL POOTOOLS_COCOAPODS"
        }
    end
end
