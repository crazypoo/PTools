#!/usr/bin/env ruby

# English: Guard the app/library boundary before CocoaPods builds the example target.
# Español: Protege el límite entre la app y la biblioteca antes de compilar el ejemplo con CocoaPods.
# 中文：在 CocoaPods 构建示例工程前，保护 App 与库之间的源码和模块边界。

require "pathname"
require "xcodeproj"

repo_root = Pathname.new(__dir__).join("../..").realpath
project_path = repo_root.join("PooTools.xcodeproj")
project = Xcodeproj::Project.open(project_path.to_s)
target = project.targets.find { |candidate| candidate.name == "PooTools_Example" }
abort "FAIL: target not found: PooTools_Example" unless target

def absolute_path(path, root)
  candidate = Pathname.new(path.to_s)
  candidate = root.join(candidate) unless candidate.absolute?
  candidate.cleanpath
end

def relative_path(path, root)
  absolute = absolute_path(path, root)
  absolute.relative_path_from(root).to_s
rescue ArgumentError
  absolute.to_s
end

def truthy_build_setting?(value)
  %w[YES true 1].include?(value.to_s)
end

def setting_text(value)
  value.is_a?(Array) ? value.join(" ") : value.to_s
end

failures = []

library_sources = target.source_build_phase.files.filter_map do |build_file|
  next unless build_file.file_ref

  path = relative_path(build_file.file_ref.real_path.to_s, repo_root)
  path if path.start_with?("PooToolsSource/")
end

unless library_sources.empty?
  failures << "PooTools_Example still compiles #{library_sources.length} PooToolsSource file(s): #{library_sources.first(10).join(', ')}"
end

target.build_configurations.each do |configuration|
  settings = configuration.build_settings
  configuration_name = configuration.name

  if settings["MODULE_NAME"].to_s == "PooTools"
    failures << "#{configuration_name}: MODULE_NAME must not be PooTools"
  end

  if truthy_build_setting?(settings["DEFINES_MODULE"])
    failures << "#{configuration_name}: DEFINES_MODULE must not be explicitly enabled for the example app"
  end

  if truthy_build_setting?(settings["ENABLE_MODULE_VERIFIER"])
    failures << "#{configuration_name}: ENABLE_MODULE_VERIFIER must not be explicitly enabled for the example app"
  end

  interface_header = settings["SWIFT_OBJC_INTERFACE_HEADER_NAME"].to_s
  if interface_header.include?("PooTools/PooTools-Swift.h")
    failures << "#{configuration_name}: Swift generated header must not use PooTools/PooTools-Swift.h"
  end

  if settings["SDKROOT"].to_s == "iphoneos"
    failures << "#{configuration_name}: SDKROOT must be selected by the build destination"
  end

  settings.each do |key, value|
    next unless key == "EXCLUDED_ARCHS" || key.start_with?("EXCLUDED_ARCHS[")
    next unless setting_text(value).split(/[,\s]+/).include?("arm64")

    failures << "#{configuration_name}: arm64 must not be excluded from Simulator builds (#{key})"
  end
end

project.build_configurations.each do |configuration|
  if configuration.build_settings["SDKROOT"].to_s == "iphoneos"
    failures << "Project #{configuration.name}: SDKROOT must be selected by the build destination"
  end
end

if failures.empty?
  puts "PASS: PooTools_Example owns only example sources and has destination-driven module settings"
else
  failures.each { |failure| warn "FAIL: #{failure}" }
  exit 1
end
