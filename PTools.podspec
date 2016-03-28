#
#  Be sure to run `pod spec lint PTools.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "PTools"
  s.version      = "1.0.3"
  s.summary      = "First To Cocoapods"
  s.description  = <<-DESC
你们好哦...............
                   DESC
  s.homepage     = "https://github.com/crazypoo/PTools"
  s.license      = "MIT"
  s.author       = { "HelloKitty" => "273277355@qq.com" }				      
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/crazypoo/PTools.git", :tag =>"1.0.3"}
  s.source_files  = "PTools/*"
end
