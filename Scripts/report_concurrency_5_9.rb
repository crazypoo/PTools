#!/usr/bin/env ruby

require "json"
require "fileutils"

repo_root = File.expand_path("..", __dir__)
source_root = File.join(repo_root, "PooToolsSource")
report_dir = File.join(repo_root, "report")
FileUtils.mkdir_p(report_dir)

patterns = {
  "unchecked_sendable" => "@unchecked Sendable",
  "nonisolated_unsafe" => "nonisolated(unsafe)",
  "task_detached" => "Task.detached",
  "main_queue_async" => "DispatchQueue.main.async",
  "try_bang" => "try!",
  "as_bang" => "as!"
}

counts = Hash.new(0)
locations = []
Dir.glob(File.join(source_root, "**", "*.swift")).sort.each do |file|
  relative = file.delete_prefix("#{repo_root}/")
  File.foreach(file).with_index do |line, index|
    next if line.lstrip.start_with?("//")
    patterns.each do |name, token|
      next unless line.include?(token)
      counts[name] += 1
      locations << {
        "rule" => name,
        "path" => relative,
        "line" => index + 1,
        "text" => line.strip
      }
    end
  end
end

payload = {
  "schema_version" => 1,
  "baseline" => "5.9.x working-tree scan",
  "counts" => counts,
  "locations" => locations
}
File.write(File.join(report_dir, "concurrency_5_9.json"), JSON.pretty_generate(payload) + "\n")

markdown = []
markdown << "# PTools 5.9.x Swift 6 并发扫描"
markdown << ""
markdown << "本报告只记录现状；系统对象兼容包装器必须继续登记在 Scripts/unchecked_sendable_allowlist.txt。"
markdown << ""
markdown << "| 规则 | 数量 |"
markdown << "| --- | ---: |"
counts.keys.sort.each { |name| markdown << "| #{name} | #{counts[name]} |" }
markdown << ""
markdown << "## 约束"
markdown << ""
markdown << "- 业务共享状态不得新增 @unchecked Sendable。"
markdown << "- 生产代码不得新增 nonisolated(unsafe)。"
markdown << "- Any、Progress 和 UIKit/PhotoKit 对象不得直接跨 actor 传递。"
markdown << "- Task.detached 只能用于明确不继承 actor 状态的纯后台工作。"
File.write(File.join(report_dir, "concurrency_5_9.md"), markdown.join("\n") + "\n")
puts "Concurrency 5.9 report: #{counts.inspect}"
