platform :ios, '13.1'
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

#添加此处是因为harbeth库无法添加
pre_install do |installer|
Pod::Installer::Xcode::TargetValidator.send(:define_method, :verify_no_static_framework_transitive_dependencies) {}
end

target 'PooTools_Example' do
  
  pod 'FLEX', :configurations => ['Debug']
  pod 'InAppViewDebugger', :configurations => ['Debug']
  pod 'LookinServer', :configurations => ['Debug']
  pod 'LifetimeTracker', :configurations => ['Debug']
  pod "HyperioniOS/Core", :configurations => ['Debug']
  pod 'HyperioniOS/AttributesInspector', :configurations => ['Debug'] # Optional plugin
  pod 'HyperioniOS/Measurements', :configurations => ['Debug'] # Optional plugin
  pod 'HyperioniOS/SlowAnimations', :configurations => ['Debug'] # Optional plugin
#  pod 'WoodPeckeriOS', :configurations => ['Debug']
  pod 'netfox', :configurations => ['Debug']
  pod 'DiDiPrism'
  pod 'DiDiPrism_Ability', :subspecs => ['WithBehaviorRecord', 'WithBehaviorReplay', 'WithBehaviorDetect', 'WithDataVisualization']
  pod 'Bugly'

  #权限询问
  pod 'PooTools', :subspecs => ['InputAll','NotificationPermission', 'LocationPermission', 'CameraPermission', 'CalendarPermission','MotionPermission','TrackingPermission','RemindersPermission','FaceIDPermission','HealthPermission','SpeechRecognizerPermission','ContactsPermission','MicPermission','MeidaPermission','BluetoothPermission','SiriPermission'], :path => 'PooTools.podspec'
  
  pod 'SwiftLint'
  pod 'Swinject'
end
