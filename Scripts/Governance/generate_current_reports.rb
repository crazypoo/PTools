#!/usr/bin/env ruby

# English: Normalize every current report to the same repository and version facts.
# Español: Normaliza cada informe actual con los mismos hechos de repositorio y versión.
# 中文：将所有当前报告统一到同一份仓库和版本事实。

require "json"
require "fileutils"
require "time"

repo_root = File.expand_path("../..", __dir__)
current_dir = ENV.fetch("PTOOLS_REPORT_DIR", File.join(repo_root, "report", "current"))
FileUtils.mkdir_p(current_dir)

revision = `git -C "#{repo_root}" rev-parse HEAD`.strip
branch = `git -C "#{repo_root}" branch --show-current`.strip
branch = "DETACHED" if branch.empty?
version = File.read(File.join(repo_root, "VERSION")).strip
generated_at = Time.now.utc.iso8601
repository = "crazypoo/PTools"
source_inputs_digest = `ruby "#{File.join(__dir__, "source_inputs_digest.rb")}"`.strip

def metadata(repository, branch, revision, version, generator_version, source_inputs_digest)
  {
    "repository" => repository,
    "branch" => branch,
    "sourceRevision" => revision,
    "sourceVersion" => version,
    "generatorVersion" => generator_version,
    "sourceInputsDigest" => source_inputs_digest
  }
end

Dir.glob(File.join(current_dir, "*.json")).sort.each do |path|
  payload = JSON.parse(File.read(path))
  generator = payload["generator"] || payload["generatorVersion"] || "current-report-normalizer"
  payload["schemaVersion"] ||= payload["schema_version"] || 1
  payload["generatedAt"] = generated_at
  payload.merge!(metadata(repository, branch, revision, version, generator, source_inputs_digest))
  payload["source_revision"] = revision if payload.key?("source_revision")
  payload["generated_at"] = payload["generatedAt"] if payload.key?("generated_at")
  File.write(path, JSON.pretty_generate(payload) + "\n")
end

report_metadata_header = [
  "<!--",
  "Current report metadata.",
  "AUTO-GENERATED FILE.",
  "Repository: #{repository}",
  "Branch: #{branch}",
  "Source revision: #{revision}",
  "Source version: #{version}",
  "Source inputs digest: #{source_inputs_digest}",
  "Generator version: 1",
  "Generator: Scripts/governance/generate_current_reports.rb",
  "Generated at: #{generated_at}",
  "-->"
].join("\n")

Dir.glob(File.join(current_dir, "*.md")).sort.each do |path|
  content = File.read(path)
  generator = content[/Generator:\s*(.+)$/, 1] || "current-report-normalizer"
  header = [
    "<!--",
    "Current report metadata.",
    "AUTO-GENERATED FILE.",
    "Repository: #{repository}",
    "Branch: #{branch}",
    "Source revision: #{revision}",
    "Source version: #{version}",
    "Source inputs digest: #{source_inputs_digest}",
    "Generator version: 1",
    "Generator: #{generator}",
    "Generated at: #{generated_at}",
    "-->"
  ].join("\n")
  if content.start_with?("<!--")
    content = content.sub(/\A<!--.*?-->/m, header)
  else
    content = "#{header}\n\n#{content}"
  end
  File.write(path, content.end_with?("\n") ? content : "#{content}\n")
end

governance = metadata(repository, branch, revision, version, "Scripts/governance/generate_current_reports.rb", source_inputs_digest)
governance["generator"] = "Scripts/governance/generate_current_reports.rb"
governance["schemaVersion"] = 1
governance["generatedAt"] = generated_at
governance["source_revision"] = revision
governance["generated_at"] = generated_at
governance["reportDirectory"] = "report/current"
governance["historicalDirectory"] = "report/baselines/<version>"
File.write(File.join(current_dir, "governance.json"), JSON.pretty_generate(governance) + "\n")

registry_path = File.join(repo_root, "Scripts", "concurrency_exception_registry.json")
registry_payload = JSON.parse(File.read(registry_path))
registry = registry_payload.fetch("exceptions", registry_payload.fetch("files", []))
allowlist = File.readlines(File.join(repo_root, "Scripts", "unchecked_sendable_allowlist.txt"), chomp: true)
  .map(&:strip).reject { |line| line.empty? || line.start_with?("#") }
declarations = []
Dir.glob(File.join(repo_root, "PooToolsSource", "**", "*.swift")).sort.each do |file|
  relative = file.delete_prefix("#{repo_root}/")
  File.readlines(file).each_with_index do |line, index|
    next unless line.include?("@unchecked Sendable")
    entry = registry.find { |item| item["path"] == relative }
    declarations << [relative, index + 1, entry]
  end
end

lines = [
  report_metadata_header,
  "",
  "# Swift 6 Concurrency Exceptions v2",
  "",
  "| File | Symbol | Exception | Category | Reason | Protection | Owner | 6.0 action |",
  "| --- | --- | --- | --- | --- | --- | --- | --- |"
]
declarations.each do |path, line, entry|
  category = entry&.fetch("category", "UNREGISTERED") || "UNREGISTERED"
  symbol = File.readlines(File.join(repo_root, path))[line - 1].strip.gsub("|", "\\|")
  reason = entry ? "system callback boundary; mutable state remains isolated" : "unregistered exception"
  protection = entry ? "serial delegate/actor or MainActor boundary" : "none"
  owner = entry ? "Debug/Concurrency owner" : "unassigned"
  action = entry ? "keep until dedicated native callback adapter replaces it" : "remove before 6.0"
  lines << "| `#{path}` | `#{symbol}` | `@unchecked Sendable` | #{category} | #{reason} | #{protection} | #{owner} | #{action} |"
end
lines << "| None | — | — | — | — | — | — | — |" if declarations.empty?
lines << ""
lines << "Allowlisted files: #{allowlist.length}. Business state must not be added to this list."
File.write(File.join(current_dir, "concurrency_exceptions_v2.md"), lines.join("\n") + "\n")

puts "Current reports normalized: #{revision} / #{version}"
