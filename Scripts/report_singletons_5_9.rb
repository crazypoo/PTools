#!/usr/bin/env ruby

require "json"
require "fileutils"

repo_root = File.expand_path("..", __dir__)
source_root = File.join(repo_root, "PooToolsSource")
report_dir = File.join(repo_root, "report")
FileUtils.mkdir_p(report_dir)

entries = []
shared_calls = 0
Dir.glob(File.join(source_root, "**", "*.swift")).sort.each do |file|
  relative = file.delete_prefix("#{repo_root}/")
  File.foreach(file).with_index do |line, index|
    shared_calls += line.scan(/\.shared\b/).length
    next unless line.match?(/\bstatic\s+(?:let|var)\s+shared\b/)
    scope = if relative.match?(/Base|Actionsheet|LocalConsole|Inspector|TouchInspector|Navigation/)
              "UI or lifecycle state"
            elsif relative.match?(/Network|Cache|Socket|Permission/)
              "service or shared resource"
            else
              "legacy/global state"
            end
    entries << {
      "path" => relative,
      "line" => index + 1,
      "declaration" => line.strip,
      "scope" => scope
    }
  end
end

payload = {
  "schema_version" => 1,
  "shared_call_count" => shared_calls,
  "declarations" => entries
}
File.write(File.join(report_dir, "singletons_5_9.json"), JSON.pretty_generate(payload) + "\n")

markdown = []
markdown << "# PTools 5.9.x 单例范围盘点"
markdown << ""
markdown << "本报告用于后续 DI 迁移；它不会自动改变现有单例生命周期。"
markdown << ""
markdown << "- .shared 调用文本计数：**#{shared_calls}**"
markdown << "- 单例声明计数：**#{entries.length}**"
markdown << ""
markdown << "| 位置 | 分类 | 声明 |"
markdown << "| --- | --- | --- |"
entries.each do |entry|
  declaration = entry["declaration"].gsub("|", "\\|")
  markdown << "| #{entry["path"]}:#{entry["line"]} | #{entry["scope"]} | #{declaration} |"
end
File.write(File.join(report_dir, "singletons_5_9.md"), markdown.join("\n") + "\n")
puts "Singleton 5.9 report: declarations=#{entries.length}, shared_calls=#{shared_calls}"
