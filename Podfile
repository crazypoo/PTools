platform :ios, '13.0'
use_frameworks!

post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
      end
      target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
            target.build_configurations.each do |config|
                config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      end
  end
end

target 'PooTools_Example' do
  pod 'PooTools/InputAll', :path => 'PooTools.podspec'
  pod 'WZLBadge'
  pod 'SnapKit'
  pod 'YYCategories'
#  pod 'WoodPeckeriOS'
  pod "GCDWebServer/WebUploader", "~> 3.0"
  pod 'HandyJSON' #JSON处理
  pod 'DeviceKit', '~> 4.0'
  pod 'SwifterSwift'#Swift扩展类
  pod 'NotificationBannerSwift'#类似推送的弹出框
  pod 'CocoaLumberjack/Swift'#Log工具
  pod 'SwiftDate'
  pod 'KakaJSON'
  pod 'Alamofire'
  pod 'HandyJSON'
  pod 'SwiftyJSON'
  pod 'CocoaLumberjack/Swift'#Log工具
  pod 'SJAttributesStringMaker'
  pod 'SDWebImage'
  pod 'MJRefresh'
  pod 'ZXNavigationBar'#导航栏
  pod 'CryptoSwift'
  
  pod 'FLEX', :configurations => ['Debug']
  pod 'InAppViewDebugger', :configurations => ['Debug']
  pod 'LookinServer', :configurations => ['Debug']

  #权限询问
  pod 'PermissionsKit/NotificationPermission', :git => 'https://github.com/sparrowcode/PermissionsKit'
  pod 'PermissionsKit/CameraPermission', :git => 'https://github.com/sparrowcode/PermissionsKit'
  pod 'PermissionsKit/LocationWhenInUsePermission', :git => 'https://github.com/sparrowcode/PermissionsKit'
  pod 'PermissionsKit/LocationAlwaysPermission', :git => 'https://github.com/sparrowcode/PermissionsKit'
  pod 'PermissionsKit/CalendarPermission', :git => 'https://github.com/sparrowcode/PermissionsKit'
  pod 'PermissionsKit/MotionPermission', :git => 'https://github.com/sparrowcode/PermissionsKit'
  pod 'PermissionsKit/PhotoLibraryPermission', :git => 'https://github.com/sparrowcode/PermissionsKit'
  pod 'PermissionsKit/TrackingPermission', :git => 'https://github.com/sparrowcode/PermissionsKit'
  pod 'PermissionsKit/RemindersPermission', :git => 'https://github.com/sparrowcode/PermissionsKit'
  pod 'PermissionsKit/FaceIDPermission', :git => 'https://github.com/sparrowcode/PermissionsKit'
  pod 'PermissionsKit/HealthPermission', :git => 'https://github.com/sparrowcode/PermissionsKit'
  pod 'PermissionsKit/SpeechRecognizerPermission', :git => 'https://github.com/sparrowcode/PermissionsKit'

#  pod 'PooTools/NotificationPermission', :path => 'PooTools.podspec'
#  pod 'PooTools/CameraPermission', :path => 'PooTools.podspec'
#  pod 'PooTools/LocationWhenInUsePermission', :path => 'PooTools.podspec'
#  pod 'PooTools/LocationAlwaysPermission', :path => 'PooTools.podspec'
#  pod 'PooTools/CalendarPermission', :path => 'PooTools.podspec'
#  pod 'PooTools/MotionPermission', :path => 'PooTools.podspec'
#  pod 'PooTools/PhotoLibraryPermission', :path => 'PooTools.podspec'
#  pod 'PooTools/TrackingPermission', :path => 'PooTools.podspec'
#  pod 'PooTools/RemindersPermission', :path => 'PooTools.podspec'
#  pod 'PooTools/FaceIDPermission', :path => 'PooTools.podspec'
#  pod 'PooTools/HealthPermission', :path => 'PooTools.podspec'
#  pod 'PooTools/SpeechRecognizerPermission', :path => 'PooTools.podspec'

  pod 'SwiftLint'
end
