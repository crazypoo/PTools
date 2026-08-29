#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# English: Keep the Core directory contract in one place for all three build entries.
# Español: Mantén el contrato de directorios Core en un solo lugar para las tres entradas de compilación.
# 中文：将三套构建入口使用的 Core 目录契约集中维护在一个位置。
core_dirs=(
  Core Blur ActionsheetAndAlert Base AppStore ApplicationFunction BlackMagic Button
  Category Log StatusBar Protocol Animation PermissionCore PhotoLibraryPermission
  AppDelegate Foundation Language DarkMode Line Badge Rotation Switch Colors Font
  FloatPanel SideMenuControl iCloud
)

printf 'Checking Core source contract (%s directories)\n' "${#core_dirs[@]}"

# English: xcodeproj is already provided by the CocoaPods toolchain; no app dependency is added.
# Español: xcodeproj ya lo proporciona la cadena de herramientas de CocoaPods; no se añade una dependencia de la aplicación.
# 中文：xcodeproj 已由 CocoaPods 工具链提供，本检查不会新增应用依赖。
ruby - "$repo_root" "${core_dirs[@]}" <<'RUBY'
require "pathname"
require "set"

begin
  require "xcodeproj"
rescue LoadError
  warn "FAIL: Ruby xcodeproj is required to verify Xcode source membership"
  exit 1
end

repo_root = File.expand_path(ARGV.shift)
core_dirs = ARGV
supported_extensions = %w[.h .m .swift .S]

failures = []

def relative_paths(paths, root)
  prefix = "#{File.expand_path(root)}/"
  paths.filter_map do |path|
    expanded = File.expand_path(path)
    expanded.start_with?(prefix) ? expanded.delete_prefix(prefix) : nil
  end.to_set
end

actual_paths = core_dirs.flat_map do |directory|
  Dir.glob(File.join(repo_root, "PooToolsSource", directory, "*")).filter_map do |path|
    File.file?(path) && supported_extensions.include?(File.extname(path)) ? path : nil
  end
end
actual_paths = relative_paths(actual_paths, repo_root)

podspec = File.read(File.join(repo_root, "PooTools.podspec"))
pod_source_line = podspec.lines.find { |line| line.include?("subspec.source_files =") }
pod_dirs = pod_source_line ? pod_source_line.scan(%r{PooToolsSource/([^/]+)/\*\.}).flatten.to_set : Set.new

package = File.read(File.join(repo_root, "Package.swift"))
package_target = package.match(/\.target\(\s*name: "ptools".*?sources: \s*\[(.*?)\]/m)
package_dirs = package_target ? package_target[1].scan(/"([^"]+)"/).flatten.to_set : Set.new

expected_dirs = core_dirs.to_set
unless pod_dirs == expected_dirs
  missing = (expected_dirs - pod_dirs).to_a.sort
  extra = (pod_dirs - expected_dirs).to_a.sort
  failures << "CocoaPods Core directories drifted; missing=#{missing.join(",")} extra=#{extra.join(",")}"
else
  puts "PASS: CocoaPods Core directories"
end

unless package_dirs == expected_dirs
  missing = (expected_dirs - package_dirs).to_a.sort
  extra = (package_dirs - expected_dirs).to_a.sort
  failures << "SwiftPM Core directories drifted; missing=#{missing.join(",")} extra=#{extra.join(",")}"
else
  puts "PASS: SwiftPM Core directories"
end

project = Xcodeproj::Project.open(File.join(repo_root, "PooTools.xcodeproj"))
target = project.targets.find { |item| item.name == "PooTools_Example" }
unless target
  failures << "Xcode target PooTools_Example was not found"
else
  xcode_paths = target.source_build_phase.files_references.compact.map(&:real_path)
  xcode_paths = relative_paths(xcode_paths, repo_root)
  xcode_core_paths = xcode_paths.select do |path|
    path.start_with?("PooToolsSource/") && core_dirs.any? do |directory|
      path.start_with?("PooToolsSource/#{directory}/")
    end
  end.to_set

  missing = (actual_paths - xcode_core_paths).to_a.sort
  extra = (xcode_core_paths - actual_paths).to_a.sort
  unless missing.empty? && extra.empty?
    failures << "Xcode Core source membership drifted; missing=#{missing.join(",")} extra=#{extra.join(",")}"
  else
    puts "PASS: Xcode Core source membership (#{actual_paths.length} files)"
  end
end

unless failures.empty?
  failures.each { |failure| warn "FAIL: #{failure}" }
  exit 1
end

puts "Core source contract OK"
RUBY
