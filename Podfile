platform :ios, '13.0'
use_frameworks!

post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
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
  pod 'LookinServer', :configurations => ['Debug']
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
end
