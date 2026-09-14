#!/usr/bin/env ruby

require "json"
require "fileutils"
require "time"

repo_root = File.expand_path("..", __dir__)
source_root = File.join(repo_root, "PooToolsSource")
report_dir = File.join(repo_root, "report", "current")
FileUtils.mkdir_p(report_dir)

pattern = /^\s*(?:(?:@[A-Za-z_][A-Za-z0-9_]*(?:\([^)]*\))?)\s*)*(public|open)\s+(?:(?:nonisolated)\s+)?(class|struct|enum|protocol|actor|func|init|var|let|typealias|subscript)\b/
declarations = []

Dir.glob(File.join(source_root, "**", "*.swift")).sort.each do |file|
  relative = file.delete_prefix("#{repo_root}/")
  File.foreach(file).with_index do |line, index|
    match = line.match(pattern)
    next unless match

    declaration = line.strip.gsub(/\s+/, " ")
    signature = declaration.sub(/[\{;].*$/, "").strip
    declarations << {
      "key" => [relative, match[1], match[2], signature].join("|"),
      "path" => relative,
      "line" => index + 1,
      "access" => match[1],
      "kind" => match[2],
      "declaration" => declaration
    }
  end
end

payload = {
  "schema_version" => 2,
  "baseline" => "current source inventory",
  "abi_claim" => false,
  "generated_from" => "PooToolsSource/**/*.swift",
  "generator" => "Scripts/report_public_api_5_9.rb",
  "source_revision" => `git -C "#{repo_root}" rev-parse HEAD`.strip,
  "generated_at" => Time.now.utc.iso8601,
  "declarations" => declarations
}

json = JSON.pretty_generate(payload) + "\n"
FileUtils.mkdir_p(report_dir)
File.write(File.join(report_dir, "public_api.json"), json)

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
markdown << "# PTools 当前公开 API 清单"
markdown << ""
markdown << "本报告由 Scripts/report_public_api_5_9.rb 生成，记录源码级声明，不宣称 ABI 稳定。"
markdown << ""
markdown << "| 位置 | 类型 | 访问级别 | 声明 |"
markdown << "| --- | --- | --- | --- |"
declarations.each do |entry|
  declaration = entry["declaration"].gsub("|", "\\|")
  markdown << "| #{entry["path"]}:#{entry["line"]} | #{entry["kind"]} | #{entry["access"]} | #{declaration} |"
end
markdown << "| 无 | - | - | 无公开声明 |" if declarations.empty?
markdown << ""
markdown << "## 兼容规则"
markdown << ""
markdown << "- 5.x 只新增正确命名的 canonical API，不删除既有公开符号。"
markdown << "- 旧拼写入口只能作为薄包装器存在，并在迁移文档中登记。"
markdown << "- 6.0.0 删除前必须先通过 API 差异检查和宿主项目迁移验证。"
File.write(File.join(report_dir, "public_api.md"), markdown.join("\n") + "\n")
puts "Public API current report: declarations=#{declarations.length}"
