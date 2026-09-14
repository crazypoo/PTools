#!/usr/bin/env ruby

require "json"
require "fileutils"
require "time"

repo_root = File.expand_path("..", __dir__)
source_root = File.join(repo_root, "PooToolsSource")
report_dir = File.join(repo_root, "report", "current")
FileUtils.mkdir_p(report_dir)

entries = []
Dir.glob(File.join(source_root, "**", "*.swift")).sort.each do |file|
  relative = file.delete_prefix("#{repo_root}/")
  File.foreach(file).with_index do |line, index|
    kind = if line.include?("NSCache")
             "NSCache"
           elsif line.include?("URLCache")
             "URLCache"
           elsif line.match?(/\b(?:Cache|cache|Caching|caching)\b/)
             "disk or custom cache"
           end
    next unless kind
    entries << {
      "path" => relative,
      "line" => index + 1,
      "kind" => kind,
      "text" => line.strip
    }
  end
end

payload = {
  "schema_version" => 1,
  "generator" => "Scripts/report_cache_inventory_5_9.rb",
  "source_revision" => `git -C "#{repo_root}" rev-parse HEAD`.strip,
  "generated_at" => Time.now.utc.iso8601,
  "entries" => entries,
  "bounded_memory_caches" => entries.count { |entry| entry["kind"] == "NSCache" }
}
File.write(File.join(report_dir, "cache_inventory.json"), JSON.pretty_generate(payload) + "\n")

markdown = []
markdown << "<!--"
markdown << "AUTO-GENERATED FILE."
markdown << "DO NOT EDIT MANUALLY."
markdown << ""
markdown << "Generator: #{payload["generator"]}"
markdown << "Source revision: #{payload["source_revision"]}"
markdown << "Generated at: #{payload["generated_at"]}"
markdown << "-->"
markdown << ""
markdown << "# PTools 当前缓存盘点"
markdown << ""
markdown << "本报告标出缓存实现位置，后续优化必须同时记录所有者、线程边界、容量和清理策略。"
markdown << ""
markdown << "| 位置 | 类型 | 代码行 |"
markdown << "| --- | --- | --- |"
entries.each do |entry|
  text = entry["text"].gsub("|", "\\|")
  markdown << "| #{entry["path"]}:#{entry["line"]} | #{entry["kind"]} | #{text} |"
end
File.write(File.join(report_dir, "cache_inventory.md"), markdown.join("\n") + "\n")
puts "Cache current report: entries=#{entries.length}"
