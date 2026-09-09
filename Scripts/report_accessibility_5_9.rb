#!/usr/bin/env ruby

require "json"
require "fileutils"

repo_root = File.expand_path("..", __dir__)
source_root = File.join(repo_root, "PooToolsSource")
report_dir = File.join(repo_root, "report")
FileUtils.mkdir_p(report_dir)

patterns = {
  "dynamic_type" => "adjustsFontForContentSizeCategory",
  "reduce_motion" => "isReduceMotionEnabled",
  "reduce_transparency" => "isReduceTransparencyEnabled",
  "accessibility" => "accessibility"
}
counts = Hash.new(0)
locations = []
Dir.glob(File.join(source_root, "**", "*.swift")).sort.each do |file|
  relative = file.delete_prefix("#{repo_root}/")
  File.foreach(file).with_index do |line, index|
    patterns.each do |name, token|
      next unless line.include?(token)
      counts[name] += 1
      locations << { "rule" => name, "path" => relative, "line" => index + 1 }
    end
  end
end

payload = {
  "schema_version" => 1,
  "counts" => counts,
  "locations" => locations
}
File.write(File.join(report_dir, "accessibility_5_9.json"), JSON.pretty_generate(payload) + "\n")

markdown = []
markdown << "# PTools 5.9.x UI 适配扫描"
markdown << ""
markdown << "| 能力 | 命中数 |"
markdown << "| --- | ---: |"
counts.keys.sort.each { |name| markdown << "| #{name} | #{counts[name]} |" }
markdown << ""
markdown << "扫描结果用于定位缺口；Dynamic Type、Reduce Motion 和 Reduce Transparency 仍需按模块人工验证。"
File.write(File.join(report_dir, "accessibility_5_9.md"), markdown.join("\n") + "\n")
puts "Accessibility 5.9 report: #{counts.inspect}"
