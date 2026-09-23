version_path = File.join(__dir__, 'VERSION')
version = File.read(version_path).strip
raise "PooTools VERSION must be semantic" unless version.match?(/\A\d+\.\d+\.\d+\z/)

Pod::Spec.new do |s|
    s.name        = 'PooTools'
    s.version     = version
    s.author           = { 'crazypoo' => '273277355@qq.com' }
    s.homepage    = 'http://crazypoo.github.io/PTools/'
    s.summary     = '多年来积累的轮子'
    s.source           = { :git => 'https://github.com/crazypoo/PTools.git', :tag => s.version.to_s }
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.platform = :ios, '17.0'
#    s.requires_arc = true
#    s.static_framework = true
    s.ios.deployment_target = '17.0'
    s.swift_versions = ['6.0']
    s.xcconfig = {"ENABLE_BITCODE" => "NO"}
    s.pod_target_xcconfig = {
      'IPHONEOS_DEPLOYMENT_TARGET' => '17.0',
      'SWIFT_VERSION' => '6.0',
      'OTHER_SWIFT_FLAGS[config=Debug]' => '-D DEBUG'
    }
    s.header_mappings_dir = 'PooToolsSource'
    
    s.default_subspec = "Core"

    # English: Foundation layers are published as opt-in subspecs for dependency-light integrations.
    # Español: Las capas Foundation se publican como subspecs opcionales para integraciones con pocas dependencias.
    # 中文：Foundation 分层以可选 subspec 形式发布，供轻依赖集成使用。
    s.subspec 'PToolsCore' do |subspec|
        subspec.source_files = 'PooToolsSource/PToolsCore/*.{h,m,swift}'
        subspec.frameworks = 'Foundation'
    end

    # English: Publish the logging contract without importing UIKit or legacy logging dependencies.
    # Español: Publica el contrato de logging sin importar UIKit ni las dependencias de logging heredadas.
    # 中文：发布不引入 UIKit 和旧日志依赖的日志契约。
    s.subspec 'Logging' do |subspec|
        subspec.source_files = 'PooToolsSource/PToolsLogging/**/*.swift'
        subspec.frameworks = 'Foundation', 'OSLog'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS" => "POOTOOLS_LOGGING POOTOOLS_COCOAPODS"
        }
    end

    s.subspec 'PToolsUIFoundation' do |subspec|
        subspec.dependency 'PooTools/PToolsCore'
        subspec.dependency 'SnapKit'
        subspec.source_files = 'PooToolsSource/PToolsUIFoundation/*.{h,m,swift}'
        subspec.frameworks = 'UIKit','Foundation'
    end

    # English: Publish typed SF Symbols and the normalized catalog as a small reusable layer.
    # Español: Publica los SF Symbols tipados y el catálogo normalizado como una capa reutilizable pequeña.
    # 中文：将类型化 SF Symbols 和标准化目录作为轻量可复用层公开。
    s.subspec 'Symbols' do |subspec|
        subspec.source_files = 'PooToolsSource/PToolsSymbols/**/*.swift'
        subspec.resource_bundles = {
            'PooToolsSymbolsResources' => ['PooToolsSource/PToolsSymbols/Resources/**/*']
        }
        subspec.frameworks = 'UIKit','Foundation','OSLog'
    end

    s.subspec 'PToolsPermissionCore' do |subspec|
        subspec.source_files = 'PooToolsSource/PToolsPermissionCore/*.{h,m,swift}'
        subspec.frameworks = 'Foundation'
    end

    s.subspec 'PToolsPermissionUI' do |subspec|
        subspec.dependency 'PooTools/PToolsPermissionCore'
        subspec.dependency 'PooTools/PToolsUIFoundation'
        subspec.source_files = 'PooToolsSource/PToolsPermissionUI/*.{h,m,swift}'
        subspec.frameworks = 'UIKit','Foundation'
    end

    # English: MediaCore contains only transport-neutral descriptors and protocols.
    # Español: MediaCore solo contiene descriptores y protocolos multimedia neutrales al transporte.
    # 中文：MediaCore 只包含与传输无关的媒体描述符和协议。
    s.subspec 'MediaCore' do |subspec|
        subspec.source_files = 'PooToolsSource/PToolsMediaCore/*.{h,m,swift}'
        subspec.frameworks = 'Foundation'
    end

    s.subspec "Core" do |subspec|
        subspec.dependency 'PooTools/PToolsCore'
        subspec.dependency 'PooTools/PToolsUIFoundation'
        subspec.dependency 'PooTools/Logging'
        subspec.dependency 'PooTools/Symbols'
        subspec.dependency 'SwiftDate'
        subspec.dependency 'SnapKit'
        subspec.dependency 'DeviceKit'
        subspec.dependency 'IQKeyboardToolbarManager'
        subspec.dependency 'IQKeyboardManagerSwift'
        subspec.dependency 'Kingfisher'
        subspec.dependency 'SmartCodable'
        subspec.dependency 'SmartCodable/Inherit'
        subspec.dependency 'KakaJSON'
        subspec.dependency 'lottie-ios'
        subspec.resource_bundles = {
            'PooToolsResource' => ['PooToolsSource/Resource/**/*','PooToolsSource/Resource/PrivacyInfo.xcprivacy','PooToolsSource/Resources/*.lproj']
        }
        subspec.frameworks = 'UIKit','Foundation','AVKit','CoreFoundation','CoreText','AVFoundation','Photos','AudioToolbox'
        subspec.source_files = 'PooToolsSource/Core/*.{h,m,swift,S}','PooToolsSource/Blur/*.{h,m,swift}','PooToolsSource/ActionsheetAndAlert/*.{h,m,swift}','PooToolsSource/Base/*.{h,m,swift}','PooToolsSource/AppStore/*.{h,m,swift}','PooToolsSource/ApplicationFunction/*.{h,m,swift}','PooToolsSource/BlackMagic/*.{h,m,swift}','PooToolsSource/Button/*.{h,m,swift}','PooToolsSource/Category/*.{h,m,swift}','PooToolsSource/Log/*.{h,m,swift}','PooToolsSource/StatusBar/*.{h,m,swift}','PooToolsSource/Protocol/*.{h,m,swift}','PooToolsSource/Animation/*.{h,m,swift}','PooToolsSource/PermissionCore/*.{h,m,swift}','PooToolsSource/PhotoLibraryPermission/*.{h,m,swift}','PooToolsSource/AppDelegate/*.{h,m,swift}','PooToolsSource/Foundation/*.{h,m,swift}','PooToolsSource/Language/*.{h,m,swift}','PooToolsSource/DarkMode/*.{h,m,swift}','PooToolsSource/Line/*.{h,m,swift}','PooToolsSource/Badge/*.{h,m,swift}','PooToolsSource/Rotation/*.{h,m,swift}','PooToolsSource/Switch/*.{h,m,swift}','PooToolsSource/Colors/*.{h,m,swift}','PooToolsSource/Font/*.{h,m,swift}','PooToolsSource/FloatPanel/*.{h,m,swift}','PooToolsSource/SideMenuControl/*.{h,m,swift}','PooToolsSource/iCloud/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_COCOAPODS POOTOOLS_SPLIT_CORE POOTOOLS_SPLIT_UIFOUNDATION"
        }
    end
    
    # English: Keep the old Network spelling as a thin compatibility alias.
    # Español: Mantiene la grafía antigua de Network como un alias de compatibilidad ligero.
    # 中文：保留旧的 Network 拼写作为轻量兼容别名。
    s.subspec 'NetWork' do |subspec|
        subspec.dependency 'PooTools/Network'
    end

    s.subspec 'Network' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/Loading'
        subspec.dependency 'Alamofire'
        subspec.source_files = 'PooToolsSource/NetWork/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_NETWORK POOTOOLS_COCOAPODS"
        }
    end

    s.subspec 'NotificationBanner' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'NotificationBannerSwift'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_NOTIFICATIONBANNER POOTOOLS_COCOAPODS"
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

    # English: Publish the native CryptoKit/Security facade without third-party security types.
    # Español: Publica la fachada nativa de CryptoKit/Security sin tipos de seguridad de terceros.
    # 中文：发布不暴露第三方安全类型的 CryptoKit/Security 原生门面。
    s.subspec 'Security' do |subspec|
        subspec.source_files = 'PooToolsSource/Security/*.{h,m,swift}'
        subspec.frameworks = 'Foundation', 'CryptoKit', 'Security', 'LocalAuthentication'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_SECURITY POOTOOLS_COCOAPODS"
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
    
    # English: Expose the corrected BioID spelling and preserve BilogyID as a forwarding alias.
    # Español: Expone la grafía corregida BioID y conserva BilogyID como alias de reenvío.
    # 中文：提供正确的 BioID 拼写，并保留 BilogyID 作为转发别名。
    s.subspec 'BilogyID' do |subspec|
        subspec.dependency 'PooTools/BioID'
    end

    s.subspec 'BioID' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/FaceIDPermission'
        subspec.dependency 'PooTools/KeyChain'
        subspec.frameworks = 'LocalAuthentication','Security'
        subspec.source_files = 'PooToolsSource/BioID/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_BIOID POOTOOLS_BILOGYID POOTOOLS_COCOAPODS"
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
        subspec.source_files = 'PooToolsSource/CheckBox/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_CHECKBOX POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'CheckDirtyWord' do |subspec|
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
        subspec.dependency 'PooTools/MediaCore'
        subspec.dependency 'PooTools/ProgressBar'
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
        subspec.frameworks = 'Security'
        subspec.source_files = 'PooToolsSource/PhoneInfo/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PHONEINFO POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'RateView' do |subspec|
        subspec.dependency 'PooTools/PToolsUIFoundation'
        subspec.dependency 'SnapKit'
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

    # English: SearchViewController is an opt-in container layered on Core and SearchBar.
    # Español: SearchViewController es un contenedor opcional sobre Core y SearchBar.
    # 中文：SearchViewController 是建立在 Core 和 SearchBar 之上的可选容器模块。
    s.subspec 'Search' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/PToolsUIFoundation'
        subspec.dependency 'PooTools/SearchBar'
        subspec.source_files = 'PooToolsSource/Search/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_SEARCH POOTOOLS_COCOAPODS"
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
        subspec.dependency 'PooTools/PToolsUIFoundation'
        subspec.dependency 'SnapKit'
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
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_ZIPARCHIVE POOTOOLS_ZIPARCHINE POOTOOLS_COCOAPODS"
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
        subspec.source_files = 'PooToolsSource/Picker/*.{h,m,swift}'
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
    
    s.subspec 'StepCount' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/HealthPermission'
        subspec.frameworks = 'HealthKit'
        subspec.source_files = 'PooToolsSource/HealthKit/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_STEPCOUNT POOTOOLS_COCOAPODS"
        }
    end
        
    s.subspec 'DEBUG' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/Symbols'
        subspec.dependency 'PooTools/NetWork'
        subspec.dependency 'PooTools/Share'
        subspec.dependency 'PooTools/SearchBar'
        subspec.dependency 'PooTools/PDF'
        subspec.source_files = 'PooToolsSource/Debug/*.{h,m,swift}','PooToolsSource/LocalConsole/*.{h,m,swift}','PooToolsSource/DevMask/*.{h,m,swift}','PooToolsSource/TouchInspector/*.{h,m,swift}','PooToolsSource/DEBUGLocation/*.{h,m,swift}','PooToolsSource/Inspector/*.{h,m,swift}','PooToolsSource/DebugLibs/*.{h,m,swift}','PooToolsSource/DebugCrash/*.{h,m,swift}','PooToolsSource/DebugFile/*.{h,m,swift}','PooToolsSource/DebugColor/*.{h,m,swift}','PooToolsSource/DebugRuler/*.{h,m,swift}','PooToolsSource/DebugPerformance/*.{h,m,swift}','PooToolsSource/DebugCategory/*.{h,m,swift}','PooToolsSource/DebugUserDefault/*.{h,m,swift}','PooToolsSource/DebugNetwork/*.{h,m,swift}'
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
        subspec.dependency 'PooTools/PToolsPermissionCore'
        subspec.source_files = 'PooToolsSource/NotificationPermission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_NOTIFICATION POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'CameraPermission' do |subspec|
        subspec.dependency 'PooTools/PToolsPermissionCore'
        subspec.source_files = 'PooToolsSource/CameraPermission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_CAMERA POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'LocationPermission' do |subspec|
        subspec.dependency 'PooTools/PToolsPermissionCore'
        subspec.source_files = 'PooToolsSource/LocationPermission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_LOCATION POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'CalendarPermission' do |subspec|
        subspec.dependency 'PooTools/PToolsPermissionCore'
        subspec.source_files = 'PooToolsSource/CalendarPermission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_CALENDAR POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'MotionPermission' do |subspec|
        subspec.dependency 'PooTools/PToolsPermissionCore'
        subspec.source_files = 'PooToolsSource/MotionPermission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_MOTION POOTOOLS_COCOAPODS"
        }
    end
        
    s.subspec 'TrackingPermission' do |subspec|
        subspec.dependency 'PooTools/PToolsPermissionCore'
        subspec.source_files = 'PooToolsSource/TrackingPermission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_TRACKING POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'RemindersPermission' do |subspec|
        subspec.dependency 'PooTools/PToolsPermissionCore'
        subspec.source_files = 'PooToolsSource/RemindersPermission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_REMINDERS POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'SpeechRecognizerPermission' do |subspec|
        subspec.dependency 'PooTools/PToolsPermissionCore'
        subspec.source_files = 'PooToolsSource/SpeechPremission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_SPEECH POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'HealthPermission' do |subspec|
        subspec.dependency 'PooTools/PToolsPermissionCore'
        subspec.source_files = 'PooToolsSource/HealthPermission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_HEALTH POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'FaceIDPermission' do |subspec|
        subspec.dependency 'PooTools/PToolsPermissionCore'
        subspec.source_files = 'PooToolsSource/FaceIDPermission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_FACEIDPERMISSION POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'ContactsPermission' do |subspec|
        subspec.dependency 'PooTools/PToolsPermissionCore'
        subspec.source_files = 'PooToolsSource/ContactsPermission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_CONTACTS POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'MicPermission' do |subspec|
        subspec.dependency 'PooTools/PToolsPermissionCore'
        subspec.source_files = 'PooToolsSource/MicPermission/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PERMISSION_MIC POOTOOLS_COCOAPODS"
        }
    end

    # English: Preserve the historical MeidaPermission name while publishing MediaPermission as canonical.
    # Español: Conserva el nombre histórico MeidaPermission y publica MediaPermission como nombre canónico.
    # 中文：保留历史 MeidaPermission 名称，同时提供规范的 MediaPermission。
    s.subspec 'MeidaPermission' do |subspec|
        subspec.dependency 'PooTools/MediaPermission'
    end

    s.subspec 'MediaPermission' do |subspec|
        subspec.dependency 'PooTools/PToolsPermissionCore'
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
        subspec.dependency 'PooTools/Symbols'
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
        subspec.dependency 'PooTools/Symbols'
        subspec.dependency 'PooTools/MediaCore'
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
        subspec.dependency 'PooTools/Symbols'
        subspec.dependency 'PooTools/MediaCore'
        subspec.dependency 'PooTools/ImagePicker'
        subspec.dependency 'PooTools/Loading'
        subspec.dependency 'Kakapos'
        subspec.source_files = 'PooToolsSource/PhotoPicker/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_PHOTOPICKER POOTOOLS_COCOAPODS"
        }
    end

    s.subspec 'ImagePicker' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/CameraPermission'
        subspec.source_files = 'PooToolsSource/ImagePicker/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_IMAGEPICKER POOTOOLS_COCOAPODS"
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
        subspec.dependency 'PooTools/Symbols'
        subspec.dependency 'PooTools/MediaCore'
        subspec.dependency 'PooTools/HarbethKit'
        subspec.dependency 'PooTools/PhotoPicker'
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
        subspec.dependency 'PooTools/Symbols'
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
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_MXMETRICMANAGERKIT POOTOOLS_MXMERRICKITMANAGER POOTOOLS_COCOAPODS"
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
    
    s.subspec 'Hud' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/ProgressBar'
        subspec.source_files = 'PooToolsSource/Hud/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_HUD POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'LaunchTimeProfiler' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.source_files = 'PooToolsSource/LaunchTimeProfiler/*.{h,m,swift}'
        subspec.pod_target_xcconfig = {
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS"  => "POOTOOLS_LAUNCHTIMEPROFILER POOTOOLS_COCOAPODS"
        }
    end
    
    s.subspec 'InputAll' do |subspec|
        subspec.dependency 'PooTools/Core'
        subspec.dependency 'PooTools/DataEncrypt'
        subspec.dependency 'PooTools/Security'
        subspec.dependency 'PooTools/Hud'
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
        subspec.dependency 'PooTools/Search'
        subspec.dependency 'PooTools/Segmented'
        subspec.dependency 'PooTools/Slider'
        subspec.dependency 'PooTools/CheckUpdate'
        subspec.dependency 'PooTools/Layout'
        subspec.dependency 'PooTools/Tabbar'
        subspec.dependency 'PooTools/SmartScreenshot'
        subspec.dependency 'PooTools/ZipArchive'
        subspec.dependency 'PooTools/GCDWebServer'
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
        subspec.dependency 'PooTools/SVG'
        subspec.dependency 'PooTools/Share'
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
