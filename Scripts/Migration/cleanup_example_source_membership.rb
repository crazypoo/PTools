#!/usr/bin/env ruby

# English: Keep library sources owned by the PooTools library target, not the example app.
# Español: Mantiene los sources de la biblioteca en el target de PooTools, no en la app de ejemplo.
# 中文：让库源码只归 PooTools 库 Target 所有，不再由示例 App 重复编译。

require "fileutils"
require "optparse"
require "pathname"
require "xcodeproj"

options = {
  project: "PooTools.xcodeproj",
  target: "PooTools_Example",
  dry_run: false,
  backup: nil,
  allowlist: nil,
  report: nil
}

OptionParser.new do |parser|
  parser.banner = "Usage: cleanup_example_source_membership.rb [options]"
  parser.on("--project PATH", "Xcode project path") { |value| options[:project] = value }
  parser.on("--target NAME", "Example target name") { |value| options[:target] = value }
  parser.on("--dry-run", "Report changes without saving the project") { options[:dry_run] = true }
  parser.on("--backup PATH", "Copy the project file before saving") { |value| options[:backup] = value }
  parser.on("--allowlist PATH", "Relative paths allowed to remain in the example target") { |value| options[:allowlist] = value }
  parser.on("--report PATH", "Write a Markdown ownership report") { |value| options[:report] = value }
end.parse!

repo_root = Pathname.new(__dir__).join("../..").realpath
project_path = repo_root.join(options[:project]).realpath
project = Xcodeproj::Project.open(project_path.to_s)
target = project.targets.find { |candidate| candidate.name == options[:target] }
abort "FAIL: target not found: #{options[:target]}" unless target

def normalized_relative_path(path, root)
  Pathname.new(path).realpath.relative_path_from(root).to_s
rescue Errno::ENOENT, ArgumentError
  candidate = Pathname.new(path).cleanpath
  return nil unless candidate.absolute? && candidate.to_s.start_with?(root.to_s + "/")
  candidate.relative_path_from(root).to_s
end

allowlist = if options[:allowlist]
              File.readlines(repo_root.join(options[:allowlist]), chomp: true)
                .map(&:strip)
                .reject { |line| line.empty? || line.start_with?("#") }
            else
              []
            end

is_allowed = lambda do |relative_path|
  allowlist.any? { |entry| entry == relative_path }
end

source_build_files = target.source_build_phase.files
source_membership = {}
source_build_files.each do |build_file|
  next unless build_file.file_ref
  relative_path = normalized_relative_path(build_file.file_ref.real_path.to_s, repo_root)
  source_membership[relative_path] = build_file
end

library_paths = source_membership.keys.select { |path| path.start_with?("PooToolsSource/") }
removable_paths = library_paths.reject { |path| is_allowed.call(path) }

if options[:report]
  all_paths = project.objects
                    .select { |object| object.isa == "PBXFileReference" && object.real_path }
                    .map { |file_ref| normalized_relative_path(file_ref.real_path.to_s, repo_root) }
                    .compact
                    .select { |path| path.start_with?("PooToolsSource/") || path.start_with?("PooTools/") }
                    .uniq
                    .sort

  podspec = File.read(repo_root.join("PooTools.podspec"))
  package = File.read(repo_root.join("Package.swift"))
  report_path = repo_root.join(options[:report])
  FileUtils.mkdir_p(report_path.dirname)
  File.open(report_path, "w") do |file|
    file.puts "# Example Source Ownership Audit"
    file.puts
    file.puts "- Target: `#{options[:target]}`"
    file.puts "- Library source membership before cleanup: `#{library_paths.length}`"
    file.puts "- Library source membership to remove: `#{removable_paths.length}`"
    file.puts "- Allowlisted library sources: `#{library_paths.length - removable_paths.length}`"
    file.puts
    file.puts "| File | Physical Path | Example Compile Sources? | Podspec Source? | SwiftPM Target? | Classification | Action |"
    file.puts "| --- | --- | --- | --- | --- | --- | --- |"
    all_paths.each do |relative_path|
      is_library = relative_path.start_with?("PooToolsSource/")
      podspec_source = is_library && podspec.include?(relative_path.split("/")[0, 2].join("/"))
      swiftpm_target = is_library && package.include?(relative_path.split("/")[0, 2].join("/"))
      in_example = source_membership.key?(relative_path)
      classification = is_library ? "Library" : "Example"
      action = is_library && in_example && !is_allowed.call(relative_path) ? "remove_from_example_target" : "keep"
      file.puts "| `#{File.basename(relative_path)}` | `#{relative_path}` | #{in_example ? "yes" : "no"} | #{podspec_source ? "yes" : "no"} | #{swiftpm_target ? "yes" : "no"} | #{classification} | #{action} |"
    end
  end
end

puts "Target: #{options[:target]}"
puts "Library sources in Example target: #{library_paths.length}"
puts "Library sources to remove: #{removable_paths.length}"

unless options[:dry_run]
  if options[:backup]
    FileUtils.mkdir_p(File.dirname(options[:backup]))
    if project_path.directory?
      FileUtils.cp_r(project_path, options[:backup])
    else
      FileUtils.cp(project_path, options[:backup])
    end
  end
  removable_paths.each do |relative_path|
    target.source_build_phase.remove_build_file(source_membership.fetch(relative_path))
  end
  project.save
  puts "Saved: #{project_path}"
else
  puts "Dry run: project was not changed"
end
