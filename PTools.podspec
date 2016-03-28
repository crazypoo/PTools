#
#  Be sure to run `pod spec lint PTools.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "PTools"
  s.version      = “1.0.1”
  s.summary      = "A short description of PTools."
  s.description  = <<-DESC
                   DESC
  s.homepage     = "https://github.com/crazypoo/PTools"
  s.license      = "MIT"
  s.author       = { "公司" => "273277355@qq.com" }				      
  s.platform     = :ios, “8.0”
  s.source       = { :git => "https://github.com/crazypoo/PTools.git", :tag => "#{s.version}" }
  s.source_files  = "PTools/*“
  # s.framework  = "SomeFramework"
  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # s.dependency "JSONKit", "~> 1.4"
end
