#
# Be sure to run `pod lib lint PooTools.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name        = 'PooTools'
    s.version     = '1.1.8'
    s.author           = { 'crazypoo' => '273277355@qq.com' }
    s.homepage    = 'https://github.com/crazypoo/PTools'
    s.summary     = 'hahahahahahahahha.'
    s.source           = { :git => 'https://github.com/crazypoo/PTools.git', :tag => s.version.to_s }
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.platform = :ios, '8.0'
    s.requires_arc = true
    s.source_files = 'PooTools/*'
    #,'PooTools/**/*.h'
    #,'PooTools/*',
    #'PooTools/*.{h,m}'

    s.ios.deployment_target = '8.0'
    s.frameworks = 'UIKit', 'AudioToolbox','ExternalAccessory','CoreText','SystemConfiguration','WebKit','QuartzCore','CoreTelephony','Security','Foundation','AVFoundation','Speech','LocalAuthentication','HealthKit','CoreMotion'

end

#Pod::Spec.new do |s|
    #s.name             = 'PTools'
  #s.version          = '1.1.7'
  #s.summary          = 'A short description of PooTools.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

#s.description      = '6666666666666'

#s.homepage         = 'https://github.com/crazypoo/PTools'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  #s.license          = { :type => 'MIT', :file => 'LICENSE' }
  #s.author           = { 'crazypoo' => '273277355@qq.com' }
  #s.source           = { :git => 'https://github.com/crazypoo/PTools.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

#s.ios.deployment_target = '8.0'

#s.source_files = 'PooTools/Classes/**/*'
  
  # s.resource_bundles = {
  #   'PooTools' => ['PooTools/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'AudioToolbox','ExternalAccessory','CoreText','SystemConfiguration','WebKit','QuartzCore','CoreTelephony','Security','Foundation','AVFoundation','Speech','LocalAuthentication','HealthKit','CoreMotion'
  # s.dependency 'AFNetworking', '~> 2.3'
  #end
