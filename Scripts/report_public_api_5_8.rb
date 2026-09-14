#!/usr/bin/env ruby

require "json"
require "fileutils"
require "time"

# English: Produce a deterministic source-level public API inventory without claiming ABI stability.
# Español: Produce un inventario determinista de API pública a nivel de código sin afirmar estabilidad ABI.
# 中文：生成确定性的源码级公开 API 清单，但不宣称 ABI 稳定。

repo_root = File.expand_path("..", __dir__)
source_root = File.join(repo_root, "PooToolsSource")
report_dir = File.join(repo_root, "report", "baselines", "5.8")
FileUtils.mkdir_p(report_dir)

declarations = []
pattern = /^\s*(public|open)\s+(?:nonisolated\s+)?(class|struct|enum|protocol|actor|func|init|var|let|typealias|subscript)\b/
Dir.glob(File.join(source_root, "**", "*.swift")).sort.each do |file|
  relative = file.delete_prefix("#{repo_root}/")
  File.readlines(file).each_with_index do |line, index|
    match = line.match(pattern)
    next unless match
    declarations << {
      "path" => relative,
      "line" => index + 1,
      "access" => match[1],
      "kind" => match[2],
      "declaration" => line.strip
    }
  end
end

payload = {
  "schema_version" => 1,
  "baseline" => "5.8.x source inventory",
  "abi_claim" => false,
  "generated_from" => "PooToolsSource/**/*.swift",
  "generator" => "Scripts/report_public_api_5_8.rb",
  "source_revision" => `git -C "#{repo_root}" rev-parse HEAD`.strip,
  "generated_at" => Time.now.utc.iso8601,
  "declarations" => declarations
}
File.write(File.join(report_dir, "public_api.generated.json"), JSON.pretty_generate(payload) + "\n")
puts "Public API report: declarations=#{declarations.length}"
