#!/usr/bin/env ruby

require "json"
require "fileutils"

# English: Generate the Swift 6 unchecked-sendable inventory from source and its centralized allowlist.
# Español: Genera el inventario de unchecked-sendable de Swift 6 desde el código y su lista centralizada.
# 中文：从源码和集中白名单生成 Swift 6 unchecked-sendable 清单。

repo_root = File.expand_path("..", __dir__)
source_root = File.join(repo_root, "PooToolsSource")
allowlist_path = File.join(repo_root, "Scripts", "unchecked_sendable_allowlist.txt")
report_dir = File.join(repo_root, "report")
FileUtils.mkdir_p(report_dir)

allowlisted = File.readlines(allowlist_path, chomp: true).filter_map do |line|
  line = line.strip
  next if line.empty? || line.start_with?("#")
  line
end

declarations = []
Dir.glob(File.join(source_root, "**", "*.swift")).sort.each do |file|
  relative = file.delete_prefix("#{repo_root}/")
  File.readlines(file).each_with_index do |line, index|
    next unless line.include?("@unchecked Sendable")
    declarations << {
      "path" => relative,
      "line" => index + 1,
      "declaration" => line.strip,
      "allowlisted" => allowlisted.include?(relative)
    }
  end
end

payload = {
  "schema_version" => 1,
  "generated_from" => "PooToolsSource/**/*.swift",
  "allowlist" => allowlisted,
  "declarations" => declarations
}
File.write(File.join(report_dir, "sendable_exceptions_5_8.json"), JSON.pretty_generate(payload) + "\n")

markdown = []
markdown << "# Swift 6 Sendable 例外清单"
markdown << ""
markdown << "本文件由 `Scripts/report_sendable_exceptions.rb` 生成；它只记录现状，不把 `@unchecked Sendable` 视为无条件安全。"
markdown << ""
markdown << "| 类型/声明位置 | 行号 | 声明 | 白名单 | 处理原则 |"
markdown << "| --- | ---: | --- | --- | --- |"
declarations.each do |entry|
  role = if entry["path"].include?("PhotoPicker") || entry["path"].include?("VideoEditor") || entry["path"].include?("AVAsset")
           "系统媒体对象窄边界，继续用快照或生命周期保护"
         elsif entry["path"].include?("Debug") || entry["path"].include?("Inspector") || entry["path"].include?("Swizzle")
           "诊断/运行时兼容边界，待诊断目标隔离"
         else
           "兼容边界；不得新增业务共享状态"
         end
  markdown << "| `#{entry["path"]}` | #{entry["line"]} | `#{entry["declaration"].gsub("|", "\\|")}` | #{entry["allowlisted"] ? "yes" : "NO"} | #{role} |"
end
markdown << "| 无 | 0 | 无声明 | - | - |" if declarations.empty?
markdown << ""
markdown << "## 版本门槛"
markdown << ""
markdown << "- 新业务模型不得新增 `@unchecked Sendable`。"
markdown << "- 新的系统对象包装器必须在 `Scripts/unchecked_sendable_allowlist.txt` 登记，并说明保护方式与替代版本。"
markdown << "- `nonisolated(unsafe)` 不得用于业务共享状态。"
File.write(File.join(repo_root, "SENDABLE_EXCEPTIONS_5_8.md"), markdown.join("\n") + "\n")

puts "Sendable report: declarations=#{declarations.length}, allowlisted_files=#{allowlisted.length}"
