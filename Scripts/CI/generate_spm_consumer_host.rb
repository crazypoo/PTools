#!/usr/bin/env ruby
# English: Generate an iOS Xcode host with one target per SwiftPM library product.
# Español: Genera un host Xcode iOS con un target por cada producto de biblioteca SwiftPM.
# 中文：生成一个 iOS Xcode 宿主工程，为每个 SwiftPM library product 建立独立 target。

require "json"
require "fileutils"
require "xcodeproj"

root = File.expand_path("../..", __dir__)
host_root = File.join(root, "Tests", "SPMConsumerHost")
index_path = File.join(root, "Tests", "SPMConsumerFixtures", "Generated", "ProductIndex.json")
project_path = File.join(host_root, "SPMConsumerHost.xcodeproj")

FileUtils.rm_rf(project_path)
FileUtils.mkdir_p(host_root)
File.write(File.join(host_root, "Info.plist"), <<~PLIST)
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0"><dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>$(EXECUTABLE_NAME)</string>
  <key>CFBundleIdentifier</key><string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>$(PRODUCT_NAME)</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSRequiresIPhoneOS</key><true/>
  <key>UIApplicationSceneManifest</key><dict><key>UIApplicationSupportsMultipleScenes</key><false/></dict>
  </dict></plist>
PLIST

project = Xcodeproj::Project.new(project_path)
project.root_object.attributes["LastUpgradeCheck"] = "2720"
package = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
package.relative_path = "../../"
project.root_object.package_references << package

products = JSON.parse(File.read(index_path)).select { |item| item["kind"] == "library" }
consumer_targets = []
products.each do |item|
  product = item["product"]
  target_name = item["targetName"]
  target = project.new_target(:application, target_name, :ios, "17.0")
  target.product_name = target_name
  target.build_configurations.each do |config|
    config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "org.pootools.consumer.#{target_name.downcase}"
    config.build_settings["INFOPLIST_FILE"] = "Info.plist"
    config.build_settings["SWIFT_VERSION"] = "6.0"
    config.build_settings["SWIFT_STRICT_CONCURRENCY"] = "complete"
    config.build_settings["CODE_SIGNING_ALLOWED"] = "NO"
    config.build_settings["CODE_SIGNING_REQUIRED"] = "NO"
    config.build_settings["TARGETED_DEVICE_FAMILY"] = "1,2"
    config.build_settings["SUPPORTED_PLATFORMS"] = "iphonesimulator"
  end
  source = "../SPMConsumerFixtures/Generated/#{item["product"].gsub(/[^A-Za-z0-9_]/, "_")}/ImportSmoke.swift"
  target.add_file_references([project.new_file(source)])
  dependency = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  dependency.package = package
  dependency.product_name = product
  target.package_product_dependencies << dependency
  consumer_targets << target
end

project.save
consumer_targets.each do |target|
  scheme = Xcodeproj::XCScheme.new
  scheme.add_build_target(target)
  scheme.set_launch_target(target)
  scheme.save_as(project_path, target.name, true)
end
puts "generated=#{project_path} targets=#{products.length}"
