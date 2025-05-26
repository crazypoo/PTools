platform :ios, '14.0'
use_frameworks!

post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
#        if config.name == 'Release'
#          # swift编译优化级别
#          config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Osize'
#          config.build_settings['SWIFT_COMPILATION_MODE'] = 'wholemodule'
#          # GCC编译优化级别
#          config.build_settings['GCC_OPTIMIZATION_LEVEL'] = 'z'
#          config.build_settings['LLVM_LTO'] = 'YES_THIN'
#          # 打包后裁剪不必要的符号
#          config.build_settings['STRIP_INSTALLED_PRODUCT'] = 'YES'
#          
#          config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf-with-dsym'
#          end
        if config.name == 'Debug'
          config.build_settings['STRIP_INSTALLED_PRODUCT'] = 'NO' # strip Linked product
        else
          config.build_settings['STRIP_INSTALLED_PRODUCT'] = 'YES'
        end
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
#  pod 'LifetimeTracker', :configurations => ['Debug']
#  pod "HyperioniOS/Core", :configurations => ['Debug']
#  pod 'HyperioniOS/AttributesInspector', :configurations => ['Debug'] # Optional plugin
#  pod 'HyperioniOS/Measurements', :configurations => ['Debug'] # Optional plugin
#  pod 'HyperioniOS/SlowAnimations', :configurations => ['Debug'] # Optional plugin
#  pod 'WoodPeckeriOS', :configurations => ['Debug']
#  pod 'netfox', :configurations => ['Debug']
#  pod 'DiDiPrism'
#  pod 'DiDiPrism_Ability', :subspecs => ['WithBehaviorRecord', 'WithBehaviorReplay', 'WithBehaviorDetect', 'WithDataVisualization']
  pod 'Bugly'
#  pod 'Reveal-SDK', :configurations => ['Debug']
##JD包体分析
#https://github.com/helele90/APPAnalyze

  pod 'PooTools/InputAll', :path => './'
#  pod 'PooTools/InputAll', :git => 'https://github.com/crazypoo/PTools.git'

#  pod 'MetaCodable'
#  pod 'MetaCodable/HelperCoders'

  pod 'SwiftLint'
  pod 'Swinject'
#  pod 'Protobuf'
#  pod 'SVGAPlayer'
#  pod 'SmartCodable/Inherit'
end
