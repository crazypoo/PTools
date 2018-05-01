Pod::Spec.new do |s|
s.name        = 'PTools'
s.version     = '1.1.5'
s.authors     = { '邓杰豪' => '273277355@qq.com' }
s.homepage    = 'https://github.com/crazypoo/PTools'
s.summary     = 'Tools.'
s.source      = { :git => 'https://github.com/crazypoo/PTools.git',
:tag => s.version.to_s }
s.license     = { :type => "MIT", :file => "LICENSE" }

s.platform = :ios, '8.0'
s.requires_arc = true
s.source_files = 'PTools'
s.public_header_files = 'PTools/*.h',"PTools/Tools/*.{h,m}","PTools/**/*.h"

s.ios.deployment_target = '8.0'
end