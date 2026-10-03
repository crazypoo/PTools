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
pod_source_line = podspec.lines.find { |line| line.include?("PooToolsSource/Core/*") }
pod_dirs = pod_source_line ? pod_source_line.scan(%r{PooToolsSource/([^/]+)/(?:\*\*/)?\*\.}).flatten.to_set : Set.new

package = File.read(File.join(repo_root, "Package.swift"))
package_target = package.match(/\.target\(\s*name: "ptools".*?sources: \s*\[(.*?)\]/m)
# English: Normalize explicit file entries back to their Core directory so a physical split does not look like drift.
# Español: Normaliza las entradas de archivos explícitas a su directorio Core para que una división física no parezca una desviación.
# 中文：将显式文件入口归一化回 Core 目录，避免文件拆分被误判为目录契约漂移。
package_dirs = if package_target
  package_target[1].scan(/"([^"]+)"/).flatten.map { |entry| entry.split("/").first }.to_set
else
  Set.new
end

# English: Verify the new SwiftPM layer targets without forcing legacy Xcode/CocoaPods sources to import them.
# Español: Verifica los nuevos targets de capa SwiftPM sin obligar a las fuentes heredadas de Xcode/CocoaPods a importarlos.
# 中文：校验新的 SwiftPM 分层 target，同时不强制旧版 Xcode/CocoaPods 源码导入这些模块。
foundation_targets = {
  "PToolsCore" => [
    'path: "PooToolsSource/PToolsCore"'
  ],
  "PToolsUIFoundation" => [
    'path: "PooToolsSource/PToolsUIFoundation"'
  ]
}

foundation_targets.each do |target_name, required_fragments|
  unless package.include?('name: "' + target_name + '"')
    failures << "SwiftPM layer target is missing: #{target_name}"
    next
  end
  required_fragments.each do |fragment|
    failures << "SwiftPM #{target_name} contract is missing: #{fragment}" unless package.include?(fragment)
  end
end

foundation_files = {
  "PToolsCore" => %w[
    PooToolsSource/PToolsCore/PTURLParser.swift
    PooToolsSource/PToolsCore/PTCoreValueTypes.swift
    PooToolsSource/PToolsCore/PTCoreAssociatedObjectStore.swift
    PooToolsSource/PToolsCore/PTCoreConcurrency.swift
    PooToolsSource/PToolsCore/PTMainActorBridge.swift
    PooToolsSource/PToolsCore/PTCoreContracts.swift
    PooToolsSource/PToolsCore/PTCoreCodable.swift
  ],
  "PToolsUIFoundation" => %w[
    PooToolsSource/PToolsUIFoundation/PTUIFoundationSnapKitEX.swift
  ]
}

foundation_files.each do |target_name, files|
  files.each do |file|
    failures << "SwiftPM #{target_name} source is missing: #{file}" unless File.file?(File.join(repo_root, file))
  end
end

%w[PToolsCore PToolsUIFoundation].each do |target_name|
  unless package.include?('"' + target_name + '"')
    failures << "ptools does not depend on #{target_name}"
  end
end

expected_dirs = core_dirs.to_set
# English: CocoaPods keeps the Foundation-only font metadata beside the monolithic Core sources so the 5.x pod can compile the split runtime files.
# Español: CocoaPods conserva los metadatos de fuentes Foundation-only junto al Core monolítico para que el pod 5.x compile los archivos de runtime divididos.
# 中文：CocoaPods 将 Foundation-only 字体元数据放在单体 Core 源码旁，以保证 5.x pod 能编译拆分后的运行时文件。
pod_compatibility_split_dirs = Set.new(%w[PToolsFontCore])
missing = (expected_dirs - pod_dirs).to_a.sort
missing_compatibility = (pod_compatibility_split_dirs - pod_dirs).to_a.sort
extra = ((pod_dirs - expected_dirs) - pod_compatibility_split_dirs).to_a.sort
unless missing.empty? && missing_compatibility.empty? && extra.empty?
  failures << "CocoaPods Core directories drifted; missing=#{missing.join(",")} missing_compatibility=#{missing_compatibility.join(",")} extra=#{extra.join(",")}"
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

if foundation_targets.keys.all? { |target_name| package.include?('name: "' + target_name + '"') }
  puts "PASS: SwiftPM Core / UIFoundation layer targets"
end

project = Xcodeproj::Project.open(File.join(repo_root, "PooTools.xcodeproj"))
target = project.targets.find { |item| item.name == "PooTools_Example" }
unless target
  failures << "Xcode target PooTools_Example was not found"
else
  xcode_paths = target.source_build_phase.files_references.compact.map(&:real_path)
  xcode_paths = relative_paths(xcode_paths, repo_root)
	# English: The example consumes the library through Pods/SwiftPM; it must not compile library sources directly.
	# Español: El ejemplo consume la biblioteca mediante Pods/SwiftPM; no debe compilar directamente sus fuentes.
	# 中文：示例工程通过 Pods/SwiftPM 使用库，不能再直接编译库源码。
	xcode_core_paths = xcode_paths.select do |path|
		path.start_with?("PooToolsSource/") && core_dirs.any? do |directory|
			path.start_with?("PooToolsSource/#{directory}/")
		end
	end.to_set

	unless xcode_core_paths.empty?
		failures << "Xcode Example target must not compile Core library sources: #{xcode_core_paths.to_a.sort.join(",")}"
	else
		puts "PASS: Xcode Example source ownership (PooToolsSource intersection is zero)"
	end
end

unless failures.empty?
  failures.each { |failure| warn "FAIL: #{failure}" }
  exit 1
end

puts "Core source contract OK"
RUBY
