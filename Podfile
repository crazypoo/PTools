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
  
  pod 'FLEX', :configurations => ['Debug']
  pod 'InAppViewDebugger', :configurations => ['Debug']
  pod 'LookinServer', :configurations => ['Debug']
  pod 'LifetimeTracker', :configurations => ['Debug']
  pod "HyperioniOS/Core", :configurations => ['Debug']
  pod 'HyperioniOS/AttributesInspector', :configurations => ['Debug'] # Optional plugin
  pod 'HyperioniOS/Measurements', :configurations => ['Debug'] # Optional plugin
  pod 'HyperioniOS/SlowAnimations', :configurations => ['Debug'] # Optional plugin
  pod 'WoodPeckeriOS', :configurations => ['Debug']

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
  pod 'Swinject'
end
