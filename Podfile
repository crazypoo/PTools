platform :ios, '17.0'
use_frameworks!

legacy_swift5_targets = %w[Appz KituraContracts]

post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        if legacy_swift5_targets.include?(target.name)
          config.build_settings['SWIFT_VERSION'] = '5.0'
          config.build_settings['SWIFT_STRICT_CONCURRENCY'] = 'minimal'
        end

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
  
  pod 'FLEX'
  pod 'InAppViewDebugger'
  pod 'LookinServer'
#  pod 'Bugly'
#  pod 'LifetimeTracker', :configurations => ['Debug']
#  pod "HyperioniOS/Core", :configurations => ['Debug']
#  pod 'HyperioniOS/AttributesInspector', :configurations => ['Debug'] # Optional plugin
#  pod 'HyperioniOS/Measurements', :configurations => ['Debug'] # Optional plugin
#  pod 'HyperioniOS/SlowAnimations', :configurations => ['Debug'] # Optional plugin
#  pod 'WoodPeckeriOS', :configurations => ['Debug']
#  pod 'netfox', :configurations => ['Debug']
#  pod 'DiDiPrism'
#  pod 'DiDiPrism_Ability', :subspecs => ['WithBehaviorRecord', 'WithBehaviorReplay', 'WithBehaviorDetect', 'WithDataVisualization']
  # English: Bugly is optional for the example app; use a vendor-provided XCFramework in a host project when needed.
  # Español: Bugly es opcional para el ejemplo; usa un XCFramework del proveedor en el proyecto anfitrión cuando sea necesario.
  # 中文：示例工程中的 Bugly 为可选依赖；需要时由宿主项目接入供应商提供的 XCFramework。
#  pod 'Reveal-SDK', :configurations => ['Debug']
##JD包体分析
#https://github.com/helele90/APPAnalyze

  pod 'PooTools/InputAll', :path => './'
  # English: Include the opt-in PooTools features used directly by the example target.
  # Español: Incluye las funciones opt-in de PooTools que el target de ejemplo usa directamente.
  # 中文：显式加入示例 Target 直接使用的 PooTools 可选功能。
  pod 'PooTools/HandSign', :path => './'
  pod 'PooTools/MediaPermission', :path => './'
  # English: The catalog uses the typed speed-test demo directly, so keep its opt-in subspec explicit.
  # Español: El catálogo usa directamente el demo de velocidad tipado; mantiene explícito su subspec opcional.
  # 中文：目录直接使用类型化测速 Demo，因此显式声明对应的可选 subspec。
  pod 'PooTools/NetworkSpeedTest', :path => './'

  # English: Keep modules imported directly by the example target explicit.
  # Español: Mantén explícitos los módulos que el target de ejemplo importa directamente.
  # 中文：示例 Target 直接导入的模块必须显式声明，不能依赖传递依赖可见性。
  pod 'Alamofire'
  pod 'CryptoSwift'
  pod 'IQKeyboardToolbarManager'
  pod 'SmartCodable'
  pod 'SnapKit'
  pod 'SVGAPlayer'

#  pod 'PooTools/InputAll', :git => 'https://github.com/crazypoo/PTools.git'

#  pod 'MetaCodable'
#  pod 'MetaCodable/HelperCoders'

  pod 'SwiftLint'
  pod 'Swinject'
  pod 'KTVHTTPCache'
#  pod 'Protobuf'
#  pod 'SVGAPlayer'
#  pod 'SmartCodable/Inherit'
end
